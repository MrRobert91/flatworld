// EL OJO: la vista desde dentro del plano. Un planilandés sólo ve una línea;
// la niebla atenúa lo lejano y así se deducen los ángulos (Reconocimiento por la Vista).
import * as THREE from 'three';

const frag = `
varying vec2 vUv; uniform sampler2D tData; uniform float uHalf,uBg,uAlpha,uTrace,uTime,uStrip; uniform vec3 uBgCol;
void main(){
  vec4 s=texture2D(tData,vec2(vUv.x,.5));
  float d=abs(vUv.y-.5)/uHalf;
  float core=1.-smoothstep(.55,1.,d);
  float glow=exp(-d*d*.11)*.34+exp(-d*.45)*.10*(1.-uStrip);
  float flick=.96+.04*sin(uTime*7.+vUv.x*40.);
  vec3 c=s.rgb*(core*1.15+glow)*flick;
  // traza: el brillo de cada punto dibujado como altura (ayuda de estudiante)
  float lum=max(s.r,max(s.g,s.b));
  float baseY=.30, ty=baseY+lum*.17;
  float tl=1.-smoothstep(.0,.0035,abs(vUv.y-ty));
  float below=step(vUv.y,.5-uHalf*1.5)*(1.-uStrip);
  c+=vec3(.90,.74,.43)*tl*uTrace*below*(.25+lum)*.9;
  float base=1.-smoothstep(0.,.002,abs(vUv.y-baseY));
  c+=vec3(.3,.4,.4)*base*uTrace*.25*(1.-uStrip);
  float vig=1.-smoothstep(.3,.5,abs(vUv.x-.5))*.55;
  float a=max(uBg,min(1.,max(c.r,max(c.g,c.b))*1.4));
  gl_FragColor=vec4(mix(uBgCol,c,min(1.,max(c.r,max(c.g,c.b))*2.))*vig+c*.3,a*uAlpha);
}`;

export class Eye {
  constructor(n = 720) {
    this.n = n; this.data = new Uint8Array(n * 4); this.hits = new Array(n).fill(null); this.dist = new Float32Array(n);
    this.tex = new THREE.DataTexture(this.data, n, 1, THREE.RGBAFormat); this.tex.magFilter = THREE.LinearFilter; this.tex.minFilter = THREE.LinearFilter;
    this.scene = new THREE.Scene(); this.cam = new THREE.OrthographicCamera(0, 1, 1, 0, -1, 1);
    this.mat = new THREE.ShaderMaterial({ transparent: true, depthTest: false, depthWrite: false,
      vertexShader: `varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.); }`, fragmentShader: frag,
      uniforms: { tData: { value: this.tex }, uHalf: { value: 0.03 }, uBg: { value: 1 }, uAlpha: { value: 1 }, uTrace: { value: 0 }, uTime: { value: 0 }, uStrip: { value: 0 }, uBgCol: { value: new THREE.Color(0x03070a) } } });
    this.quad = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), this.mat); this.scene.add(this.quad);
    this.fov = 1.75; this.trace = 0;
  }
  // traza de rayos 2D contra los segmentos del mundo
  cast(segs, ox, oy, facing, fog, ambient = 0.035) {
    const n = this.n, th = Math.tan(this.fov / 2), D = this.data;
    const cf = Math.cos(facing), sf = Math.sin(facing);
    const near = []; const maxD = fog * 5.5;
    for (const s of segs) {
      const mx = (s.ax + s.bx) / 2 - ox, my = (s.ay + s.by) / 2 - oy, hl = Math.hypot(s.bx - s.ax, s.by - s.ay) / 2;
      if (Math.hypot(mx, my) - hl > maxD) continue;
      if (mx * cf + my * sf < -hl) continue;
      near.push(s);
    }
    for (let i = 0; i < n; i++) {
      const u = 1 - 2 * i / (n - 1), lx = 1, ly = -u * th; // izquierda de la pantalla = izquierda del observador
      const l = Math.hypot(lx, ly), dx = (lx * cf - (-ly) * sf) / l, dy = (lx * sf + (-ly) * cf) / l;
      let bt = 1e9, bs = null;
      for (let k = 0; k < near.length; k++) {
        const s = near[k], ex = s.bx - s.ax, ey = s.by - s.ay, den = dx * ey - dy * ex;
        if (den > -1e-9 && den < 1e-9) continue;
        const qx = s.ax - ox, qy = s.ay - oy, t = (qx * ey - qy * ex) / den;
        if (t < 0.02 || t >= bt) continue;
        const v = (qx * dy - qy * dx) / den; if (v < 0 || v > 1) continue;
        bt = t; bs = s;
      }
      const o = i * 4;
      if (bs) { const f = Math.exp(-bt / fog) * bs.lum; D[o] = Math.min(255, (ambient * 0.5 + bs.r * f) * 255); D[o + 1] = Math.min(255, (ambient * 0.6 + bs.g * f) * 255); D[o + 2] = Math.min(255, (ambient * 0.6 + bs.b * f) * 255); this.hits[i] = bs.id; this.dist[i] = bt; }
      else { D[o] = ambient * 110; D[o + 1] = ambient * 150; D[o + 2] = ambient * 150; this.hits[i] = null; this.dist[i] = 1e9; }
      D[o + 3] = 255;
    }
    this.tex.needsUpdate = true;
  }
  // t: 0 = tira en el HUD, 1 = pantalla completa
  layout(t, aspect, time, stripVisible) {
    const u = this.mat.uniforms, e = t * t * (3 - 2 * t);
    const sw = innerWidth < innerHeight && innerWidth < 820 ? 0.7 : 0.44, w = sw + (1 - sw) * e, h = (44 / innerHeight) + (1 - 44 / innerHeight) * e;
    const cy = (1 - (14 + 22) / innerHeight) + (0.5 - (1 - 36 / innerHeight)) * e;
    this.quad.scale.set(w, h, 1); this.quad.position.set(0.5, cy, 0);
    u.uStrip.value = 1 - e; u.uHalf.value = 0.26 + (0.022 - 0.26) * e; u.uBg.value = 0.85 + 0.15 * e;
    u.uAlpha.value = stripVisible ? 1 : e; u.uTime.value = time; u.uTrace.value = this.trace;
  }
  // rumbo en pantalla (0..1) de un punto del mundo, o null si queda fuera del campo
  bearing(ox, oy, facing, x, y) {
    const a = Math.atan2(y - oy, x - ox) - facing, c = Math.cos(a), s = Math.sin(a);
    if (c <= 0.05) return s > 0 ? -1 : 2;
    const u = (s / c) / Math.tan(this.fov / 2); return 0.5 - u / 2;
  }
}
