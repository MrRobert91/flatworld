// Núcleo: bucle, entrada, estado, guardado y utilidades de guion para los capítulos.
import * as THREE from 'three';
import { World, PAL, lerp, clamp, angDiff } from './world.js';
import { Eye } from './eye.js';
import { UI } from './ui.js';
import { Audio } from './audio.js';
import { FRAGMENTS, KNOWLEDGE } from './content/book.js';

const SAVE = 'planilandia.v1';
const fresh = () => ({ chapter: 0, max: 0, rep: { sac: 0, ciu: 0, aut: 0 }, her: 0, know: {}, frags: {}, flags: {} });

export class Game {
  constructor(canvas) {
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, 2)); this.renderer.autoClear = false;
    this.world = new World(); this.eye = new Eye();
    this.keys = new Set(); this.state = fresh(); this.load();
    this.view = 'top'; this.viewLock = false; this.showStrip = true; this.busy = false; this.locked = false; this.paused = false;
    this.handlers = new Map(); this.waiters = []; this.timers = []; this.tickers = new Set();
    this.auto = new URLSearchParams(location.search).has('auto'); UI.auto = this.auto;
    this.bg = new THREE.Color(); this.last = performance.now(); this.running = false;
    addEventListener('resize', () => this.resize()); this.resize();
    addEventListener('keydown', e => this.key(e)); addEventListener('keyup', e => this.keys.delete(e.code));
    addEventListener('blur', () => this.keys.clear());
    canvas.addEventListener('pointerdown', e => { this.drag = { x: e.clientX, y: e.clientY }; UI.advance(); });
    addEventListener('pointerup', () => { this.drag = null; });
    addEventListener('pointermove', e => { if (this.drag && this.world.camMode === 'free') { const F = this.world.free; F.yaw -= (e.clientX - this.drag.x) * 0.006; F.pitch = clamp(F.pitch + (e.clientY - this.drag.y) * 0.005, 0.12, 1.5); this.drag = { x: e.clientX, y: e.clientY }; } });
    addEventListener('wheel', e => { if (this.world.camMode === 'free') this.world.free.dist = clamp(this.world.free.dist * (1 + Math.sign(e.deltaY) * 0.08), 8, 90); });
    requestAnimationFrame(t => this.frame(t));
  }
  resize() { const w = innerWidth, h = innerHeight; this.renderer.setSize(w, h, false); this.world.cam.aspect = w / h; this.world.cam.updateProjectionMatrix(); }

  // ---------- estado ----------
  load() { try { const s = JSON.parse(localStorage.getItem(SAVE)); if (s) this.state = Object.assign(fresh(), s); } catch (e) { } }
  save() { try { localStorage.setItem(SAVE, JSON.stringify(this.state)); } catch (e) { } }
  reset() { this.state = fresh(); this.save(); }
  frag(n) { if (this.state.frags[n]) return; this.state.frags[n] = 1; UI._lastFrag = n; this.save(); Audio.sfx('frag');
    UI.toast('frag', `Manuscrito · sección ${n} de 22 — pulsa J`, `«${FRAGMENTS[n - 1].title}»`); }
  learn(id) { if (this.state.know[id]) return; this.state.know[id] = 1; this.save(); Audio.sfx('know'); UI.toast('', 'Nuevo saber', KNOWLEDGE[id].title); if (id === 'vista') this.eye.trace = 1; }
  knows(id) { return !!this.state.know[id]; }
  rep(f, d) { this.state.rep[f] = clamp(this.state.rep[f] + d, -5, 5); this.save(); Audio.sfx(d > 0 ? 'good' : 'bad');
    UI.toast(d > 0 ? 'good' : 'bad', 'Posición social', `${{ sac: 'Sacerdocio', ciu: 'Ciudadanía', aut: 'Autoridad' }[f]} ${d > 0 ? '▲' : '▼'}`); }
  her(d) { this.state.her = clamp(this.state.her + d, -5, 5); this.save(); if (d > 0) Audio.sfx('her'); UI.toast('her', 'Tu pensamiento', d > 0 ? 'Hacia la herejía ▲' : 'Hacia la ortodoxia ▼'); }
  flag(k, v) { if (v === undefined) return this.state.flags[k]; this.state.flags[k] = v; this.save(); }

  // ---------- entrada ----------
  key(e) {
    Audio.init();
    if (e.repeat && !/Arrow|Key[WASDRF]/.test(e.code)) return;
    if (e.code === 'Tab') e.preventDefault();
    if (!this.running) return;
    if (e.code === 'KeyJ' && !UI.dlgChoosing) { UI.toggleJournal(this); this.paused = UI.journalOpen; return; }
    if (e.code === 'Escape') { if (UI.journalOpen) { UI.toggleJournal(this); this.paused = false; } else this.onMenu?.(); return; }
    if (e.code === 'KeyM') { UI.toast('', 'Sonido', Audio.toggleMute() ? 'silenciado' : 'activado'); return; }
    if (UI.journalOpen) return;
    if (/^(Digit|Numpad)[1-9]$/.test(e.code) && UI._pickKey) { UI._pickKey(+e.code.slice(-1) - 1); return; }
    if (e.code === 'Space' || e.code === 'Enter') { e.preventDefault(); if (UI.advance()) return; }
    if (e.code === 'KeyE' && !this.busy && !this.locked && this.near) { this.runHandler(this.near); return; }
    if ((e.code === 'KeyV' || e.code === 'Tab') && !this.viewLock && this.player && this.world.camMode === 'follow') { this.setView(this.view === 'top' ? 'eye' : 'top'); Audio.sfx('door'); return; }
    this.keys.add(e.code);
  }
  setView(v) { this.view = v; }
  down(...codes) { return codes.some(c => this.keys.has(c)); }

  // ---------- utilidades de guion ----------
  get player() { return this.world.ents.get('yo'); }
  setMap(map) { this.handlers.clear(); this.world.load(map); this.near = null; UI.prompt(null); }
  spawnPlayer(x, y, rot = Math.PI / 2, extra = {}) { const p = this.world.add({ id: 'yo', n: 4, r: 0.78, solid: true, x, y, rot, name: 'Tú', ...extra }); this.world.camX = x; this.world.camY = y; return p; }
  add(d) { return this.world.add(d); }
  npc(id) { return this.world.get(id); }
  on(id, label, fn) { this.handlers.set(id, { label, fn }); }
  off(id) { this.handlers.delete(id); this.world.unmark(id); }
  async runHandler(o) {
    const h = this.handlers.get(o.id); if (!h) return;
    this.busy = true; UI.prompt(null); this.keys.clear();
    if (!o.spot && this.player && !o.script) { o.frozen = true; o.rot = Math.atan2(this.player.y - o.y, this.player.x - o.x); }
    try { await h.fn(o); } finally { UI.closeDlg(); o.frozen = false; this.busy = false; }
  }
  until(fn) { return this.auto && fn.auto ? (fn.auto(), Promise.resolve()) : new Promise(res => this.waiters.push({ fn, res })); }
  wait(sec) { return this.auto ? Promise.resolve() : new Promise(res => this.timers.push({ t: sec, res })); }
  // tarea por fotograma; devuelve función para detenerla
  tick(fn) { this.tickers.add(fn); return () => this.tickers.delete(fn); }
  // animación 0→1 en `sec` segundos de tiempo de juego
  tween(sec, fn) { if (this.auto) { fn(1); return Promise.resolve(); } return new Promise(res => { let t = 0; const stop = this.tick(dt => { t += dt / sec; fn(Math.min(1, t)); if (t >= 1) { stop(); res(); } }); }); }
  objective(t, target) { UI.objective(t); if (target !== undefined) this.world.target = target; }
  async goTo(x, y, r, text) {
    this.world.addSpot({ id: '_goal', x, y }); this.world.mark('_goal'); this.objective(text, { x, y });
    if (this.auto) { this.player.x = x; this.player.y = y; }
    else await this.until(() => Math.hypot(this.player.x - x, this.player.y - y) < r);
    this.world.removeSpot('_goal'); this.objective('', null); Audio.sfx('pick');
  }
  // espera a que el jugador hable con `id` y ejecuta la escena
  async talk(id, text, fn, label = 'Hablar') {
    this.world.mark(id); this.objective(text, id);
    if (this.auto) { const o = this.world.get(id); this.player.x = o.x - 1.6; this.player.y = o.y; await fn(o); UI.closeDlg(); }
    else await new Promise(res => this.on(id, label, async o => { this.off(id); this.objective('', null); await fn(o); res(); }));
    this.off(id); this.objective('', null);
  }
  // escena guionizada: bloquea al jugador mientras dura
  async scene(fn) { this.busy = true; UI.prompt(null); this.keys.clear(); try { await fn(); } finally { UI.closeDlg(); this.busy = false; } }
  // varias conversaciones en cualquier orden: {id: {label, fn, again}}
  async all(targets, text, need) {
    const ids = Object.keys(targets); let done = 0; need = need ?? ids.length;
    this.objective(text, ids[0]);
    if (this.auto) { for (const id of ids) await targets[id].fn(this.world.get(id)); UI.closeDlg(); this.objective('', null); return; }
    await new Promise(res => {
      for (const id of ids) {
        const T = targets[id]; this.world.mark(id);
        this.on(id, T.label || 'Hablar', async o => {
          await T.fn(o); this.world.unmark(id); done++;
          if (T.again) this.on(id, T.label || 'Hablar', T.again); else this.handlers.delete(id);
          const rest = ids.filter(i => this.world.marks.has(i)); this.world.target = rest[0] || null;
          if (done >= need) { rest.forEach(i => this.world.unmark(i)); res(); }
        });
      }
    });
    this.objective('', null);
  }
  // ayuda de desarrollo: salta al objetivo actual y lo activa
  assist() {
    if (this.busy || !this.player) return; let T = this.world.target; if (typeof T === 'string') T = this.world.get(T); if (!T) return;
    const p = this.player; p.x = T.x - (T.spot || T.rad === undefined ? 0 : 1.4); p.y = T.y; if (this.world.camMode === 'free') p.alt = Math.max(p.alt, 4);
    const h = T.id && this.handlers.get(T.id); if (h) this.runHandler(T);
  }
  async teleport(x, y, rot) { const p = this.player; p.x = x; p.y = y; if (rot !== undefined) p.rot = rot; this.world.camX = x; this.world.camY = y; }

  // ---------- bucle ----------
  frame(now) {
    requestAnimationFrame(t => this.frame(t));
    const dt = Math.min(0.05, (now - this.last) / 1000); this.last = now;
    const W = this.world, p = this.player;
    if (!this.paused) {
      if (p && this.running) this.movePlayer(dt, p);
      for (const f of [...this.tickers]) f(dt);
      W.eyeT = clamp(W.eyeT + (this.view === 'eye' ? 1 : -1) * dt * 1.1, 0, 1);
      W.shift = UI.dlgOpen && innerWidth > 900 ? W.zoomCur * 0.13 : 0;
      W.update(dt, p);
      for (let i = this.timers.length - 1; i >= 0; i--) { const t = this.timers[i]; if ((t.t -= dt) <= 0) { this.timers.splice(i, 1); t.res(); } }
      for (let i = this.waiters.length - 1; i >= 0; i--) { const w = this.waiters[i]; if (w.fn()) { this.waiters.splice(i, 1); w.res(); } }
    }
    const e = W.eyeT, R = this.renderer, free = W.camMode === 'free';
    this.bg.set(W.pal.bg); if (!free) this.bg.lerp(new THREE.Color(0x03070a), e);
    R.setClearColor(this.bg, 1); R.clear();
    if (e < 0.995 || free) R.render(W.scene, W.cam);
    const strip = this.showStrip && p && !free && this.running;
    document.body.classList.toggle('free', free); document.body.classList.toggle('eye', e > 0.5); document.body.classList.toggle('noeye', !strip);
    if (p && (strip || e > 0) && !free) {
      const fx = p.local[0][0] * 0.9;
      this.eye.cast(W.segments(p), p.x + Math.cos(p.rot) * fx, p.y + Math.sin(p.rot) * fx, p.rot, W.fog);
      this.eye.layout(e, innerWidth / innerHeight, W.time, strip);
      R.render(this.eye.scene, this.eye.cam);
    }
    this.hud(p, e);
  }
  movePlayer(dt, p) {
    const W = this.world, k = this.keys, can = !this.busy && !this.locked && !UI.journalOpen;
    const ax = (this.down('KeyD', 'ArrowRight') ? 1 : 0) - (this.down('KeyA', 'ArrowLeft') ? 1 : 0);
    const ay = (this.down('KeyW', 'ArrowUp') ? 1 : 0) - (this.down('KeyS', 'ArrowDown') ? 1 : 0);
    const sp = (this.down('ShiftLeft', 'ShiftRight') ? 9 : 6) * (this.speedMul || 1);
    if (can && !p.script) {
      if (W.camMode === 'free') {
        const yaw = W.free.yaw, fx = -Math.sin(yaw), fy = Math.cos(yaw), rx = Math.cos(yaw), ry = Math.sin(yaw);
        const mx = fx * ay + rx * ax, my = fy * ay + ry * ax, l = Math.hypot(mx, my);
        if (l > 0) { p.x += mx / l * sp * 1.6 * dt; p.y += my / l * sp * 1.6 * dt; p.rot += angDiff(p.rot, Math.atan2(my, mx)) * Math.min(1, dt * 8); }
        p.alt = clamp(p.alt + ((this.down('KeyR', 'Space') ? 1 : 0) - (this.down('KeyF') ? 1 : 0)) * 9 * dt, this.altMin ?? 3, this.altMax ?? 40);
        const b = W.map.bounds; p.x = clamp(p.x, b.x0, b.x1); p.y = clamp(p.y, b.y0, b.y1);
      } else if (this.view === 'eye') {
        p.rot -= ax * 2.1 * dt;
        if (ay) { p.x += Math.cos(p.rot) * ay * sp * 0.8 * dt; p.y += Math.sin(p.rot) * ay * sp * 0.8 * dt; }
        W.collide(p);
      } else {
        const l = Math.hypot(ax, ay);
        if (l > 0) { p.x += ax / l * sp * dt; p.y += ay / l * sp * dt; p.rot += angDiff(p.rot, Math.atan2(ay, ax)) * Math.min(1, dt * 10); this.moved = (this.moved || 0) + sp * dt; }
        W.collide(p);
      }
    }
    // objeto interactuable cercano
    this.near = can ? W.nearest(p.x, p.y, 1.5, o => o !== p && this.handlers.has(o.id) && Math.abs((o.alt || 0) - p.alt) < 0.5) : null;
    UI.prompt(this.near ? `<b>E</b>${this.handlers.get(this.near.id).label}${this.near.name || this.near.label ? ' — ' + (this.near.name || this.near.label) : ''}` : null);
  }
  hud(p, e) {
    const b = document.getElementById('bearing'), h = document.getElementById('eyeHint');
    h.hidden = !(e > 0.9 && this.running && !this.busy && !this.hideEyeHint);
    let T = this.world.target; if (typeof T === 'string') T = this.world.get(T);
    if (p && T && e > 0.9) {
      const u = this.eye.bearing(p.x, p.y, p.rot, T.x, T.y);
      b.hidden = false; b.textContent = u < 0 ? '◀' : u > 1 ? '▶' : '◆'; b.style.left = clamp(u, 0.03, 0.97) * 100 + '%';
    } else b.hidden = true;
  }
}
