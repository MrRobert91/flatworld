// Reparto, mapa de la ciudad y minijuegos compartidos.
import * as THREE from 'three';
import { UI } from '../ui.js';
import { Audio } from '../audio.js';
import { GAS, rad } from '../world.js';

export const say = (w, t) => UI.say(w, t);
export const choose = (o, e) => UI.choose(o, e);
export const narr = (t, w) => UI.narrate(t, w);

UI.cast({
  esposa: { name: 'Tu esposa', color: '#f0c9d2', voice: 'mujer' }, hija: { name: 'Tu hija', color: '#f0c9d2', voice: 'mujer' },
  nieto: { name: 'Tu nieto, el Hexágono', color: '#a8dcc0', voice: 'nino' }, hijo: { name: 'Tu hijo mayor, Pentágono', color: '#c9d6a0', voice: 'penta' },
  criado: { name: 'El criado, Isósceles', color: '#c8a98a', voice: 'iso' }, mayordomo: { name: 'El mayordomo', color: '#c8a98a', voice: 'tri' },
  mercader: { name: 'Comerciante Equilátero', color: '#d9c28f', voice: 'tri' }, noble: { name: 'Hexágono ocioso', color: '#a8c8e0', voice: 'hexa' },
  soldado: { name: 'Soldado Isósceles', color: '#c8a98a', voice: 'iso' }, guardia: { name: 'Sargento de la Puerta', color: '#c8a98a', voice: 'iso' },
  dama: { name: 'Una dama', color: '#f0c9d2', voice: 'mujer' }, obrera: { name: 'Mujer del obrero', color: '#f0c9d2', voice: 'mujer' },
  obrero: { name: 'Obrero Isósceles', color: '#c8a98a', voice: 'iso' }, medico: { name: 'Médico Pentágono', color: '#c9d6a0', voice: 'penta' },
  irregular: { name: 'El calderero', color: '#e0b0a0', voice: 'tri' }, inspector: { name: 'Inspector de Configuración', color: '#c9d6a0', voice: 'penta' },
  archivero: { name: 'El viejo archivero', color: '#a8c8e0', voice: 'hexa' }, estudiante: { name: 'Estudiante', color: '#a8dcc0', voice: 'nino' },
  cromatistes: { name: 'Cromatistes', color: '#ffb36b', voice: 'penta' }, pantociclo: { name: 'Pantociclo, Círculo Supremo', color: '#ffffff', voice: 'circ' },
  agitador: { name: 'El tribuno del Color', color: '#ff8f7a', voice: 'iso' }, voces: { name: 'La multitud', color: '#c8a98a', voice: 'iso' },
  circulo: { name: 'Círculo oficiante', color: '#ffffff', voice: 'circ' }, novicio: { name: 'Círculo joven', color: '#e6e6f5', voice: 'circ' },
  madre: { name: 'La madre', color: '#f0c9d2', voice: 'mujer' }, padre: { name: 'El padre Isósceles', color: '#c8a98a', voice: 'iso' },
  rey: { name: 'El Rey de Linealandia', color: '#d4c4ff', voice: 'rey' }, esfera: { name: 'El Forastero', color: '#9fe8e0', voice: 'esfera' },
  hermano: { name: 'Tu hermano', color: '#d8d0b8', voice: 'cuad' }, presidente: { name: 'El Presidente del Consejo', color: '#ffffff', voice: 'circ' },
  punto: { name: 'El Punto', color: '#ffe9a8', voice: 'punto' }, heraldo: { name: 'Heraldo', color: '#d9c28f', voice: 'tri' },
  prefecto: { name: 'El Prefecto', color: '#a8c8e0', voice: 'hexa' }, orador: { name: 'El conferenciante', color: '#c9d6a0', voice: 'penta' },
});

