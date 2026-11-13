// El mundo plano: geometría, figuras, colisiones, cámara y aspecto ("sombras duras de bordes luminosos").
import * as THREE from 'three';

export const PAL = {
  flat:  { bg: 0x05090b, a: 0x13282f, b: 0x24474d, line: 0x9fb8b2, fog: 0x2b4244, edge: 0xece5d0, fill: 0x04080a, wall: 0xaebcb4 },
  dream: { bg: 0x07050f, a: 0x181033, b: 0x2c2152, line: 0xa99ad8, fog: 0x3a2f5c, edge: 0xe4dcff, fill: 0x05030b, wall: 0xb4a8e0 },
  color: { bg: 0x0c0906, a: 0x2b2014, b: 0x44331d, line: 0xd8c49a, fog: 0x4a3c28, edge: 0xfff2d6, fill: 0x0a0705, wall: 0xd9c8a4 },
  space: { bg: 0x0e1626, a: 0x1d3c4c, b: 0x3a7076, line: 0xcfe6dc, fog: 0x2a4a55, edge: 0xfff7e2, fill: 0x081016, wall: 0xd4e2d8 },
  cell:  { bg: 0x030506, a: 0x0b1518, b: 0x15262a, line: 0x6f8a84, fog: 0x0c1416, edge: 0xdcd5c0, fill: 0x030506, wall: 0xb4c0b8 },
};
export const GAS = 0xe6bd6e;
const TAU = Math.PI * 2;
export const rad = d => d * Math.PI / 180;
export const lerp = (a, b, t) => a + (b - a) * t;
export const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
export const ease = t => t * t * (3 - 2 * t);
export function angDiff(a, b) { let d = (b - a) % TAU; if (d > Math.PI) d -= TAU; if (d < -Math.PI) d += TAU; return d; }

// ---------- geometría ----------
export function makePoints(d) {
  if (d.pts) return d.pts.map(p => [p[0], p[1]]);
  if (d.woman) { const L = d.r || 0.95; return [[L, 0], [-L, 0]]; }
  if (d.iso) { // isósceles: ápice hacia +x
    const L = (d.r || 1) * 1.7, a = rad(d.iso) / 2, h = L * Math.cos(a), b = L * Math.sin(a);
    return [[h * 0.62, 0], [-h * 0.38, b], [-h * 0.38, -b]];
  }
  const n = d.n || 4, r = d.r || 0.75, out = [];
  for (let i = 0; i < n; i++) out.push([r * Math.cos(TAU * i / n), r * Math.sin(TAU * i / n)]);
  return out;
}
function flatGeo(pts, y = 0) {
  const pos = [], n = pts.length; let cx = 0, cy = 0;
  pts.forEach(p => { cx += p[0] / n; cy += p[1] / n; });
  for (let i = 0; i < n; i++) { const a = pts[i], b = pts[(i + 1) % n]; pos.push(cx, y, -cy, a[0], y, -a[1], b[0], y, -b[1]); }
  const g = new THREE.BufferGeometry(); g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); return g;
}
function ringGeo(pts, w, y = 0, colors = null, base = null) {
  const pos = [], col = [], n = pts.length; let cx = 0, cy = 0;
  pts.forEach(p => { cx += p[0] / n; cy += p[1] / n; });
  let inr = 1e9;
  for (let i = 0; i < n; i++) { const a = pts[i], b = pts[(i + 1) % n]; const l = Math.hypot(b[0] - a[0], b[1] - a[1]) || 1; inr = Math.min(inr, Math.abs((b[0] - a[0]) * (a[1] - cy) - (a[0] - cx) * (b[1] - a[1])) / l); }
  const k = clamp(1 - w / Math.max(inr, 1e-4), 0, 1);
  const inn = pts.map(p => [cx + (p[0] - cx) * k, cy + (p[1] - cy) * k]);
  const c = new THREE.Color();
  for (let i = 0; i < n; i++) {
    const j = (i + 1) % n, a = pts[i], b = pts[j], ai = inn[i], bi = inn[j];
    pos.push(a[0], y, -a[1], b[0], y, -b[1], bi[0], y, -bi[1], a[0], y, -a[1], bi[0], y, -bi[1], ai[0], y, -ai[1]);
    c.set(colors ? colors[i % colors.length] : base); for (let q = 0; q < 6; q++) col.push(c.r, c.g, c.b);
  }
  const g = new THREE.BufferGeometry();
  g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  g.setAttribute('color', new THREE.Float32BufferAttribute(col, 3)); return g;
}
function pushQuad(pos, ax, ay, bx, by, w, y) {
  const dx = bx - ax, dy = by - ay, l = Math.hypot(dx, dy) || 1, nx = -dy / l * w / 2, ny = dx / l * w / 2;
  const ex = dx / l * w / 2, ey = dy / l * w / 2;
  const A = [ax - ex + nx, ay - ey + ny], B = [bx + ex + nx, by + ey + ny], C = [bx + ex - nx, by + ey - ny], D = [ax - ex - nx, ay - ey - ny];
  pos.push(A[0], y, -A[1], B[0], y, -B[1], C[0], y, -C[1], A[0], y, -A[1], C[0], y, -C[1], D[0], y, -D[1]);
}

