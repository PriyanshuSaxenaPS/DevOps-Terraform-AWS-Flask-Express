#!/bin/bash
set -euxo pipefail
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3-venv python3-pip nodejs npm
mkdir -p /opt/demo/flask /opt/demo/express
cat >/opt/demo/flask/app.py <<'PY'
from flask import Flask, jsonify
app=Flask(__name__)
@app.get("/")
def home(): return jsonify(service="flask-backend", message="Flask is running")
@app.get("/health")
def health(): return jsonify(status="ok")
@app.get("/api/hello")
def hello(): return jsonify(message="Hello from Flask")
PY
python3 -m venv /opt/demo/flask/venv
/opt/demo/flask/venv/bin/pip install Flask==3.1.1 gunicorn==23.0.0
cat >/opt/demo/express/server.js <<'JS'
const express=require("express"); const app=express();
app.get("/",(req,res)=>res.send("<h1>Express frontend is running</h1><p>Flask API: <a href='http://"+req.headers.host.replace(/:3000$/,":5000")+"/api/hello'>test API</a></p>"));
app.get("/healthz",(req,res)=>res.send("ok"));
app.listen(3000,"0.0.0.0",()=>console.log("Express on 3000"));
JS
cat >/opt/demo/express/package.json <<'JSON'
{"name":"demo","version":"1.0.0","dependencies":{"express":"4.21.2"}}
JSON
cd /opt/demo/express && npm install --omit=dev
cat >/etc/systemd/system/flask.service <<'UNIT'
[Unit]
Description=Flask backend
After=network.target
[Service]
WorkingDirectory=/opt/demo/flask
ExecStart=/opt/demo/flask/venv/bin/gunicorn --bind 0.0.0.0:5000 app:app
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
cat >/etc/systemd/system/express.service <<'UNIT'
[Unit]
Description=Express frontend
After=network.target
[Service]
WorkingDirectory=/opt/demo/express
ExecStart=/usr/bin/node /opt/demo/express/server.js
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now flask express
