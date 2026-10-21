// Procedural, low-poly 3D silhouettes for EVERY rental type in catalog.js.
// For the 3D demonstration only. These are not physical measurements.
export const TOOL_ICONS = {
  step_ladder:'🪜', cordless_drill:'🛠️', wet_dry_vacuum:'🧹', carpet_cleaner:'🧼',
  pressure_washer:'💦', steam_cleaner:'♨️', hand_truck:'📦', furniture_kit:'🛋️',
  laser_measure:'📏', laser_level:'📐', stud_finder:'🔎', workbench:'🪚',
  drain_auger:'🌀', dehumidifier:'💧', window_kit:'🪟'
};

export function makeToolModel(T, id) {
  const g = new T.Group();
  const p={yellow:0xffc44f,orange:0xef9e4a,navy:0x344e63,steel:0x99a9b3,light:0xe8eff1,
    blue:0x58a4c9,black:0x27333d,red:0xd95e57,green:0x55b5a0,wood:0xb98759};
  const m={};for(const [k,v] of Object.entries(p))m[k]=new T.MeshStandardMaterial({color:v,roughness:.75,metalness:k==='steel'?.4:0});
  function add(geo,ma,x=0,y=0,z=0,rot){const n=new T.Mesh(geo,m[ma]||m.steel);n.position.set(x,y,z);if(rot)n.rotation.set(...rot);n.castShadow=true;n.receiveShadow=true;g.add(n);return n;}
  function b(w,h,d,ma,x=0,y=0,z=0,rot){return add(new T.BoxGeometry(w,h,d),ma,x,y,z,rot);}
  function c(r,h,ma,x=0,y=0,z=0){return add(new T.CylinderGeometry(r,r,h,12),ma,x,y,z);}
  function tube(a,z,r,ma){const st=new T.Vector3(...a),end=new T.Vector3(...z),delta=end.clone().sub(st);const obj=add(new T.CylinderGeometry(r,r,delta.length(),10),ma,...st.clone().add(end).multiplyScalar(.5).toArray());obj.quaternion.setFromUnitVectors(new T.Vector3(0,1,0),delta.normalize());return obj;}
  function wheel(x,y,z=.24){const w=c(.18,.12,'black',x,y,z);w.rotation.x=Math.PI/2;c(.075,.132,'steel',x,y,z).rotation.x=Math.PI/2;return w;}
  switch(id){
    case 'step_ladder':{
      // A visibly tall A-frame ladder with four rungs and open rear support.
      tube([-.33,.05,.11],[-.27,1.8,.05],.055,'steel');tube([.33,.05,.11],[.27,1.8,.05],.055,'steel');
      tube([-.27,1.72,-.05],[-.48,.03,-.47],.045,'navy');tube([.27,1.72,-.05],[.48,.03,-.47],.045,'navy');
      for(let j=0;j<4;j++)b(.66,.105,.22,'yellow',0,.29+j*.34,.1);
      b(.66,.24,.28,'orange',0,1.76,.02);break;
    }
    case 'cordless_drill':{
      b(.85,.36,.38,'yellow',0,.65,0);b(.33,.64,.27,'black',-.12,.23,.02);
      b(.45,.19,.37,'navy',-.1,-.09,.02);c(.15,.3,'steel',.53,.64,0).rotation.z=Math.PI/2;
      tube([.7,.64,0],[1.02,.64,0],.052,'steel');b(.15,.17,.09,'black',-.12,.37,.26);break;
    }
    case 'wet_dry_vacuum':{
      c(.42,.8,'steel',0,.55,0);c(.46,.16,'navy',0,1.00,0);
      c(.17,.16,'black',.20,1.15,0);wheel(-.34,.18,.39);wheel(.34,.18,.39);
      tube([.32,.92,0],[.68,1.24,.22],.07,'black');tube([.68,1.24,.22],[.96,.70,.22],.07,'black');break;
    }
    case 'carpet_cleaner':{
      b(.9,.24,.6,'blue',0,.15,.15);b(.48,1.0,.36,'navy',0,.78,-.06);
      b(.35,.40,.16,'light',0,.96,.16);tube([0,1.23,-.18],[0,1.85,-.32],.06,'steel');
      b(.68,.09,.15,'steel',0,1.86,-.32);wheel(-.33,.20,-.19);wheel(.33,.20,-.19);break;
    }
    case 'pressure_washer':{
      b(.78,.86,.55,'green',0,.63,0);b(.66,.20,.48,'navy',0,.16,0);
      wheel(-.40,.17,.37);wheel(.40,.17,.37);
      tube([-.31,1.0,0],[-.31,1.47,0],.05,'black');tube([.31,1.0,0],[.31,1.47,0],.05,'black');
      tube([-.31,1.48,0],[.31,1.48,0],.06,'black');
      tube([.57,1.25,.20],[1.32,1.64,.25],.035,'black');tube([1.32,1.64,.25],[1.62,1.75,.25],.024,'steel');break;
    }
    case 'steam_cleaner':{
      b(.9,.55,.57,'light',0,.35,0);b(.66,.13,.48,'blue',0,.71,0);
      c(.12,.10,'navy',-.22,.81,0);wheel(-.35,.14,.33);wheel(.35,.14,.33);
      tube([.28,.75,0],[.64,1.15,.12],.06,'black');tube([.64,1.15,.12],[1.07,1.11,.12],.048,'black');break;
    }
    case 'hand_truck':{
      for(const x of [-.34,.34])tube([x,.13,0],[x,1.7,0],.055,'steel');
      tube([-.35,1.74,0],[.35,1.74,0],.07,'navy');b(.95,.10,.66,'orange',0,.11,.27);
      wheel(-.36,.15,-.22);wheel(.36,.15,-.22);break;
    }
    case 'furniture_kit':{
      for(const [x,z] of [[-.46,-.34],[.46,-.34],[-.46,.34],[.46,.34]]){
        c(.25,.12,'black',x,.12,z);c(.16,.12,'yellow',x,.20,z);
      }
      tube([-.35,.45,0],[.76,1.21,0],.075,'steel');b(.26,.18,.25,'red',.8,1.24,0);break;
    }
    case 'laser_measure':{
      b(.54,.94,.31,'navy',0,.63,0);b(.43,.45,.32,'blue',0,.73,.02);
      b(.36,.12,.035,'light',0,.64,.18);b(.22,.09,.04,'yellow',0,.38,.19);
      c(.095,.055,'red',0,1.12,.0);break;
    }
    case 'laser_level':{
      for(let k=0;k<3;k++){const a=k*Math.PI*2/3;tube([0,.75,0],[Math.cos(a)*.68,.05,Math.sin(a)*.68],.035,'steel');}
      b(.79,.53,.6,'orange',0,.95,0);b(.48,.28,.09,'black',0,1.01,.34);
      c(.08,.10,'green',0,.96,.4).rotation.x=Math.PI/2;break;
    }
    case 'stud_finder':{
      b(.48,.83,.22,'yellow',0,.49,0);c(.16,.12,'navy',0,.71,.15).rotation.x=Math.PI/2;
      b(.28,.12,.035,'green',0,.33,.13);b(.29,.10,.03,'red',0,.12,.13);break;
    }
    case 'workbench':{
      b(1.55,.2,.72,'wood',0,1.14,0);
      tube([-.56,1.08,-.15],[.44,.09,-.15],.055,'navy');tube([.56,1.08,.15],[-.44,.09,.15],.055,'navy');
      tube([-.56,1.08,.15],[.44,.09,.15],.055,'steel');tube([.56,1.08,-.15],[-.44,.09,-.15],.055,'steel');
      b(.14,.22,.8,'black',.65,1.37,0);break;
    }
    case 'drain_auger':{
      c(.47,.19,'orange',0,.62,0).rotation.x=Math.PI/2;
      for(let i=0;i<3;i++){const t=add(new T.TorusGeometry(.31-i*.045,.032,8,24),'steel',0,.62,.18+i*.04);t.rotation.x=0;}
      tube([.39,.62,0],[.85,.62,0],.065,'black');tube([.85,.62,0],[.85,1.02,0],.065,'steel');
      tube([0,.62,-.18],[-.65,.62,-.18],.034,'steel');break;
    }
    case 'dehumidifier':{
      b(.85,1.16,.58,'light',0,.65,0);b(.71,.17,.62,'blue',0,1.2,0);
      for(let i=0;i<5;i++)b(.56,.045,.03,'navy',0,.48+i*.09,.31);
      b(.26,.13,.04,'green',0,1.14,.32);wheel(-.30,.12,.31);wheel(.30,.12,.31);break;
    }
    case 'window_kit':{
      tube([0,.02,0],[0,1.82,0],.045,'steel');tube([0,1.83,0],[.15,2.0,0],.045,'navy');
      b(.92,.12,.13,'blue',.15,2.02,0);b(.9,.08,.12,'black',.15,1.94,.03);
      b(.16,.30,.13,'orange',0,.24,0);break;
    }
    default: b(.7,.7,.7,'yellow',0,.4,0);
  }
  g.userData.toolId=id;
  return g;
}
