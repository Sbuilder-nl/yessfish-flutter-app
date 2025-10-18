#!/usr/bin/env python3
"""
YessFish Flutter App - GitHub Webhook Listener
Listens for GitHub push events and triggers Flutter APK builds
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import subprocess
import hmac
import hashlib
import os
import logging
from datetime import datetime

# Configuration
PORT = 8081  # Different port than Android WebView listener (8080)
SECRET = "1f887bbed21609f96756240910d5812cfd0abf6b0c4f127c08452bdb1e0c64c6"  # Same secret for consistency
BUILD_SCRIPT = "/opt/yessfish-flutter-app/scripts/build-flutter-app.sh"
LOG_FILE = "/var/log/yessfish-flutter-builds/webhook.log"

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler()
    ]
)

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Handle incoming POST requests from GitHub webhook"""

        # Health check endpoint
        if self.path == "/health":
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "healthy", "app": "yessfish-flutter"}).encode())
            return

        # Only accept webhook on /webhook path
        if self.path != "/webhook":
            self.send_response(404)
            self.end_headers()
            return

        # Read the payload
        content_length = int(self.headers['Content-Length'])
        payload = self.rfile.read(content_length)

        # Verify signature
        signature = self.headers.get('X-Hub-Signature-256')
        if not signature or not self.verify_signature(payload, signature):
            logging.warning("❌ Invalid signature - rejecting webhook")
            self.send_response(403)
            self.end_headers()
            return

        # Parse the payload
        try:
            data = json.loads(payload.decode('utf-8'))
        except json.JSONDecodeError:
            logging.error("❌ Invalid JSON payload")
            self.send_response(400)
            self.end_headers()
            return

        # Check if this is a push event to main branch
        if 'ref' in data and data['ref'] == 'refs/heads/main':
            branch = data['ref'].split('/')[-1]
            commit_sha = data['after'][:7]
            commit_msg = data['commits'][0]['message'] if data.get('commits') else 'No message'
            pusher = data.get('pusher', {}).get('name', 'Unknown')

            logging.info("="*70)
            logging.info("🚀 GitHub Push Event Received - Flutter App")
            logging.info("="*70)
            logging.info(f"📝 Branch: {branch}")
            logging.info(f"🔖 Commit: {commit_sha}")
            logging.info(f"👤 Pusher: {pusher}")
            logging.info(f"💬 Message: {commit_msg[:60]}")
            logging.info("")

            # Trigger the build in background
            self.trigger_build(branch, commit_sha)

            # Send success response
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            response = {
                "status": "success",
                "message": "Flutter build triggered",
                "branch": branch,
                "commit": commit_sha,
                "app": "yessfish-flutter"
            }
            self.wfile.write(json.dumps(response).encode())
        else:
            # Not a main branch push, ignore
            logging.info(f"ℹ️  Ignoring non-main push: {data.get('ref', 'unknown ref')}")
            self.send_response(200)
            self.end_headers()

    def verify_signature(self, payload, signature_header):
        """Verify GitHub webhook signature"""
        if not signature_header.startswith('sha256='):
            return False

        expected_signature = 'sha256=' + hmac.new(
            SECRET.encode('utf-8'),
            payload,
            hashlib.sha256
        ).hexdigest()

        return hmac.compare_digest(expected_signature, signature_header)

    def trigger_build(self, branch, commit_sha):
        """Trigger the Flutter build script in background"""
        try:
            logging.info("🏗️  Starting Flutter build process...")

            # Run build script in background
            subprocess.Popen(
                [BUILD_SCRIPT, branch, commit_sha],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True
            )

            logging.info("✅ Flutter build process started in background")
            logging.info("")

        except Exception as e:
            logging.error(f"❌ Failed to trigger build: {e}")

    def do_GET(self):
        """Handle GET requests (health check)"""
        if self.path == "/health":
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "healthy",
                "app": "yessfish-flutter",
                "port": PORT,
                "timestamp": datetime.now().isoformat()
            }).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, format, *args):
        """Override to use custom logging"""
        logging.info(f"{self.address_string()} - {format % args}")

def main():
    """Start the webhook listener server"""

    # Ensure log directory exists
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)

    logging.info("="*70)
    logging.info("🚀 YessFish Flutter Webhook Listener Starting...")
    logging.info("="*70)
    logging.info(f"📡 Port: {PORT}")
    logging.info(f"📁 Build Script: {BUILD_SCRIPT}")
    logging.info(f"📝 Log File: {LOG_FILE}")
    logging.info("")

    server = HTTPServer(('0.0.0.0', PORT), WebhookHandler)

    logging.info("✅ Server is running and listening for webhooks!")
    logging.info(f"🌐 Webhook URL: http://185.177.126.21:{PORT}/webhook")
    logging.info(f"🏥 Health Check: http://185.177.126.21:{PORT}/health")
    logging.info("")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logging.info("\n⏹️  Shutting down webhook listener...")
        server.shutdown()

if __name__ == '__main__':
    main()
