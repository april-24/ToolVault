import {recommend, namesFor} from './assistant.js';
import {TOOLS} from './catalog.js';
import {makeToolModel, TOOL_ICONS} from './tool_models.js';

// Your original Flutter apps remain untouched and provide REAL reservations and returns.
const APP_URLS={phone:'http://localhost:5000',kiosk:'http://localhost:5001'};
const $=id=>document.getElementById(id);
const mission={booking:false,pickup:false,returned:false};
let selectedToolId='cordless_drill',currentApp='phone',toastTimer;
let lastRecommended=[];
const byId=id=>TOOLS.find(t=>t.id===id);
function toast(message){const el=$('toast');el.textContent=message;el.classList.remove('hidden');clearTimeout(toastTimer);toastTimer=setTimeout(()=>el.classList.add('hidden'),4000);}

// Sounds are original, self-contained WAVs bundled with this project.
let musicEnabled=false,sfxEnabled=true;
const background=$('bg-music');background.volume=.24;
const effectFiles={pickup:'./audio/pickup.wav',return:'./audio/return.wav',open:'./audio/open.wav',step:'./audio/step.wav',success:'./audio/success.wav'};
const soundPool=Object.fromEntries(Object.entries(effectFiles).map(([k,v])=>[k,new Audio(v)]));
let stepPlayedAt=0;
function playEffect(name){
  if(!sfxEnabled)return;
  if(name==='step'){const now=performance.now();if(now-stepPlayedAt<340)return;stepPlayedAt=now;}
  const sample=soundPool[name];if(!sample)return;
  try{const copy=sample.cloneNode();copy.volume=name==='step'?.17:.65;copy.play().catch(()=>{});}catch{}
}
$('music-toggle').addEventListener('click',async()=>{
  musicEnabled=!musicEnabled;
  if(musicEnabled){try{await background.play();}catch{musicEnabled=false;toast('Chrome blocked music. Click again to enable it.');}}
  else background.pause();
  $('music-toggle').textContent=musicEnabled?'♫ Music: ON':'♫ Music: OFF';
  $('music-toggle').setAttribute('aria-pressed',String(musicEnabled));
});
$('sfx-toggle').addEventListener('click',()=>{sfxEnabled=!sfxEnabled;$('sfx-toggle').textContent=sfxEnabled?'🔊 Effects: ON':'🔇 Effects: OFF';$('sfx-toggle').setAttribute('aria-pressed',String(sfxEnabled));if(sfxEnabled)playEffect('open');});
$('music-volume').addEventListener('input',e=>background.volume=Number(e.target.value)/100);

function updateMission(){
  for(const [key,id] of [['booking','mission-home'],['pickup','mission-kiosk'],['returned','mission-return']]){
    const element=$(id);element.classList.toggle('done',mission[key]);element.querySelector('.tick').textContent=mission[key]?'✓':'○';
  }
  $('mission-count').textContent=`${String(Object.values(mission).filter(Boolean).length).padStart(2,'0')} / 03`;
  const carried=mission.pickup&&!mission.returned;
  $('carried-info').classList.toggle('hidden',!carried);
  $('carried-name').textContent=byId(selectedToolId)?.name||'rental tool';
  $('mark-return').disabled=!carried;
  $('mark-pickup').disabled=carried;
}
function selectTool(id){
  if(!byId(id))return;
  selectedToolId=id;$('tool-select').value=id;
  document.querySelectorAll('.tool-card').forEach(card=>card.classList.toggle('selected',card.dataset.tool===id));
}
function buildGallery(){
  const sel=$('tool-select');const grid=$('tool-grid');
  for(const item of TOOLS){
    const option=document.createElement('option');option.value=item.id;option.textContent=`${TOOL_ICONS[item.id]} ${item.name}`;sel.appendChild(option);
    const card=document.createElement('button');card.type='button';card.className='tool-card';card.dataset.tool=item.id;
    // This visual card is paired with an individual low-poly Three.js model when carried.
    card.innerHTML=`<span class="tool-picture"></span><span class="tool-title"></span><span class="tool-price"></span>`;
    card.querySelector('.tool-picture').textContent=TOOL_ICONS[item.id];
    card.querySelector('.tool-title').textContent=item.name;
    card.querySelector('.tool-price').textContent=`RM${item.rate} / hour`;
    card.addEventListener('click',()=>{selectTool(item.id);playEffect('open');toast(`${item.name} selected for the 3D demonstration.`);});
    grid.appendChild(card);
  }
  sel.addEventListener('change',e=>selectTool(e.target.value));selectTool(selectedToolId);
}
buildGallery();updateMission();

