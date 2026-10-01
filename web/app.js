const $=s=>document.querySelector(s), app=$('#app'),content=$('#content');let state={},tab='overview';
const post=(n,b={})=>fetch(`https://${GetParentResourceName()}/${n}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(b)}).then(r=>r.json());
const money=n=>'$'+Number(n||0).toLocaleString('hu-HU');
function render(){
 $('#title').textContent=state.society?.label||'-';$('#balance').textContent=money(state.balance);
 document.querySelectorAll('.nav[data-tab]').forEach(b=>b.classList.toggle('active',b.dataset.tab===tab));
 if(tab==='overview'){let on=(state.members||[]).filter(x=>x.online).length;content.innerHTML=`<div class="grid"><div class="card"><div class="label">ALKALMAZOTTAK</div><div class="big">${state.members?.length||0}</div></div><div class="card"><div class="label">ONLINE</div><div class="big">${on}</div></div><div class="card"><div class="label">SZERVEZETI EGYENLEG</div><div class="big">${money(state.balance)}</div></div></div>`}
 if(tab==='members'){content.innerHTML=`<div class="list">${(state.members||[]).map(m=>`<div class="row"><div><div class="name">${esc(m.name)}</div><div class="sub">${esc(m.citizenid)}</div></div><div><span class="pill ${m.online?'':'off'}">${m.online?'ONLINE':'OFFLINE'}</span></div><div>${esc(m.gradeLabel)}</div><div class="actions">${state.canManage?`<select class="grade" data-cid="${esc(m.citizenid)}">${(state.grades||[]).map(g=>`<option value="${g.grade}" ${+g.grade===+m.grade?'selected':''}>${esc(g.label)}</option>`).join('')}</select><button class="red fire" data-cid="${esc(m.citizenid)}">Kirúgás</button>`:''}</div></div>`).join('')||'<div class="empty">Nincs alkalmazott.</div>'}</div>`}
 if(tab==='hire'){content.innerHTML=`<div class="list">${(state.candidates||[]).map(p=>`<div class="row"><div><div class="name">${esc(p.name)}</div><div class="sub">ID ${p.source} · ${esc(p.citizenid)}</div></div><div>Közeli játékos</div><div><select class="hiregrade" data-source="${p.source}">${(state.grades||[]).map(g=>`<option value="${g.grade}">${esc(g.label)}</option>`).join('')}</select></div><div class="actions"><button class="primary hire" data-source="${p.source}">Felvétel</button></div></div>`).join('')||'<div class="empty">Nincs felvehető játékos a közelben.</div>'}</div>`}
 if(tab==='finance'){content.innerHTML=`${state.canManage?`<div class="financeBox"><div class="card"><input id="dep" class="input" type="number" min="1" placeholder="Összeg"><button id="deposit" class="primary">Befizetés</button></div><div class="card"><input id="with" class="input" type="number" min="1" placeholder="Összeg"><button id="withdraw" class="secondary">Kivétel</button></div></div>`:''}<div class="card"><div class="label">TRANZAKCIÓK</div>${(state.transactions||[]).map(t=>`<div class="transaction"><span>${esc(t.reason||'Tranzakció')}<div class="sub">${new Date(t.created_at).toLocaleString('hu-HU')}</div></span><b class="${+t.amount>=0?'positive':'negative'}">${+t.amount>=0?'+':''}${money(t.amount)}</b></div>`).join('')||'<div class="empty">Nincs tranzakció.</div>'}</div>`}
 bind();
}
function esc(v){return String(v??'').replace(/[&<>"']/g,m=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]))}
function act(action,data={}){post('action',{action,...data})}
function bind(){
 document.querySelectorAll('.fire').forEach(b=>b.onclick=()=>act('fire',{citizenid:b.dataset.cid}));
 document.querySelectorAll('.grade').forEach(s=>s.onchange=()=>act('grade',{citizenid:s.dataset.cid,grade:+s.value}));
 document.querySelectorAll('.hire').forEach(b=>b.onclick=()=>{let s=document.querySelector(`.hiregrade[data-source="${b.dataset.source}"]`);act('hire',{source:+b.dataset.source,grade:+s.value})});
 let d=$('#deposit');if(d)d.onclick=()=>act('deposit',{amount:+$('#dep').value});let w=$('#withdraw');if(w)w.onclick=()=>act('withdraw',{amount:+$('#with').value});
}
window.addEventListener('message',e=>{let m=e.data;if(m.action==='open'){state=m.data||{};tab='overview';app.classList.remove('hidden');render()}if(m.action==='data'){state=m.data||{};render()}if(m.action==='close')app.classList.add('hidden')});
document.querySelectorAll('.nav[data-tab]').forEach(b=>b.onclick=()=>{tab=b.dataset.tab;render()});$('#close').onclick=()=>post('close');document.addEventListener('keydown',e=>{if(e.key==='Escape')post('close')});