const hatchVert = `varying vec2 vP; void main(){ vP = position.xz; gl_Position = projectionMatrix*modelViewMatrix*vec4(position,1.); }`;
const hatchFrag = `varying vec2 vP; uniform vec3 uFill; uniform vec3 uInk; uniform float uDens; uniform float uHatch; uniform float uAlpha;
void main(){ float v=(vP.x+vP.y)*uDens; float l=abs(fract(v)-.5); float w=fwidth(v);
  float h=1.-smoothstep(.10-w,.10+w,l); vec3 c=mix(uFill,uInk,h*uHatch); gl_FragColor=vec4(c,uAlpha); }`;
function hatchMat(fill, ink, dens, hatch, alpha = 1) {
  return new THREE.ShaderMaterial({ vertexShader: hatchVert, fragmentShader: hatchFrag, transparent: true, depthWrite: false,
    uniforms: { uFill: { value: new THREE.Color(fill) }, uInk: { value: new THREE.Color(ink) }, uDens: { value: dens }, uHatch: { value: hatch }, uAlpha: { value: alpha } } });
}

const groundFrag = `
uniform vec3 uA,uB,uLine,uFog; uniform float uTime,uRain,uAlpha; uniform vec4 uBounds; varying vec2 vW;
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float n(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h(i),h(i+vec2(1,0)),f.x),mix(h(i+vec2(0,1)),h(i+vec2(1,1)),f.x),f.y);}
float fbm(vec2 p){float a=.5,s=0.;for(int i=0;i<4;i++){s+=a*n(p);p*=2.1;a*=.5;}return s;}
void main(){
  float f=fbm(vW*.11+vec2(uTime*.012,0.)); vec3 c=mix(uA,uB,f);
  c+=(h(floor(vW*38.))-.5)*.016;
  float st=abs(fract(vW.y*2.2+f*1.5)-.5); c+=uLine*(1.-smoothstep(.0,.07,st))*.022;      // buril: surcos este-oeste
  vec2 g=abs(fract(vW/6.)-.5)*6.; float w=fwidth(vW.x)*1.3; float l=1.-smoothstep(0.,w+.015,min(g.x,g.y)); c=mix(c,uLine,l*.11);
  float rx=floor(vW.x*2.6); float ry=fract(vW.y*.09+uTime*.55+h(vec2(rx,1.)));
  float fx=fract(vW.x*2.6); c+=uLine*smoothstep(.86,1.,ry)*step(.6,h(vec2(rx,7.)))*smoothstep(0.,.08,fx)*smoothstep(.22,.12,fx)*uRain*.5;                         // lluvia del Norte
  float d=min(min(vW.x-uBounds.x,uBounds.z-vW.x),min(vW.y-uBounds.y,uBounds.w-vW.y));
  float fog=1.-smoothstep(-3.,12.,d+fbm(vW*.2+uTime*.03)*6.); c=mix(c,uFog,fog*.85);
  gl_FragColor=vec4(c,uAlpha*(1.-smoothstep(-14.,-30.,d)*0.0));
}`;

