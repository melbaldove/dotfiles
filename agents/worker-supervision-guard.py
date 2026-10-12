#!/usr/bin/env python3
import json
import math
import os
from pathlib import Path
import re
import shlex
import sys


SUPERVISOR = Path(__file__).resolve().with_name('worker-supervise.py')
OPERATORS = re.compile(r'^[;&|()]+$|^[{}]$')


def shell_tokens(source):
    lexer = shlex.shlex(source, posix=True, punctuation_chars=';&|()')
    lexer.whitespace_split = True
    tokens = []
    for token in lexer:
        if re.fullmatch(r'[;&|()]+', token):
            tokens.extend(re.findall(r'[()]|[^()]+', token))
        else:
            tokens.append(token)
    return tokens


def executable_command(tokens):
    tokens = list(tokens)
    detached = False
    for _ in range(8):
        if not tokens:
            break
        if re.match(r'^[A-Za-z_]\w*=', tokens[0]) or tokens[0] in ('do', 'then', 'else', '!'):
            tokens = tokens[1:]
            continue
        executable = Path(tokens[0]).name
        if executable == 'nohup':
            tokens = tokens[1:]
            detached = True
        elif executable in ('command', 'exec'):
            tokens = tokens[1:]
            while tokens and tokens[0].startswith('-'):
                option = tokens.pop(0)
                if option == '-a' and tokens:
                    tokens.pop(0)
        elif executable == 'env':
            tokens = tokens[1:]
            while tokens:
                if tokens[0] in ('-u', '--unset'):
                    tokens = tokens[2:]
                elif tokens[0].startswith('-') or re.match(r'^[A-Za-z_]\w*=', tokens[0]):
                    tokens = tokens[1:]
                else:
                    break
        elif executable == 'timeout':
            tokens = tokens[1:]
            while tokens and tokens[0].startswith('-'):
                option = tokens.pop(0)
                if option in ('-k', '--kill-after', '-s', '--signal') and tokens:
                    tokens.pop(0)
            tokens = tokens[1:]
        else:
            break
    return tokens, detached


def script_sources(command, cwd):
    assignments = dict(re.findall(r'(?:^|[;\n]\s*)\s*([A-Za-z_]\w*)=([^;\n ]+)', command))
    expanded = os.path.expandvars(command)
    for name, value in assignments.items():
        expanded = expanded.replace('${' + name + '}', value).replace('$' + name, value)
    try:
        tokens = shell_tokens(expanded)
    except ValueError:
        return []
    sources = []
    candidates = []
    for command_tokens, detached in segments(tokens):
        command_tokens, wrapped_detached = executable_command(command_tokens)
        if not command_tokens:
            continue
        executable = Path(command_tokens[0]).name
        if command_tokens[0].endswith('.sh'):
            candidates.append(command_tokens[0])
        elif executable in ('bash', 'sh', 'zsh', 'source', '.'):
            candidates.extend(token for token in command_tokens[1:] if token.endswith('.sh'))
    for token in candidates:
        if '\n' in token:
            continue
        path = Path(os.path.expanduser(token))
        if not path.is_absolute():
            path = Path(cwd) / path
        try:
            if path.is_file() and path.stat().st_size <= 1024 * 1024:
                sources.append(path.read_text())
        except (OSError, UnicodeError):
            continue
    return sources


def valid_supervisor(tokens, cwd):
    if not tokens:
        return False
    executable = Path(tokens[0]).name
    if executable in ('python', 'python3') or re.fullmatch(r'python3\.\d+', executable):
        tokens = tokens[1:]
    if not tokens:
        return False
    path = Path(os.path.expanduser(os.path.expandvars(tokens[0])))
    if not path.is_absolute():
        path = Path(cwd) / path
    if path.resolve() != SUPERVISOR.resolve() or '--' not in tokens:
        return False
    separator = tokens.index('--')
    options = tokens[1:separator]
    if len(options) != 10 or not tokens[separator + 1:]:
        return False
    values = dict(zip(options[::2], options[1::2]))
    if set(values) != {'--cwd', '--log', '--result', '--receipt', '--timeout'}:
        return False
    paths = [Path(os.path.expandvars(values[name])).expanduser() for name in ('--log', '--result', '--receipt')]
    try:
        timeout = float(values['--timeout'])
        return all(path.is_absolute() for path in paths) and len(set(paths)) == 3 and math.isfinite(timeout) and timeout > 0
    except ValueError:
        return False


def pattern_probe(tokens):
    for index, token in enumerate(tokens):
        name = Path(token).name
        if name == 'pgrep' and any(re.fullmatch(r'-[A-Za-z]*f[A-Za-z]*', option) for option in tokens[index + 1:]):
            return True
        if name == 'ps' and '|' in tokens[index + 1:] and 'grep' in tokens[index + 1:]:
            return True
    return False


