import contextlib
import datetime
import fcntl
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tarfile
import tempfile
import uuid


@contextlib.contextmanager
def operation_lock(home):
    root = home / '.optmem'
    root.mkdir(mode=0o700, exist_ok=True)
    root.chmod(0o700)
    with (root / 'operations.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield


def run_local(home, upstream, arguments):
    os.umask(0o077)
    with operation_lock(home):
        store = home / '.optmem/memory'
        if store.exists():
            store.chmod(0o700)
        os.environ['MEMORY_DIR'] = str(store)
        public = str(home / '.optmem/memo')
        sys.argv = [public, *arguments]
        namespace = {'__name__': '__main__', '__file__': public}
        exec(compile(Path(upstream).read_bytes(), public, 'exec'), namespace)


def ssh_command(ssh, known_hosts, arguments, executable='memo'):
    remote = shlex.join([f'/Users/melbournebaldove/.optmem/{executable}', *arguments])
    return [ssh, '-F', '/dev/null', '-T', '-p', '22', '-o', 'BatchMode=yes', '-o',
            'StrictHostKeyChecking=yes', '-o', f'UserKnownHostsFile={known_hosts}',
            '-o', 'GlobalKnownHostsFile=/dev/null', '-o', 'ConnectTimeout=10',
            '-o', 'ServerAliveInterval=15', '-o', 'ServerAliveCountMax=3',
            'melbournebaldove@100.89.96.77', remote]


def snapshot(home, output):
    os.umask(0o077)
    with tempfile.TemporaryFile() as spool:
        with operation_lock(home):
            store = home / '.optmem/memory'
            if not (store / 'LOG.txt').is_file():
                raise RuntimeError('OptMem store is not initialized')
            with (store / '.lock').open('a') as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                with tarfile.open(fileobj=spool, mode='w:gz') as archive:
                    archive.add(store, arcname='memory', filter=lambda member:
                                None if member.name == 'memory/.lock' else member)
        spool.seek(0)
        shutil.copyfileobj(spool, output)


def backup(home, command):
    os.umask(0o077)
    destination = home / '.local/state/optmem/backups'
    destination.mkdir(parents=True, mode=0o700, exist_ok=True)
    destination.chmod(0o700)
    with (destination / '.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        descriptor, temporary = tempfile.mkstemp(prefix='.pending-', dir=destination)
        try:
            with os.fdopen(descriptor, 'wb') as output:
                subprocess.run(command, stdout=output, check=True)
                output.flush()
                os.fsync(output.fileno())
            with tarfile.open(temporary, 'r:gz') as archive:
                members = archive.getmembers()
                if not any(member.name == 'memory/LOG.txt' for member in members):
                    raise RuntimeError('Snapshot has no OptMem log')
                for member in members:
                    if member.isfile():
                        with archive.extractfile(member) as source:
                            while source.read(1024 * 1024):
                                pass
            stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
            target = destination / f'optmem-{stamp}-{uuid.uuid4().hex}.tar.gz'
            os.replace(temporary, target)
            for old in sorted(destination.glob('optmem-*.tar.gz'), reverse=True)[14:]:
                old.unlink()
            print(target)
        finally:
            Path(temporary).unlink(missing_ok=True)


def main():
    home = Path.home()
    role, *arguments = sys.argv[1:]
    if role == 'server':
        upstream, *arguments = arguments
        run_local(home, upstream, arguments)
    elif role == 'snapshot':
        snapshot(home, sys.stdout.buffer)
    elif role in ('client', 'backup'):
        ssh, known_hosts, *arguments = arguments
        if role == 'client':
            if arguments and arguments[0] == 'import':
                raise SystemExit('Import is server-local only; no automatic memory migration is configured.')
            result = subprocess.call(ssh_command(ssh, known_hosts, arguments))
            if result == 255:
                print('OptMem connection failed. A write may already have been saved; check recall before retrying.', file=sys.stderr)
            raise SystemExit(result)
        backup(home, ssh_command(ssh, known_hosts, [], 'snapshot'))
    else:
        raise ValueError(f'Unknown OptMem role: {role}')


if __name__ == '__main__':
    main()
