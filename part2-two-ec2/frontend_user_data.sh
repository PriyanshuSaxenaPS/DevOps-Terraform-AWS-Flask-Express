#!/bin/bash
set -euxo pipefail
apt-get update
apt-get install -y nodejs npm
mkdir -p /opt/express
cat >/opt/express/server.js <<'JS'
const express=require("express"); const app=express();
const backend=process.env.BACKEND_URL;
app.get("/",(req,res)=>res.send(`<h1>Express frontend on its own EC2</h1><p>Flask backend: <a href="${backend}/api/hello">API test</a></p>`));
app.get("/healthz",(req,res)=>res.send("ok"));
app.listen(3000,"0.0.0.0",()=>console.log("Express on 3000"));
JS
cat >/opt/express/package.json <<'JSON'
{"name":"express-demo","version":"1.0.0","dependencies":{"express":"4.21.2"}}
JSON
cd /opt/express && npm install --omit=dev
cat >/etc/systemd/system/express.service <<UNIT
[Unit]
Description=Express frontend
After=network.target
[Service]
WorkingDirectory=/opt/express
Environment=BACKEND_URL=http://${backend_private_ip}:5000
ExecStart=/usr/bin/node /opt/express/server.js
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload && systemctl enable --now express
