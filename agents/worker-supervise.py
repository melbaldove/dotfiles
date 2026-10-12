#!/usr/bin/env python3
import argparse
from dataclasses import asdict, dataclass
import json
import math
import os
import re
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
from typing import Optional


@dataclass
class Receipt:
    status: str
    reason: str
    log_path: str
    report_path: str
    cwd: str
    pid: Optional[int] = None
    exit_code: Optional[int] = None
    elapsed_seconds: float = 0.0


def write_receipt(path, receipt):
    descriptor, temporary = tempfile.mkstemp(prefix='.' + path.name + '.', dir=str(path.parent))
    try:
        with os.fdopen(descriptor, 'w') as output:
            json.dump(asdict(receipt), output)
            output.write('\n')
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def artifact_path(value):
    path = Path(value)
    if not path.is_absolute():
        raise ValueError('Artifact paths must be absolute: ' + value)
    parent = path.parent.resolve(strict=True)
    if not parent.is_dir():
        raise ValueError('Artifact parent must be a directory: ' + value)
    return parent / path.name


def reserve_artifacts(paths):
    if len(set(paths)) != len(paths):
        raise ValueError('Log, result, and receipt paths must be distinct.')
    for path in paths:
        if path.exists() or path.is_symlink():
            raise ValueError('Artifact already exists; use a fresh path: ' + str(path))
    reserved = []
    try:
        for path in paths:
            descriptor = os.open(str(path), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            os.close(descriptor)
            reserved.append(path)
    except OSError:
        for path in reserved:
            path.unlink()
        raise


def read_report(path):
    try:
        if path.is_symlink() or not path.is_file():
            return 'unverified', 'Worker report is absent or is not a regular file.'
        with path.open() as source:
            text = source.read(1024 * 1024 + 1)
        if len(text) > 1024 * 1024:
            return 'unverified', 'Worker report exceeds 1 MiB.'
        if re.match(r'^Blocked(?:\s|[.:])', text):
            return 'blocked', text.strip()
        report = json.loads(text)
        if not isinstance(report, dict) or report.get('status') not in ('completed', 'blocked', 'failed'):
            return 'unverified', 'Worker report must declare completed, blocked, or failed.'
        reason = report.get('reason')
        if not isinstance(reason, str) or not reason.strip():
            return 'unverified', 'Worker report must include a nonempty reason.'
        return report['status'], reason.strip()
    except (OSError, ValueError, UnicodeError) as error:
        return 'unverified', 'Worker report is absent or malformed: ' + str(error)


def stop_group(worker):
    try:
        os.killpg(worker.pid, signal.SIGTERM)
    except ProcessLookupError:
        worker.wait()
        return
    deadline = time.monotonic() + 0.3
    while time.monotonic() < deadline:
        worker.poll()
        time.sleep(0.02)
    worker.poll()
    try:
        os.killpg(worker.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    worker.wait()


def supervise(arguments):
    cwd = Path(arguments.cwd).resolve(strict=True)
    if not cwd.is_dir():
        raise ValueError('Worker cwd must be a directory.')
    log = artifact_path(arguments.log)
    result = artifact_path(arguments.result)
    receipt_path = artifact_path(arguments.receipt)
    reserve_artifacts([log, result, receipt_path])
    receipt = Receipt('running', 'Worker launch is pending.', str(log), str(result), str(cwd))
    started = time.monotonic()
    cancelled = []
    previous_handlers = {}
    worker = None
    return_code = 1

    def receive_signal(number, frame):
        cancelled.append(number)

    try:
        for number in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
            previous_handlers[number] = signal.signal(number, receive_signal)
        write_receipt(receipt_path, receipt)
        with log.open('a') as output:
            worker = subprocess.Popen(arguments.command, cwd=str(cwd), stdin=subprocess.DEVNULL, stdout=output, stderr=subprocess.STDOUT, start_new_session=True)
            receipt.pid = worker.pid
            receipt.reason = 'Worker is running.'
            write_receipt(receipt_path, receipt)
            while True:
                exit_code = worker.poll()
                if cancelled:
                    receipt.status = 'failed'
                    receipt.reason = 'Worker cancelled by signal ' + str(cancelled[0]) + '.'
                    return_code = 128 + cancelled[0]
                    break
                if exit_code is not None:
                    receipt.status, receipt.reason = read_report(result)
                    if exit_code != 0:
                        receipt.status = 'failed'
                        receipt.reason = 'Worker exited with code {}. {}'.format(exit_code, receipt.reason)
                    return_code = 0 if receipt.status == 'completed' else 1
                    break
                status, reason = read_report(result)
                if status in ('blocked', 'failed'):
                    receipt.status, receipt.reason = status, reason
                    try:
                        worker.wait(timeout=0.05)
                    except subprocess.TimeoutExpired:
                        pass
                    break
                if time.monotonic() - started >= arguments.timeout:
                    receipt.status = 'failed'
                    receipt.reason = 'Worker timeout after {} seconds.'.format(arguments.timeout)
                    return_code = 124
                    break
                time.sleep(0.05)
    except Exception as error:
        receipt.status = 'failed'
        receipt.reason = 'Worker supervision failed: ' + str(error)
    finally:
        if worker is not None:
            try:
                stop_group(worker)
            except OSError as error:
                receipt.status = 'failed'
                receipt.reason += ' Process-group cleanup failed: ' + str(error)
                return_code = 1
                if worker.poll() is None:
                    worker.kill()
                worker.wait()
            receipt.exit_code = worker.returncode
        receipt.elapsed_seconds = round(time.monotonic() - started, 6)
        write_receipt(receipt_path, receipt)
        for number, handler in previous_handlers.items():
            signal.signal(number, handler)
    print(json.dumps(asdict(receipt)))
    return return_code


def main():
    parser = argparse.ArgumentParser(description='Own a developer worker, its result, and its process group. The worker must write JSON with terminal status and a reason to --result. Use fresh absolute artifact paths.')
    for name in ('cwd', 'log', 'result', 'receipt'):
        parser.add_argument('--' + name, required=True)
    parser.add_argument('--timeout', type=float, required=True)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    arguments = parser.parse_args()
    if arguments.command[:1] == ['--']:
        arguments.command = arguments.command[1:]
    if not arguments.command or not math.isfinite(arguments.timeout) or arguments.timeout <= 0:
        parser.error('A command and a finite positive timeout are required.')
    try:
        return supervise(arguments)
    except (OSError, ValueError) as error:
        parser.exit(2, str(error) + '\n')


if __name__ == '__main__':
    sys.exit(main())