export const F = {
  mujer: (id, x, y, o) => ({ id, woman: true, r: 0.95, voice: 'mujer', x, y, name: 'Mujer', ...o }),
  iso: (id, x, y, deg = 14, o) => ({ id, iso: deg, r: 0.9, n: 3, voice: 'iso', x, y, name: 'Isósceles', ...o }),
  tri: (id, x, y, o) => ({ id, n: 3, r: 0.82, voice: 'tri', x, y, name: 'Equilátero', ...o }),
  cuad: (id, x, y, o) => ({ id, n: 4, r: 0.78, voice: 'cuad', x, y, name: 'Cuadrado', ...o }),
  penta: (id, x, y, o) => ({ id, n: 5, r: 0.82, voice: 'penta', x, y, name: 'Pentágono', ...o }),
  hexa: (id, x, y, o) => ({ id, n: 6, r: 0.85, voice: 'hexa', x, y, name: 'Hexágono', ...o }),
  poli: (id, x, y, n, o) => ({ id, n, r: 0.9, voice: 'hexa', x, y, name: 'Polígono', ...o }),
  circ: (id, x, y, o) => ({ id, n: 30, r: 0.95, voice: 'circ', x, y, name: 'Círculo', noEye: true, ...o }),
};

export const HOME = { x: -28, y: 17 };
export const P = { // lugares
  study: [-28, 23], salon: [-28, 12], wroom: [-34.5, 11], eroom: [-21.5, 11], wdoorIn: [-36, 13.3], wdoorOut: [-39.2, 13.3], edoorOut: [-16.6, 13.3],
  street: [-40, 1], plaza: [0, 0], gate: [-65, 0], school: [18, 15.5], schoolDoor: [18, 9], temple: [30, -20], templeDoor: [30, -8.5], palace: [-14, -22], palaceDoor: [-14, -11.4],
};
export function town(open = {}) {
  const house = (id, x, y, R, label) => ({ id, x, y, R, n: 5, rot: 90, label });
  return {
    bounds: { x0: -84, y0: -46, x1: 76, y1: 46 }, fog: 13,
    walls: [[-70, -46, -70, -3.4], [-70, 3.4, -70, 46]],
    buildings: [
      { id: 'home', x: -28, y: 17, R: 12, n: 5, rot: 90, sealed: false, label: 'Tu casa', labelDy: -8.4, labelSize: 0.8,
        doors: [{ id: 'homeW', side: 1, t: 0.55, w: 2.6, open: open.homeW !== false }, { id: 'homeE', side: 3, t: 0.45, w: 1.8, open: false }],
        inner: [[-11.18, 3, -1.3, 3], [1.3, 3, 11.18, 3], [-3.6, 3, -3.6, -2.0], [-3.6, -4.6, -3.6, -9.71], [3.6, 3, 3.6, -2.0], [3.6, -4.6, 3.6, -9.71],
          [4.8, 4.0, 6.6, 4.0], [6.6, 4.0, 6.6, 5.6], [6.6, 5.6, 4.8, 5.6], [4.8, 5.6, 4.8, 4.0]] },
      { id: 'school', x: 18, y: 20, R: 11, n: 6, rot: 0, label: 'Colegio de Vista', doors: [{ id: 'school', side: 4, t: 0.5, w: 2.8, open: !!open.school }] },
      { id: 'temple', x: 30, y: -25, R: 15, n: 24, rot: 7.5, label: 'Templo de los Círculos', labelSize: 1.3, doors: [{ id: 'temple', side: 5, t: 0.5, w: 3.2, open: !!open.temple }] },
      { id: 'palace', x: -14, y: -25, R: 13, n: 8, rot: 22.5, label: 'Palacio del Prefecto', doors: [{ id: 'palace', side: 1, t: 0.5, w: 3, open: !!open.palace }] },
      { ...house('hospital', 56, 18, 8, 'Hospital de Reconfiguración'), labelSize: 0.7 },
      { id: 'barracks', x: 60, y: -20, R: 9.5, n: 3, rot: 90, label: 'Cuartel' },
      house('h1', -56, 17, 8), house('h2', -4, 16, 7.5), house('h3', 40, 17, 7), house('h4', -58, -17, 7.5), house('h5', -41, -17, 6.5), house('h6', 7, -17, 5.5),
    ],
    labels: [{ t: 'Calle Mayor', x: 2, y: 3.6, s: 1.5, a: 0.22 }, { t: 'Puerta Oeste', x: -70, y: 6, s: 0.9, a: 0.5 }, { t: 'Norte ↑ de allí viene la lluvia', x: -28, y: 32, s: 0.75, a: 0.3, it: true },
      { t: 'camino de las aldeas', x: -78, y: -2.2, s: 0.6, a: 0.3, it: true },
      { t: 'estudio', x: -28, y: 25.4, s: 0.8, a: 0.45, it: true }, { t: 'salón', x: -28, y: 18.4, s: 0.8, a: 0.45, it: true }, { t: 'varones', x: -34.4, y: 18.6, s: 0.7, a: 0.45, it: true }, { t: 'mujeres', x: -21.6, y: 18.6, s: 0.7, a: 0.45, it: true },
      { t: 'puerta de los varones', x: -42.6, y: 15, s: 0.62, a: 0.45, it: true }, { t: 'puerta de las mujeres', x: -13.6, y: 15, s: 0.62, a: 0.45, it: true }],
  };
}

