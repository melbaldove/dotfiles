import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time
import unittest
import uuid


ROOT = Path(__file__).resolve().parent
SUPERVISOR = ROOT / 'worker-supervise.py'
GUARD = ROOT / 'worker-supervision-guard.py'
FIXTURES = json.loads((ROOT / 'worker-supervision-transcript-fixtures.json').read_text())
BLOCKED = FIXTURES['blocked_report']['text']


class WorkerSupervisionTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.directory = Path(self.temp.name).resolve()
        self.log = self.directory / 'worker.log'
        self.result = self.directory / 'result.json'
        self.receipt = self.directory / 'receipt.json'

    def tearDown(self):
        self.temp.cleanup()

    def launch(self, source, timeout=3):
        return [sys.executable, str(SUPERVISOR), '--cwd', str(self.directory), '--log', str(self.log), '--result', str(self.result), '--receipt', str(self.receipt), '--timeout', str(timeout), '--', sys.executable, '-c', source]

    def run_worker(self, source, timeout=3):
        process = subprocess.run(self.launch(source, timeout), capture_output=True, text=True, timeout=8)
        self.assertTrue(self.receipt.is_file(), process.stderr)
        receipt = json.loads(self.receipt.read_text())
        self.assertEqual(json.loads(process.stdout), receipt)
        return process, receipt

    def write_report(self, report):
        return 'from pathlib import Path; Path({!r}).write_text({!r})'.format(str(self.result), json.dumps(report))

    def guard(self, command, background=False):
        payload = {'hook_event_name': 'PreToolUse', 'tool_name': 'Bash', 'tool_input': {'command': command, 'run_in_background': background}, 'cwd': str(self.directory)}
        return subprocess.run([sys.executable, str(GUARD)], input=json.dumps(payload), text=True, capture_output=True, timeout=3)

    def assert_denied(self, command, background=False):
        process = self.guard(command, background)
        self.assertEqual(process.returncode, 0, process.stderr)
        self.assertTrue(process.stdout.strip(), 'The guard must emit a deny decision.')
        decision = json.loads(process.stdout)['hookSpecificOutput']
        self.assertEqual(decision['permissionDecision'], 'deny')
        self.assertIn('worker-supervise.py', decision['permissionDecisionReason'])

    def test_historical_tool_commands_are_denied(self):
        for fixture in FIXTURES['commands']:
            with self.subTest(source=fixture['source'], line=fixture['line']):
                tool = fixture['tool_input']
                self.assert_denied(tool['command'], tool.get('run_in_background', False))

    def test_invoked_watcher_source_is_checked(self):
        writer = next(item for item in FIXTURES['commands'] if item['source'].startswith('agent-a6') and item['line'] == 86)
        script = writer['tool_input']['command'].split("<<'EOF'\n", 1)[1].split('\nEOF', 1)[0]
        watch = self.directory / 'stepc' / 'watch.sh'
        watch.parent.mkdir()
        watch.write_text(script)
        command = 'S={}; bash $S/stepc/watch.sh log pattern worktree'.format(self.directory)
        self.assert_denied(command)

    def test_guard_allows_quoted_watcher_documentation(self):
        watcher = self.directory / 'unsafe-example.sh'
        watcher.write_text('until ! pgrep -f worker; do sleep 30; done')
        process = self.guard('echo {}'.format(watcher))
        self.assertEqual(process.returncode, 0)
        self.assertEqual(process.stdout, '')

    def test_guard_allows_diagnostics_and_supervisor(self):
        for command in ['pgrep -f codex', 'ps -axo args | grep codex', '{} {} --cwd /tmp --log /tmp/l --result /tmp/r --receipt /tmp/s --timeout 20 -- codex exec task'.format(sys.executable, SUPERVISOR), 'python3 -c "print(123)"', "printf '%s\\n' 'codex exec task &'", "echo 'until ! pgrep -f task; do sleep 30; done'", 'while true; do pgrep -f codex; break; done']:
            with self.subTest(command=command):
                process = self.guard(command)
                self.assertEqual(process.returncode, 0, process.stderr)
                self.assertEqual(process.stdout, '')

    def test_guard_denies_detached_workers_despite_supervisor_mentions(self):
        for command in ['echo worker-supervise.py; codex exec task &', 'python3 -c "print(\"worker-supervise.py\")"; codex exec task &', 'claude -p task &', 'codex exec task']:
            with self.subTest(command=command):
                self.assert_denied(command, background=True)

    def test_guard_rejects_fake_supervisor_and_missing_artifact_options(self):
        for command in ['python3 /tmp/worker-supervise.py --cwd /tmp --log /tmp/l --result /tmp/r --receipt /tmp/s --timeout 20 -- codex exec task &', 'python3 {} -- codex exec task &'.format(SUPERVISOR)]:
            with self.subTest(command=command):
                self.assert_denied(command)

    def test_guard_denies_detached_workers_through_common_wrappers(self):
        for prefix in ['env TMPDIR=/tmp', 'command', 'timeout 30', 'exec', 'nohup', '/usr/bin/env -u UNUSED']:
            with self.subTest(prefix=prefix):
                self.assert_denied(prefix + ' codex exec task &')
                process = self.guard(prefix + ' pgrep -f codex')
                self.assertEqual(process.returncode, 0, process.stderr)
                self.assertEqual(process.stdout, '')

    def test_guard_allows_wrapped_canonical_supervisor(self):
        command = '{} {} --cwd /tmp --log /tmp/l --result /tmp/r --receipt /tmp/s --timeout 20 -- codex exec task'.format(sys.executable, SUPERVISOR)
        for prefix in ['env TMPDIR=/tmp', 'command', 'timeout 30', 'exec']:
            with self.subTest(prefix=prefix):
                process = self.guard(prefix + ' ' + command, background=True)
                self.assertEqual(process.returncode, 0, process.stderr)
                self.assertEqual(process.stdout, '')

    def test_guard_resolves_supervisor_from_relocated_source_and_symlink(self):
        checkout = self.directory / 'checkout' / 'agents'
        checkout.mkdir(parents=True)
        relocated_guard = checkout / 'worker-supervision-guard.py'
        relocated_supervisor = checkout / 'worker-supervise.py'
        relocated_guard.write_text(GUARD.read_text())
        relocated_supervisor.write_text(SUPERVISOR.read_text())
        hook_link = self.directory / 'installed-hook.py'
        hook_link.symlink_to(relocated_guard)
        command = '{} {} --cwd /tmp --log /tmp/l --result /tmp/r --receipt /tmp/s --timeout 20 -- codex exec task'.format(sys.executable, relocated_supervisor)
        payload = {'tool_name': 'Bash', 'tool_input': {'command': command, 'run_in_background': True}, 'cwd': str(self.directory)}
        for hook in [relocated_guard, hook_link]:
            with self.subTest(hook=str(hook)):
                process = subprocess.run([sys.executable, str(hook)], input=json.dumps(payload), text=True, capture_output=True, timeout=3)
                self.assertEqual(process.returncode, 0, process.stderr)
                self.assertEqual(process.stdout, '')

    def test_guard_denies_workers_inside_detached_shell_groups(self):
        for command in ['(codex exec task) &', '(cd /tmp; codex exec task) &', '{ codex exec task; } &', '(codex exec task)&', '( (codex exec task) ) &']:
            with self.subTest(command=command):
                self.assert_denied(command)

    def test_guard_allows_foreground_groups_and_quoted_group_text(self):
        for command in ['(codex exec task)', '(cd /tmp; codex exec task)', '{ codex exec task; }', 'echo "(codex exec task) &"', "printf '%s\\n' '{ codex exec task; } &'", '(pgrep -f codex) &']:
            with self.subTest(command=command):
                process = self.guard(command)
                self.assertEqual(process.returncode, 0, process.stderr)
                self.assertEqual(process.stdout, '')

    def test_zero_exit_requires_valid_terminal_report(self):
        process, receipt = self.run_worker(self.write_report({'status': 'completed', 'reason': 'The requested check passed.'}))
        self.assertEqual(process.returncode, 0)
        self.assertEqual(receipt['status'], 'completed')
        self.assertEqual(receipt['exit_code'], 0)
        self.assertEqual(receipt['report_path'], str(self.result))

    def test_historical_blocked_report_is_visible_on_synthetic_zero_exit(self):
        source = 'from pathlib import Path; Path({!r}).write_text({!r})'.format(str(self.result), BLOCKED)
        process, receipt = self.run_worker(source)
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(receipt['status'], 'blocked')
        self.assertIn('sandbox access to the shared Git index', receipt['reason'])
        self.assertEqual(receipt['exit_code'], 0)
        self.assertEqual(self.result.read_text(), BLOCKED)

    def test_blocked_report_interrupts_live_worker(self):
        source = self.write_report({'status': 'blocked', 'reason': 'Git index access denied.'}) + '; import time; time.sleep(10)'
        process, receipt = self.run_worker(source, timeout=4)
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(receipt['status'], 'blocked')
        self.assertLess(receipt['elapsed_seconds'], 3)

    def test_nonzero_exit_preserves_logs(self):
        process, receipt = self.run_worker('import sys; print("worker failure", flush=True); sys.exit(7)')
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(receipt['status'], 'failed')
        self.assertEqual(receipt['exit_code'], 7)
        self.assertIn('worker failure', self.log.read_text())
        self.assertEqual(receipt['log_path'], str(self.log))

    def test_missing_report_is_unverified(self):
        process, receipt = self.run_worker('pass')
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(receipt['status'], 'unverified')

    def test_malformed_report_is_unverified(self):
        source = 'from pathlib import Path; Path({!r}).write_text("not JSON")'.format(str(self.result))
        process, receipt = self.run_worker(source)
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(receipt['status'], 'unverified')

    def test_invalid_terminal_status_is_unverified(self):
        process, receipt = self.run_worker(self.write_report({'status': 'running', 'reason': 'still running'}))
        self.assertNotEqual(process.returncode, 0)
        self.assertEqual(receipt['status'], 'unverified')

    def test_structured_failed_report_preserves_reason(self):
        process, receipt = self.run_worker(self.write_report({'status': 'failed', 'reason': 'The native check failed.'}))
        self.assertEqual(process.returncode, 1)
        self.assertEqual(receipt['status'], 'failed')
        self.assertEqual(receipt['reason'], 'The native check failed.')

    def test_completed_report_requires_reason(self):
        process, receipt = self.run_worker(self.write_report({'status': 'completed'}))
        self.assertEqual(process.returncode, 1)
        self.assertEqual(receipt['status'], 'unverified')

    def test_running_receipt_is_visible_before_terminal_receipt(self):
        source = 'import time; time.sleep(0.5); ' + self.write_report({'status': 'completed', 'reason': 'done'})
        process = subprocess.Popen(self.launch(source), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            deadline = time.monotonic() + 2
            running = None
            while time.monotonic() < deadline and process.poll() is None:
                try:
                    candidate = json.loads(self.receipt.read_text())
                    if candidate['pid'] is not None:
                        running = candidate
                        break
                except (OSError, ValueError):
                    pass
                time.sleep(0.02)
            self.assertIsNotNone(running)
            self.assertEqual(running['status'], 'running')
            stdout, stderr = process.communicate(timeout=4)
            self.assertEqual(process.returncode, 0, stderr)
            self.assertEqual(json.loads(stdout)['status'], 'completed')
            self.assertEqual(json.loads(self.receipt.read_text())['pid'], running['pid'])
        finally:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=4)

    def test_symlink_artifact_fails_without_changing_target(self):
        target = self.directory / 'preserved'
        target.write_text('preserve')
        self.log.symlink_to(target)
        process = subprocess.run(self.launch('pass'), capture_output=True, text=True, timeout=3)
        self.assertEqual(process.returncode, 2)
        self.assertEqual(target.read_text(), 'preserve')
        self.assertFalse(self.receipt.exists())

    def test_existing_artifacts_fail_without_launch(self):
        self.log.write_text('preserve')
        marker = self.directory / 'launched'
        command = self.launch('from pathlib import Path; Path({!r}).touch()'.format(str(marker)))
        process = subprocess.run(command, capture_output=True, text=True, timeout=3)
        self.assertNotEqual(process.returncode, 0)
        self.assertFalse(marker.exists())
        self.assertEqual(self.log.read_text(), 'preserve')
        self.assertFalse(self.receipt.exists())

    def test_colliding_artifact_paths_fail_without_launch(self):
        command = self.launch('pass')
        command[command.index('--result') + 1] = str(self.log)
        process = subprocess.run(command, capture_output=True, text=True, timeout=3)
        self.assertNotEqual(process.returncode, 0)
        self.assertFalse(self.log.exists())

    def descendant_source(self, complete=False):
        heartbeat = self.directory / 'heartbeat'
        child = 'import signal,time; from pathlib import Path; signal.signal(signal.SIGTERM, signal.SIG_IGN); p=Path({!r});\nwhile True:\n p.write_text(str(time.monotonic())); time.sleep(0.03)'.format(str(heartbeat))
        source = 'import subprocess,sys,time; subprocess.Popen([sys.executable,"-c",{!r}]); time.sleep(0.2); '.format(child)
        source += self.write_report({'status': 'completed', 'reason': 'done'}) if complete else 'time.sleep(10)'
        return source, heartbeat

    def assert_heartbeat_stopped(self, heartbeat):
        self.assertTrue(heartbeat.exists())
        before = heartbeat.read_text()
        time.sleep(0.15)
        self.assertEqual(heartbeat.read_text(), before)

    def test_timeout_kills_term_ignoring_descendants(self):
        source, heartbeat = self.descendant_source()
        process, receipt = self.run_worker(source, timeout=0.4)
        self.assertEqual(process.returncode, 124)
        self.assertEqual(receipt['status'], 'failed')
        self.assertIn('timeout', receipt['reason'])
        self.assert_heartbeat_stopped(heartbeat)

    def test_success_cleans_lingering_descendants(self):
        source, heartbeat = self.descendant_source(complete=True)
        process, receipt = self.run_worker(source)
        self.assertEqual(process.returncode, 0)
        self.assertEqual(receipt['status'], 'completed')
        self.assert_heartbeat_stopped(heartbeat)

    def test_cancellation_kills_owned_group(self):
        source, heartbeat = self.descendant_source()
        process = subprocess.Popen(self.launch(source), stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            deadline = time.monotonic() + 3
            while not heartbeat.exists() and process.poll() is None and time.monotonic() < deadline:
                time.sleep(0.03)
            self.assertTrue(heartbeat.exists())
            process.send_signal(signal.SIGTERM)
            stdout, stderr = process.communicate(timeout=4)
            self.assertEqual(process.returncode, 143, stderr)
            receipt = json.loads(stdout)
            self.assertEqual(receipt['status'], 'failed')
            self.assertIn('cancelled', receipt['reason'])
            self.assert_heartbeat_stopped(heartbeat)
        finally:
            if process.poll() is None:
                process.kill()
                process.wait()

    def test_historical_peer_watchers_outlive_finished_worker(self):
        for historical in ['worker-task', 'codex exec resume fixture-session', 'codex exec.*worker-worktree']:
            pattern = historical + '-' + uuid.uuid4().hex
            command = "until ! pgrep -f '{}' >/dev/null; do sleep 0.03; done".format(pattern)
            dummy = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(10)', pattern], start_new_session=True)
            watchers = []
            try:
                watchers = [subprocess.Popen(['/bin/bash', '-c', command], start_new_session=True) for _ in range(3)]
                time.sleep(0.15)
                self.assertTrue(all(process.poll() is None for process in watchers))
                dummy.terminate()
                dummy.wait()
                time.sleep(0.15)
                self.assertTrue(all(process.poll() is None for process in watchers), 'Historical peers must keep matching after their worker exits.')
                print('REPLAY three historical peer watchers remain after worker exit: ' + historical, flush=True)
            finally:
                for process in watchers + [dummy]:
                    if process.poll() is None:
                        os.killpg(process.pid, signal.SIGKILL)
                    process.wait()

    @unittest.skipUnless(sys.platform == 'darwin', 'BSD pgrep ancestor exclusion is macOS-specific.')
    def test_lone_historical_watcher_exits_on_current_bsd_pgrep(self):
        pattern = 'worker-task-' + uuid.uuid4().hex
        process = subprocess.run(['/bin/bash', '-c', "until ! pgrep -f '{}' >/dev/null; do sleep 0.03; done".format(pattern)], timeout=2)
        self.assertEqual(process.returncode, 0)
        print('NEGATIVE CONTROL one historical watcher exits under current BSD pgrep.', flush=True)


if __name__ == '__main__':
    unittest.main(verbosity=2)