function showApp(which){
  currentApp=which;
  $('app-window').classList.toggle('phone-window',which==='phone');
  $('app-window').classList.toggle('kiosk-window',which==='kiosk');
  $('modal-icon').textContent=which==='phone'?'📱':'▦';
  $('modal-title').textContent=which==='phone'?'ToolVault Resident Phone':'ToolVault Locker Kiosk';
  $('modal-subtitle').textContent=which==='phone'?'Real Flutter booking website':'Real Flutter pickup and return website';
  $('app-frame').src=APP_URLS[which];$('external-app').href=APP_URLS[which];
  $('phone-actions').classList.toggle('hidden',which!=='phone');
  $('locker-actions').classList.toggle('hidden',which!=='kiosk');
  $('app-modal').classList.remove('hidden');
  $('assistant-input').blur();playEffect('open');
}
function closeApp(){
  $('app-modal').classList.add('hidden');$('app-frame').src='about:blank';$('assistant-input').blur();
}
$('close-modal').addEventListener('click',closeApp);
$('external-app').addEventListener('click',()=>toast('Opening the original Flutter website in a separate Chrome tab.'));
$('app-modal').addEventListener('click',e=>{if(e.target===$('app-modal'))closeApp();});
$('phone-quick').addEventListener('click',()=>showApp('phone'));
$('kiosk-quick').addEventListener('click',()=>{if(nearInteraction()==='kiosk')showApp('kiosk');else toast('Walk to the ToolVault station to use the kiosk.');});
$('mark-booking').addEventListener('click',()=>{
  // Manual demo confirmation; intentionally does NOT write Firebase.
  if(mission.returned){mission.booking=false;mission.pickup=false;mission.returned=false;attachCarriedTool(null);}
  mission.booking=true;updateMission();playEffect('success');closeApp();toast('Booking shown! Walk to ToolVault, press E and enter the PIN in the actual kiosk.');
});
$('mark-pickup').addEventListener('click',()=>{
  if(mission.pickup&&!mission.returned)return;
  if(!mission.booking)toast('Note: You have not marked a booking in the 3D mission.');
  mission.pickup=true;mission.returned=false;attachCarriedTool(selectedToolId);updateMission();playEffect('pickup');closeApp();
  toast(`The resident is now visibly carrying the ${byId(selectedToolId).name}. Walk around, then return to the locker.`);
});
$('mark-return').addEventListener('click',()=>{
  if(!mission.pickup||mission.returned)return;
  mission.returned=true;attachCarriedTool(null);updateMission();playEffect('return');closeApp();
  toast('The 3D tool has been returned. Verify actual return/payment in the Flutter kiosk and resident app.');
});
$('gallery-button').addEventListener('click',()=>{$('gallery-modal').classList.remove('hidden');playEffect('open');});
$('close-gallery').addEventListener('click',()=>{$('gallery-modal').classList.add('hidden');});
$('gallery-modal').addEventListener('click',e=>{if(e.target===$('gallery-modal'))$('gallery-modal').classList.add('hidden');});

