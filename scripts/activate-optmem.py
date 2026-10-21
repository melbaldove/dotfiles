import datetime
import json
import os
from pathlib import Path
import socket
import subprocess
import sys


def activate(deployment):
    host = socket.gethostname().split('.')[0].lower()
    if host not in ('einstein', 'eisenhower', 'turing') or not deployment.name.endswith(f'-optmem-deploy-{host}'):
        raise SystemExit('Deployment does not match this host')
    if not (deployment / '.optmem/memo').is_file():
        raise SystemExit('Build or import the deployment before activation')
    os.umask(0o077)
    home = Path.home()
    state = home / '.local/state/optmem/deployments'
    state.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    receipt = state / stamp
    receipt.mkdir()
    links = []
    for folder, _, names in os.walk(deployment):
        for name in names:
            source = Path(folder) / name
            target = home / source.relative_to(deployment)
            if target.exists() and not target.is_symlink():
                raise SystemExit(f'Refusing to replace unmanaged file: {target}')
            links.append({'path': str(target), 'previous': os.readlink(target) if target.is_symlink() else None, 'installed': str(source)})
    (receipt / 'links.json').write_text(json.dumps(links, indent=2) + '\n')
    subprocess.run(['nix-store', '--add-root', str(receipt / 'result'), '--realise', str(deployment)], check=True)
    for link in links:
        target = Path(link['path'])
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_name(target.name + '.optmem-new')
        temporary.symlink_to(link['installed'])
        os.replace(temporary, target)
    (home / '.optmem').chmod(0o700)
    if host == 'eisenhower':
        if not (home / '.optmem/memory').exists():
            subprocess.run([str(home / '.optmem/memo'), 'init'], check=True, stdout=subprocess.DEVNULL)
        (home / '.optmem/memory').chmod(0o700)
    elif host == 'einstein':
        subprocess.run(['systemctl', '--user', 'daemon-reload'], check=True)
        subprocess.run(['systemctl', '--user', 'enable', '--now', 'optmem-backup.timer'], check=True)
    print(f'Rollback links recorded in {receipt}/links.json')


def rollback(receipt):
    home = Path.home()
    links = json.loads(receipt.read_text())
    for link in links:
        target = Path(link['path'])
        if not target.is_relative_to(home) or not target.is_symlink() or os.readlink(target) != link['installed']:
            raise SystemExit(f'Link changed since activation; refusing rollback: {target}')
    if socket.gethostname().split('.')[0].lower() == 'einstein':
        subprocess.run(['systemctl', '--user', 'disable', '--now', 'optmem-backup.timer'], check=True)
        subprocess.run(['systemctl', '--user', 'stop', 'optmem-backup.service'], check=True)
    for link in links:
        target = Path(link['path'])
        target.unlink()
        if link['previous'] is not None:
            target.symlink_to(link['previous'])
    if socket.gethostname().split('.')[0].lower() == 'einstein':
        subprocess.run(['systemctl', '--user', 'daemon-reload'], check=True)
    print('Restored previous links. Memory data, backups, and deployment roots were preserved.')


if __name__ == '__main__':
    if sys.argv[1] == '--rollback':
        rollback(Path(sys.argv[2]))
    else:
        activate(Path(sys.argv[1]).resolve())
