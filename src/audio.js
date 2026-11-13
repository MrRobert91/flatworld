// Sonido enteramente procedural (WebAudio): ambiente, voces por clase social, efectos.
let ctx = null, master = null, droneBus = null, drones = [], muted = false;

const VOICES = {
  yo: { f: 196, type: 'triangle' }, narr: { f: 110, type: 'sine' }, inner: { f: 330, type: 'sine' },
  mujer: { f: 620, type: 'sine' }, iso: { f: 130, type: 'sawtooth' }, tri: { f: 165, type: 'square' },
  cuad: { f: 185, type: 'triangle' }, penta: { f: 220, type: 'triangle' }, hexa: { f: 262, type: 'triangle' },
  nino: { f: 392, type: 'triangle' }, circ: { f: 98, type: 'sine' }, esfera: { f: 247, type: 'sine' },
  rey: { f: 147, type: 'square' }, punto: { f: 880, type: 'sine' },
};

export const Audio = {
  init() {
    if (ctx) { if (ctx.state === 'suspended') ctx.resume(); return; }
    try {
      ctx = new (window.AudioContext || window.webkitAudioContext)();
      master = ctx.createGain(); master.gain.value = muted ? 0 : 0.8; master.connect(ctx.destination);
      droneBus = ctx.createGain(); droneBus.gain.value = 0.5;
      const lp = ctx.createBiquadFilter(); lp.type = 'lowpass'; lp.frequency.value = 900;
      droneBus.connect(lp); lp.connect(master);
      if (this._pending) this.drone(this._pending);
    } catch (e) { ctx = null; }
  },
  toggleMute() { muted = !muted; if (master) master.gain.setTargetAtTime(muted ? 0 : 0.8, ctx.currentTime, 0.05); return muted; },
  tone(f, dur = 0.2, type = 'sine', vol = 0.15, slide = 0, delay = 0) {
    if (!ctx) return;
    const t = ctx.currentTime + delay, o = ctx.createOscillator(), g = ctx.createGain();
    o.type = type; o.frequency.setValueAtTime(f, t);
    if (slide) o.frequency.exponentialRampToValueAtTime(Math.max(20, f * slide), t + dur);
    g.gain.setValueAtTime(0, t); g.gain.linearRampToValueAtTime(vol, t + 0.012);
    g.gain.exponentialRampToValueAtTime(0.0008, t + dur);
    o.connect(g); g.connect(master); o.start(t); o.stop(t + dur + 0.05);
  },
  blip(voice = 'yo') {
    const v = VOICES[voice] || VOICES.yo;
    this.tone(v.f * (0.94 + Math.random() * 0.14), 0.055, v.type, v.type === 'sine' ? 0.07 : 0.035);
    if (voice === 'circ' || voice === 'esfera') this.tone(v.f * 1.5, 0.07, 'sine', 0.03);
  },
  sfx(n) {
    const T = (...a) => this.tone(...a);
    switch (n) {
      case 'ui': T(520, 0.05, 'sine', 0.06); break;
      case 'pick': T(660, 0.07, 'sine', 0.07); break;
      case 'frag': [392, 494, 587, 784].forEach((f, i) => T(f, 0.5, 'sine', 0.09, 0, i * 0.09)); break;
      case 'know': T(523, 0.25, 'triangle', 0.08); T(784, 0.4, 'triangle', 0.08, 0, 0.12); break;
      case 'good': T(440, 0.15, 'sine', 0.08); T(660, 0.25, 'sine', 0.08, 0, 0.1); break;
      case 'bad': T(196, 0.3, 'sawtooth', 0.06, 0.7); break;
      case 'her': T(311, 0.6, 'sine', 0.08); T(466, 0.8, 'sine', 0.06, 0, 0.1); T(740, 1.0, 'sine', 0.04, 0, 0.2); break;
      case 'door': T(90, 0.2, 'square', 0.06, 0.6); break;
      case 'peace': T(900, 0.09, 'sine', 0.05, 1.25); T(1150, 0.12, 'sine', 0.04, 0.85, 0.1); break;
      case 'gavel': T(70, 0.5, 'square', 0.16, 0.5); T(50, 0.9, 'sine', 0.2, 0.8); break;
      case 'sphere': [220, 277, 330, 415, 554].forEach((f, i) => T(f, 2.2, 'sine', 0.05, 0, i * 0.07)); break;
      case 'rise': T(80, 3.5, 'sine', 0.16, 9); T(120, 3.5, 'triangle', 0.07, 9, 0.1); break;
      case 'fall': T(900, 2.4, 'sine', 0.12, 0.05); break;
      case 'bell': T(880, 1.6, 'sine', 0.08); T(1320, 1.2, 'sine', 0.04); T(440, 2, 'sine', 0.05); break;
      case 'herald': [294, 294, 392].forEach((f, i) => T(f, 0.3, 'square', 0.06, 0, i * 0.22)); break;
      case 'stab': T(1400, 0.12, 'sawtooth', 0.07, 0.3); break;
      case 'chalk': T(1800 + Math.random() * 600, 0.03, 'triangle', 0.02); break;
    }
  },
  // ambiente: 'flat' | 'home' | 'dream' | 'space' | 'cell' | 'temple' | 'color' | 'none'
  drone(mode) {
    this._pending = mode;
    if (!ctx || this._mode === mode) return;
    this._mode = mode;
    const t = ctx.currentTime;
    drones.forEach(d => { d.g.gain.setTargetAtTime(0, t, 0.8); d.o.stop(t + 4); });
    drones = [];
    const sets = {
      flat: [[55, 'sine', .5], [82.4, 'sine', .28], [164.8, 'triangle', .05], [165.6, 'sine', .05]],
      home: [[65.4, 'sine', .45], [98, 'sine', .25], [196, 'sine', .06], [246.9, 'sine', .04]],
      temple: [[49, 'sine', .5], [73.4, 'sine', .35], [98, 'sine', .2], [146.8, 'sine', .1], [147.5, 'sine', .1]],
      dream: [[61.7, 'sine', .4], [92.5, 'triangle', .12], [185, 'sine', .08], [277.2, 'sine', .06], [278.4, 'sine', .05]],
      space: [[87.3, 'sine', .35], [130.8, 'sine', .25], [196, 'sine', .14], [329.6, 'sine', .1], [493.9, 'sine', .07], [495.5, 'sine', .06]],
      color: [[110, 'sine', .3], [164.8, 'triangle', .1], [277.2, 'sine', .12], [329.6, 'sine', .1], [415.3, 'sine', .07]],
      cell: [[41.2, 'sine', .6], [43.6, 'sine', .25]],
      none: [],
    };
    for (const [f, type, v] of sets[mode] || []) {
      const o = ctx.createOscillator(), g = ctx.createGain(), l = ctx.createOscillator(), lg = ctx.createGain();
      o.type = type; o.frequency.value = f; g.gain.value = 0; g.gain.setTargetAtTime(v * 0.5, t, 1.5);
      l.frequency.value = 0.05 + Math.random() * 0.12; lg.gain.value = v * 0.18; l.connect(lg); lg.connect(g.gain); l.start(t);
      o.connect(g); g.connect(droneBus); o.start(t); drones.push({ o, g });
    }
  },
};