$('assistant-toggle').addEventListener('click',()=>{
  const collapsed=document.querySelector('.assistant').classList.toggle('collapsed');
  $('assistant-toggle').textContent=collapsed?'+':'−';
});
function bubble(text,isUser=false){
  const row=document.createElement('div');row.className=`chat-row ${isUser?'user':'bot'}`;
  if(!isUser){const avatar=document.createElement('div');avatar.className='chat-avatar';avatar.textContent='✦';row.appendChild(avatar);}
  const el=document.createElement('div');el.className='bubble';el.textContent=text;row.appendChild(el);
  $('messages').appendChild(row);$('messages').scrollTop=$('messages').scrollHeight;return el;
}
let liveAI=false;
async function initAI(){
  try{const r=await fetch('/api/assistant/status',{signal:AbortSignal.timeout(1800)});const data=await r.json();liveAI=!!data.live_ai;
    if(liveAI)$('assistant-mode').textContent='✦ Live AI enabled · Catalogue-aware';
  }catch{}
}
initAI();
async function ask(question){
  if(!question.trim())return;
  bubble(question,true);$('assistant-input').value='';playEffect('open');
  const local=recommend(question);const output=bubble(liveAI?'Checking the tool catalogue…':local.reply);
  if(local.tools.length){lastRecommended=local.tools;selectTool(local.tools[0]);toast(`Tori highlighted ${byId(local.tools[0]).name} for the pickup demo.`);}
  if(!liveAI)return;
  try{const res=await fetch('/api/assistant',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({question}),signal:AbortSignal.timeout(26000)});
    if(!res.ok)throw Error('Unavailable');const data=await res.json();output.textContent=data.answer||local.reply;
    if(data.answer&&local.tools.length)output.textContent+='\n\nMatching catalogue items: '+namesFor(local.tools).join(' • ');
  }catch{output.textContent=local.reply+'\n\n(Live AI unavailable; built-in guide used.)';}
  $('messages').scrollTop=$('messages').scrollHeight;
}
$('assistant-form').addEventListener('submit',e=>{e.preventDefault();ask($('assistant-input').value);});
$('suggestions').addEventListener('click',e=>{const btn=e.target.closest('[data-example]');if(btn)ask(btn.dataset.example);});

let THREE;
try{THREE=await import('https://cdn.jsdelivr.net/npm/three@0.171.0/build/three.module.js');}
catch(err){try{THREE=await import('https://unpkg.com/three@0.171.0/build/three.module.js');}
catch{$('loading').innerHTML='<div class="loading-mark">⚠️</div><h1>3D engine could not load</h1><p>Connect to the internet and refresh. Three.js currently loads from a CDN.</p>';throw Error('Three.js CDN unavailable.');}}