// ---------- figura ----------
export class Entity {
  constructor(world, d) {
    Object.assign(this, { id: d.id, name: d.name || '', n: d.n || 4, voice: d.voice, woman: !!d.woman, label: d.label,
      x: d.x || 0, y: d.y || 0, rot: d.rot || 0, alt: 0, scale: 1, speed: d.speed || 2.6, ai: d.ai || null, lum: d.lum ?? 1,
      solidity: d.solid ? 1 : 0, sway: d.woman ? (d.sway ?? 1) : 0, hidden: false, noCollide: !!d.noCollide, sideColors: null, t: Math.random() * 10 });
    this.world = world; this.def = d;
    this.local = makePoints(d);
    this.rad = d.woman ? 0.35 : Math.max(...this.local.map(p => Math.hypot(p[0], p[1]))) * 0.86;
    this.group = new THREE.Group(); world.figs.add(this.group);
    this.build();
  }
  build() {
    const g = this.group, P = this.world.pal, d = this.def;
    while (g.children.length) { const c = g.children.pop(); c.geometry?.dispose(); }
    let pts = this.local;
    if (this.woman) { const L = pts[0][0]; pts = [[L, 0], [0, 0.055], [-L, 0], [0, -0.055]]; }
    const edgeCol = d.tint ?? P.edge;
    this.fill = new THREE.Mesh(flatGeo(pts, 0.01), hatchMat(P.fill, edgeCol, 3.2, this.solidity ? 0.5 : 0.16, 0.96));
    this.halo = new THREE.Mesh(ringGeo(pts.map(p => [p[0] * 1.09, p[1] * 1.09]), 0.3, 0.012, null, edgeCol),
      new THREE.MeshBasicMaterial({ vertexColors: true, transparent: true, opacity: 0.13, blending: THREE.AdditiveBlending, depthWrite: false }));
    this.edge = new THREE.Mesh(ringGeo(pts, this.woman ? 0.06 : 0.075, 0.02, this.sideColors, edgeCol), new THREE.MeshBasicMaterial({ vertexColors: true }));
    g.add(this.fill, this.halo, this.edge);
    const dot = (x, y, r, col) => { const m = new THREE.Mesh(new THREE.CircleGeometry(r, 12), new THREE.MeshBasicMaterial({ color: col })); m.rotation.x = -Math.PI / 2; m.position.set(x, 0.03, -y); g.add(m); return m; };
    if (this.woman) { dot(pts[0][0], 0, 0.085, edgeCol); dot(-pts[0][0], 0, 0.05, edgeCol); }
    else if (!d.noEye) { const f = this.local[0], k = 1 - 0.2 / Math.hypot(f[0], f[1]); dot(f[0] * k, f[1] * k, 0.055, edgeCol); }
    // entrañas: sólo visibles desde el Espacio
    this.guts = new THREE.Group(); this.guts.visible = this.world.showGuts;
    if (!this.woman && !d.noGuts) {
      const s = this.rad * 0.42, gp = [];
      for (let i = 0; i < 9; i++) { const a = TAU * i / 9; gp.push([s * (0.75 + 0.3 * Math.sin(i * 2.3)) * Math.cos(a) - s * 0.3, s * (0.7 + 0.3 * Math.cos(i * 1.7)) * Math.sin(a)]); }
      const m1 = new THREE.Mesh(ringGeo(gp, 0.045, 0.025, null, 0xe2857a), new THREE.MeshBasicMaterial({ vertexColors: true }));
      const m2 = new THREE.Mesh(new THREE.CircleGeometry(s * 0.2, 10), new THREE.MeshBasicMaterial({ color: 0xf0b25c })); m2.rotation.x = -Math.PI / 2; m2.position.set(s * 0.1, 0.028, 0);
      this.guts.add(m1, m2); this.heart = m2;
    }
    g.add(this.guts);
  }
  setColors(arr) { this.sideColors = arr; this.build(); }
  get effRot() { return this.rot + (this.sway ? Math.sin(this.t * 4.2) * 0.3 * this.sway : 0); }
  worldPts() {
    const c = Math.cos(this.effRot), s = Math.sin(this.effRot), k = this.scale;
    return this.local.map(p => [this.x + (p[0] * c - p[1] * s) * k, this.y + (p[0] * s + p[1] * c) * k]);
  }
  moveTo(x, y, speed) { return new Promise(res => { this.script = { x, y, speed: speed || this.speed, res }; }); }
  face(x, y) { this.rot = Math.atan2(y - this.y, x - this.x); }
  update(dt) {
    this.t += dt;
    let tx = null, ty = null, sp = this.speed;
    if (this.script) { tx = this.script.x; ty = this.script.y; sp = this.script.speed; }
    else if (this.ai && !this.frozen) {
      const a = this.ai;
      if (a.type === 'wander') {
        a.wait = (a.wait ?? Math.random() * 3) - dt;
        if (a.wait <= 0 && !a.tgt) { const an = Math.random() * TAU, r = Math.random() * a.r; a.tgt = [a.home[0] + Math.cos(an) * r * (a.sx || 1), a.home[1] + Math.sin(an) * r]; a.life = 7; }
        if (a.tgt) { tx = a.tgt[0]; ty = a.tgt[1]; a.life -= dt; if (a.life < 0) { a.tgt = null; a.wait = 1; tx = null; } }
      } else if (a.type === 'path') { const p = a.pts[a.i = a.i || 0]; tx = p[0]; ty = p[1]; }
      else if (a.type === 'follow') { const t = this.world.get(a.target); if (t && Math.hypot(t.x - this.x, t.y - this.y) > (a.dist || 2)) { tx = t.x; ty = t.y; sp = a.speed || 5.5; } }
    }
    if (tx !== null) {
      const dx = tx - this.x, dy = ty - this.y, d = Math.hypot(dx, dy), step = sp * dt;
      if (d <= Math.max(step, 0.05)) {
        if (this.script) { this.x = tx; this.y = ty; const r = this.script.res; this.script = null; r(); }
        else if (this.ai.type === 'wander') { this.ai.tgt = null; this.ai.wait = 1.5 + Math.random() * 4; }
        else if (this.ai.type === 'path') { this.ai.i = (this.ai.i + 1) % this.ai.pts.length; }
      } else {
        this.x += dx / d * step; this.y += dy / d * step;
        this.rot += angDiff(this.rot, Math.atan2(dy, dx)) * Math.min(1, dt * 7);
        if (!this.script && this.ai?.type === 'wander') this.world.collide(this);
      }
    }
    const g = this.group; g.visible = !this.hidden;
    g.position.set(this.x, this.alt, -this.y); g.rotation.y = this.effRot; g.scale.setScalar(this.scale);
    if (this.heart) this.heart.scale.setScalar(1 + 0.25 * Math.sin(this.t * 5));
  }
  dispose() { this.world.figs.remove(this.group); }
}

