#!/usr/bin/env python3
"""
EMPIRICAL CHALLENGER M5-2: Web Server & Port 5000 Adversarial Stress Test Suite
================================================================================
Target: fillbill_mobile/serve_web.py & fillbill_mobile/build/web/*
Role: Challenger M5-2 (critic, specialist)

Tests:
  1. Socket Level Empirical Challenges (Port 5000 & SO_REUSEADDR rapid rebinding)
  2. CLI & Process Execution Robustness (Banner, signal handling, arguments)
  3. HTTP Handler Header Injection & Security Invariants (CORS, COOP, COEP, MIME, Traversal)
  4. Web Assets Integrity & Brand Conformance (index.html, main.dart.js, canvaskit, manifests)
"""

import os
import sys
import time
import socket
import json
import io
import subprocess
import signal

# Ensure fillbill_mobile root is in sys.path
TEST_DIR = os.path.dirname(os.path.abspath(__file__))
APP_DIR = os.path.dirname(TEST_DIR)
if APP_DIR not in sys.path:
    sys.path.insert(0, APP_DIR)

from serve_web import ReusableTCPServer, FlutterWebHandler, DIRECTORY, DEFAULT_PORT

TOTAL_ASSERTIONS = 0
PASSED_ASSERTIONS = 0
FAILED_ASSERTIONS = 0

def record_assertion(description, condition, details=""):
    global TOTAL_ASSERTIONS, PASSED_ASSERTIONS, FAILED_ASSERTIONS
    TOTAL_ASSERTIONS += 1
    if condition:
        PASSED_ASSERTIONS += 1
        print(f"  [PASS] Assertion {TOTAL_ASSERTIONS:02d}: {description}")
    else:
        FAILED_ASSERTIONS += 1
        print(f"  [FAIL] Assertion {TOTAL_ASSERTIONS:02d}: {description} -- {details}")

class MockSocket:
    """Mock socket simulation for in-process HTTP handler testing without loopback isolation issues."""
    def __init__(self, request_bytes):
        self.rfile = io.BytesIO(request_bytes)
        self.wfile = io.BytesIO()

    def makefile(self, mode, *args, **kwargs):
        if 'r' in mode:
            return self.rfile
        elif 'w' in mode:
            return self.wfile
        raise ValueError(f"Unsupported mode: {mode}")

    def sendall(self, data):
        self.wfile.write(data)

class DummyServer:
    pass

def execute_http_request(method="GET", path="/index.html", headers=None, body=b""):
    """Executes a simulated HTTP request directly against FlutterWebHandler."""
    req_lines = [f"{method} {path} HTTP/1.1", "Host: localhost:5000"]
    if headers:
        for k, v in headers.items():
            req_lines.append(f"{k}: {v}")
    raw_req = "\r\n".join(req_lines).encode('utf-8') + b"\r\n\r\n" + body
    
    mock_sock = MockSocket(raw_req)
    try:
        # FlutterWebHandler handles request during __init__
        FlutterWebHandler(mock_sock, ('127.0.0.1', 54321), DummyServer())
    except Exception:
        pass

    raw_response = mock_sock.wfile.getvalue()
    parts = raw_response.split(b"\r\n\r\n", 1)
    header_block = parts[0].decode('utf-8', errors='replace')
    resp_body = parts[1] if len(parts) > 1 else b""
    
    header_lines = header_block.split("\r\n")
    status_line = header_lines[0] if header_lines else ""
    
    resp_headers = {}
    for line in header_lines[1:]:
        if ":" in line:
            hk, hv = line.split(":", 1)
            resp_headers[hk.strip().lower()] = hv.strip()
            
    return status_line, resp_headers, resp_body