def process_wait(tokens):
    for index, token in enumerate(tokens):
        if token not in ('while', 'until'):
            continue
        try:
            body = tokens.index('do', index + 1)
            end = tokens.index('done', body + 1)
        except ValueError:
            continue
        if pattern_probe(tokens[index + 1:body]):
            return True
        for condition in range(body + 1, end):
            if tokens[condition] != 'if':
                continue
            try:
                branch = tokens.index('then', condition + 1)
                finish = tokens.index('fi', branch + 1)
            except ValueError:
                continue
            if finish <= end and pattern_probe(tokens[condition + 1:branch]) and any(word in ('exit', 'break') for word in tokens[branch + 1:finish]):
                return True
    return False


def detached_group_indexes(tokens):
    stack = []
    detached = set()
    for index, token in enumerate(tokens):
        if token in ('(', '{'):
            stack.append((token, index))
        elif token in (')', '}') and stack:
            opener, start = stack[-1]
            if (opener, token) in (('(', ')'), ('{', '}')):
                stack.pop()
                if index + 1 < len(tokens) and tokens[index + 1] == '&':
                    detached.update(range(start + 1, index))
    return detached


def segments(tokens, background_indexes=None):
    background_indexes = background_indexes or set()
    current = []
    inherited = False
    for index, token in enumerate(tokens):
        if OPERATORS.fullmatch(token):
            if current:
                yield current, inherited or token == '&'
            current = []
            inherited = False
        else:
            current.append(token)
            inherited = inherited or index in background_indexes
    if current:
        yield current, inherited


def raw_worker(tokens):
    if not tokens:
        return False
    executable = Path(tokens[0]).name
    if executable == 'codex':
        return 'exec' in tokens[1:]
    if executable == 'claude':
        return any(option == '--print' or re.fullmatch(r'-[A-Za-z]*p[A-Za-z]*', option) for option in tokens[1:])
    return False


def source_violation(source, background, cwd, depth=0):
    if depth > 4:
        return None
    try:
        tokens = shell_tokens(source)
    except ValueError:
        return None
    if process_wait(tokens):
        return 'Process-pattern wait loops can match peer watchers and miss a stopped worker.'
    for command, detached in segments(tokens, detached_group_indexes(tokens)):
        command, wrapped_detached = executable_command(command)
        detached = detached or wrapped_detached
        if not command or valid_supervisor(command, cwd):
            continue
        executable = Path(command[0]).name
        launcher = command[1] if executable.startswith('python') and len(command) > 1 else command[0]
        if Path(launcher).name == 'worker-supervise.py':
            return 'Use the managed supervisor path and all required artifact and timeout options.'
        if raw_worker(command) and (background or detached):
            return 'A detached developer worker loses its child handle and final result.'
        if executable in ('bash', 'sh', 'zsh'):
            for index, token in enumerate(command[1:], start=1):
                if re.fullmatch(r'-[A-Za-z]*c[A-Za-z]*', token) and index + 1 < len(command):
                    reason = source_violation(command[index + 1], background or detached, cwd, depth + 1)
                    if reason:
                        return reason
    return None


def violation(command, background, cwd):
    for source in [command] + script_sources(command, cwd):
        reason = source_violation(source, background, cwd)
        if reason:
            return reason
    if background:
        try:
            for command_tokens, detached in segments(shell_tokens(command)):
                command_tokens, wrapped_detached = executable_command(command_tokens)
                if not command_tokens:
                    continue
                executable = Path(command_tokens[0]).name
                script = command_tokens[1] if executable in ('bash', 'sh', 'zsh') and len(command_tokens) > 1 else command_tokens[0]
                if Path(script).name == 'watch.sh' and any('codex exec' in argument for argument in command_tokens[1:]):
                    return 'This worker watcher has no owned child handle. Its source must use the supported supervisor.'
        except ValueError:
            pass
    return None


def main():
    try:
        event = json.load(sys.stdin)
        if event.get('tool_name') != 'Bash':
            return 0
        tool_input = event.get('tool_input', {})
        command = tool_input.get('command', '')
        if not isinstance(command, str):
            return 0
        reason = violation(command, bool(tool_input.get('run_in_background')), event.get('cwd', os.getcwd()))
        if reason:
            output = {'hookSpecificOutput': {'hookEventName': 'PreToolUse', 'permissionDecision': 'deny', 'permissionDecisionReason': reason + ' Use ' + str(SUPERVISOR) + ' --cwd PATH --log PATH --result PATH --receipt PATH --timeout SECONDS -- COMMAND ARG... with fresh paths.'}}
            print(json.dumps(output))
        return 0
    except (ValueError, OSError, TypeError) as error:
        print('worker-supervision-guard: ' + str(error), file=sys.stderr)
        return 2


if __name__ == '__main__':
    sys.exit(main())
