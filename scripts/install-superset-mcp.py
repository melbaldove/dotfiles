import os
import tempfile
import tomllib
from pathlib import Path


source = Path(__file__).resolve().parents[1] / 'codex/superset-mcp.toml'
fragment = source.read_bytes()
name = 'heyyou-superset'
desired = tomllib.loads(fragment.decode())['mcp_servers'][name]
config = Path.home() / '.codex/config.toml'
original = config.read_bytes()
current = tomllib.loads(original.decode()).get('mcp_servers', {}).get(name)
if current is not None:
    if current != desired:
        raise SystemExit('The existing Superset entry differs; inspect it before replacement')
    print('The personal Superset configuration already matches its dotfiles source.')
else:
    updated = original.rstrip() + b'\n\n' + fragment
    assert tomllib.loads(updated.decode())['mcp_servers'][name] == desired
    os.umask(0o077)
    state = Path.home() / '.local/state/hy-superset-mcp'
    state.mkdir(mode=0o700, parents=True, exist_ok=True)
    descriptor, backup = tempfile.mkstemp(prefix='codex-before-', suffix='.toml', dir=state)
    with os.fdopen(descriptor, 'wb') as stream:
        stream.write(original)
        stream.flush()
        os.fsync(stream.fileno())
    descriptor, staged = tempfile.mkstemp(prefix='.superset-', dir=config.parent)
    with os.fdopen(descriptor, 'wb') as stream:
        stream.write(updated)
        stream.flush()
        os.fsync(stream.fileno())
    assert config.read_bytes() == original
    os.replace(staged, config)
    descriptor = os.open(config.parent, os.O_RDONLY)
    os.fsync(descriptor)
    os.close(descriptor)
    print('Installed the personal Superset entry from its dotfiles source.')
