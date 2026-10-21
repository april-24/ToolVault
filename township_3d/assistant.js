import {TOOLS} from './catalog.js';
const safetyWords = /(electric shock|live wire|sparking|gas leak|structural crack|electrical socket|asbestos|severe mould|heavy water leak|exposed wiring|broken electrical|fire)/i;
const guideWords = /(how (do i|to)|where is|how can i|go to|walk to|pick.?up|collect|return|booking website|locker station|pin code|reservation|how does|what now|game)/i;
const stopwords=new Set('i my a an the to and is are want need should some this that use for of in on with it me can how please do'.split(' '));
function words(s){return (s.toLowerCase().match(/[a-z0-9]+/g)||[]).filter(w=>!stopwords.has(w));}
function scoreTool(t,q){const text=q.toLowerCase();const terms=words(q);let n=0;for(const k of t.keywords){if(text.includes(k)) n+=k.includes(' ')?7:3;else{const v=words(k);if(v.length>1 && v.every(w=>terms.includes(w))) n+=4;}}const names=words(t.name);for(const w of names){if(w.length>4&&terms.includes(w))n+=2;}return n;}
export function recommend(question){
 const q=question.trim();if(!q) return {reply:'Tell me about a household task, like “I need to hang a picture” or “my sink is blocked”.',tools:[]};
 if(safetyWords.test(q))return {reply:'⚠️ This could be hazardous. Please stop work and contact a qualified professional or building maintenance first. I cannot recommend a rental tool as a substitute for professional safety checks.',tools:[]};
 const score=TOOLS.map(tool=>({...tool,score:scoreTool(tool,q)})).filter(t=>t.score>0).sort((a,b)=>b.score-a.score);
 if(score.length){const top=score.slice(0,2);const names=top.map(t=>`${t.name} (RM${t.rate}/hour)`);return {reply:`For that job, I'd suggest ${names.join(' and ')}.\n\n${top[0].note}\n\nPress E anywhere away from the locker to open the resident booking website on your phone. Availability is confirmed by that website, not by me.`,tools:top.map(t=>t.id)};}
 if(guideWords.test(q)){return {reply:'Here is your journey: ① Press E anywhere away from the locker to take out your phone and book a tool. ② Get your pickup PIN from the real resident app. ③ Walk to ToolVault and press E to open the real kiosk. ④ After completing pickup in the kiosk, choose the same item and press “Show collected item in 3D” to carry a matching 3D prop. ⑤ Return to the machine, complete the real return, then press “Show returned item in 3D”. WASD walks and Esc closes screens.',tools:[]};}
 return {reply:'I can recommend tools for cleaning, home DIY, moving furniture, measuring, and basic drain blockages. What exactly are you trying to do? For example: “I need to clean my sofa.”',tools:[]};
}
export function namesFor(ids){return ids.map(id=>TOOLS.find(t=>t.id===id)?.name).filter(Boolean);}
