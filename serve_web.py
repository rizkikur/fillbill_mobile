#!/usr/bin/env python3
"""
FillBill Mobile — Flutter Web Production Server
Serves the compiled production web bundle from build/web on port 5000 with SO_REUSEADDR.
"""

import http.server
import socketserver
import os
import sys

DEFAULT_PORT = 5000
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DIRECTORY = os.path.join(BASE_DIR, 'build', 'web')

class ReusableTCPServer(socketserver.TCPServer):
    """TCPServer enabling SO_REUSEADDR to avoid WinError 10013 / port conflicts on Windows."""
    allow_reuse_address = True

class FlutterWebHandler(http.server.SimpleHTTPRequestHandler):
    """Custom HTTP handler serving Flutter Web assets with proper CORS and security headers."""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        # Headers required for WebAssembly, CanvasKit, and cross-origin resource isolation
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

def main():
    port = DEFAULT_PORT
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            print(f"Invalid port: {sys.argv[1]}. Defaulting to {DEFAULT_PORT}.")

    if not os.path.isdir(DIRECTORY):
        print(f"Error: Web directory not found at: {DIRECTORY}")
        print("Please ensure Flutter web has been built (`flutter build web`).")
        sys.exit(1)

    index_file = os.path.join(DIRECTORY, 'index.html')
    if not os.path.isfile(index_file):
        print(f"Warning: index.html not found in {DIRECTORY}")

    print("==================================================", flush=True)
    print("       FILLBILL FLUTTER WEB SERVER (PORT " + str(port) + ")       ", flush=True)
    print("==================================================", flush=True)
    print(f"Serving Directory: {DIRECTORY}", flush=True)
    print(f"Local URL:         http://localhost:{port}", flush=True)
    print(f"Network URL:       http://127.0.0.1:{port}", flush=True)
    print("Press Ctrl+C to terminate.", flush=True)
    print("==================================================", flush=True)

    try:
        with ReusableTCPServer(('127.0.0.1', port), FlutterWebHandler) as httpd:
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer shutdown requested by user.")
    except Exception as e:
        print(f"\nServer error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
