const app = document.getElementById('app');
const content = document.getElementById('content');
let state = {}; let adminMsg = '';
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (m) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));
function post(name, data = {}) { return fetch(`https://${GetParentResourceName()}/${name}`, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(data)}).then(r=>r.json()).catch(()=>({})); }
function tab(title, body){ return `<div class='card'><h2>${title}</h2>${body}</div>`; }
function submitProfile(e){ e.preventDefault(); post('updateProfile',{profile_name:e.target.profile_name.value,profile_image:e.target.profile_image.value}); }
function submitTransfer(e){ e.preventDefault(); post('transferContract',{target:e.target.target.value,price:Number(e.target.price.value||0),note:e.target.note.value}); }
function submitAdmin(e, action){ e.preventDefault(); const id=e.target.identifier.value; const amount=Number(e.target.amount?.value||0); post(action,{identifier:id,amount}).then((r)=>{adminMsg = JSON.stringify(r || 'sent'); render();}); }
function render() {
  const p = state.profile || {}; const active = state.active || null; const available = state.available || []; const isAdmin = !!state.isAdmin;
  const store = (state.store || []).map(i=>`<div>${esc(i.label||i.item)} - ${esc(i.description||'')} | ${i.price||0} crypto | Stock: ${state.storeStock?.[i.item] ?? i.stock ?? 'n/a'} <button onclick='post("buyStoreItem",{item:"${esc(i.item)}"})'>Buy</button></div>`).join('') || '<p>No items.</p>';
  const activeDetails = active ? `<p>Class: ${esc(active.class)} | Vehicle: ${esc(active.vehicle_model)} | Plate: ${esc(active.plate)} | Hacking: ${active.hack_completed==1?'Done':'Pending'} | Tracker: ${active.has_tracker==1?(active.tracker_removed==1?'Removed':'Active'):'None'} | Dropoff: ${esc(active.dropoff)}</p>` : '<p>No active contract</p>';
  const actionBtns = active ? `<button onclick='post("completeContract")'>Complete</button>${active.requires_hacking==1 && active.hack_completed!=1?`<button onclick='post("startHack")'>Hack</button>`:''}${active.has_tracker==1 && active.tracker_removed!=1?`<button onclick='post("removeTracker")'>Remove tracker</button>`:''}${['A','S','S+'].includes(active.class)?`<button onclick='post("vinScratch")'>VIN</button>`:''}<button onclick='post("cancelContract")'>Cancel</button>` : '';
  content.innerHTML = tab('Dashboard', `<p>${esc(p.profile_name || 'Unknown')} | Lvl ${p.level || 1} | XP ${p.xp || 0} | Crypto ${p.crypto || 0}</p>`) +
    tab('Contracts', available.map((c,i)=>`<div>${esc(c.class)} ${esc(c.vehicle_model)} <button onclick='post("acceptContract",{index:${i+1}})'>Accept</button></div>`).join('') || '<p>No contracts</p>') +
    tab('Active', activeDetails + actionBtns) + tab('Store', store) +
    (isAdmin ? tab('Admin', `<div>${esc(adminMsg)}</div>`) : '');
}
window.submitProfile=submitProfile; window.submitTransfer=submitTransfer; window.submitAdmin=submitAdmin; window.post=post; window.render=render;
window.addEventListener('message', (e) => { if (e.data.action==='open') app.classList.remove('hidden'); if (e.data.action==='state') { state=e.data.data||{}; render(); }});
document.getElementById('close').onclick = () => { post('close'); app.classList.add('hidden'); };