// ---------- Reconocimiento por la Vista ----------
const ico = n => { let p = ''; if (n === 2) p = '3,13 23,13'; else if (n === 1) p = '4,20 22,20 13,2 ' ; else for (let i = 0; i < n; i++) { const a = Math.PI * 2 * i / n - Math.PI / 2; p += `${13 + 10 * Math.cos(a)},${13 + 10 * Math.sin(a)} `; }
  if (n === 1) p = '11.5,22 14.5,22 13,2';
  return `<svg width="26" height="26"><polygon points="${p}" fill="none" stroke="currentColor" stroke-width="1.3"/></svg>`; };
export const CLASSES = [
  { id: 'mujer', label: 'Mujer', svg: ico(2) }, { id: 'iso', label: 'Isósceles', svg: ico(1) }, { id: 'tri', label: 'Equilátero', svg: ico(3) },
  { id: 'cuad', label: 'Cuadrado', svg: ico(4) }, { id: 'penta', label: 'Pentágono', svg: ico(5) }, { id: 'hexa', label: 'Hexágono', svg: ico(6) }, { id: 'circ', label: 'Círculo', svg: ico(24) },
];
const NAME = Object.fromEntries(CLASSES.map(c => [c.id, c.label]));

// Una figura emerge de la niebla frente al jugador. Devuelve la respuesta elegida.
export async function sightRound(g, kind, o = {}) {
  const p = g.player, W = g.world, dir = p.rot, big = { r: 1.45 };
  if (g.auto) { if (o.keep) g.add({ id: '_s', pts: [[1.5, 0], [-0.5, 1.25], [-1.0, -0.55]], x: p.x + Math.cos(dir) * 3.4, y: p.y + Math.sin(dir) * 3.4, noCollide: true }); return o.options ? (o.options[1] || o.options[0]).id : kind; }
  const mk = { mujer: () => F.mujer('_s', 0, 0, { r: 1.5 }), iso: () => F.iso('_s', 0, 0, o.deg || 12, big), tri: () => F.tri('_s', 0, 0, big), cuad: () => F.cuad('_s', 0, 0, big),
    penta: () => F.penta('_s', 0, 0, big), hexa: () => F.hexa('_s', 0, 0, big), circ: () => F.circ('_s', 0, 0, { r: 1.5 }), irr: () => ({ id: '_s', pts: [[1.5, 0], [-0.5, 1.25], [-1.0, -0.55]], voice: 'tri', name: 'Irregular' }) };
  const d = mk[kind](); d.noCollide = true; d.id = o.keep ? '_s' : '_s' + (sightRound.n = (sightRound.n || 0) + 1); const sid = d.id; if (o.colors) d.tintColors = o.colors;
  const e = g.add(d); if (o.colors) e.setColors(o.colors);
  const far = 15, near = o.near || 3.4;
  e.x = p.x + Math.cos(dir) * far; e.y = p.y + Math.sin(dir) * far; e.rot = dir + Math.PI + (o.turn || 0);
  const base = e.rot; let t = 0;
  const stop = g.tick(dt => { t += dt; if (!e.woman) e.rot = base + Math.sin(t * 0.7) * (o.wobble ?? 0.22); });
  const mv = e.moveTo(p.x + Math.cos(dir) * near, p.y + Math.sin(dir) * near, 3.2); mv.then(() => { e.rot = base; });
  if (e.woman) Audio.sfx('peace');
  const ans = await UI.panel(o.title || 'Reconocimiento por la vista', o.text || '¿Qué figura se acerca? Observa cómo se apagan sus extremos en la niebla.', o.options || CLASSES);
  stop(); e.script = null; e.rot = base;
  if (o.reveal !== false) {
    g.setView('top'); W.focus = { x: (e.x + p.x) / 2, y: (e.y + p.y) / 2 }; W.zoom = 20;
    const ok = ans === kind;
    Audio.sfx(ok ? 'good' : 'bad');
    UI.note(o.verdict ? o.verdict(ans) : (ok ? `Cierto: ${NAME[kind]}. *La lámina te lo confirma.*` : `No: era ${kind === 'mujer' ? 'una' : 'un'} ${NAME[kind]}. *Mírala desde arriba y compara con la línea.*`), 4);
    await g.wait(3.6);
    g.setView('eye'); W.focus = null; W.zoom = W.baseZoom;
  }
  if (!o.keep) { const side = dir + Math.PI / 2; e.moveTo(e.x + Math.cos(side) * 3 - Math.cos(dir) * 12, e.y + Math.sin(side) * 3 - Math.sin(dir) * 12, 6).then(() => W.remove(sid)); await g.wait(0.9); }
  return ans;
}

