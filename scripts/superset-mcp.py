import argparse
import os
import signal
import subprocess
import sys
import tempfile
from pathlib import Path


def shutdown(signum, frame):
    raise SystemExit(0)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--workspace', type=Path, required=True)
    parser.add_argument('--profile', required=True)
    parser.add_argument('--private-key', type=Path, required=True)
    arguments = parser.parse_args()
    os.umask(0o077)
    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGHUP, shutdown)
    workspace = arguments.workspace.resolve()
    repo = Path(subprocess.check_output([str(workspace / 'scripts/repo-path'), 'superset'], text=True).strip())
    sys.path.insert(0, str(repo / 'upgrade/operations'))
    from prepare_copy import Operator
    import protected_copy as copy

    key = arguments.private_key
    if not key.is_file() or key.is_symlink() or key.stat().st_mode & 0o077:
        parser.error('The personal signing key requires a private regular file')
    state = Path.home() / '.local/state/hy-superset-mcp'
    state.mkdir(mode=0o700, parents=True, exist_ok=True)
    directory = Path(tempfile.mkdtemp(prefix='connection-', dir=state))
    operator = Operator(arguments.profile, 'ap-southeast-2', directory, None, None)
    with operator.tunnel(copy.CANDIDATE, 5008, 'personal-mcp') as port:
        command = [sys.executable, str(repo / 'upgrade/tools/client_proxy.py'), '--private-key', str(key),
                   '--endpoint', 'http://127.0.0.1:' + str(port) + '/mcp']
        child = subprocess.Popen(command)
        try:
            return child.wait()
        finally:
            if child.poll() is None:
                child.terminate()
                try:
                    child.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    child.kill()
                    child.wait(timeout=5)


if __name__ == '__main__':
    raise SystemExit(main())