def run_suite():
    print("======================================================================")
    print("    CHALLENGER M5-2: WEB SERVER & PORT 5000 EMPIRICAL CHALLENGE SUITE   ")
    print("======================================================================")
    print(f"Timestamp: {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}")
    print(f"App Directory:  {APP_DIR}")
    print(f"Web Directory:  {DIRECTORY}\n")

    # =========================================================================
    # SUITE 1: Socket Level Empirical Challenges (Port 5000 & SO_REUSEADDR)
    # =========================================================================
    print("--- [Suite 1/4] Socket Level & Rapid Rebinding Challenges ---")

    # 1.1 Single bind on 127.0.0.1:5000 with SO_REUSEADDR
    s1 = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s1.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    bind_ok = False
    try:
        s1.bind(('127.0.0.1', DEFAULT_PORT))
        bind_ok = True
    except Exception as e:
        bind_err = str(e)
    record_assertion(
        "Single socket bind to 127.0.0.1:5000 with SO_REUSEADDR succeeds without permission errors",
        bind_ok,
        details=f"Error: {bind_err if not bind_ok else 'None'}"
    )

    # 1.2 getsockname confirmation
    sock_name = s1.getsockname() if bind_ok else ('', 0)
    record_assertion(
        "getsockname() strictly confirms bound address is ('127.0.0.1', 5000)",
        sock_name == ('127.0.0.1', DEFAULT_PORT),
        details=f"Actual: {sock_name}"
    )
    s1.close()

    # 1.3 Rapid rebinding stress test (50 cycles in rapid succession)
    rapid_failures = 0
    t0 = time.perf_counter()
    for cycle in range(50):
        try:
            s_rapid = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s_rapid.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s_rapid.bind(('127.0.0.1', DEFAULT_PORT))
            s_rapid.close()
        except Exception:
            rapid_failures += 1
    t1 = time.perf_counter()
    duration_ms = (t1 - t0) * 1000
    record_assertion(
        f"Rapid rebinding stress test: 50 consecutive bind/close cycles on port 5000 succeed with 0 failures ({duration_ms:.1f}ms)",
        rapid_failures == 0,
        details=f"Failures: {rapid_failures}/50"
    )

    # 1.4 ReusableTCPServer class property allow_reuse_address is True
    record_assertion(
        "ReusableTCPServer class property allow_reuse_address is strictly True",
        ReusableTCPServer.allow_reuse_address is True
    )

    # 1.5 Context manager lifecycle with ReusableTCPServer
    ctx_bound = False
    try:
        with ReusableTCPServer(('127.0.0.1', DEFAULT_PORT), FlutterWebHandler) as srv:
            ctx_bound = srv.server_address == ('127.0.0.1', DEFAULT_PORT)
    except Exception as e:
        ctx_bound = False
    record_assertion(
        "ReusableTCPServer context manager binds ('127.0.0.1', 5000) and executes lifecycle cleanly",
        ctx_bound
    )

    # 1.6 Instant re-bindability post context manager exit (no TIME_WAIT hang)
    post_ctx_ok = False
    try:
        s_post = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s_post.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s_post.bind(('127.0.0.1', DEFAULT_PORT))
        s_post.close()
        post_ctx_ok = True
    except Exception as e:
        post_ctx_ok = False
    record_assertion(
        "Port 5000 is immediately re-bindable post-TCPServer teardown (server_close invoked)",
        post_ctx_ok
    )

    # 1.7 Alternate port rebinding (e.g. 5001, 5002)
    alt_port_ok = True
    for p in [5001, 5002]:
        try:
            s_alt = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s_alt.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s_alt.bind(('127.0.0.1', p))
            s_alt.close()
        except Exception:
            alt_port_ok = False
    record_assertion(
        "Alternate port binding (5001, 5002) operates identically with SO_REUSEADDR",
        alt_port_ok
    )

    # 1.8 Empirical Proof: Binding without SO_REUSEADDR vs with SO_REUSEADDR
    win_error_10013_caught = False
    s_no_reuse = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        s_no_reuse.bind(('127.0.0.1', DEFAULT_PORT))
        s_no_reuse.close()
    except (PermissionError, OSError) as e:
        win_error_10013_caught = True
        err_msg = str(e)
    record_assertion(
        "Empirical proof: Binding port 5000 WITHOUT SO_REUSEADDR is rejected by Windows with [WinError 10013] PermissionError",
        win_error_10013_caught,
        details=f"Caught: {err_msg if win_error_10013_caught else 'None'}"
    )

    # =========================================================================
    # SUITE 2: CLI & Process Execution Robustness
    # =========================================================================
    print("\n--- [Suite 2/4] CLI & Process Execution Robustness ---")

    # 2.1 Spawning serve_web.py as subprocess with default port
    server_script = os.path.join(APP_DIR, 'serve_web.py')
    proc = subprocess.Popen(
        [sys.executable, "-u", server_script],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd=APP_DIR
    )
    
    # Read banner lines deterministically
    banner_lines = []
    for _ in range(8):
        line = proc.stdout.readline()
        if not line:
            break
        banner_lines.append(line)
    stdout_text = "".join(banner_lines)

    proc_running = proc.poll() is None
    record_assertion(
        "Spawning python serve_web.py launches active persistent background process",
        proc_running
    )

    # 2.2-2.4 Banner output verification
    record_assertion(
        "Server banner contains title 'FILLBILL FLUTTER WEB SERVER (PORT 5000)'",
        "FILLBILL FLUTTER WEB SERVER (PORT 5000)" in stdout_text
    )
    record_assertion(
        "Server banner displays Local URL 'http://localhost:5000'",
        "http://localhost:5000" in stdout_text
    )
    record_assertion(
        "Server banner displays Network URL 'http://127.0.0.1:5000'",
        "http://127.0.0.1:5000" in stdout_text
    )

    proc.terminate()
    try:
        proc.wait(timeout=2.0)
    except Exception:
        proc.kill()
        proc.wait()

    record_assertion(
        "Process terminates cleanly upon SIGTERM with exit code 0, 1, or -15",
        proc.returncode in (0, -15, 1)  # On Windows terminate() typically exits with 1
    )

    # 2.6 CLI custom port argument: python serve_web.py 5005
    proc_custom = subprocess.Popen(
        [sys.executable, "-u", server_script, "5005"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd=APP_DIR
    )
    custom_lines = []
    for _ in range(8):
        line = proc_custom.stdout.readline()
        if not line:
            break
        custom_lines.append(line)
    stdout_custom = "".join(custom_lines)
    proc_custom.terminate()
    try:
        proc_custom.wait(timeout=2.0)
    except Exception:
        proc_custom.kill()

    record_assertion(
        "CLI custom port argument '5005' correctly configures server to PORT 5005",
        "FILLBILL FLUTTER WEB SERVER (PORT 5005)" in stdout_custom and "http://localhost:5005" in stdout_custom
    )

    # 2.7 CLI invalid argument fallback: python serve_web.py invalid_port
    proc_invalid = subprocess.Popen(
        [sys.executable, "-u", server_script, "invalid_port"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd=APP_DIR
    )
    invalid_lines = []
    for _ in range(8):
        line = proc_invalid.stdout.readline()
        if not line:
            break
        invalid_lines.append(line)
    stdout_invalid = "".join(invalid_lines)
    proc_invalid.terminate()
    try:
        proc_invalid.wait(timeout=2.0)
    except Exception:
        proc_invalid.kill()

    record_assertion(
        "CLI non-integer port argument safely falls back to default 5000 with warning",
        "Invalid port: invalid_port. Defaulting to 5000." in stdout_invalid and "FILLBILL FLUTTER WEB SERVER (PORT 5000)" in stdout_invalid
    )

    # 2.8 Non-existent web directory error handling
    test_env = os.environ.copy()
    code_test_missing = """
import sys, os
from unittest.mock import patch
import serve_web
with patch('serve_web.DIRECTORY', 'non_existent_dir_999'):
    try:
        serve_web.main()
    except SystemExit as se:
        print(f"EXIT_CODE_{se.code}")
"""
    res_missing = subprocess.run(
        [sys.executable, "-c", code_test_missing],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        cwd=APP_DIR
    )
    record_assertion(
        "Missing web directory produces explicit error and exits with code 1",
        "EXIT_CODE_1" in res_missing.stdout and "Error: Web directory not found" in res_missing.stdout
    )

    # =========================================================================
    # SUITE 3: HTTP Handler Header Injection & Security Invariants
    # =========================================================================
    print("\n--- [Suite 3/4] HTTP Handler Header Injection & Security Invariants ---")

    # 3.1 GET /index.html returns 200 OK
    st, hdrs, body = execute_http_request("GET", "/index.html")
    record_assertion("GET /index.html returns HTTP status 200 OK", "200 OK" in st)

    # 3.2 Access-Control-Allow-Origin: *
    record_assertion(
        "GET /index.html injects 'Access-Control-Allow-Origin: *' header",
        hdrs.get('access-control-allow-origin') == '*'
    )

    # 3.3 Cross-Origin-Opener-Policy: same-origin
    record_assertion(
        "GET /index.html injects 'Cross-Origin-Opener-Policy: same-origin' header",
        hdrs.get('cross-origin-opener-policy') == 'same-origin'
    )

    # 3.4 Cross-Origin-Embedder-Policy: require-corp
    record_assertion(
        "GET /index.html injects 'Cross-Origin-Embedder-Policy: require-corp' header",
        hdrs.get('cross-origin-embedder-policy') == 'require-corp'
    )

    # 3.5 Content-Type: text/html
    record_assertion(
        "GET /index.html Content-Type is text/html",
        'text/html' in hdrs.get('content-type', '')
    )

    # 3.6 Body matches disk content
    with open(os.path.join(DIRECTORY, 'index.html'), 'rb') as f:
        disk_index = f.read()
    record_assertion(
        f"GET /index.html response body exactly matches disk file ({len(body)} == {len(disk_index)} bytes)",
        body == disk_index
    )

    # 3.7 GET / (root) serves index.html with 200 OK
    st_root, hdrs_root, body_root = execute_http_request("GET", "/")
    record_assertion(
        "GET / (root path) serves index.html with 200 OK and security headers",
        "200 OK" in st_root and hdrs_root.get('cross-origin-opener-policy') == 'same-origin' and body_root == disk_index
    )

    # 3.8-3.10 GET /main.dart.js
    st_js, hdrs_js, body_js = execute_http_request("GET", "/main.dart.js")
    record_assertion("GET /main.dart.js returns HTTP status 200 OK", "200 OK" in st_js)
    record_assertion(
        "GET /main.dart.js injects all required security headers (CORS, COOP, COEP)",
        hdrs_js.get('access-control-allow-origin') == '*' and
        hdrs_js.get('cross-origin-opener-policy') == 'same-origin' and
        hdrs_js.get('cross-origin-embedder-policy') == 'require-corp'
    )
    record_assertion(
        "GET /main.dart.js Content-Type is JavaScript (application/javascript or text/javascript)",
        'javascript' in hdrs_js.get('content-type', '')
    )

    # 3.11 GET /flutter_bootstrap.js
    st_boot, hdrs_boot, _ = execute_http_request("GET", "/flutter_bootstrap.js")
    record_assertion(
        "GET /flutter_bootstrap.js returns 200 OK with security headers",
        "200 OK" in st_boot and hdrs_boot.get('cross-origin-opener-policy') == 'same-origin'
    )

    # 3.12 GET /manifest.json
    st_man, hdrs_man, _ = execute_http_request("GET", "/manifest.json")
    record_assertion(
        "GET /manifest.json returns 200 OK with Content-Type application/json",
        "200 OK" in st_man and 'application/json' in hdrs_man.get('content-type', '')
    )

    # 3.13 GET /favicon.png
    st_fav, hdrs_fav, _ = execute_http_request("GET", "/favicon.png")
    record_assertion(
        "GET /favicon.png returns 200 OK with Content-Type image/png",
        "200 OK" in st_fav and 'image/png' in hdrs_fav.get('content-type', '')
    )

    # 3.14 GET /version.json
    st_ver, hdrs_ver, _ = execute_http_request("GET", "/version.json")
    record_assertion(
        "GET /version.json returns 200 OK with Content-Type application/json",
        "200 OK" in st_ver and 'application/json' in hdrs_ver.get('content-type', '')
    )

    # 3.15 GET /canvaskit/canvaskit.wasm
    st_wasm, hdrs_wasm, _ = execute_http_request("GET", "/canvaskit/canvaskit.wasm")
    record_assertion(
        "GET /canvaskit/canvaskit.wasm returns 200 OK with security headers for Wasm execution",
        "200 OK" in st_wasm and hdrs_wasm.get('cross-origin-embedder-policy') == 'require-corp'
    )

    # 3.16 GET /canvaskit/canvaskit.js
    st_ckjs, hdrs_ckjs, _ = execute_http_request("GET", "/canvaskit/canvaskit.js")
    record_assertion(
        "GET /canvaskit/canvaskit.js returns 200 OK with JavaScript Content-Type",
        "200 OK" in st_ckjs and 'javascript' in hdrs_ckjs.get('content-type', '')
    )

    # 3.17 GET non-existent resource
    st_404, _, _ = execute_http_request("GET", "/does_not_exist_xyz123.html")
    record_assertion(
        "GET non-existent resource returns HTTP status 404 Not Found",
        "404" in st_404
    )

    # 3.18 Path traversal attack: /../../serve_web.py
    st_trav1, _, _ = execute_http_request("GET", "/../../serve_web.py")
    record_assertion(
        "Adversarial path traversal GET /../../serve_web.py is blocked (404/403)",
        "404" in st_trav1 or "403" in st_trav1
    )

    # 3.19 Encoded path traversal: /%2e%2e/%2e%2e/serve_web.py
    st_trav2, _, _ = execute_http_request("GET", "/%2e%2e/%2e%2e/serve_web.py")
    record_assertion(
        "Encoded path traversal GET /%2e%2e/%2e%2e/serve_web.py is blocked (404/403)",
        "404" in st_trav2 or "403" in st_trav2
    )

    # 3.20 HEAD request method support
    st_head, hdrs_head, body_head = execute_http_request("HEAD", "/index.html")
    record_assertion(
        "HEAD /index.html returns 200 OK, full headers, and empty body",
        "200 OK" in st_head and hdrs_head.get('cross-origin-opener-policy') == 'same-origin' and len(body_head) == 0
    )

    # =========================================================================
    # SUITE 4: Web Assets Integrity & Brand Conformance
    # =========================================================================
    print("\n--- [Suite 4/4] Web Assets Integrity & Brand Conformance ---")

    index_path = os.path.join(DIRECTORY, 'index.html')
    with open(index_path, 'r', encoding='utf-8') as f:
        index_html = f.read()

    # 4.1 index.html size
    record_assertion(
        f"build/web/index.html exists and size >= 2000 bytes (actual: {len(index_html)} bytes)",
        os.path.isfile(index_path) and len(index_html) >= 2000
    )

    # 4.2 Brand container #loading-container
    record_assertion(
        "index.html contains #loading-container element for brand splash",
        'id="loading-container"' in index_html
    )

    # 4.3 Brand title 'FillBill'
    record_assertion(
        "index.html contains app-title with 'FillBill'",
        '<div class="app-title">FillBill</div>' in index_html
    )

    # 4.4 Brand subtitle
    record_assertion(
        "index.html contains app-sub 'Memuat Aplikasi Finansial...'",
        '<div class="app-sub">Memuat Aplikasi Finansial...</div>' in index_html
    )

    # 4.5 Primary emerald color #10B981
    record_assertion(
        "index.html incorporates BrandConfig primary emerald color (#10B981)",
        '#10B981' in index_html
    )

    # 4.6 Brand dark color #0D2137
    record_assertion(
        "index.html incorporates BrandConfig dark navy background (#0D2137)",
        '#0D2137' in index_html
    )

    # 4.7 flutter_bootstrap.js script tag
    record_assertion(
        "index.html references Flutter bootstrap script (<script src=\"flutter_bootstrap.js\" async>)",
        '<script src="flutter_bootstrap.js" async></script>' in index_html
    )

    # 4.8 Viewport configuration
    record_assertion(
        "index.html contains responsive mobile viewport tag with user-scalable=no",
        'name="viewport"' in index_html and 'user-scalable=no' in index_html
    )

    # 4.9-4.11 main.dart.js
    main_js_path = os.path.join(DIRECTORY, 'main.dart.js')
    main_js_size = os.path.getsize(main_js_path) if os.path.isfile(main_js_path) else 0
    record_assertion(
        f"build/web/main.dart.js exists with size > 9MB (actual: {main_js_size / (1024*1024):.2f} MB / {main_js_size} bytes)",
        main_js_size > 9000000
    )

    # Node check on main.dart.js
    node_main = subprocess.run(
        ["node", "--check", main_js_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    record_assertion(
        "build/web/main.dart.js passes syntax validation via node --check (valid JS)",
        node_main.returncode == 0
    )

    # 4.12-4.14 flutter_bootstrap.js
    boot_path = os.path.join(DIRECTORY, 'flutter_bootstrap.js')
    boot_size = os.path.getsize(boot_path) if os.path.isfile(boot_path) else 0
    record_assertion(
        f"build/web/flutter_bootstrap.js exists with size > 5KB (actual: {boot_size} bytes)",
        boot_size > 5000
    )

    node_boot = subprocess.run(
        ["node", "--check", boot_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    record_assertion(
        "build/web/flutter_bootstrap.js passes syntax validation via node --check",
        node_boot.returncode == 0
    )

    with open(boot_path, 'r', encoding='utf-8') as f:
        boot_content = f.read()
    record_assertion(
        "flutter_bootstrap.js configures _flutter.buildConfig for main.dart.js and canvaskit",
        '_flutter.buildConfig' in boot_content and 'main.dart.js' in boot_content and 'canvaskit' in boot_content
    )

    # 4.15 manifest.json validation
    manifest_path = os.path.join(DIRECTORY, 'manifest.json')
    try:
        with open(manifest_path, 'r', encoding='utf-8') as f:
            manifest_json = json.load(f)
        manifest_valid = manifest_json.get('name') == 'fillbill_mobile' and len(manifest_json.get('icons', [])) > 0
    except Exception:
        manifest_valid = False
    record_assertion(
        "build/web/manifest.json is valid JSON with name 'fillbill_mobile' and icon declarations",
        manifest_valid
    )

    # 4.16 version.json validation
    version_path = os.path.join(DIRECTORY, 'version.json')
    try:
        with open(version_path, 'r', encoding='utf-8') as f:
            version_json = json.load(f)
        version_valid = version_json.get('app_name') == 'fillbill_mobile' and 'version' in version_json
    except Exception:
        version_valid = False
    record_assertion(
        "build/web/version.json is valid JSON with app_name 'fillbill_mobile'",
        version_valid
    )

    # 4.17 canvaskit.wasm integrity
    wasm_path = os.path.join(DIRECTORY, 'canvaskit', 'canvaskit.wasm')
    wasm_size = os.path.getsize(wasm_path) if os.path.isfile(wasm_path) else 0
    record_assertion(
        f"build/web/canvaskit/canvaskit.wasm exists with size > 5MB (actual: {wasm_size / (1024*1024):.2f} MB)",
        wasm_size > 5000000
    )

    # 4.18 canvaskit.js ES module syntax check
    ckjs_path = os.path.join(DIRECTORY, 'canvaskit', 'canvaskit.js')
    with open(ckjs_path, 'rb') as f:
        ckjs_bytes = f.read()
    node_ckjs = subprocess.run(
        ["node", "--input-type=module", "--check"],
        input=ckjs_bytes,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    record_assertion(
        "build/web/canvaskit/canvaskit.js passes ES module syntax validation via node --check",
        node_ckjs.returncode == 0,
        details=node_ckjs.stderr.decode('utf-8', errors='replace')
    )

    # 4.19 AssetManifest.bin.json validation (Flutter base64-encoded binary manifest)
    import base64
    asset_manifest_path = os.path.join(DIRECTORY, 'assets', 'AssetManifest.bin.json')
    try:
        with open(asset_manifest_path, 'r', encoding='utf-8') as f:
            asset_manifest_raw = json.load(f)
        decoded_bytes = base64.b64decode(asset_manifest_raw)
        asset_manifest_valid = (
            isinstance(asset_manifest_raw, str) and
            b'dana.svg' in decoded_bytes and
            b'gopay.svg' in decoded_bytes and
            b'linkaja.svg' in decoded_bytes
        )
    except Exception as e:
        asset_manifest_valid = False
        manifest_err = str(e)
    record_assertion(
        "build/web/assets/AssetManifest.bin.json is valid base64-encoded Flutter binary manifest containing e-wallet icons",
        asset_manifest_valid,
        details=manifest_err if not asset_manifest_valid else ""
    )

    # 4.20 FontManifest.json validation
    font_manifest_path = os.path.join(DIRECTORY, 'assets', 'FontManifest.json')
    try:
        with open(font_manifest_path, 'r', encoding='utf-8') as f:
            font_manifest = json.load(f)
        font_manifest_valid = isinstance(font_manifest, list) and len(font_manifest) > 0
    except Exception:
        font_manifest_valid = False
    record_assertion(
        "build/web/assets/FontManifest.json is valid JSON list of font declarations",
        font_manifest_valid
    )

    # =========================================================================
    # SUMMARY & SCORECARD
    # =========================================================================
    print("\n======================================================================")
    print("                     EMPIRICAL CHALLENGE SCORECARD                    ")
    print("======================================================================")
    print(f"Total Assertions: {TOTAL_ASSERTIONS}")
    print(f"Passed:           {PASSED_ASSERTIONS} ({(PASSED_ASSERTIONS/TOTAL_ASSERTIONS*100):.1f}%)")
    print(f"Failed:           {FAILED_ASSERTIONS}")
    print("======================================================================")

    if FAILED_ASSERTIONS == 0:
        print(f"\n>> VERDICT: CONFIRMED CORRECT — ALL {TOTAL_ASSERTIONS} EMPIRICAL ASSERTIONS PASSED <<\n")
        sys.exit(0)
    else:
        print(f"\n>> VERDICT: CHALLENGE FAILED — {FAILED_ASSERTIONS} ASSERTIONS FAILED <<\n")
        sys.exit(1)

if __name__ == '__main__':
    run_suite()
