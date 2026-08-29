//! Miner control pool console HTML
pub fn html() []const u8 {
    return
        \\<!doctype html><html><head><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
        \\<title>Miner control — YarnRake</title>
        \\<style>
        \\body{margin:0;font-family:system-ui,sans-serif;background:#0f1117;color:#e8eaed;padding:20px;max-width:960px}
        \\h1{font-size:1.35rem;margin:0 0 6px} .sub{color:#9aa0a6;font-size:.9rem;margin-bottom:16px}
        \\.grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}
        \\@media(max-width:720px){.grid{grid-template-columns:1fr}}
        \\.card{background:#1a1d27;border:1px solid #2a2f3a;border-radius:12px;padding:14px 16px}
        \\h2{font-size:1rem;margin:0 0 10px;color:#bdc1c6}
        \\label{display:block;font-size:.75rem;color:#9aa0a6;margin:8px 0 4px}
        \\input,select{width:100%;box-sizing:border-box;background:#0f1117;border:1px solid #3a4150;color:#eee;border-radius:8px;padding:8px 10px}
        \\button{background:#3d7eff;color:#fff;border:0;border-radius:8px;padding:8px 14px;font-weight:600;cursor:pointer;margin:8px 6px 0 0}
        \\button.sec{background:#2a2f3a}
        \\table{width:100%;border-collapse:collapse;font-size:.85rem}
        \\th,td{text-align:left;padding:6px 4px;border-bottom:1px solid #2a2f3a}
        \\.tag{display:inline-block;padding:2px 8px;border-radius:999px;background:#2a2f3a;font-size:.75rem}
        \\.tag.on{background:#1e3d2f;color:#6dcea4} .tag.off{background:#3d2a2a;color:#e88}
        \\a{color:#5e9bdc} pre{background:#0a0c10;padding:10px;border-radius:8px;overflow:auto;font-size:.8rem}
        \\.modes{font-size:.8rem;color:#9aa0a6;line-height:1.45}
        \\<\/style><\/head><body>
        \\<h1>Miner control pool console<\/h1>
        \\<p class=sub>Assign any or all pools to workers. Modes: manual, automatic, failover, round-robin, all pools, custom.
        \\ · <a href=\/>home<\/a> · <a href=\/launch>launch<\/a> · <a href=\/onboard>onboard<\/a><\/p>
        \\<div class=grid>
        \\<div class=card>
        \\<h2>Pools<\/h2>
        \\<div id=pools>loading…<\/div>
        \\<label>Name<\/label><input id=pname value="Backup pool">
        \\<label>Stratum URL<\/label><input id=purl value="stratum+tcp:\/\/127.0.0.1:3333">
        \\<label>Algo<\/label><input id=palgo value="skein">
        \\<label>Priority (lower preferred in failover)<\/label><input id=ppri type=number value=10>
        \\<button onclick=addPool()>Add pool<\/button>
        \\<\/div>
        \\<div class=card>
        \\<h2>Assign worker → pool(s)<\/h2>
        \\<label>Worker name<\/label><input id=worker placeholder="device-1">
        \\<label>Mode<\/label>
        \\<select id=mode>
        \\<option value=manual>Manual — selected pool id(s)<\/option>
        \\<option value=automatic>Automatic — match worker algo<\/option>
        \\<option value=failover>Failover — ordered list<\/option>
        \\<option value=round_robin>Round-robin — rotate selected<\/option>
        \\<option value=all_pools>All pools — every enabled pool<\/option>
        \\<option value=custom>Custom — free-form stratum URL<\/option>
        \\<\/select>
        \\<label>Pool IDs (comma-separated, or * for all)<\/label><input id=pids placeholder="p1,p2 or *">
        \\<label>Custom URL (custom mode)<\/label><input id=curl placeholder="stratum+tcp:\/\/host:port">
        \\<label>Notes<\/label><input id=notes placeholder="optional">
        \\<button onclick=assign()>Save assignment<\/button>
        \\<button class=sec onclick=resolve()>Preview resolve<\/button>
        \\<pre id=resolveOut><\/pre>
        \\<\/div>
        \\<\/div>
        \\<div class=card style="margin-top:14px">
        \\<h2>Assignments<\/h2>
        \\<div id=assigns>loading…<\/div>
        \\<\/div>
        \\<div class=card style="margin-top:14px">
        \\<h2>Mode reference<\/h2>
        \\<div class=modes>
        \\<b>manual<\/b> — listed pool ids only.<br>
        \\<b>automatic<\/b> — enabled pools matching worker algo.<br>
        \\<b>failover<\/b> — try pools in list order.<br>
        \\<b>round_robin<\/b> — rotate among listed pools.<br>
        \\<b>all_pools<\/b> — every enabled pool.<br>
        \\<b>custom<\/b> — custom stratum URL only.
        \\<\/div>
        \\<\/div>
        \\<script>
        \\async function refresh(){
        \\  const s=await fetch('\/control\/state').then(r=>r.json());
        \\  let ph='<table><tr><th>ID<\/th><th>Name<\/th><th>Algo<\/th><th>URL<\/th><th>Pri<\/th><th><\/th><\/tr>';
        \\  (s.pools||[]).forEach(p=>{
        \\    const st=p.enabled?'<span class="tag on">on<\/span>':'<span class="tag off">off<\/span>';
        \\    ph+=`<tr><td>${p.id}<\/td><td>${p.name}<\/td><td>${p.algo}<\/td><td>${p.url}<\/td><td>${p.priority}<\/td><td>${st} <button class=sec onclick="toggle('${p.id}',${!p.enabled})">${p.enabled?'Disable':'Enable'}<\/button><\/td><\/tr>`;
        \\  });
        \\  pools.innerHTML=ph+'<\/table>';
        \\  let ah='<table><tr><th>Worker<\/th><th>Mode<\/th><th>Pools<\/th><th>Custom<\/th><th>Notes<\/th><\/tr>';
        \\  (s.assignments||[]).forEach(a=>{
        \\    ah+=`<tr><td>${a.worker}<\/td><td><span class=tag>${a.mode}<\/span><\/td><td>${a.pool_ids||''}<\/td><td>${a.custom_url||''}<\/td><td>${a.notes||''}<\/td><\/tr>`;
        \\  });
        \\  assigns.innerHTML=(s.assignments||[]).length?ah+'<\/table>':'<p class=sub>No assignments — default automatic.<\/p>';
        \\}
        \\async function addPool(){
        \\  const b=new URLSearchParams({name:pname.value,url:purl.value,algo:palgo.value,priority:ppri.value});
        \\  await fetch('\/control\/pools',{method:'POST',headers:{'Content-Type':'application\/x-www-form-urlencoded'},body:b});
        \\  refresh();
        \\}
        \\async function toggle(id,en){
        \\  const b=new URLSearchParams({id,enabled:en?'1':'0'});
        \\  await fetch('\/control\/pools\/enable',{method:'POST',headers:{'Content-Type':'application\/x-www-form-urlencoded'},body:b});
        \\  refresh();
        \\}
        \\async function assign(){
        \\  const b=new URLSearchParams({worker:worker.value.trim(),mode:mode.value,pool_ids:pids.value.trim()||'*',custom_url:curl.value.trim(),notes:notes.value.trim()});
        \\  const r=await fetch('\/control\/assign',{method:'POST',headers:{'Content-Type':'application\/x-www-form-urlencoded'},body:b});
        \\  resolveOut.textContent=await r.text();
        \\  refresh();
        \\}
        \\async function resolve(){
        \\  const w=worker.value.trim()||'device-1';
        \\  const a=palgo.value.trim()||'skein';
        \\  const r=await fetch('\/control\/resolve?worker='+encodeURIComponent(w)+'&algo='+encodeURIComponent(a));
        \\  resolveOut.textContent=await r.text();
        \\}
        \\refresh();
        \\<\/script><\/body><\/html>
    ;
}
