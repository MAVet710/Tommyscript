const app = document.getElementById('app');
const content = document.getElementById('content');
let state = {};

function post(name, data = {}) {
  return fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify(data)
  }).then(r => r.json()).catch(() => ({}));
}

function tab(title, body){ return `<div class='card'><h2>${title}</h2>${body}</div>`; }

function render() {
  const p = state.profile || {};
  const active = state.active || null;
  const available = state.available || [];
  const isAdmin = !!state.isAdmin;
  content.innerHTML =
    tab('Dashboard', `<p>${p.profile_name || 'Unknown'} | Lvl ${p.level || 1} | XP ${p.xp || 0} | Crypto ${p.crypto || 0}</p>`) +
    tab('Contracts', available.map((c,i)=>`<div>${c.class} ${c.vehicle_model} <button onclick='post("acceptContract",{index:${i+1}})'>Accept contract</button></div>`).join('')) +
    tab('Active Contract', active ? `<button onclick='post("completeContract")'>Complete delivery</button><button onclick='post("startHack")'>Start hack</button><button onclick='post("removeTracker")'>Remove tracker</button><button onclick='post("vinScratch")'>VIN scratch</button><button onclick='post("cancelContract")'>Cancel contract</button>` : '<p>No active contract</p>') +
    tab('Store', `<button onclick='post("buyStoreItem",{item:"tracker_remover"})'>Buy store item</button>`) +
    tab('History', `<button onclick='post("getHistory")'>History</button>`) +
    tab('Leaderboard', `<button onclick='post("getLeaderboard")'>Leaderboard</button>`) +
    tab('Profile', `<button onclick='post("updateProfile",{profile_name:"Boosted"})'>Update profile</button>`) +
    tab('Transfer', `<button onclick='post("transferContract",{target:""})'>Transfer contract</button>`) +
    (isAdmin ? tab('Admin', `<button onclick='post("adminSearchPlayer",{identifier:""})'>Search</button><button onclick='post("adminAddCrypto",{identifier:"",amount:1})'>+Crypto</button><button onclick='post("adminRemoveCrypto",{identifier:"",amount:1})'>-Crypto</button><button onclick='post("adminAddXP",{identifier:"",amount:1})'>+XP</button><button onclick='post("adminRemoveXP",{identifier:"",amount:1})'>-XP</button><button onclick='post("adminSetXP",{identifier:"",amount:1})'>Set XP</button><button onclick='post("adminGenerateContract",{identifier:"",class:"D"})'>Generate</button><button onclick='post("adminCancelContract",{identifier:""})'>Cancel</button><button onclick='post("adminForceComplete",{identifier:""})'>Force complete</button><button onclick='post("adminGetLogs")'>Logs</button>`) : '');
}

window.addEventListener('message', (e) => {
  if (e.data.action === 'open') app.classList.remove('hidden');
  if (e.data.action === 'state') { state = e.data.data; render(); }
});
document.getElementById('close').onclick = () => { post('close'); app.classList.add('hidden'); };
