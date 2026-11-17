#!/bin/bash
set -euxo pipefail
apt-get update
apt-get install -y python3-venv
mkdir -p /opt/flask
cat >/opt/flask/app.py <<'PY'
from flask import Flask, jsonify
app=Flask(__name__)
@app.get("/")
def home(): return jsonify(service="flask-backend")
@app.get("/health")
def health(): return jsonify(status="ok")
@app.get("/api/hello")
def hello(): return jsonify(message="Hello from separate Flask EC2")
PY
python3 -m venv /opt/flask/venv
/opt/flask/venv/bin/pip install Flask==3.1.1 gunicorn==23.0.0
cat >/etc/systemd/system/flask.service <<'UNIT'
[Unit]
Description=Flask API
After=network.target
[Service]
WorkingDirectory=/opt/flask
ExecStart=/opt/flask/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload && systemctl enable --now flask
