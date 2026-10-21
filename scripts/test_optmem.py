import contextlib
import importlib.util
import io
import os
from pathlib import Path
import shlex
import sys
import tarfile
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('optmem', Path(__file__).with_name('optmem.py'))
optmem = importlib.util.module_from_spec(spec)
spec.loader.exec_module(optmem)


class OptMemTests(unittest.TestCase):
    def test_forwarded_arguments_are_literal_and_route_is_pinned(self):
        arguments = ['note', 'quote\' " ; $(touch /tmp/unsafe) `id`\nnew line', '--x']
        command = optmem.ssh_command('/bin/ssh', '/known hosts', arguments)
        self.assertEqual(shlex.split(command[-1]), ['/Users/melbournebaldove/.optmem/memo', *arguments])
        self.assertEqual(command[-2], 'melbournebaldove@100.89.96.77')
        self.assertEqual(command[1:5], ['-F', '/dev/null', '-T', '-p'])
        self.assertIn('StrictHostKeyChecking=yes', command)
        self.assertIn('BatchMode=yes', command)

    def test_server_ignores_alternate_store_and_keeps_public_path(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            upstream = home / 'upstream'
            upstream.write_text("import os, sys\nprint(__file__)\nprint(os.environ['MEMORY_DIR'])\nprint(repr(sys.argv))\n")
            output = io.StringIO()
            with patch.dict(os.environ, {'MEMORY_DIR': '/wrong/store'}), patch.object(sys, 'argv', []), contextlib.redirect_stdout(output):
                optmem.run_local(home, upstream, ['wake'])
            self.assertEqual(output.getvalue().splitlines(), [str(home / '.optmem/memo'), str(home / '.optmem/memory'), repr([str(home / '.optmem/memo'), 'wake'])])

    def test_snapshot_restores_log_tree_and_config_without_lock(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            store = home / '.optmem/memory'
            (store / 'TREE').mkdir(parents=True)
            for name, data in [('LOG.txt', b'original notes'), ('config', b'WAKE_LINES=96'), ('TREE/2', b'summary')]:
                (store / name).write_bytes(data)
            output = io.BytesIO()
            optmem.snapshot(home, output)
            output.seek(0)
            with tarfile.open(fileobj=output, mode='r:gz') as archive:
                self.assertNotIn('memory/.lock', archive.getnames())
                archive.extractall(home / 'restore')
            for name in ['LOG.txt', 'config', 'TREE/2']:
                self.assertEqual((store / name).read_bytes(), (home / 'restore/memory' / name).read_bytes())

    def test_failed_backup_preserves_previous_success(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            store = home / '.optmem/memory'
            store.mkdir(parents=True)
            (store / 'LOG.txt').write_text('saved note')
            source = home / 'snapshot.tar.gz'
            with source.open('wb') as output:
                optmem.snapshot(home, output)
            with contextlib.redirect_stdout(io.StringIO()):
                optmem.backup(home, [sys.executable, '-c', 'import pathlib,sys;sys.stdout.buffer.write(pathlib.Path(sys.argv[1]).read_bytes())', str(source)])
            destination = home / '.local/state/optmem/backups'
            previous = list(destination.glob('optmem-*.tar.gz'))
            contents = previous[0].read_bytes()
            with self.assertRaises(Exception):
                optmem.backup(home, [sys.executable, '-c', 'print("partial");raise SystemExit(255)'])
            self.assertEqual(list(destination.glob('optmem-*.tar.gz')), previous)
            self.assertEqual(previous[0].read_bytes(), contents)
            self.assertEqual(list(destination.glob('.pending-*')), [])


if __name__ == '__main__':
    unittest.main()