let scene,camera,renderer,player,legs=[],arms=[],carryAnchor,phoneProp,heldObject;
let lastFootstep=0;
const game=$('game');
const interactingObjects=[];
const kioskTarget=new THREE.Vector3(8,0,-2.0);
const motion={};let facing=0;
const clock=new THREE.Clock();
function mat(hex,roughness=1){return new THREE.MeshStandardMaterial({color:hex,roughness});}
const materials={grass:mat('#8ac78b'),grass2:mat('#74b97f'),pavement:mat('#eadfc7'),road:mat('#859c9e'),cream:mat('#fcebc9'),white:mat('#fff7eb'),wall:mat('#d6e3d4'),turquoise:mat('#5bb9b1'),navy:mat('#264a59'),roof:mat('#d88270'),yellow:mat('#f5c66f'),wood:mat('#a77b57'),soil:mat('#86624c'),leaf:mat('#5b9f70'),pink:mat('#eea49c'),skin:mat('#e9a67b'),hair:mat('#3d3942'),pants:mat('#334e70'),blue:mat('#4689a9'),glass:new THREE.MeshStandardMaterial({color:'#8fd5dc',transparent:true,opacity:.82,metalness:.1,roughness:.15}),steel:mat('#9cabb0'),orange:mat('#f4a95f'),black:mat('#28384b')};
function mesh(parent,geometry,material,x=0,y=0,z=0,rotation){
  const o=new THREE.Mesh(geometry,material);o.position.set(x,y,z);
  if(rotation)o.rotation.set(...rotation);o.castShadow=true;o.receiveShadow=true;parent.add(o);return o;
}
function box(parent,w,h,d,material,x,y,z){return mesh(parent,new THREE.BoxGeometry(w,h,d),material,x,y,z);}
function cyl(parent,r1,r2,h,material,x,y,z,sides=9){return mesh(parent,new THREE.CylinderGeometry(r1,r2,h,sides),material,x,y,z);}
function sphere(parent,r,material,x,y,z,segments=10){return mesh(parent,new THREE.SphereGeometry(r,segments,8),material,x,y,z);}
function group(x=0,y=0,z=0){let obj=new THREE.Group();obj.position.set(x,y,z);scene.add(obj);return obj;}
function labelTexture(text,bg='#234656',fg='#ffffff'){
  const c=document.createElement('canvas');c.width=512;c.height=128;const ctx=c.getContext('2d');
  ctx.fillStyle=bg;ctx.beginPath();ctx.roundRect(5,5,502,118,16);ctx.fill();ctx.fillStyle=fg;ctx.font='800 56px Arial';ctx.textAlign='center';ctx.textBaseline='middle';ctx.fillText(text,256,67,460);
  let texture=new THREE.CanvasTexture(c);texture.colorSpace=THREE.SRGBColorSpace;
  return new THREE.MeshBasicMaterial({map:texture,transparent:true,side:THREE.DoubleSide});
}
function sign(parent,text,x,y,z,scale=1){return mesh(parent,new THREE.PlaneGeometry(3.1*scale,.78*scale),labelTexture(text),x,y,z);}
function terrain(){
  const g=box(scene,90,.2,65,materials.grass,0,-.17,0);g.receiveShadow=true;
  box(scene,47,.07,6,materials.pavement,0,-.01,0);
  for(let x=-22;x<=22;x+=2){box(scene,1.8,.02,5.8,mat(x%4===0?'#f1e6cb':'#e8dec8'),x,.025,0);}
  box(scene,45,.05,2.6,materials.road,0,-.035,8.0);
  for(let x=-21;x<=21;x+=4){box(scene,1.9,.015,.09,materials.white,x,.005,8.0);}
  // stone pads leading to building doors
  for(const x of [-8,8]){
    for(let z=-4;z<-1;z+=.7){box(scene,2.8,.06,.52,materials.pavement,x,.05,z);}
  }
  for(let n=0;n<60;n++){
    const x=(Math.sin(n*13.24)+Math.cos(n*4.17))*11;const z=(Math.cos(n*17.93))*11;
    if(Math.abs(z)<5.1&&Math.abs(x)<22)continue;
    if((Math.abs(x+8)<5||Math.abs(x-8)<5)&&z>-11&&z<-3)continue;
    const fl=group(x,0,z);cyl(fl,.17,.22,.1,materials.grass2,0,.025,0,8);
    sphere(fl,.11,n%2===0?materials.pink:materials.yellow,.15,.12,0,7);
  }
}
function makeTree(x,z,s=1){
  let t=group(x,0,z);cyl(t,.19*s,.25*s,2.6*s,materials.wood,0,1.3*s,0);
  sphere(t,1.35*s,materials.leaf,0,3.25*s,0,9);
  sphere(t,.95*s,materials.grass2,-.6*s,3.55*s,.1*s,8);
  sphere(t,.93*s,materials.leaf,.65*s,3.65*s,.2*s,9);
}
function makeBush(x,z,s=1){let b=group(x,0,z);sphere(b,.48*s,materials.grass2,0,.35*s,0);sphere(b,.35*s,materials.leaf,.35*s,.4*s,.15*s);}
function makeHome(){
  const h=group(-8,0,-7.0); // Decorative home: no booking hotspot.
  box(h,6.2,4.4,5.2,materials.cream,0,2.2,0);
  const roof=cyl(h,0,4.72,2.0,materials.roof,0,5.3,0,4);roof.rotation.y=Math.PI/4;
  box(h,1.7,2.55,.16,materials.wood,0,1.30,2.66);
  box(h,1.6,1.4,.18,materials.glass,-2,2.65,2.66);
  box(h,1.6,1.4,.18,materials.glass,2,2.65,2.66);
  for(const wx of [-2,2]){
    box(h,.10,1.55,.2,materials.white,wx,2.65,2.8);box(h,1.85,.1,.2,materials.white,wx,2.65,2.8);
  }
  sphere(h,.09,materials.yellow,.62,1.4,2.79);
  box(h,2,.19,1.2,materials.pavement,0,.1,3.2);
  sign(h,'HOME',0,4.07,2.69,.72);
  const desk=group(-10,0,-1);box(desk,1.2,.13,.7,materials.wood,0,1,0);cyl(desk,.06,.08,.95,materials.navy,-.45,.48,0);cyl(desk,.06,.08,.95,materials.navy,.45,.48,0);
  box(desk,.58,.44,.06,materials.navy,0,1.32,-.04);box(desk,.53,.34,.064,materials.glass,0,1.32,-.003);
  for(const [xx,zz] of [[-11.6,-4.4],[-4.6,-4.5]]){cyl(scene,.36,.46,.67,materials.wood,xx,.37,zz);sphere(scene,.6,materials.grass2,xx,1.02,zz);}
}
function makeStation(){
  const k=group(8,0,-7.0);k.userData.interact='kiosk';interactingObjects.push(k);
  box(k,6.5,.34,5.7,materials.white,0,.16,.1);
  box(k,6.2,4.5,4.6,materials.navy,0,2.45,0);
  box(k,6.45,.38,4.9,materials.turquoise,0,4.9,0);
  sign(k,'TOOLVAULT',-.05,4.15,2.37,1.16);
  // 3x3 bright mechanical locker doors on front face
  for(let i=0;i<3;i++)for(let j=0;j<3;j++){
    const xx=-2.18+i*1.31, yy=1.0+j*.9;
    box(k,1.12,.74,.075,(i+j)%2===0?materials.white:materials.wall,xx,yy,2.37);
    box(k,.10,.21,.08,materials.steel,xx+.38,yy,2.45);
  }
  // digital screen to the right
  box(k,1.1,1.38,.12,materials.black,2.21,2.26,2.4);
  box(k,.89,.96,.14,materials.glass,2.21,2.34,2.49);
  box(k,.58,.11,.09,materials.turquoise,2.21,2.01,2.58);
  box(k,1.4,.15,.55,materials.pavement,2.2,.72,2.62);
  box(k,6.5,.15,1.5,materials.pavement,0,.05,3.5);
  const left=group(4.55,0,-2.9);cyl(left,.42,.48,.7,materials.white,0,.35,0);sphere(left,.62,materials.grass2,0,.88,0);
  const right=group(11.45,0,-2.9);cyl(right,.42,.48,.7,materials.white,0,.35,0);sphere(right,.62,materials.leaf,0,.88,0);
}
function makeResident(){
  const p=group(-8,0,3.5);const facingNode=new THREE.Group();p.add(facingNode);
  const shadow=mesh(p,new THREE.CircleGeometry(.68,18),new THREE.MeshBasicMaterial({color:'#294f4b',transparent:true,opacity:.22}),0,.035,0,[-Math.PI/2,0,0]);shadow.castShadow=false;
  cyl(facingNode,.41,.37,1.1,materials.turquoise,0,1.37,0,10);
  sphere(facingNode,.40,materials.skin,0,2.28,0,12);
  sphere(facingNode,.41,materials.hair,0,2.52,-.11,11);
  sphere(facingNode,.34,materials.skin,0,2.3,.17,11);
  for(const x of [-.13,.13])sphere(facingNode,.036,materials.black,x,2.34,.48,7);
  for(const x of [-1,1]){
    const arm=new THREE.Group();arm.position.set(.52*x,1.77,0);facingNode.add(arm);
    mesh(arm,new THREE.CapsuleGeometry(.13,.62,4,8),materials.skin,0,-.40,0);arms.push(arm);
    const leg=new THREE.Group();leg.position.set(.22*x,.94,0);facingNode.add(leg);
    mesh(leg,new THREE.CapsuleGeometry(.17,.74,4,8),materials.pants,0,-.45,0);
    box(leg,.36,.2,.54,materials.white,0,-.92,.17);legs.push(leg);
  }
  carryAnchor=new THREE.Group();
  carryAnchor.position.set(.72,1.40,.23);
  facingNode.add(carryAnchor);
  // The actual item is swapped into carryAnchor after the kiosk demo pickup.
  phoneProp=new THREE.Group();
  phoneProp.position.set(.67,1.44,.50);
  facingNode.add(phoneProp);
  box(phoneProp,.31,.56,.055,materials.black,0,0,0);
  box(phoneProp,.265,.47,.064,materials.glass,0,.015,.015);
  phoneProp.rotation.x=-.18;
  phoneProp.visible=false;
  player={root:p,facingNode};
}
function lamppost(x,z){
  const l=group(x,0,z);cyl(l,.08,.12,3.2,materials.steel,0,1.6,0);sphere(l,.36,materials.yellow,0,3.3,0);
}
function extras(){
  for(let x=-20;x<=20;x+=6){if(Math.abs(x-8)<4||Math.abs(x+8)<4)continue;makeTree(x,-12,1.0+(Math.abs(x)%3)*.11);makeTree(x,13,.9);}
  for(const [x,z] of [[-17,3],[-13,5],[13,5],[17,3],[-1,-5],[0,13]])makeTree(x,z,.85);
  for(const [x,z] of [[-14,-3.8],[-4,-3.5],[4,-3.5],[14,-3.8],[0,-6]])makeBush(x,z,1);
  for(const x of [-2.5,2.5])lamppost(x,4.5);
  // decorative pond and bench
  const p=group(-16,0,-8);cyl(p,1.7,1.7,.11,materials.glass,0,.015,0,24);
  const bench=group(0,0,-4.5);box(bench,2.2,.25,.65,materials.wood,0,.76,0);box(bench,2.2,.88,.2,materials.wood,0,1.22,-.29);
  for(const x of [-.8,.8])box(bench,.15,.73,.14,materials.navy,x,.35,0);
}
function updateCharacter(dt,time){
  let x=(motion.KeyD||motion.ArrowRight?1:0)-(motion.KeyA||motion.ArrowLeft?1:0);
  let z=(motion.KeyS||motion.ArrowDown?1:0)-(motion.KeyW||motion.ArrowUp?1:0);
  const moving=(x!==0||z!==0)&&$('app-modal').classList.contains('hidden');
  if(moving){let len=Math.hypot(x,z);x/=len;z/=len;
    const nx=THREE.MathUtils.clamp(player.root.position.x+x*dt*5.0,-22,22),nz=THREE.MathUtils.clamp(player.root.position.z+z*dt*5.0,-9.7,15);
    const insideHome=Math.abs(nx+8)<3.6&&nz< -4.0;
    const insideStation=Math.abs(nx-8)<3.8&&nz< -4.15;
    if(!insideHome&&!insideStation)player.root.position.set(nx,0,nz);
    facing=Math.atan2(x,z);player.facingNode.rotation.y=THREE.MathUtils.lerp(player.facingNode.rotation.y,facing,.2);
  }
  for(let i=0;i<2;i++){const a=moving?Math.sin(time*10+i*Math.PI):0;legs[i].rotation.x=THREE.MathUtils.lerp(legs[i].rotation.x,a*.48,.16);arms[i].rotation.x=THREE.MathUtils.lerp(arms[i].rotation.x,-a*.39,.16);}
  if(moving && (time-lastFootstep)>.38){lastFootstep=time; playEffect('step');}
  phoneProp.visible= !(!$('app-modal').classList.contains('hidden')) && currentApp==='phone';
  if(heldObject)heldObject.rotation.z=.04*Math.sin(time*3.2);
}
function nearInteraction(){
  return player.root.position.distanceTo(kioskTarget)<4.8?'kiosk':null;
}
function attachCarriedTool(id){
  if(heldObject){carryAnchor.remove(heldObject);heldObject=null;}
  if(!id)return;
  const obj=makeToolModel(THREE,id);
  const bbox=new THREE.Box3().setFromObject(obj);
  const size=new THREE.Vector3();bbox.getSize(size);
  const maxSpan=Math.max(size.x,size.y,size.z);
  const desired=id==='step_ladder'?1.6:1.05;
  const factor=desired/Math.max(.01,maxSpan);
  obj.scale.setScalar(factor);
  const center=new THREE.Vector3();bbox.getCenter(center);
  obj.position.copy(center.multiplyScalar(-factor));
  obj.position.y+=id==='step_ladder'?.43:.13;
  obj.rotation.z=id==='step_ladder'?.28:0;
  carryAnchor.add(obj);
  heldObject=obj;
}
function updatePrompt(){
  $('interact-hint').classList.toggle('hidden',!$('app-modal').classList.contains('hidden') || !$('gallery-modal').classList.contains('hidden'));
  $('interact-title').textContent=nearInteraction()==='kiosk'?'Open ToolVault pickup / return screen':'Take out phone and book a tool';
}
function placeLabel(id,world){
  let p=world.clone().project(camera),rect=game.getBoundingClientRect();
  const el=$(id);const visible=p.z<1&&p.z>-1&&p.x>=-1.5&&p.x<=1.5;
  el.style.display=visible?'block':'none';if(visible){el.style.left=`${((p.x+1)*.5)*rect.width}px`;el.style.top=`${((1-p.y)*.5)*rect.height-14}px`;}
}
function animate(){requestAnimationFrame(animate);const dt=Math.min(clock.getDelta(),.04),t=clock.elapsedTime;updateCharacter(dt,t);
  const desired=new THREE.Vector3(player.root.position.x+9.5,11.2,player.root.position.z+15.4);
  camera.position.lerp(desired,.065);camera.lookAt(player.root.position.x,1.2,player.root.position.z-2.8);
  renderer.render(scene,camera);
  placeLabel('label-home',new THREE.Vector3(-8,6.6,-7));placeLabel('label-kiosk',new THREE.Vector3(8,6.6,-7));updatePrompt();
}
function resize(){const width=game.clientWidth,height=game.clientHeight;camera.aspect=width/height;camera.updateProjectionMatrix();renderer.setSize(width,height);}
function initWorld(){
  scene=new THREE.Scene();scene.background=new THREE.Color('#bfe4f2');scene.fog=new THREE.Fog('#bfe4f2',39,80);
  camera=new THREE.PerspectiveCamera(48,1,.1,130);camera.position.set(0,14,20);
  renderer=new THREE.WebGLRenderer({antialias:true,alpha:false,powerPreference:'high-performance'});
  renderer.setPixelRatio(Math.min(window.devicePixelRatio,1.6));renderer.shadowMap.enabled=true;renderer.shadowMap.type=THREE.PCFSoftShadowMap;
  renderer.outputColorSpace=THREE.SRGBColorSpace;renderer.toneMapping=THREE.ACESFilmicToneMapping;renderer.toneMappingExposure=1.23;
  game.appendChild(renderer.domElement);
  const hemi=new THREE.HemisphereLight('#eaf7ff','#7f9b78',3.0);scene.add(hemi);
  const sun=new THREE.DirectionalLight('#fff3d1',3.7);sun.position.set(-8,17,7);sun.castShadow=true;sun.shadow.mapSize.set(2048,2048);sun.shadow.camera.left=-28;sun.shadow.camera.right=28;sun.shadow.camera.top=26;sun.shadow.camera.bottom=-26;sun.shadow.bias=-.0004;scene.add(sun);
  terrain();makeHome();makeStation();extras();makeResident();resize();
  window.addEventListener('resize',resize);
  animate();
  const loading=$('loading');loading.style.opacity=0;setTimeout(()=>loading.remove(),520);
  updateMission();
}
try{initWorld();}
catch(error){console.error(error);$('loading').innerHTML='<h1>Cannot start 3D</h1><p>Try enabling Chrome hardware acceleration, then reload the page.</p>';}



