const app = document.getElementById('app');
const content = document.getElementById('content');
let state = {};
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (m) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
function post(name, data = {}) { return fetch(`https://${GetParentResourceName()}/${name}`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data)}).then(r=>r.json()).catch(()=>({})); }
function tab(title, body){ return `<div class='card'><h2>${title}</h2>${body}</div>`; }
function submitProfile(e){ e.preventDefault(); post('updateProfile',{profile_name:e.target.profile_name.value,profile_image:e.target.profile_image.value}); }
function submitTransfer(e){ e.preventDefault(); post('transferContract',{target:e.target.target.value,price:Number(e.target.price.value||0),note:e.target.note.value}); }
function submitAdmin(e, action){ e.preventDefault(); const id=e.target.identifier.value; const amount=Number(e.target.amount?.value||0); post(action,{identifier:id,amount}); }
function render() {
  const p = state.profile || {}; const active = state.active || null; const available = state.available || []; const isAdmin = !!state.isAdmin;
  const store = (state.storeStock || []).map(i=>`<div>${esc(i.label||i.item)} (${i.price||0}) <button onclick='post("buyStoreItem",{item:"${esc(i.item)}"})'>Buy</button></div>`).join('') || '<p>No items.</p>';
  const history = (state.history || []).slice(0,10).map(h=>`<li>${esc(h.class)} ${esc(h.vehicle_model)} - ${esc(h.status)}</li>`).join('') || '<li>No history.</li>';
  const board = (state.leaderboard || []).slice(0,10).map(r=>`<li>${esc(r.profile_name || r.identifier)} L${r.level} XP ${r.xp}</li>`).join('') || '<li>No leaderboard.</li>';
  content.innerHTML =
    tab('Dashboard', `<p>${esc(p.profile_name || 'Unknown')} | Lvl ${p.level || 1} | XP ${p.xp || 0} | Crypto ${p.crypto || 0}</p>`) +
    tab('Contracts', available.map((c,i)=>`<div>${esc(c.class)} ${esc(c.vehicle_model)} <button onclick='post("acceptContract",{index:${i+1}})'>Accept</button></div>`).join('') || '<p>No contracts</p>') +
    tab('Active', active ? `<button onclick='post("completeContract")'>Complete</button><button onclick='post("startHack")'>Hack</button><button onclick='post("removeTracker")'>Remove tracker</button><button onclick='post("vinScratch")'>VIN</button><button onclick='post("cancelContract")'>Cancel</button>` : '<p>No active contract</p>') +
    tab('Store', store) + tab('History', `<button onclick='post("getHistory").then(r=>{state.history=r||[];render();})'>Refresh</button><ul>${history}</ul>`) +
    tab('Leaderboard', `<button onclick='post("getLeaderboard").then(r=>{state.leaderboard=r||[];render();})'>Refresh</button><ul>${board}</ul>`) +
    tab('Profile', `<form onsubmit='submitProfile(event)'><input name='profile_name' placeholder='Profile name' value='${esc(p.profile_name||'')}'/><input name='profile_image' placeholder='Image URL' value='${esc(p.profile_image||'')}'/><button type='submit'>Save</button></form>`) +
    tab('Transfer', `<form onsubmit='submitTransfer(event)'><input name='target' placeholder='Target identifier' required/><input name='price' type='number' min='0' placeholder='Price'/><input name='note' placeholder='Note'/><button type='submit'>Transfer</button></form>`) +
    (isAdmin ? tab('Admin', `<form onsubmit='submitAdmin(event,"adminAddCrypto")'><input name='identifier' placeholder='Identifier' required/><input name='amount' type='number' placeholder='Amount' required/><button>Add Crypto</button></form><form onsubmit='submitAdmin(event,"adminSetXP")'><input name='identifier' placeholder='Identifier' required/><input name='amount' type='number' placeholder='XP' required/><button>Set XP</button></form><form onsubmit='submitAdmin(event,"adminGenerateContract")'><input name='identifier' placeholder='Identifier' required/><input name='amount' placeholder='Class (D/S etc)'/><button onclick='event.preventDefault(); const f=this.closest("form"); post("adminGenerateContract",{identifier:f.identifier.value,class:f.amount.value||"D"});'>Generate</button></form><form onsubmit='submitAdmin(event,"adminCancelContract")'><input name='identifier' placeholder='Identifier' required/><button>Cancel Contract</button></form><form onsubmit='submitAdmin(event,"adminForceComplete")'><input name='identifier' placeholder='Identifier' required/><button>Force Complete</button></form><form onsubmit='submitAdmin(event,"adminResetProfile")'><input name='identifier' placeholder='Identifier' required/><button>Reset Profile</button></form>`) : '');
}
window.submitProfile=submitProfile; window.submitTransfer=submitTransfer; window.submitAdmin=submitAdmin; window.post=post; window.render=render;
window.addEventListener('message', (e) => { if (e.data.action==='open') app.classList.remove('hidden'); if (e.data.action==='state') { state=e.data.data||{}; render(); }});
document.getElementById('close').onclick = () => { post('close'); app.classList.add('hidden'); };
