// Interfaz DOM: diálogos (columna al estilo novela), narrador, avisos, manuscrito, paneles.
import { Audio } from './audio.js';
import { FRAGMENTS, KNOWLEDGE } from './content/book.js';

const $ = id => document.getElementById(id);
const fmt = t => t.replace(/\*(.+?)\*/g, '<i>$1</i>');

export const SPEAKERS = {
  yo: { name: 'Tú', cls: 'you', voice: 'yo' },
  narr: { name: '', cls: 'narr', voice: 'narr' },
  logica: { name: 'Lógica', cls: 'inner', color: '#8fc7d8', voice: 'inner' },
  decoro: { name: 'Decoro', cls: 'inner', color: '#d8b48f', voice: 'inner' },
  asombro: { name: 'Asombro', cls: 'inner', color: '#b79cf0', voice: 'inner' },
  recelo: { name: 'Recelo', cls: 'inner', color: '#e08a7a', voice: 'inner' },
};

export const UI = {
  auto: false, _adv: null, busyText: false,
  advance() { if (this._adv) { const f = this._adv; this._adv = null; f(); return true; } return false; },
  waitAdvance() { return new Promise(r => { this._adv = r; }); },
  sleep(ms) { return new Promise(r => setTimeout(r, this.auto ? 0 : ms)); },

  toast(kind, small, text) {
    const d = document.createElement('div'); d.className = 'toast ' + kind; d.innerHTML = `<small>${small}</small>${text}`;
    $('toasts').appendChild(d); setTimeout(() => d.remove(), 5000);
    while ($('toasts').children.length > 4) $('toasts').firstChild.remove();
  },
  objective(t) { $('objective').textContent = t || ''; },
  chapterTag(t) { $('chapterTag').textContent = t; },
  prompt(html) { const p = $('prompt'); if (html) { if (p._h !== html) { p.innerHTML = html; p._h = html; } p.hidden = false; } else p.hidden = true; },
  async fade(on, ms = 1200) { const f = $('fade'); f.style.transitionDuration = (this.auto ? 0 : ms) + 'ms'; f.classList.toggle('on', on); await this.sleep(ms + 60); },
  async title(num, title, sub) {
    const c = $('titleCard'); c.querySelector('.tc-num').textContent = num; c.querySelector('.tc-title').textContent = title; c.querySelector('.tc-sub').textContent = sub || '';
    c.hidden = false; c.style.animation = 'none'; void c.offsetWidth; c.style.animation = '';
    Audio.sfx('bell'); await this.sleep(5200); c.hidden = true;
  },

  // tecleo de texto con voz
  async type(el, html, voice, cps = 62) {
    if (this.auto) { el.innerHTML = html; return; }
    const plain = html.replace(/<[^>]+>/g, ''); let skip = false, i = 0;
    this._adv = () => { skip = true; };
    el.innerHTML = `<span></span><span style="opacity:0">${html}</span>`;
    const a = el.firstChild, b = el.lastChild;
    while (i < plain.length && !skip) {
      i = Math.min(plain.length, i + 2);
      a.textContent = plain.slice(0, i); b.textContent = plain.slice(i);
      if (i % 6 === 0 && plain[i - 1] !== ' ') Audio.blip(voice);
      await new Promise(r => setTimeout(r, 2000 / cps * (/[.,;:!?—]/.test(plain[i - 1]) ? 3.5 : 1)));
    }
    this._adv = null; el.innerHTML = html;
  },
  // Narración del preso (bloqueante: espera a que el jugador continúe)
  async narrate(text, wide) {
    if (this.auto) return;
    const c = $('caption'); c.hidden = false; c.classList.toggle('wide', !!wide || $('dlg').hidden);
    c.innerHTML = '<span></span>';
    await this.type(c.firstChild, fmt(text), 'narr', 70);
    c.insertAdjacentHTML('beforeend', '<small>espacio ▸</small>');
    await this.waitAdvance(); Audio.sfx('ui'); c.hidden = true;
  },
  // Apunte no bloqueante
  note(text, sec = 6) {
    if (this.auto) return;
    const c = $('caption'); c.hidden = false; c.classList.add('wide'); c.innerHTML = fmt(text);
    clearTimeout(this._nt); this._nt = setTimeout(() => { if (!this._adv) c.hidden = true; }, sec * 1000);
  },

  // ---------- diálogo ----------
  cast(map) { Object.assign(SPEAKERS, map); },
  dlgOpen: false,
  openDlg() { if (!this.dlgOpen) { this.dlgOpen = true; $('dlgLog').innerHTML = ''; $('dlgChoices').innerHTML = ''; $('dlg').hidden = false; document.body.classList.add('talk'); } },
  closeDlg() { this.dlgOpen = false; $('dlg').hidden = true; document.body.classList.remove('talk'); },
  async say(who, text) {
    if (this.auto) return;
    this.openDlg();
    const sp = SPEAKERS[who] || { name: who, voice: 'yo' }, log = $('dlgLog');
    log.querySelectorAll('.ln').forEach(l => l.classList.add('old'));
    const d = document.createElement('div'); d.className = 'ln ' + (sp.cls || '');
    if (sp.color) d.style.color = sp.cls === 'inner' ? sp.color : '';
    d.innerHTML = (sp.name ? `<span class="who" style="${sp.color ? 'color:' + sp.color : ''}">${sp.name}</span>` : '') + '<span class="tx"></span>';
    log.appendChild(d); log.scrollTop = log.scrollHeight;
    await this.type(d.querySelector('.tx'), fmt(text), sp.voice);
    log.scrollTop = log.scrollHeight;
    $('dlgMore').hidden = false; await this.waitAdvance(); $('dlgMore').hidden = true; Audio.sfx('ui');
  },
  // opts: [{t, id, tag, lock}]  → devuelve id (o índice)
  async choose(opts, echo = true) {
    if (this.auto) { const i = this.autoPick ? this.autoPick(opts) : opts.findIndex(o => !o.lock); return opts[i].id ?? i; }
    this.openDlg();
    const box = $('dlgChoices'); box.innerHTML = '';
    const pick = await new Promise(res => {
      opts.forEach((o, i) => {
        const b = document.createElement('button'); b.className = 'ch' + (o.lock ? ' lock' : '');
        b.innerHTML = `<i>${i + 1}.</i>${o.tag ? `<em>[${o.tag}]</em>` : ''}${fmt(o.t)}${o.lock ? ` <em>— ${o.lock}</em>` : ''}`;
        if (!o.lock) b.onclick = () => res(i);
        box.appendChild(b);
      });
      this._pickKey = n => { if (opts[n] && !opts[n].lock) res(n); };
      $('dlgLog').scrollTop = 1e6;
    });
    this._pickKey = null; box.innerHTML = ''; Audio.sfx('pick');
    const o = opts[pick];
    if (echo && !o.silent) {
      const log = $('dlgLog'); log.querySelectorAll('.ln').forEach(l => l.classList.add('old'));
      const d = document.createElement('div'); d.className = 'ln you'; d.innerHTML = `<span class="who">Tú</span>${fmt(o.t)}`; log.appendChild(d); log.scrollTop = 1e6;
    }
    return o.id ?? pick;
  },

  // ---------- panel de minijuego ----------
  async panel(title, text, options) {
    if (this.auto) return options[0].id ?? 0;
    const p = $('panel'), inn = $('panelIn'); p.hidden = false;
    inn.innerHTML = `<h3>${title}</h3><p>${fmt(text)}</p><div class="opts"></div>`;
    const pick = await new Promise(res => {
      options.forEach((o, i) => {
        const b = document.createElement('button'); b.className = 'opt' + (o.swatch ? ' swatch' : '');
        if (o.swatch) b.style.background = o.swatch; else b.innerHTML = (o.svg || '') + o.label + (o.sub ? `<i>${o.sub}</i>` : `<i>${i + 1}</i>`);
        b.onclick = () => res(i); inn.querySelector('.opts').appendChild(b);
      });
      this._pickKey = n => { if (options[n]) res(n); };
    });
    this._pickKey = null; p.hidden = true; Audio.sfx('pick');
    return options[pick].id ?? pick;
  },
  panelInfo(title, text) { const p = $('panel'); if (!title) { p.hidden = true; return; } if (this.auto) return; p.hidden = false; $('panelIn').innerHTML = `<h3>${title}</h3><p style="margin-bottom:0">${fmt(text)}</p>`; },
  slate(show, cap = '') { $('slate').hidden = !show || this.auto; $('slateCap').textContent = cap; return $('slateCv').getContext('2d'); },

  // ---------- manuscrito ----------
  journalOpen: false,
  toggleJournal(game, tab) {
    this.journalOpen = !this.journalOpen; $('journal').hidden = !this.journalOpen;
    if (this.journalOpen) { this._game = game; this.jTab(tab || this._tab || 'ms'); Audio.sfx('ui'); }
  },
  jTab(tab) {
    this._tab = tab; const S = this._game.state, list = $('jList'), text = $('jText');
    document.querySelectorAll('.j-head [data-tab]').forEach(b => b.classList.toggle('on', b.dataset.tab === tab));
    list.innerHTML = ''; text.innerHTML = '';
    if (tab === 'ms') {
      const have = Object.keys(S.frags).length;
      const show = n => {
        const f = FRAGMENTS[n - 1]; list.querySelectorAll('.it').forEach(b => b.classList.toggle('sel', +b.dataset.n === n));
        text.innerHTML = `<div class="sec">${n <= 12 ? 'Parte I · Este mundo' : 'Parte II · Otros mundos'} — § ${n}</div><h2>${f.title}</h2>` +
          (S.frags[n] ? f.text.map(p => `<p>${fmt(p)}</p>`).join('') : `<p class="missing">Esta sección aún no ha sido escrita. ${f.hint}</p>`);
      };
      list.innerHTML = `<div style="font-style:italic;color:var(--dim);padding:0 8px 4px">${have} de 22 secciones recuperadas</div>`;
      FRAGMENTS.forEach((f, i) => {
        if (i === 0) list.insertAdjacentHTML('beforeend', '<h4>Parte I — Este mundo</h4>');
        if (i === 12) list.insertAdjacentHTML('beforeend', '<h4>Parte II — Otros mundos</h4>');
        const b = document.createElement('button'); b.className = 'it' + (S.frags[i + 1] ? '' : ' no'); b.dataset.n = i + 1;
        b.innerHTML = `<i>§${i + 1}</i>${S.frags[i + 1] ? f.title : '· · ·'}`; b.onclick = () => show(i + 1); list.appendChild(b);
      });
      show(this._lastFrag && S.frags[this._lastFrag] ? this._lastFrag : (+Object.keys(S.frags)[0] || 1));
    } else if (tab === 'know') {
      const ids = Object.keys(KNOWLEDGE);
      const show = id => { const k = KNOWLEDGE[id]; list.querySelectorAll('.it').forEach(b => b.classList.toggle('sel', b.dataset.n === id));
        text.innerHTML = S.know[id] ? `<div class="sec">Saber</div><h2>${k.title}</h2><p>${fmt(k.text)}</p>` : `<p class="missing">Aún ignoras esto.</p>`; };
      list.innerHTML = '<h4>Lo que sabes del mundo</h4>';
      ids.forEach(id => { const b = document.createElement('button'); b.className = 'it' + (S.know[id] ? '' : ' no'); b.dataset.n = id; b.innerHTML = S.know[id] ? KNOWLEDGE[id].title : '· · ·'; b.onclick = () => show(id); list.appendChild(b); });
      show(ids.find(i => S.know[i]) || ids[0]);
    } else {
      const bar = (name, v, lo, hi, desc) => `<div class="bar"><label><span>${name}</span><span>${lo} ←→ ${hi}</span></label><div class="tr"><i style="left:${50 + Math.max(-5, Math.min(5, v)) * 10}%"></i></div><small>${desc}</small></div>`;
      const d = (v, a, b, c) => v <= -2 ? a : v >= 2 ? c : b;
      list.innerHTML = `<h4>Tu figura</h4><div style="padding:0 8px;line-height:1.4">Un <b>Cuadrado</b>: cuatro lados iguales, cuatro ángulos rectos. Clase profesional. Tus hijos son Pentágonos; tus nietos, Hexágonos.<br><br><span style="color:var(--dim);font-style:italic">Mujeres (líneas) · Isósceles · Equiláteros · <b style="color:var(--bone)">Cuadrados</b> · Pentágonos · Hexágonos… · Círculos</span></div>`;
      text.innerHTML = `<div class="sec">Posición social</div><h2>Cómo te ven</h2>` +
        bar('Sacerdocio', S.rep.sac, 'sospechoso', 'devoto', d(S.rep.sac, 'Los Círculos te observan de reojo.', 'Para los Círculos eres un Cuadrado más.', 'Los Círculos te tienen por hijo fiel de la Configuración.')) +
        bar('Ciudadanía', S.rep.ciu, 'altivo', 'apreciado', d(S.rep.ciu, 'En la calle se apartan a tu paso, y no por respeto.', 'Tus vecinos te saludan con la cortesía debida.', 'Hasta los Isósceles pronuncian tu nombre con afecto.')) +
        bar('Autoridad', S.rep.aut, 'díscolo', 'fiable', d(S.rep.aut, 'El Prefecto guarda una tablilla con tu nombre.', 'La autoridad no tiene queja de ti.', 'La autoridad te considera un instrumento seguro.')) +
        bar('Tu pensamiento', S.her, 'ortodoxia', 'herejía', d(S.her, 'Crees lo que te enseñaron, y duermes bien.', 'Dudas, pero en voz baja.', 'Has empezado a preguntar lo que no se pregunta.'));
    }
  },
};
document.querySelectorAll('.j-head [data-tab]').forEach(b => b.onclick = () => UI.jTab(b.dataset.tab));
$('dlgMore').onclick = () => UI.advance();
