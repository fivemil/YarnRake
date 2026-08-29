//! Miner control pool console HTML
pub fn html() []const u8 {
    return
        \\<!doctype html><html><head><meta charset=utf-8><title>Miner control</title>
        \\<style>
        \\body{margin:0;font-family:system-ui,sans-serif;background:#0f1117;color:#e8eaed;padding:20px;max-width:960px}
        \\.grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}
        \\.card{background:#1a1d27;border:1px solid #2a2f3a;border-radius:12px;padding:14px}
        \\label{display:block;font-size:.75rem;color:#9aa0a6;margin:8px 0 4px}
        \\input,select{width:100%;box-sizing:border-box;background:#0f1117;border:1px solid #3a4150;color:#eee;border-radius:8px;padding:8px}
        \\button{background:#3d7eff;color:#fff;border:0;border-radius:8px;padding:8px 14px;margin:8px 6px 0 0;cursor:pointer}
        \\button.sec{background:#2a2f3a} table{width:100%;font-size:.85rem;border-collapse:collapse}
        \\th,td{text-align:left;padding:6px 4px;border-bottom:1px solid #2a2f3a}
        \\a{color:#5e9bdc} pre{background:#0a0c10;padding:10px;border-radius:8px;font-size:.8rem}
        \\<\/style><\/head><body>
        \\<h1>Miner control pool console<\/h1>
        \\<p>Assign any\/all pools · modes: manual, automatic, failover, round_robin, all_pools, custom
        \\ · <a href=\/>home<\/a> · <a href=\/launch>launch<\/a><\/p>
        \\<div class=grid>
        \\<div class=card><h2>Pools<\/h2><div id=pools><\/div>
        \\<label>Name<\/label><input id=pname value="Backup pool">
        \\<label>URL<\/label><input id=purl value="stratum+tcp:\/\/127.0.0.1:3333">
        \\<label>Algo<\/label><input id=palgo value="skein">
        \\<label>Priority<\/label><input id=ppri type=number value=10>
        \\<button onclick=addPool()>Add pool<\/button><\/div>
        \\<div class=card><h2>Assign worker<\/h2>
        \\<label>Worker<\/label><input id=worker placeholder="device-1">
        \\<label>Mode<\/label><select id=mode>
        \\<option value=manual>manual<\/option>
        \\<option value=automatic>automatic<\/option>
        \\<option value=failover>failover<\/option>
        \\<option value=round_robin>round_robin<\/option>
        \\<option value=all_pools>all_pools<\/option>
        \\<option value=custom>custom<\/option>
        \\<\/select>
        \\<label>Pool IDs (* = all)<\/label><input id=pids value="*">
        \\<label>Custom URL<\/label><input id=curl>
        \\<label>Notes<\/label><input id=notes>
        \\<button onclick=assign()>Save<\/button>
        \\<button class=sec onclick=resolve()>Resolve<\/button>
        \\<pre id=out><\/pre><\/div><\/div>
        \\<div class=card style="margin-top:14px"><h2>Assignments<\/h2><div id=assigns><\/div><\/div>
        \\<script>
        \\async function refresh(){
        \\ const s=await fetch('\/control\/state').then(r=>r.json());
        \\ let h='<table><tr><th>ID<\/th><th>Name<\/th><th>Algo<\/th><th>URL<\/th><th><\/th><\/tr>';
        \\ (s.pools||[]).forEach(p=>{h+=`<tr><td>${p.id}<\/td><td>${p.name}<\/td><td>${p.algo}<\/td><td>${p.url}<\/td><td><button class=sec onclick="toggle('${p.id}',${!p.enabled})">${p.enabled?'off':'on'}<\/button><\/td><\/tr>`;});
        \\ pools.innerHTML=h+'<\/table>';
        \\ let a='<table><tr><th>Worker<\/th><th>Mode<\/th><th>Pools<\/th><th>Custom<\/th><\/tr>';
        \\ (s.assignments||[]).forEach(x=>{a+=`<tr><td>${x.worker}<\/td><td>${x.mode}<\/td><td>${x.pool_ids||''}<\/td><td>${x.custom_url||''}<\/td><\/tr>`;});
        \\ assigns.innerHTML=(s.assignments||[]).length?a+'<\/table>':'<p>None — default automatic<\/p>';
        \\}
        \\async function addPool(){await fetch('\/control\/pools',{method:'POST',headers:{'Content-Type':'application\/x-www-form-urlencoded'},body:new URLSearchParams({name:pname.value,url:purl.value,algo:palgo.value,priority:ppri.value})});refresh();}
        \\async function toggle(id,en){await fetch('\/control\/pools\/enable',{method:'POST',headers:{'Content-Type':'application\/x-www-form-urlencoded'},body:new URLSearchParams({id,enabled:en?'1':'0'})});refresh();}
        \\async function assign(){const r=await fetch('\/control\/assign',{method:'POST',headers:{'Content-Type':'application\/x-www-form-urlencoded'},body:new URLSearchParams({worker:worker.value,mode:mode.value,pool_ids:pids.value||'*',custom_url:curl.value,notes:notes.value})});out.textContent=await r.text();refresh();}
        \\async function resolve(){const r=await fetch('\/control\/resolve?worker='+encodeURIComponent(worker.value||'device-1')+'&algo='+encodeURIComponent(palgo.value||'skein'));out.textContent=await r.text();}
        \\refresh();
        \\<\/script><\/body><\/html>
    ;
}
