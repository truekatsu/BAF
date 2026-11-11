import http.server
import socketserver
import os

PORT = 28888
DIRECTORY = r"d:\BAF\src"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

with socketserver.TCPServer(("127.0.0.1", PORT), Handler) as httpd:
    print(f"Serving at http://127.0.0.1:{PORT}")
    httpd.serve_forever()
