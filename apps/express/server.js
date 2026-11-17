const express = require("express");
const app = express();
const PORT = Number(process.env.PORT || 3000);

app.get("/", (_req, res) => {
  res.type("html").send(`<!doctype html>
<html><head><meta charset="utf-8"><title>Terraform demo</title></head>
<body style="font-family:Arial;margin:3rem">
<h1>Express frontend is running</h1>
<p>This page is served by Node.js / Express.</p>
<button onclick="loadBackend()">Call Flask backend</button>
<pre id="result">Click the button to call /api/hello</pre>
<script>
async function loadBackend() {
  const el = document.getElementById("result");
  try {
    const response = await fetch("/api/hello");
    el.textContent = JSON.stringify(await response.json(), null, 2);
  } catch (e) { el.textContent = String(e); }
}
</script></body></html>`);
});
app.get("/healthz", (_req, res) => res.status(200).send("ok"));
app.listen(PORT, "0.0.0.0", () => console.log(`Express listening on ${PORT}`));
