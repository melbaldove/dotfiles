import json, os, select, subprocess, sys, time

codex = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else "~/.local/bin/codex")
proc = subprocess.Popen([codex, "app-server"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)

def send(message):
    proc.stdin.write(json.dumps(message) + "\n")
    proc.stdin.flush()

def receive(request_id, timeout=30):
    deadline = time.time() + timeout
    while time.time() < deadline:
        ready, _, _ = select.select([proc.stdout], [], [], 1)
        if ready:
            line = proc.stdout.readline()
            if not line:
                break
            message = json.loads(line)
            if message.get("id") == request_id:
                return message
    raise SystemExit(f"no response to request {request_id}")

def mstack_hooks(request_id):
    send({"jsonrpc": "2.0", "id": request_id, "method": "hooks/list", "params": {"cwds": [os.path.expanduser("~")]}})
    hooks = receive(request_id)["result"]["data"][0]["hooks"]
    return [hook for hook in hooks if hook.get("pluginId") == "mstack@mstack"]

send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"clientInfo": {"name": "mstack-trust", "version": "0"}}})
receive(1)
send({"jsonrpc": "2.0", "method": "initialized"})

pending = [hook for hook in mstack_hooks(2) if hook["trustStatus"] != "trusted"]
state = {}
for hook in pending:
    trusted_hash, content_hash = hook["currentHash"].split("/", 1)
    state[hook["key"]] = {"trusted_hash": trusted_hash, "trusted_content_hash": content_hash}
if state:
    send({"jsonrpc": "2.0", "id": 3, "method": "config/batchWrite", "params": {"edits": [{"keyPath": "hooks.state", "value": state, "mergeStrategy": "upsert"}]}})
    print(json.dumps(receive(3))[:300])
for hook in mstack_hooks(4):
    print(hook["key"], hook["trustStatus"])
proc.terminate()