// ---------- Reconocimiento por el Tacto ----------
export async function feel(g, e, text) {
  if (g.auto) return true;
  const W = g.world, p = g.player;
  // vértice más cercano
  const pts = e.worldPts(); let bi = 0, bd = 1e9; pts.forEach((q, i) => { const d = Math.hypot(q[0] - p.x, q[1] - p.y); if (d < bd) { bd = d; bi = i; } });
  const n = pts.length, v = pts[bi], a = pts[(bi + n - 1) % n], b = pts[(bi + 1) % n];
  let a0 = Math.atan2(a[1] - v[1], a[0] - v[0]), a1 = Math.atan2(b[1] - v[1], b[0] - v[0]);
  let da = a1 - a0; while (da > Math.PI) da -= Math.PI * 2; while (da < -Math.PI) da += Math.PI * 2;
  const geo = new THREE.BufferGeometry(), arc = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({ color: GAS, side: THREE.DoubleSide }));
  W.fx.add(arc); W.focus = { x: v[0], y: v[1] }; W.zoom = 13;
  UI.panelInfo('Reconocimiento por el tacto', text || 'Mantén pulsada **E** para recorrer el ángulo con tu lado. *Despacio: un ángulo agudo hiere.*'.replace(/\*\*/g, ''));
  let prog = 0;
  await new Promise(res => { const stop = g.tick(dt => {
    if (g.down('KeyE')) { prog = Math.min(1, prog + dt * 0.7); if (Math.random() < 0.3) Audio.sfx('chalk'); }
    const pos = [], steps = 24, r0 = 0.34, r1 = 0.42;
    for (let i = 0; i < steps * prog; i++) { const t0 = a0 + da * i / steps, t1 = a0 + da * (i + 1) / steps;
      const q = (t, r) => [v[0] + Math.cos(t) * r, 0.05, -(v[1] + Math.sin(t) * r)];
      pos.push(...q(t0, r0), ...q(t1, r0), ...q(t1, r1), ...q(t0, r0), ...q(t1, r1), ...q(t0, r1)); }
    geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
    if (prog >= 1) { stop(); res(); }
  }); });
  const deg = Math.round(Math.abs(da) * 180 / Math.PI);
  const opts = [{ id: 'iso', label: 'Agudo, menor de 60°', sub: 'Isósceles' }, { id: 60, label: '60°', sub: 'Equilátero' }, { id: 90, label: '90°', sub: 'Cuadrado' }, { id: 108, label: '108°', sub: 'Pentágono' }, { id: 120, label: '120°', sub: 'Hexágono' }];
  const ans = await UI.panel('Has palpado el ángulo', '¿Cuánto mide la abertura que has recorrido?', opts);
  const ok = deg < 58 ? ans === 'iso' : Math.abs(ans - deg) < 4;
  W.fx.remove(arc); geo.dispose(); W.focus = null; W.zoom = W.baseZoom;
  Audio.sfx(ok ? 'good' : 'bad');
  return ok;
}

// Pizarra: anima un dibujo de tiza. draw(ctx, t 0..1)
export async function slateAnim(g, cap, sec, draw) {
  if (g.auto) return;
  const c = UI.slate(true, cap);
  await g.tween(sec, t => { c.fillStyle = '#0a1215'; c.fillRect(0, 0, 640, 420); c.strokeStyle = '#ece5d0'; c.fillStyle = '#ece5d0'; c.lineWidth = 2; c.font = "italic 22px 'Cormorant Garamond', Georgia, serif"; draw(c, t); });
}
export const slateOff = () => UI.slate(false);