// ---------- mundo ----------
export class World {
  constructor() {
    this.scene = new THREE.Scene();
    this.cam = new THREE.PerspectiveCamera(30, 1, 0.05, 900);
    this.figs = new THREE.Group(); this.staticG = new THREE.Group(); this.fx = new THREE.Group();
    this.scene.add(this.staticG, this.figs, this.fx);
    this.ents = new Map(); this.spots = new Map(); this.walls = []; this.marks = new Map();
    this.pal = PAL.flat; this.palName = 'flat'; this.showGuts = false;
    this.zoom = 58; this.zoomCur = 58; this.baseZoom = 58; this.focus = null; this.camX = 0; this.camY = 0; this.eyeT = 0;
    this.camMode = 'follow'; this.free = { yaw: 0.6, pitch: 0.9, dist: 30 };
    this.fog = 13; this.rain = 0; this.time = 0; this.target = null;
    this.ground = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), new THREE.ShaderMaterial({
      transparent: true, depthWrite: false, side: THREE.DoubleSide,
      vertexShader: `varying vec2 vW; void main(){ vec4 w=modelMatrix*vec4(position,1.); vW=vec2(w.x,-w.z); gl_Position=projectionMatrix*viewMatrix*w; }`,
      fragmentShader: groundFrag,
      uniforms: { uA: { value: new THREE.Color() }, uB: { value: new THREE.Color() }, uLine: { value: new THREE.Color() }, uFog: { value: new THREE.Color() },
        uTime: { value: 0 }, uRain: { value: 0 }, uAlpha: { value: 1 }, uBounds: { value: new THREE.Vector4(-10, -10, 10, 10) } } }));
    this.ground.rotation.x = -Math.PI / 2; this.ground.position.y = -0.03; this.ground.renderOrder = -5;
    this.scene.add(this.ground);
    // flecha de objetivo
    const ag = new THREE.BufferGeometry(); ag.setAttribute('position', new THREE.Float32BufferAttribute([0.45, 0, 0, -0.2, 0, -0.26, -0.2, 0, 0.26], 3));
    this.arrow = new THREE.Mesh(ag, new THREE.MeshBasicMaterial({ color: GAS, transparent: true, opacity: 0.9, side: THREE.DoubleSide })); this.arrow.position.y = 0.05;
    this.scene.add(this.arrow);
  }
  setPalette(name) {
    this.palName = name; this.pal = PAL[name]; const u = this.ground.material.uniforms, P = this.pal;
    u.uA.value.set(P.a); u.uB.value.set(P.b); u.uLine.value.set(P.line); u.uFog.value.set(P.fog);
    for (const e of this.ents.values()) e.build();
    if (this.map) this.rebuild();
  }
  load(map) {
    for (const e of [...this.ents.values()]) e.dispose();
    this.ents.clear(); this.spots.forEach(s => this.fx.remove(s.mesh)); this.spots.clear();
    this.marks.forEach(m => this.fx.remove(m)); this.marks.clear(); this.target = null; this.focus = null;
    this.map = map; this.fog = map.fog || 13; this.known = {}; this.ground.visible = true; this.rain = 0;
    this.doorState = {}; (map.buildings || []).forEach(b => (b.doors || []).forEach(d => { this.doorState[d.id] = !!d.open; }));
    const b = map.bounds; this.ground.scale.set(b.x1 - b.x0 + 120, b.y1 - b.y0 + 120, 1);
    this.ground.position.set((b.x0 + b.x1) / 2, -0.03, -(b.y0 + b.y1) / 2);
    this.ground.material.uniforms.uBounds.value.set(b.x0, b.y0, b.x1, b.y1);
    this.setPalette(map.palette || 'flat');
    this.showGuts = false; this.camMode = 'follow'; this.baseZoom = this.zoom = map.zoom || 58;
  }
  setDoor(id, open) { if (this.doorState[id] !== open) { this.doorState[id] = open; this.rebuild(); } }
  reveal(id, v = true) { if (!!this.known[id] !== v) { this.known[id] = v; this.rebuild(); } }
  rebuild() {
    const g = this.staticG, P = this.pal, map = this.map;
    while (g.children.length) { const c = g.children.pop(); c.geometry?.dispose(); c.material?.map?.dispose(); c.material?.dispose(); }
    this.walls = [];
    const wallPos = [], doorPos = [], haloPos = [];
    const add = (ax, ay, bx, by, door) => {
      this.walls.push({ ax, ay, bx, by, lum: door ? 0.38 : 0.62 });
      pushQuad(door ? doorPos : wallPos, ax, ay, bx, by, door ? 0.07 : 0.17, 0.015);
      if (!door) pushQuad(haloPos, ax, ay, bx, by, 0.55, 0.012);
    };
    for (const w of map.walls || []) add(w[0], w[1], w[2], w[3]);
    for (const B of map.buildings || []) {
      const pts = makePoints({ n: B.n, r: B.R }).map(p => { const a = rad(B.rot || 0), c = Math.cos(a), s = Math.sin(a); return [B.x + p[0] * c - p[1] * s, B.y + p[0] * s + p[1] * c]; });
      B.poly = pts;
      for (let i = 0; i < pts.length; i++) {
        const a = pts[i], b = pts[(i + 1) % pts.length];
        const ds = (B.doors || []).filter(d => d.side === i).sort((p, q) => p.t - q.t);
        const L = Math.hypot(b[0] - a[0], b[1] - a[1]); let t0 = 0;
        const at = t => [lerp(a[0], b[0], t), lerp(a[1], b[1], t)];
        for (const d of ds) {
          const h = (d.w || 2.3) / 2 / L, p0 = at(d.t - h), p1 = at(d.t + h), q = at(t0);
          add(q[0], q[1], p0[0], p0[1]);
          if (!this.doorState[d.id]) add(p0[0], p0[1], p1[0], p1[1], true);
          d.pos = at(d.t); t0 = d.t + h;
        }
        const q = at(t0); add(q[0], q[1], b[0], b[1]);
      }
      for (const w of B.inner || []) add(B.x + w[0], B.y + w[1], B.x + w[2], B.y + w[3]);
      const sealed = B.sealed !== false && !this.known[B.id];
      const fm = new THREE.Mesh(flatGeo(pts, 0.004), hatchMat(P.fill, P.wall, sealed ? 1.1 : 0.6, sealed ? 0.42 : 0.0, sealed ? 0.97 : 0.55));
      fm.renderOrder = -2; g.add(fm);
      if (B.label && (sealed || B.sealed === false)) g.add(this.textPlane(B.label, B.x, B.y + (B.labelDy ?? (sealed ? 0 : -B.R * 0.55)), B.labelSize || 1.05, 0, sealed ? 0.75 : 0.4));
    }
    for (const l of map.labels || []) g.add(this.textPlane(l.t, l.x, l.y, l.s || 1.2, l.rot || 0, l.a ?? 0.38, l.it));
    const mk = (pos, mat) => { if (!pos.length) return; const bg = new THREE.BufferGeometry(); bg.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); g.add(new THREE.Mesh(bg, mat)); };
    mk(haloPos, new THREE.MeshBasicMaterial({ side: THREE.DoubleSide, color: P.wall, transparent: true, opacity: 0.07, blending: THREE.AdditiveBlending, depthWrite: false }));
    mk(wallPos, new THREE.MeshBasicMaterial({ color: P.wall, side: THREE.DoubleSide }));
    mk(doorPos, new THREE.MeshBasicMaterial({ side: THREE.DoubleSide, color: P.wall, transparent: true, opacity: 0.55 }));
  }
  textPlane(text, x, y, size, rot, alpha, italic) {
    const cv = document.createElement('canvas'), c = cv.getContext('2d');
    const font = `${italic ? 'italic ' : ''}64px ${italic ? "'IM Fell English'" : "'IM Fell English SC'"}, Georgia, serif`;
    c.font = font; const w = Math.ceil(c.measureText(text).width) + 40; cv.width = w; cv.height = 96;
    c.font = font; c.fillStyle = '#fff'; c.textBaseline = 'middle'; c.textAlign = 'center';
    if ('letterSpacing' in c) c.letterSpacing = '6px';
    c.fillText(text, w / 2, 50);
    const tex = new THREE.CanvasTexture(cv); tex.anisotropy = 4;
    const m = new THREE.Mesh(new THREE.PlaneGeometry(size * w / 96, size), new THREE.MeshBasicMaterial({ map: tex, color: this.pal.line, transparent: true, opacity: alpha, depthWrite: false }));
    m.rotation.set(-Math.PI / 2, 0, rot); m.position.set(x, 0.008, -y); m.renderOrder = -1; return m;
  }
  add(d) { const e = new Entity(this, d); this.ents.set(d.id, e); e.update(0); return e; }
  remove(id) { const e = this.ents.get(id); if (e) { e.dispose(); this.ents.delete(id); } this.unmark(id); }
  get(id) { return this.ents.get(id) || this.spots.get(id); }
  addSpot(d) {
    const pts = makePoints({ n: 4, r: 0.34 });
    const mesh = new THREE.Mesh(ringGeo(pts, 0.07, 0.02, null, GAS), new THREE.MeshBasicMaterial({ vertexColors: true, transparent: true, opacity: 0.85 }));
    mesh.position.set(d.x, 0, -d.y); this.fx.add(mesh);
    const s = { ...d, spot: true, mesh, rad: 0.2 }; this.spots.set(d.id, s); return s;
  }
  removeSpot(id) { const s = this.spots.get(id); if (s) { this.fx.remove(s.mesh); this.spots.delete(id); } this.unmark(id); }
  mark(id) {
    if (this.marks.has(id)) return;
    const pts = makePoints({ n: 28, r: 1 });
    const m = new THREE.Mesh(ringGeo(pts, 0.05, 0.04, null, GAS), new THREE.MeshBasicMaterial({ vertexColors: true, transparent: true, opacity: 0.8, depthWrite: false }));
    this.fx.add(m); this.marks.set(id, m);
  }
  unmark(id) { const m = this.marks.get(id); if (m) { this.fx.remove(m); this.marks.delete(id); } }
  collide(e) {
    if (e.noCollide) return;
    const r = e.rad * e.scale;
    for (const w of this.walls) {
      const dx = w.bx - w.ax, dy = w.by - w.ay, l2 = dx * dx + dy * dy || 1;
      const t = clamp(((e.x - w.ax) * dx + (e.y - w.ay) * dy) / l2, 0, 1), px = w.ax + dx * t, py = w.ay + dy * t;
      const ox = e.x - px, oy = e.y - py, d = Math.hypot(ox, oy);
      if (d < r && d > 1e-6) { e.x = px + ox / d * r; e.y = py + oy / d * r; }
    }
    for (const o of this.ents.values()) {
      if (o === e || o.hidden || o.noCollide || Math.abs(o.alt - e.alt) > 0.5) continue;
      const ox = e.x - o.x, oy = e.y - o.y, d = Math.hypot(ox, oy), rr = r + o.rad * o.scale;
      if (d < rr && d > 1e-6) { e.x = o.x + ox / d * rr; e.y = o.y + oy / d * rr; }
    }
    const b = this.map.bounds; e.x = clamp(e.x, b.x0 + 1, b.x1 - 1); e.y = clamp(e.y, b.y0 + 1, b.y1 - 1);
  }
  nearest(x, y, maxd, ok) {
    let best = null, bd = maxd;
    const test = o => { if (o.hidden || !ok(o)) return; const d = Math.hypot(o.x - x, o.y - y) - (o.rad || 0) * (o.scale || 1); if (d < bd) { bd = d; best = o; } };
    this.ents.forEach(test); this.spots.forEach(test); return best;
  }
  // segmentos para la vista 1D
  segments(exclude) {
    const out = this.walls.slice(), c = new THREE.Color(), P = this.pal;
    c.set(P.wall); for (const w of out) { w.r = c.r; w.g = c.g; w.b = c.b; w.id = null; }
    for (const e of this.ents.values()) {
      if (e === exclude || e.hidden || Math.abs(e.alt) > 0.01) continue;
      const p = e.worldPts(), n = p.length, m = e.woman ? 1 : n;
      for (let i = 0; i < m; i++) {
        const a = p[i], b = p[(i + 1) % n];
        c.set(e.sideColors ? e.sideColors[i % e.sideColors.length] : (e.def.tint ?? P.edge));
        out.push({ ax: a[0], ay: a[1], bx: b[0], by: b[1], lum: e.lum, r: c.r, g: c.g, b: c.b, id: e.id });
      }
    }
    return out;
  }
  update(dt, player) {
    this.time += dt;
    const u = this.ground.material.uniforms; u.uTime.value = this.time; u.uRain.value = lerp(u.uRain.value, this.rain, dt * 0.8);
    for (const e of this.ents.values()) e.update(dt);
    this.spots.forEach(s => { s.mesh.rotation.y = this.time * 1.3; s.mesh.scale.setScalar(1 + 0.15 * Math.sin(this.time * 3)); });
    this.marks.forEach((m, id) => { const o = this.get(id); if (!o || o.hidden) { m.visible = false; return; } m.visible = true;
      const r = ((o.rad || 0.3) * (o.scale || 1) + 0.5) * (1 + 0.1 * Math.sin(this.time * 4)); m.scale.setScalar(r); m.position.set(o.x, o.alt || 0, -o.y); });
    // flecha
    let T = this.target; if (typeof T === 'string') T = this.get(T);
    if (T && player && !T.hidden && Math.hypot(T.x - player.x, T.y - player.y) > 5 && this.eyeT < 0.3 && this.camMode === 'follow') {
      const a = Math.atan2(T.y - player.y, T.x - player.x); this.arrow.visible = true;
      this.arrow.position.set(player.x + Math.cos(a) * 2, 0.05, -(player.y + Math.sin(a) * 2)); this.arrow.rotation.y = a;
      this.arrow.material.opacity = 0.55 + 0.35 * Math.sin(this.time * 5);
    } else this.arrow.visible = false;
    this.updateCam(dt, player);
  }
  updateCam(dt, p) {
    const cam = this.cam, f = this.focus || p || { x: 0, y: 0 };
    const k = Math.min(1, dt * 4);
    this.shiftCur = lerp(this.shiftCur || 0, this.shift || 0, k); this.camX = lerp(this.camX, f.x + this.shiftCur, k); this.camY = lerp(this.camY, f.y, k); this.zoomCur = lerp(this.zoomCur, this.zoom, Math.min(1, dt * 2));
    if (this.camMode === 'free' && p) {
      const F = this.free, cp = Math.cos(F.pitch), tx = p.x, ty = p.alt, tz = -p.y;
      cam.position.set(tx + Math.sin(F.yaw) * cp * F.dist, ty + Math.sin(F.pitch) * F.dist, tz + Math.cos(F.yaw) * cp * F.dist);
      cam.up.set(0, 1, 0); cam.lookAt(tx, ty, tz); cam.fov = 42; cam.updateProjectionMatrix();
      this.ground.material.uniforms.uAlpha.value = 1; return;
    }
    const e = ease(this.eyeT), px = p ? p.x : f.x, py = p ? p.y : f.y, r = p ? p.rot : Math.PI / 2;
    const dx = Math.cos(r), dy = Math.sin(r);
    cam.fov = lerp(30, 62, e); cam.updateProjectionMatrix();
    cam.position.set(lerp(this.camX, px - dx * 0.2, e), lerp(this.zoomCur, 0.012, e), -lerp(this.camY, py - dy * 0.2, e));
    const lx = lerp(this.camX, px + dx * 12, e), lz = -lerp(this.camY, py + dy * 12, e);
    cam.up.set(lerp(0, 0, e), e, lerp(-1, 0, e)); if (e < 0.999) cam.up.set(dx * e * (1 - e) * 2, e, -(1 - e) - dy * e * (1 - e) * 2);
    cam.up.normalize(); cam.lookAt(lx, lerp(0, 0.012, e), lz);
    this.ground.material.uniforms.uAlpha.value = 1 - e * e;
  }
}
