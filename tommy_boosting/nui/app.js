const app=document.getElementById('app'),content=document.getElementById('content');
let state={};
function post(name,data={}){return fetch(`https://${GetParentResourceName()}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}).then(r=>r.json()).catch(()=>({}))}
function render(){const p=state.profile||{}; const available=state.available||[]; content.innerHTML=`<div class='card'><h2>Dashboard</h2><p>${p.profile_name||'Unknown'} | Lvl ${p.level||1} | XP ${p.xp||0} | Crypto ${p.crypto||0}</p></div><div class='card'><h2>Contracts</h2>${available.map((c,i)=>`<div>${c.class} ${c.vehicle_model} $${c.cash_reward} <button onclick='accept(${i+1})'>Accept</button></div>`).join('')}</div><div class='card'><button onclick='post("completeContract")'>Deliver Active</button><button onclick='post("vinScratch")'>VIN Scratch</button></div>`}
window.accept=(i)=>post('acceptContract',{index:i});
window.addEventListener('message',(e)=>{if(e.data.action==='open'){app.classList.remove('hidden')} if(e.data.action==='state'){state=e.data.data;render()}})
document.getElementById('close').onclick=()=>{post('close');app.classList.add('hidden')};document.onkeyup=(e)=>{if(e.key==='Escape'){post('close');app.classList.add('hidden')}};
