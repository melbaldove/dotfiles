#!/usr/bin/env python3
import argparse
import json
import subprocess
import sys
import time
import webbrowser
from urllib.parse import urlparse

from websockets.sync.client import unix_connect


class AccountError(Exception):
    pass


class Rpc:
    def __init__(self, connection):
        self.connection = connection
        self.request_id = 0
        self.login_completions = {}

    def send(self, message):
        self.connection.send(json.dumps(message))

    def receive(self, deadline):
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("The shared Codex server did not reply in time.")
        message = json.loads(self.connection.recv(timeout=remaining))
        if not isinstance(message, dict):
            raise AccountError("The shared Codex server returned an invalid message.")
        if message.get("method") == "account/login/completed":
            params = message.get("params", {})
            self.login_completions[params.get("loginId")] = params.get("success") is True
        if "method" in message and "id" in message:
            self.send({"id": message["id"], "error": {"code": -32601, "message": "This account client does not handle server requests."}})
        return message

    def request(self, method, params, timeout=30):
        self.request_id += 1
        request_id = self.request_id
        self.send({"id": request_id, "method": method, "params": params})
        deadline = time.monotonic() + timeout
        while True:
            message = self.receive(deadline)
            if message.get("id") != request_id or "method" in message:
                continue
            if "error" in message:
                code = message["error"].get("code", "unknown")
                raise AccountError(f"The shared Codex server rejected {method} with code {code}.")
            return message.get("result", {})

    def wait_for_login(self, login_id, timeout):
        deadline = time.monotonic() + timeout
        while login_id not in self.login_completions:
            self.receive(deadline)
        if not self.login_completions.pop(login_id):
            raise AccountError("Codex sign-in did not complete successfully. The existing sessions remain open.")


def daemon_version():
    result = subprocess.run(["codex", "app-server", "daemon", "version"], capture_output=True, text=True, timeout=15)
    if result.returncode:
        raise AccountError("Codex could not read the shared server status.")
    version = json.loads(result.stdout)
    if version.get("status") != "running" or not version.get("socketPath"):
        raise AccountError("The shared Codex server is not running. Start Codex before using this command.")
    return version


def print_account(result, version):
    account = result.get("account") or {}
    print(json.dumps({
        "serverStatus": version["status"],
        "serverVersion": version.get("appServerVersion"),
        "accountType": account.get("type"),
        "email": account.get("email"),
        "planType": account.get("planType"),
    }, indent=2))


def main():
    parser = argparse.ArgumentParser(prog="codex-shared-login", description="Read or change the subscription login on the shared Codex server.")
    parser.add_argument("command", choices=["status", "login", "endpoint"])
    parser.add_argument("--timeout", type=int, default=600, help="Seconds to wait for browser sign-in.")
    args = parser.parse_args()
    if args.timeout <= 0:
        parser.error("--timeout must be greater than zero")
    version = daemon_version()
    if args.command == "endpoint":
        print("unix://" + version["socketPath"])
        return
    with unix_connect(version["socketPath"], open_timeout=10, close_timeout=2, max_size=16 * 1024 * 1024) as connection:
        rpc = Rpc(connection)
        rpc.request("initialize", {"clientInfo": {"name": "codex-shared-login", "version": "0.1.0"}})
        rpc.send({"method": "initialized"})
        if args.command == "login":
            login = rpc.request("account/login/start", {"type": "chatgpt"})
            if login.get("type") != "chatgpt" or not login.get("loginId"):
                raise AccountError("The shared Codex server did not start subscription sign-in.")
            completed = False
            try:
                auth_url = login.get("authUrl", "")
                if urlparse(auth_url).scheme != "https":
                    raise AccountError("The shared Codex server returned an invalid sign-in address.")
                if not webbrowser.open(auth_url):
                    raise AccountError("The browser could not open Codex sign-in.")
                print("Complete this one browser sign-in. New turns in Codex CLI sessions on this shared server will use the new login.", flush=True)
                rpc.wait_for_login(login["loginId"], args.timeout)
                completed = True
            finally:
                if not completed:
                    try:
                        rpc.request("account/login/cancel", {"loginId": login["loginId"]}, timeout=5)
                    except Exception as error:
                        print(f"Could not confirm sign-in cancellation ({type(error).__name__}). The server expires the sign-in attempt after ten minutes.", file=sys.stderr)
        account = rpc.request("account/read", {"refreshToken": False})
        if args.command == "login" and (account.get("account") or {}).get("type") != "chatgpt":
            raise AccountError("Codex sign-in completed, but the shared server does not report a ChatGPT subscription login.")
        print_account(account, version)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("Codex account command interrupted. Existing agent sessions remain open.", file=sys.stderr)
        sys.exit(130)
    except AccountError as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
    except TimeoutError:
        print("Codex account command timed out. Existing agent sessions remain open.", file=sys.stderr)
        sys.exit(1)
    except Exception as error:
        print(f"Codex account command failed ({type(error).__name__}). No agent process was restarted.", file=sys.stderr)
        sys.exit(1)
