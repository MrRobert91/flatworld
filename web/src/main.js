import { Game } from './game.js';
import { UI } from './ui.js';
import { Audio } from './audio.js';
import { CHAPTERS } from './content/chapters.js';
import { F, town } from './content/common.js';

const $ = id => document.getElementById(id);
const g = new Game($('gl')); window.__game = g; window.__ui = UI;

// fondo vivo del menú: la ciudad vista desde arriba, a la deriva
function menuBackdrop() {
  g.setMap(town()); g.world.rain = 0.6; g.world.zoom = 60; g.world.zoomCur = 60;
  const kinds = [F.tri, F.cuad, F.penta, F.hexa, F.circ, F.mujer];
  for (let i = 0; i < 16; i++) g.add({ ...kinds[i % 6]('m' + i, -50 + Math.random() * 100, -4 + Math.random() * 8), ai: { type: 'wander', home: [-40 + i * 6, 0], r: 5, sx: 3 }, speed: 1.5 });
  let t = 0; g.world.focus = { x: -20, y: 4 }; g.tick(dt => { if (g.running) return; t += dt; g.world.focus = { x: -10 + Math.sin(t * 0.05) * 30, y: 6 + Math.cos(t * 0.07) * 5 }; });
}

function buildMenu() {
  const box = $('menuBtns'); box.innerHTML = '';
  const S = g.state, btn = (t, fn, parent = box) => { const b = document.createElement('button'); b.textContent = t; b.onclick = () => { Audio.init(); Audio.sfx('pick'); fn(); }; parent.appendChild(b); return b; };
  if (S.chapter > 0 || Object.keys(S.frags).length) btn(`Continuar — ${CHAPTERS[Math.min(S.chapter, CHAPTERS.length - 1)].name}`, () => start(S.chapter));
  btn('Nueva partida', () => { if (S.max > 0 && !box.dataset.sure) { box.dataset.sure = 1; event.target.textContent = '¿Borrar el manuscrito y empezar? Pulsa otra vez'; return; } g.reset(); start(0); });
  if (S.max > 0) {
    btn('Capítulos', () => { chs.hidden = !chs.hidden; });
    const chs = document.createElement('div'); chs.className = 'chs'; chs.hidden = true; box.appendChild(chs);
    CHAPTERS.forEach((c, i) => { const b = btn(c.name, () => start(i), chs); b.disabled = i > S.max; });
  }
}

async function start(i) {
  sessionStorage.setItem('pl.start', i); location.reload();
}
async function run(i) {
  $('menu').hidden = true; $('hud').hidden = false; $('fade').classList.add('on'); g.tickers.clear();
  g.running = true; if (g.state.know.vista) g.eye.trace = 1;
  g.onMenu = () => { if (confirmBack()) location.reload(); };
  for (; i < CHAPTERS.length; i++) {
    g.state.chapter = i; g.state.max = Math.max(g.state.max, i); g.save();
    g.locked = false; g.viewLock = false; g.busy = false; g.speedMul = 1; g.hideEyeHint = false;
    await CHAPTERS[i].run(g);
    g.tickers.clear(); g.handlers.clear();
  }
  g.state.chapter = 0; g.state.max = CHAPTERS.length - 1; g.save(); location.reload();
}
let backT = 0;
function confirmBack() { const now = Date.now(); if (now - backT < 2500) return true; backT = now; UI.toast('', 'Menú', 'Pulsa Esc otra vez para volver al menú. El progreso se guarda por capítulos.'); return false; }

(document.fonts?.ready || Promise.resolve()).then(() => {
  const q = new URLSearchParams(location.search), s = sessionStorage.getItem('pl.start');
  sessionStorage.removeItem('pl.start');
  if (q.has('ch')) run(+q.get('ch'));
  else if (s !== null) run(+s);
  else { menuBackdrop(); buildMenu(); Audio.drone('flat'); }
});
addEventListener('pointerdown', () => Audio.init(), { once: true });