window.addEventListener('keydown',e=>{
  if(e.code==='Escape'){
    if(!$('app-modal').classList.contains('hidden'))closeApp();
    else if(!$('gallery-modal').classList.contains('hidden'))$('gallery-modal').classList.add('hidden');
    else $('assistant-input').blur();
    return;
  }
  if(e.target instanceof HTMLElement && (e.target.closest('input,textarea,select,iframe')||e.target.isContentEditable))return;
  if(!$('app-modal').classList.contains('hidden')||!$('gallery-modal').classList.contains('hidden'))return;
  if(e.code==='KeyE'){e.preventDefault();if(nearInteraction()==='kiosk')showApp('kiosk');else showApp('phone');return;}
  if(e.code==='KeyP'){e.preventDefault();showApp('phone');return;}
  if(e.code==='KeyG'){e.preventDefault();$('gallery-modal').classList.remove('hidden');return;}
  if(['KeyW','KeyA','KeyS','KeyD','ArrowUp','ArrowDown','ArrowLeft','ArrowRight'].includes(e.code)){
    motion[e.code]=true;e.preventDefault();
  }
});
window.addEventListener('keyup',e=>{motion[e.code]=false;});
window.addEventListener('blur',()=>{for(const k of Object.keys(motion))motion[k]=false;});
$('reset-game').addEventListener('click',()=>{player.root.position.set(-8,0,3.5);toast('Back at the starting point. E opens your phone anywhere outside the station.');});
const ray=new THREE.Raycaster(),pointer=new THREE.Vector2();
renderer.domElement.addEventListener('click',e=>{
  if(!$('app-modal').classList.contains('hidden')||!$('gallery-modal').classList.contains('hidden'))return;
  const rect=renderer.domElement.getBoundingClientRect();pointer.x=((e.clientX-rect.left)/rect.width)*2-1;pointer.y=-((e.clientY-rect.top)/rect.height)*2+1;
  ray.setFromCamera(pointer,camera);
  const hits=ray.intersectObjects(interactingObjects,true);
  if(!hits.length)return;
  let obj=hits[0].object;while(obj&&!obj.userData.interact)obj=obj.parent;
  if(obj?.userData.interact==='kiosk'){
    if(nearInteraction()==='kiosk')showApp('kiosk');
    else toast('Walk closer to the ToolVault locker to use the pickup/return screen.');
  }
});
