#!/usr/bin/env python3
import argparse
import json
import pathlib
import shutil
import subprocess
import tempfile
import time


def send_message(stdin, message):
    data = json.dumps(message).encode("utf-8")
    stdin.write(f"Content-Length: {len(data)}\r\n\r\n".encode("ascii") + data)
    stdin.flush()


def read_message(stdout, timeout=10):
    header = b""
    start = time.time()
    while b"\r\n\r\n" not in header:
        if time.time() - start > timeout:
            raise TimeoutError("Timed out waiting for LSP header")
        chunk = stdout.read(1)
        if not chunk:
            raise RuntimeError("Unexpected EOF while reading LSP header")
        header += chunk

    content_length = None
    for line in header.decode("ascii", errors="replace").split("\r\n"):
        if line.lower().startswith("content-length:"):
            content_length = int(line.split(":", 1)[1].strip())
            break

    if content_length is None:
        raise RuntimeError(f"Missing Content-Length in header: {header!r}")

    body = stdout.read(content_length)
    return json.loads(body.decode("utf-8", errors="replace"))


def decode_tokens(source_text, encoded_tokens, legend):
    lines = source_text.splitlines()
    line = 0
    column = 0
    decoded = []

    for index in range(0, len(encoded_tokens), 5):
        delta_line, delta_start, length, token_type, token_modifiers = encoded_tokens[index:index + 5]
        line += delta_line
        column = delta_start if delta_line else column + delta_start

        modifiers = [
            legend["tokenModifiers"][bit]
            for bit in range(len(legend["tokenModifiers"]))
            if token_modifiers & (1 << bit)
        ]
        text = lines[line][column:column + length]

        decoded.append({
            "line": line + 1,
            "column": column + 1,
            "length": length,
            "text": text,
            "tokenType": legend["tokenTypes"][token_type],
            "tokenModifiers": modifiers,
        })

    return decoded


def compile_command_for(path, sdk_path):
    language = "objective-c-header" if path.suffix == ".h" else "objective-c"
    return " ".join([
        "clang",
        "-x", language,
        "-fsyntax-only",
        "-isysroot", sdk_path,
        "-fmodules",
        "-fobjc-arc",
        f"-I{path.parent}",
        str(path),
    ])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--fixtures-dir",
        default="Tests/SyntaxInkTests/Fixtures/ObjCSemantic",
        help="Directory containing .h/.m fixtures",
    )
    args = parser.parse_args()

    fixtures_dir = pathlib.Path(args.fixtures_dir).resolve()
    fixture_paths = sorted(
        path for path in fixtures_dir.iterdir()
        if path.suffix in {".h", ".m"}
    )

    if not fixture_paths:
        raise SystemExit(f"No Objective-C fixtures found in {fixtures_dir}")

    sourcekit_lsp = subprocess.check_output(
        ["xcrun", "--find", "sourcekit-lsp"],
        text=True,
    ).strip()
    sdk_path = subprocess.check_output(
        ["xcrun", "--sdk", "macosx", "--show-sdk-path"],
        text=True,
    ).strip()

    with tempfile.TemporaryDirectory(prefix="objc-semantic-") as tmpdir:
        workspace = pathlib.Path(tmpdir)

        compile_commands = []
        workspace_files = {}

        for fixture_path in fixture_paths:
            copied_path = workspace / fixture_path.name
            shutil.copy2(fixture_path, copied_path)
            workspace_files[fixture_path] = copied_path
            compile_commands.append({
                "directory": str(workspace),
                "file": str(copied_path),
                "command": compile_command_for(copied_path, sdk_path),
            })

        (workspace / "compile_commands.json").write_text(
            json.dumps(compile_commands, indent=2) + "\n",
            encoding="utf-8",
        )

        proc = subprocess.Popen(
            [
                sourcekit_lsp,
                "--default-workspace-type", "compilationDatabase",
                "--compilation-db-search-path", ".",
            ],
            cwd=workspace,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=False,
        )

        try:
            send_message(proc.stdin, {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "processId": None,
                    "clientInfo": {"name": "SyntaxInk", "version": "1"},
                    "rootUri": workspace.as_uri(),
                    "capabilities": {
                        "textDocument": {
                            "semanticTokens": {
                                "tokenTypes": [],
                                "tokenModifiers": [],
                                "requests": {"full": True},
                                "formats": ["relative"],
                            }
                        }
                    },
                    "workspaceFolders": [{"uri": workspace.as_uri(), "name": workspace.name}],
                },
            })
            initialize = read_message(proc.stdout)
            legend = initialize["result"]["capabilities"]["semanticTokensProvider"]["legend"]

            send_message(proc.stdin, {"jsonrpc": "2.0", "method": "initialized", "params": {}})

            for version, (fixture_path, copied_path) in enumerate(workspace_files.items(), start=1):
                source_text = copied_path.read_text(encoding="utf-8")
                uri = copied_path.as_uri()

                send_message(proc.stdin, {
                    "jsonrpc": "2.0",
                    "method": "textDocument/didOpen",
                    "params": {
                        "textDocument": {
                            "uri": uri,
                            "languageId": "objective-c",
                            "version": version,
                            "text": source_text,
                        }
                    },
                })
                send_message(proc.stdin, {
                    "jsonrpc": "2.0",
                    "id": version + 100,
                    "method": "textDocument/semanticTokens/full",
                    "params": {"textDocument": {"uri": uri}},
                })

                response = None
                while True:
                    message = read_message(proc.stdout, timeout=15)
                    if message.get("id") == version + 100:
                        response = message["result"]
                        break

                payload = {
                    "source": fixture_path.name,
                    "legend": legend,
                    "tokens": decode_tokens(source_text, response["data"], legend),
                }

                output_path = fixture_path.with_name(f"{fixture_path.name}.semantic-tokens.json")
                output_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

            send_message(proc.stdin, {"jsonrpc": "2.0", "method": "shutdown", "id": 999, "params": {}})
            read_message(proc.stdout)
            send_message(proc.stdin, {"jsonrpc": "2.0", "method": "exit", "params": {}})
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                proc.kill()


if __name__ == "__main__":
    main()
