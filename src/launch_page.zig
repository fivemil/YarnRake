const std = @import("std");

/// Fleet quick-launch checkbox console
pub fn html() []const u8 {
    return
        \\<!doctype html><html><head><meta charset=utf-8><meta name=viewport content="width=device-width,initial-scale=1">
        \\<title>Fleet launch — YarnRake / MagiMDM</title>
        \\<style>
        \\body{margin:0;font-family:system-ui,sans-serif;background:#0f1117;color:#e8eaed;padding:24px;max-width:720px}
        \\h1{font-size:1.4rem;margin:0 0 8px} .sub{color:#9aa0a6;margin-bottom:20px;font-size:.9rem}
        \\.card{background:#1a1d27;border:1px solid #2a2f3a;border-radius:12px;padding:16px 18px;margin-bottom:14px}
        \\label.row{display:flex;gap:10px;align-items:flex-start;padding:8px 0;border-bottom:1px solid #2a2f3a;cursor:pointer}
        \\label.row:last-child{border:0} input[type=checkbox]{margin-top:3px;width:18px;height:18px}
        \\.name{font-weight:600} .hint{display:block;color:#9aa0a6;font-size:.8rem;margin-top:2px}
        \\.fields{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:10px}
        \\input[type=text]{width:100%;box-sizing:border-box;background:#0f1117;border:1px solid #3a4150;color:#eee;border-radius:8px;padding:8px 10px}
        \\button{background:#3d7eff;color:#fff;border:0;border-radius:8px;padding:10px 16px;font-weight:600;cursor:pointer;margin-right:8px;margin-top:8px}
        \\button.sec{background:#2a2f3a} pre{background:#0a0c10;border-radius:8px;padding:12px;overflow:auto;font-size:.85rem;white-space:pre-wrap}
        \\a{color:#5e9bdc}
        \\<\/style><\/head><body>
        \\<h1>Fleet quick launch<\/h1>
        \\<p class=sub>Tick what to run. Copy the command into a terminal on this machine (miners are not started from the browser).<\/p>
        \\<div class=card>
        \\<label class=row><input type=checkbox id=yr checked><span><span class=name>YarnRake pool<\/span><span class=hint>HTTP console + stratum — required for mining workers<\/span><\/span><\/label>
        \\<label class=row><input type=checkbox id=mdm><span><span class=name>MagiMDM console<\/span><span class=hint>Needs MAGIMDM_PATH and a built zig-mdm binary<\/span><\/span><\/label>
        \\<label class=row><input type=checkbox id=mock><span><span class=name>Mock MDM agent<\/span><span class=hint>Python enroll\/poll against MagiMDM<\/span><\/span><\/label>
        \\<label class=row><input type=checkbox id=onboard checked><span><span class=name>Onboard worker on YarnRake<\/span><span class=hint>Register this worker name in the pool<\/span><\/span><\/label>
        \\<label class=row><input type=checkbox id=lab checked><span><span class=name>Lab stratum client<\/span><span class=hint>No external miner — good first test<\/span><\/span><\/label>
        \\<label class=row><input type=checkbox id=xmrig><span><span class=name>XMRig<\/span><span class=hint>CPU RandomX \/ GhostRider (binary on PATH)<\/span><\/span><\/label>
        \\<label class=row><input type=checkbox id=cpu><span><span class=name>cpuminer-opt<\/span><span class=hint>Skein \/ Yescrypt \/ Scrypt<\/span><\/span><\/label>
        \\<label class=row><input type=checkbox id=lol><span><span class=name>lolMiner<\/span><span class=hint>GPU KawPow \/ Etchash<\/span><\/span><\/label>
        \\<div class=fields>
        \\<div><label class=hint>Worker<\/label><input type=text id=worker value=device-1><\/div>
        \\<div><label class=hint>Algo<\/label><input type=text id=algo value=skein list=algo-list>
        \\<datalist id=algo-list><option>skein<\/option><option>yescrypt_r16<\/option><option>randomx<\/option><option>kawpow<\/option><option>sha256d<\/option><option>scrypt<\/option><\/datalist><\/div>
        \\<\/div>
        \\<button type=button onclick=build()>Copy command<\/button>
        \\<button type=button class=sec onclick=status()>Refresh status<\/button>
        \\<\/div>
        \\<div class=card><div class=hint>Command<\/div><pre id=cmd>.\/tools\/fleet_launch.sh --all-lab<\/pre>
        \\<div class=hint>Status<\/div><pre id=st>loading…<\/pre><\/div>
        \\<p class=sub>Docs: <a href="https:\/\/github.com\/fivemil\/YarnRake\/blob\/main\/docs\/LAUNCH.md">LAUNCH.md<\/a> · <a href=\/pool>pool<\/a> · <a href=\/onboard>onboard<\/a> · <a href=\/>home<\/a><\/p>
        \\<script>
        \\function build(){
        \\  const f=['.\/tools\/fleet_launch.sh'];
        \\  if(yr.checked)f.push('--yarnrake');
        \\  if(mdm.checked)f.push('--mdm');
        \\  if(mock.checked)f.push('--mock-agent');
        \\  if(onboard.checked)f.push('--onboard');
        \\  if(lab.checked)f.push('--lab-client');
        \\  if(xmrig.checked)f.push('--xmrig');
        \\  if(cpu.checked)f.push('--cpuminer');
        \\  if(lol.checked)f.push('--lolminer');
        \\  f.push('--worker',worker.value.trim()||'device-1');
        \\  f.push('--algo',algo.value.trim()||'skein');
        \\  const s=f.join(' ');
        \\  cmd.textContent=s;
        \\  navigator.clipboard.writeText(s).then(()=>st.textContent='Copied.\n'+st.textContent).catch(()=>{});
        \\}
        \\async function status(){
        \\  try{
        \\    const p=await fetch('\/pool').then(r=>r.json());
        \\    st.textContent='YarnRake OK\nalgo='+p.algo+' stratum='+p.stratum_port+'\nshares='+p.shares_total+' rejected='+p.rejected_total+' sessions='+p.sessions;
        \\  }catch(e){st.textContent='Pool unreachable (is yarnrake running?)';}
        \\}
        \\status();
        \\<\/script><\/body><\/html>
    ;
}
