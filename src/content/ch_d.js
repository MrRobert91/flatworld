// Capítulos VIII–X: Espaciolandia, Puntolandia, el nieto, el juicio y la celda.
import * as THREE from 'three';
import { UI } from '../ui.js';
import { Audio } from '../audio.js';
import { GAS, lerp, ease, clamp } from '../world.js';
import { say, choose, narr, F, town, slateAnim, slateOff } from './common.js';
import { intro, outro, cell } from './ch_a.js';
import { FRAGMENTS } from './book.js';

// ---------- objetos del Espacio ----------
function makeSphere() {
  const m = new THREE.Mesh(new THREE.SphereGeometry(1.7, 56, 40), new THREE.ShaderMaterial({
    uniforms: { uTime: { value: 0 }, uAnger: { value: 0 } },
    vertexShader: `varying vec3 vN,vV; void main(){ vec4 mv=modelViewMatrix*vec4(position,1.); vN=normalize(normalMatrix*normal); vV=normalize(-mv.xyz); gl_Position=projectionMatrix*mv; }`,
    fragmentShader: `varying vec3 vN,vV; uniform float uTime,uAnger;
      void main(){ vec3 n=normalize(vN); float f=pow(1.-max(dot(n,normalize(vV)),0.),2.2);
        float d=.5+.5*dot(n,normalize(vec3(.35,.85,.4)));
        vec3 base=mix(vec3(.06,.2,.24),vec3(.7,1.,.95),d*d);
        base+=.22*cos(6.283*(f*1.4+d*.6+vec3(0.,.33,.67))+uTime*.4)*f*1.6; base+=f*.5;
        base=mix(base,vec3(.9,.2,.12)*(.3+d),uAnger);
        gl_FragColor=vec4(base,1.); }` }));
  return m;
}
function backdrop() {
  const G = new THREE.Group(), pos = [];
  for (let i = 0; i < 1400; i++) { const v = new THREE.Vector3().randomDirection().multiplyScalar(380 + Math.random() * 60); if (v.y < -60) v.y = -v.y; pos.push(v.x, v.y, v.z); }
  const sg = new THREE.BufferGeometry(); sg.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3));
  G.add(new THREE.Points(sg, new THREE.PointsMaterial({ color: 0xfff3d6, size: 1.6, sizeAttenuation: false, transparent: true, opacity: 0.8 })));
  const solids = [new THREE.IcosahedronGeometry(14), new THREE.BoxGeometry(18, 18, 18), new THREE.TetrahedronGeometry(16), new THREE.OctahedronGeometry(13), new THREE.DodecahedronGeometry(12), new THREE.ConeGeometry(10, 22, 24), new THREE.CylinderGeometry(8, 8, 20, 24)];
  G.userData.spin = [];
  solids.forEach((geo, i) => { const a = i / solids.length * 6.283 + 0.4, l = new THREE.LineSegments(new THREE.EdgesGeometry(geo), new THREE.LineBasicMaterial({ color: [0x9fe8e0, 0xe6bd6e, 0xb79cf0, 0xf0a090][i % 4], transparent: true, opacity: 0.55 }));
    l.position.set(Math.cos(a) * 170, 50 + (i % 3) * 30, Math.sin(a) * 170); G.add(l); G.userData.spin.push(l); });
  return G;
}
const shadeMat = (col = 0xece5d0) => new THREE.ShaderMaterial({ uniforms: { uC: { value: new THREE.Color(col) } }, transparent: true,
  vertexShader: `varying vec3 vN; void main(){ vN=normalize(mat3(modelMatrix)*normal); gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.); }`,
  fragmentShader: `varying vec3 vN; uniform vec3 uC; void main(){ float d=.25+.75*max(0.,dot(normalize(vN),normalize(vec3(.4,.8,.45)))); gl_FragColor=vec4(uC*d,.94); }` });

// ============ CAP. VIII — ESPACIOLANDIA ============
export async function ch8(g) {
  const map = town({ palace: true }); map.palette = 'space'; g.setMap(map);
  const W = g.world; map.buildings.forEach(b => { W.known[b.id] = true; }); W.rebuild();
  g.spawnPlayer(-27.6, 12, -Math.PI / 2); const p = g.player;
  // la casa dormida
  g.add(F.mujer('esposa', -28, 10, { ai: { type: 'wander', home: [-28, 10.5], r: 2.6 }, speed: 2.4 }));
  [[-35, 13], [-34.6, 10.6], [-33.2, 16.5], [-36, 15.6]].forEach((q, i) => g.add(F.penta('hj' + i, q[0], q[1], { rot: i })));
  g.add(F.hexa('n1', -33.6, 8.5, { r: 0.6 })); g.add(F.hexa('n2', -32.6, 9.8, { r: 0.66, rot: 1 }));
  g.add(F.mujer('hija', -22.4, 8.8, { r: 0.8, sway: 0 })); g.add(F.iso('cr1', -21, 15.5, 10)); g.add(F.tri('cr2', -21.6, 11.4, { r: 0.6 }));
  // el Consejo
  const pres = g.add(F.circ('presidente', -14, -33.5, { r: 1.5, rot: Math.PI / 2 }));
  const cons = [-22, -19, -9, -6].map((x, i) => g.add(F.circ('co' + i, x, -30 + Math.abs(x + 14) * 0.35, { rot: Math.PI / 2 })));
  cons.push(g.add(F.poli('co4', -21, -24, 14, { rot: 0 })), g.add(F.poli('co5', -7, -24, 16, { rot: Math.PI })));
  const bro = g.add(F.cuad('hermano', -10.5, -28.5, { name: 'tu hermano', rot: 2.4 }));
  const gu = [[-17, -15.5], [-11, -15.5], [-19, -18], [-9, -18]].map((q, i) => g.add(F.iso('gu' + i, q[0], q[1], 14, { rot: -Math.PI / 2 })));
  ['dama', 'obrero', 'medico'].forEach((id, i) => g.add({ ...(i === 0 ? F.mujer : i === 1 ? F.iso : F.penta)(id, -10 + i * 14, 1), ai: { type: 'wander', home: [-10 + i * 14, 0], r: 4 }, speed: 1.5 }));
  const sph = makeSphere(), bd = backdrop(); W.scene.add(sph, bd);
  let sphFree = true, time = 0;
  g.tick(dt => { time += dt; sph.material.uniforms.uTime.value = time; bd.userData.spin.forEach((s, i) => { s.rotation.x += dt * 0.07 * (1 + i % 3); s.rotation.y += dt * 0.1; });
    if (sphFree) { const y = W.free.yaw; sph.position.lerp(new THREE.Vector3(p.x + Math.cos(y) * 4.5, p.alt + 1.2 + Math.sin(time) * 0.3, -p.y + -Math.sin(y) * 4.5 - 1), Math.min(1, dt * 3)); } });
  g.showStrip = false; g.viewLock = true; W.camMode = 'free'; W.free = { yaw: 0.5, pitch: 0.42, dist: 26 }; p.alt = 0.4; p.noCollide = true; g.altMin = 0.4; g.altMax = 0.4;
  UI.chapterTag('Capítulo VIII · Espaciolandia'); Audio.drone('space');
  await narr('Un horror indecible. Oscuridad. Luego una sensación mareante de una vista que no era ver: vi una Línea que no era Línea; un Espacio que no era Espacio. Yo era yo y no lo era.', true);
  await narr('Grité: «¡Esto es la locura, o es el Infierno!»', true);
  await UI.title('Capítulo VIII', 'Espaciolandia', '«Ni lo uno ni lo otro. Es el Conocimiento; son las Tres Dimensiones. Abre el ojo de nuevo y procura mirar con firmeza.»');
  W.showGuts = true; for (const e of W.ents.values()) e.guts.visible = true;
  UI.fade(false, 3000);
  await g.tween(6, t => { const k = ease(t); p.alt = 0.4 + k * 13; W.free.pitch = 0.42 + k * 0.5; W.free.dist = 26 + k * 12; W.free.yaw = 0.5 + k * 0.9; });
  g.altMin = 4; g.altMax = 20;
  await g.scene(async () => {
    await say('esfera', 'Mira. No con el borde de tu ojo: con todo él. Lo que hay debajo de ti es tu mundo. Entero.');
    await say('asombro', 'Tu casa. No su raya: *su forma*. Los cinco lados a la vez. Y dentro de ella, sin pared que lo impida, todo.');
    await say('narr', 'Y vi a la Esfera. No una rebanada: él. Lo que yo había tomado por un Círculo era una cosa con un *dentro* que no se veía y un *fuera* por todas partes. Era hermoso de un modo para el que aún no tengo palabra.');
  });
  UI.note('**Arrastra el ratón** para mirar alrededor · **WASD** para volar · **R / F** para subir y bajar · rueda: acercar'.replace(/\*\*/g, ''), 14);
  await g.goTo(-28, 17, 6, 'Vuela sobre tu casa y mírala por dentro');
  await g.scene(async () => {
    await say('yo', 'Mis hijos, dormidos en sus cuartos del Oeste. Mis dos nietos. Mi hija. Los criados. Y… veo dentro de *ellos*. Sus entrañas. Les late algo.');
    await say('esfera', 'Desde Arriba no hay dentro que se esconda. Así vi yo tu alacena. Así te toqué el estómago.');
    await say('yo', 'Y mi esposa. Recorre el salón de punta a punta. Me busca.');
    await say('logica', 'Para ella has desaparecido sin cruzar ninguna puerta. Como el Forastero. Como tú ante el Rey de la Línea.');
    await say('esfera', 'Ven. Hay algo que debes oír. Es la primera hora del primer día del año 2000, y el Alto Consejo de tu país está reunido, como lo estuvo hace mil años, y hace dos mil.');
  });
  await g.goTo(-14, -24, 6.5, 'Vuela hacia el sur: la Sala del Consejo, en el Palacio');
  await g.scene(async () => {
    g.tween(2.5, t => { p.x = lerp(p.x, -14, t * 0.2); p.y = lerp(p.y, -20, t * 0.2); p.alt = lerp(p.alt, 11, t * 0.2); W.free.dist = lerp(W.free.dist, 30, t * 0.2); });
    await say('yo', '¡Mi hermano! Es el Escribano Mayor del Consejo. Está leyendo.');
    await say('hermano', '«…considerando que cada milenio han turbado a los Estados gentes mal intencionadas que pretenden haber recibido revelaciones de Otro Mundo…»');
    await say('hermano', '«…se resuelve: que en el primer día de cada milenio los Prefectos busquen a tales extraviados; que se destruya sin examen al que sea Isósceles; se azote y encarcele al Equilátero; se envíe al Manicomio al Cuadrado o Pentágono; y se arreste a cualquiera de rango superior.»');
    await say('esfera', 'Ya oyes tu destino. Y, sin embargo, voy a decírselo a ellos también. Mira cómo me ven.');
    sphFree = false; Audio.sfx('sphere');
    const sec = g.add(F.circ('secc', -14, -25.5, { r: 1.7, tint: 0x9fe8e0, noGuts: true, noCollide: true })); sec.scale = 0.001;
    const from = sph.position.clone();
    await g.tween(3.2, t => { const k = ease(t); sph.position.set(lerp(from.x, -14, k), lerp(from.y, 0, k), lerp(from.z, 25.5, k)); const h = sph.position.y; sec.scale = Math.abs(h) < 1.7 ? Math.max(0.001, Math.sqrt(1 - (h / 1.7) ** 2)) : 0.001; });
    await say('esfera', '¡Consejeros de Planilandia! Vengo a proclamar que existe una tierra de Tres Dimensiones.');
    cons.forEach(c => c.moveTo(c.x + (c.x + 14) * 0.25, c.y + (c.y + 25.5) * 0.2, 4));
    await say('narr', 'Desde arriba vi lo que ellos veían: un Círculo surgido de la nada en mitad de la sala. Los consejeros jóvenes retrocedieron. El Presidente no se movió.');
    await say('presidente', 'Guardias.');
    gu.forEach((s, i) => s.moveTo(-14 + Math.cos(i * 1.57) * 2.2, -25.5 + Math.sin(i * 1.57) * 2.2, 9)); Audio.sfx('herald');
    await g.tween(1.6, t => { const k = ease(t); sph.position.y = k * 9; const h = sph.position.y; sec.scale = h < 1.7 ? Math.max(0.001, Math.sqrt(1 - (h / 1.7) ** 2)) : 0.001; });
    W.remove('secc'); sphFree = true;
    await say('presidente', 'Ha vuelto a ocurrir, como en el año mil y en el año cero. No ha ocurrido nada. Los guardias que lo han visto serán destruidos. El Escribano, que también lo ha visto, y cuyo rango impide destruirlo: prisión perpetua.');
    Audio.sfx('gavel'); gu.forEach((s, i) => setTimeout(() => { s.hidden = true; }, g.auto ? 0 : 400 + i * 300));
    const esc = [g.add(F.iso('e1', -14, -13, 3, { rot: -1.57 })), g.add(F.iso('e2', -13, -13, 3, { rot: -1.57 }))];
    esc.forEach((s, i) => s.moveTo(bro.x + (i ? 1.6 : -1.6), bro.y + 0.5, 8));
    await say('hermano', 'Excelencia… yo sólo leía el acta.');
    const c = await choose([{ t: '¡Hermano! ¡Déjame bajar, Esfera! Yo se lo explicaré al Consejo.', id: 'a' }, { t: '(Mirar. Como miraste en la Puerta.)', id: 'b' }]);
    if (c === 'a') await say('esfera', 'No. Nada que digas hoy lo salvaría, y a ti te perdería. Tu misión no es morir en esa sala.');
    else await say('recelo', 'Esta vez no hay sargento que apunte tu silencio. Sólo tú.');
    bro.moveTo(-14, -13.5, 2.5).then(() => { bro.hidden = true; }); esc.forEach((s, i) => { s.ai = { type: 'follow', target: 'hermano', dist: 1.6, speed: 3 }; });
    await say('narr', 'Mi hermano. El mejor de los Cuadrados: justo, sensato, alegre. Condenado por haber visto.');
    g.frag(18);
    await say('esfera', 'Sube conmigo. Más alto. Te enseñaré de qué estás hecho, y de qué estoy hecho yo.');
  });
  g.altMax = 44; g.objective('Asciende (mantén R) hasta dejar la ciudad muy abajo', null);
  await g.until(Object.assign(() => p.alt > 32, { auto() { p.alt = 34; } }));
  g.objective('', null); g.altMin = 30;
  // --- los Sólidos ---
  const cube = new THREE.Mesh(new THREE.BoxGeometry(1, 1, 1), shadeMat()), edges = new THREE.LineSegments(new THREE.EdgesGeometry(new THREE.BoxGeometry(1, 1, 1)), new THREE.LineBasicMaterial({ color: GAS }));
  cube.add(edges); W.scene.add(cube); const L = 4; cube.scale.set(0.08, 0.08, 0.08);
  await g.scene(async () => {
    cube.position.set(p.x, p.alt + 0.5, -p.y - 9); W.free.yaw = 0.35; W.free.pitch = 0.35; W.free.dist = 24;
    await say('esfera', 'Aquí tienes un Punto.');
    await g.tween(2, t => cube.scale.set(lerp(0.08, L, ease(t)), 0.08, 0.08)); Audio.sfx('know');
    await say('esfera', 'Lo muevo: una Línea. Dos puntos terminales.');
    await g.tween(2, t => cube.scale.set(L, 0.08, lerp(0.08, L, ease(t)))); Audio.sfx('know');
    await say('esfera', 'La muevo paralela a sí misma: un Cuadrado. Cuatro puntos terminales. Eres tú.');
    await say('esfera', 'Y ahora lo muevo en la dirección que tu nieto intuyó y tú mandaste a la cama. Hacia Arriba.');
    Audio.sfx('sphere'); await g.tween(3, t => { cube.scale.set(L, lerp(0.08, L, ease(t)), L); cube.position.y = p.alt + 0.5 + L / 2 * ease(t); });
    await say('yo', 'Ocho puntos terminales. Seis lados, y cada uno es… un Cuadrado. Tres pulgadas en todos los sentidos. *Tres al cubo.*');
    const sp = g.tick(dt => { cube.rotation.y += dt * 0.5; cube.rotation.x += dt * 0.23; });
    await say('logica', 'Fíjate en cómo lo ves: unas caras más claras, otras más oscuras. Luz y sombra. Así se ve la profundidad desde fuera, igual que tú leías los ángulos en la niebla.');
    g.learn('solidos'); g.learn('altura');
    await say('narr', 'Lo adoré. No hay otra palabra. Le llamé Maestro, y lo era.');
    // --- la Cuarta ---
    await say('yo', 'Maestro: me habéis mostrado las entrañas de mis compatriotas desde la tierra de Tres Dimensiones. Llevadme ahora a la de Cuatro.');
    await say('esfera', '¿Qué dices?');
    let c = await choose([{ t: 'Desde allí miraríamos este Espacio y veríamos el interior de todo Sólido. Vuestras propias entrañas.', id: 'a' }, { t: '(Callar. Has visto bastante.)', id: 's' }]);
    if (c === 's') await say('narr', 'Pude callar. Había visto más que nadie en mil años. No callé: un Cuadrado que ha contado hasta tres quiere contar hasta cuatro.');
    await say('esfera', 'No existe tal tierra. La sola idea es inconcebible.');
    sph.material.uniforms.uAnger.value = 0.2;
    // teseracto imaginado
    const tg = new THREE.BufferGeometry(), tess = new THREE.LineSegments(tg, new THREE.LineBasicMaterial({ color: 0xb79cf0 })); W.scene.add(tess);
    const V = []; for (let i = 0; i < 16; i++) V.push([i & 1 ? 1 : -1, i & 2 ? 1 : -1, i & 4 ? 1 : -1, i & 8 ? 1 : -1]);
    const E = []; for (let i = 0; i < 16; i++) for (let b = 0; b < 4; b++) if (!(i & (1 << b))) E.push([i, i | (1 << b)]);
    let ta = 0, tsc = 0.01; const cpos = cube.position.clone();
    const st = g.tick(dt => { ta += dt * 0.6; const pos = [], ca = Math.cos(ta), sa = Math.sin(ta), cb = Math.cos(ta * 0.6), sb = Math.sin(ta * 0.6);
      const pr = v => { let [x, y, z, w] = v; [x, w] = [x * ca - w * sa, x * sa + w * ca]; [y, z] = [y * cb - z * sb, y * sb + z * cb]; const k = 2.6 / (3.2 - w) * tsc; return [cpos.x + x * k * 2.6, cpos.y + y * k * 2.6, cpos.z + z * k * 2.6]; };
      E.forEach(e => pos.push(...pr(V[e[0]]), ...pr(V[e[1]]))); tg.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); });
    await say('yo', 'Vuestra propia Analogía, Maestro. Punto, Línea, Cuadrado, Cubo: uno, dos, cuatro, ocho puntos terminales. ¿Qué sigue?');
    c = await choose([{ t: 'Dieciséis.', id: 16 }, { t: 'Diez.', id: 10 }, { t: 'Doce.', id: 12 }]);
    Audio.sfx('her'); g.tween(4, t => { tsc = ease(t); cube.material.uniforms.uC.value.setScalar(1 - t * 0.6); cube.scale.setScalar(L * (1 - 0.45 * ease(t))); });
    await say('yo', c === 16 ? 'Dieciséis. Y sus límites: dos Puntos, cuatro Líneas, seis Cuadrados… *ocho Cubos*. Un Cubo movido en una dirección nueva. ¡Casi lo veo!' : 'No… el doble cada vez: *dieciséis*. Y sus límites: dos Puntos, cuatro Líneas, seis Cuadrados… ocho Cubos. ¡Casi lo veo!');
    g.learn('cuarta');
    await say('asombro', 'Eso que gira ahí no está en el Espacio. Está en ti. Es la sombra de una sombra, y es lo más grande que has pensado nunca.');
    sph.material.uniforms.uAnger.value = 0.45;
    await say('esfera', 'Basta. Son fantasías. Analogías sin objeto.');
    c = await choose([{ t: '¿No es cierto que en vuestro país se han visto Seres entrar en cuartos cerrados, como vos en el mío?', id: 'a' }, { t: '(Ceder.) Perdonad, Maestro.', id: 's' }]);
    if (c === 's') await say('narr', 'No cedí. Tú has elegido la prudencia dos veces y yo te he desmentido dos veces: así fue. No sabía parar.');
    await say('esfera', '…Se cuenta. Visiones. Cosas del cerebro de quien las ve. Nadie las cree.');
    await say('logica', '«Un truco de mago.» «Visiones del cerebro.» El Rey, tú, la Esfera. Cada mundo tiene su frase para lo que le queda por encima.');
    sph.material.uniforms.uAnger.value = 0.75; g.her(1);
    await say('yo', '¡Entonces existe! ¡Y más allá, la Quinta, la Sexta, la Séptima Dimensión! ¡Llevadme! ¡Hacia Arriba de Arriba!');
    sph.material.uniforms.uAnger.value = 1; Audio.sfx('gavel');
    await say('esfera', '¡SILENCIO!');
    g.frag(19); UI.closeDlg(); st(); sp(); W.scene.remove(tess); W.scene.remove(cube);
    Audio.sfx('fall'); g.altMin = 0; UI.fade(true, 2300);
    await g.tween(2.4, t => { p.alt = lerp(34, 0.2, t * t); p.rot += 0.3; W.free.pitch = lerp(0.35, 1.2, t); });
  });
  W.scene.remove(sph, bd); W.camMode = 'follow'; g.showStrip = true; g.viewLock = false; W.showGuts = false; W.known = { home: true, school: W.known.school, temple: true };
  await narr('Un estrépito. Y me hallé de nuevo en mi estudio, en el Plano, oyendo acercarse el Grito de Paz de mi esposa.', true);
}

// ============ CAP. IX — PUNTOLANDIA Y EL NIETO ============
export async function ch9(g) {
  // --- visión: Puntolandia ---
  g.setMap({ bounds: { x0: -40, y0: -40, x1: 40, y1: 40 }, palette: 'cell', fog: 10 });
  const W = g.world; g.spawnPlayer(8, -8, 2.3); const p = g.player; W.ground.visible = false;
  const cv = document.createElement('canvas'); cv.width = cv.height = 128; const c2 = cv.getContext('2d'), gr = c2.createRadialGradient(64, 64, 0, 64, 64, 64);
  gr.addColorStop(0, '#fff'); gr.addColorStop(0.12, '#ffe9a8'); gr.addColorStop(0.4, 'rgba(255,220,130,.18)'); gr.addColorStop(1, 'rgba(255,220,130,0)'); c2.fillStyle = gr; c2.fillRect(0, 0, 128, 128);
  const pt = new THREE.Sprite(new THREE.SpriteMaterial({ map: new THREE.CanvasTexture(cv), blending: THREE.AdditiveBlending, depthWrite: false })); pt.scale.setScalar(1.6); W.scene.add(pt);
  const sph = makeSphere(); W.scene.add(sph); let time = 0, hum = 0;
  g.tick(dt => { time += dt; sph.material.uniforms.uTime.value = time; sph.position.lerp(new THREE.Vector3(p.x + 3.5, p.alt + 1, -p.y - 3), Math.min(1, dt * 3)); pt.scale.setScalar(1.5 + 0.25 * Math.sin(time * 6));
    hum -= dt; if (hum < 0) { hum = 1.4; const d = Math.hypot(p.x, p.y, p.alt); if (d < 22) Audio.tone(880, 0.5, 'sine', 0.05 * (1 - d / 22)); } });
  g.showStrip = false; g.viewLock = true; W.camMode = 'free'; W.free = { yaw: 0.8, pitch: 0.3, dist: 16 }; p.alt = 5; p.noCollide = true; g.altMin = 1; g.altMax = 14;
  UI.chapterTag('Capítulo IX · Hacia Arriba, no hacia el Norte'); Audio.drone('dream');
  await UI.title('Capítulo IX', 'Hacia Arriba, no hacia el Norte', 'Donde se visita el reino más pequeño y más feliz, y se pierde a un discípulo.');
  await UI.fade(false);
  await narr('Aquella noche soñé. La Esfera estaba otra vez a mi lado, y su brillo ya no mostraba enojo. «Te he tratado con dureza», dijo. «Ven: te debo una última lección.»', true);
  await g.goTo(0, 0, 4.5, 'Acércate a esa luz diminuta');
  await g.scene(async () => {
    await say('esfera', 'Contempla Puntolandia: el Abismo de Ninguna Dimensión. Esa criatura es un Ser como nosotros, pero no conoce largo, ni ancho, ni alto. No conoce siquiera el número Dos. Él es su Mundo, su Universo. Escúchalo.');
    await say('punto', '¡Infinita beatitud de la existencia! Ello es; y nada hay fuera de Ello.');
    await say('punto', 'Ello llena todo el Espacio, y lo que llena, lo es. Lo que piensa, lo dice; lo que dice, lo oye; Ello es Pensador, Palabra y Oyente; el Uno, y sin embargo el Todo en Todo. ¡Ah, la dicha de Ser!');
    for (let n = 0; n < 2; n++) {
      const c = await choose([{ t: '¡Calla, criatura! No eres el Todo: eres la Nada. Un punto.', id: 'a' }, { t: 'Escucha: hay otros. Hay líneas, planos, sólidos. Yo vengo de fuera de ti.', id: 'b' }, { t: 'Hola. ¿Me oyes?', id: 'c' }].slice(n ? 1 : 0, n ? 3 : 2));
      if (c === 'a') await say('punto', '¡Ah, el gozo, el gozo del Pensamiento! ¿Qué no alcanzará Ello pensando? Su propio Pensamiento viene a Ello sugiriéndole su menosprecio, para realzar con ello su dicha. ¡Dulce rebelión que acaba en triunfo!');
      if (c === 'b') await say('punto', '«Otros.» «Fuera.» ¡Qué fecunda es la mente de Ello, que inventa palabras sin objeto para deleitarse en su propia unidad! ¡Ah, el poder creador del Todo en Uno!');
      if (c === 'c') await say('punto', '«¿Me oyes?», se pregunta Ello a sí mismo, pues no hay otro a quien preguntar. Y se responde: sí. ¡Ah, la dicha de la conversación perfecta!');
    }
    await say('esfera', 'Ya ves lo poco que logran tus palabras. Todo lo que oye, cree haberlo pensado él. Nada que tú o yo hagamos lo sacará de su contento.');
    await say('esfera', 'Aprende esto: estar satisfecho de uno mismo es ser vil e ignorante. Aspirar es mejor que ser ciega e impotentemente feliz.');
    const c = await choose([{ t: 'El Punto, el Rey de la Línea… ¿y yo, ante vos? ¿Y vos, ante la Cuarta?', id: 'h', tag: 'Atreverse' }, { t: 'Lo he comprendido, Maestro.', id: 'o' }]);
    if (c === 'h') { await say('esfera', '…Vuelve a tu mundo. Enseña lo que has visto. Y sí: quizá por eso te elegí a ti y no a un Círculo.'); g.her(1); }
    else await say('esfera', 'Vuelve a tu mundo. Enseña lo que has visto. No esperes que te lo agradezcan.');
    g.frag(20); g.learn('punto');
  });
  await outro(g); W.scene.remove(pt, sph); W.ground.visible = true; W.camMode = 'follow';

  // --- despertar ---
  g.setMap(town()); g.spawnPlayer(-28, 22.5, -Math.PI / 2); g.showStrip = true; g.viewLock = false; W.rain = 0.2;
  const wife = g.add(F.mujer('esposa', -26, 12, { name: 'tu esposa', rot: 2 }));
  const kid = g.add(F.hexa('nieto', -34.3, 11.6, { name: 'tu nieto menor', r: 0.6 }));
  g.add(F.penta('hijo', -33, 13.5, { name: 'tu hijo mayor', rot: -1 }));
  const her = g.add(F.tri('heraldo', -60, 1.5, { name: 'un heraldo', ai: { type: 'path', pts: [[-20, 1.5], [-60, 1.5]] }, speed: 2.5 }));
  UI.chapterTag('Capítulo IX · Hacia Arriba, no hacia el Norte'); Audio.drone('home'); await UI.fade(false);
  await narr('Desperté gozoso. Iba a evangelizar a toda Planilandia, de las mujeres a los Círculos. Empezaría por mi esposa.');
  await g.scene(async () => {
    Audio.sfx('herald');
    await say('heraldo', '(En la calle.) ¡Oíd, oíd! ¡Resolución del Alto Consejo! Todo aquel que pervierta las mentes del pueblo con delirios, pretendiendo revelaciones de Otro Mundo, será arrestado, encarcelado o ejecutado, según su número de lados.');
    await say('recelo', 'Lo oíste leer anoche, desde arriba, de boca de tu hermano. Ahora suena distinto: suena desde tu altura.');
  });
  g.on('hijo', 'Hablar', async () => {
    await say('hijo', 'Buenos días, padre. ¿Ha oído el pregón? Ya era hora. La semana pasada un Triángulo decía en mi consulta que oía voces de «fuera». Lo denuncié, naturalmente.');
    await say('narr', 'Mis hijos. Pentágonos de carácter y posición. Me habrían entregado al Prefecto con lágrimas sinceras.');
  });
  await g.talk('esposa', 'Habla con tu esposa', async () => {
    await say('esposa', '¡Esposo! Anoche desapareciste. Te busqué por toda la casa. ¿Dónde estabas?');
    const c = await choose([{ t: 'Fuera del Plano, querida. Arriba. He visto nuestra casa por dentro, toda a la vez.', id: 'h', tag: 'La verdad' }, { t: 'Me caí por la trampilla del sótano y quedé sin sentido.', id: 'o', tag: 'La mentira' }]);
    if (c === 'h') { await say('narr', 'Estuve a un grano de arena de decírselo. El heraldo volvió a pasar bajo el muro. Dije: «Me caí por la trampilla del sótano».'); g.her(1); }
    await say('esposa', 'Pero, esposo… nuestra casa no tiene sótano.');
    await say('esposa', 'Tienes fiebre. Acuéstate. Y no hables así delante de los chicos.');
    await say('logica', 'Ella no sabe leer ni contar. La ley se ocupó de eso. Tus hijos sí saben, y no preguntan. Te queda uno: el que preguntó por 3³.');
  });
  const mov = g.add(F.cuad('movil', -33.4, 9.6, { name: 'un cuadrado móvil', r: 0.42, noEye: true, noGuts: true }));
  await g.talk('nieto', 'Enséñale a tu nieto lo que has visto', async () => {
    await say('yo', 'Ven, pequeño. Cierra la puerta. ¿Recuerdas lo que dijiste de 3³? Tenías razón. Mira este cuadrado. Vamos a moverlo, no hacia el Norte, sino hacia Arriba.');
    UI.closeDlg();
    UI.panelInfo('La lección', 'Mueve el cuadrado **hacia Arriba**. *(WASD / flechas)*'.replace(/\*\*/g, ''));
    const tried = new Set(); let tm = 0, said = 0;
    if (!g.auto) await new Promise(res => { const stop = g.tick(dt => {
      tm += dt; const k = [['KeyW', 'ArrowUp', 0, 1, 'Eso es el Norte.'], ['KeyS', 'ArrowDown', 0, -1, 'Eso es el Sur.'], ['KeyD', 'ArrowRight', 1, 0, 'Eso es el Este.'], ['KeyA', 'ArrowLeft', -1, 0, 'Eso es el Oeste.']];
      for (const [a, b, dx, dy, msg] of k) if (g.down(a, b)) { mov.x = clamp(mov.x + dx * 3 * dt, -34.6, -32.3); mov.y = clamp(mov.y + dy * 3 * dt, 8, 11.5); if (!tried.has(a)) { tried.add(a); UI.note(`*Tu nieto:* «${msg}»`, 3); Audio.blip('nino'); } }
      if (g.down('KeyR', 'KeyF', 'Space', 'KeyE') && tm - said > 2) { said = tm; UI.note('*No ocurre nada. No hay tecla para lo que quieres decir.*', 3); Audio.sfx('bad'); }
      if (tried.size >= 3 || tm > 16) { stop(); res(); } }); });
    UI.panelInfo(null); await g.wait(1.2);
    Audio.sfx('herald');
    await say('heraldo', '(En la calle, otra vez.) …¡arrestado, encarcelado o ejecutado!');
    await say('nieto', 'Abuelito… lo de 3³ era sólo una broma. Claro que no quería decir nada. Y entonces no sabíamos nada de la Ley nueva. Y yo no dije nada de la Tercera Dimensión.');
    await say('nieto', 'Y seguro que no dije ni una palabra de «hacia Arriba, no hacia el Norte», porque sería una tontería. ¿Cómo va a moverse una cosa hacia Arriba y no hacia el Norte? Ni un bebé sería tan bobo. ¡Ja, ja, ja!');
    const c = await choose([{ t: '¡No es ninguna bobada! Mira: lo muevo… no así, sino… ¡de algún modo!', id: 'a' }, { t: '(Soltar el cuadrado.) Tienes razón. Era una broma.', id: 's' }]);
    if (c === 'a') { await g.tween(1.5, t => { mov.x = -33.4 + Math.sin(t * 30) * 0.5; mov.y = 9.6 + Math.cos(t * 23) * 0.5; mov.rot += 0.3; }); await say('narr', 'Agité aquel cuadrado como un loco, sin propósito alguno. El niño se reía cada vez más alto, para que se oyera desde la calle.'); }
    else await say('narr', 'No lo solté. Lo agité como un loco, sin propósito alguno, mientras el niño se reía cada vez más alto, para que se oyera desde la calle.');
    await say('nieto', '¡El abuelo no me está enseñando, está jugando conmigo!');
    kid.moveTo(-36.8, 12.8, 6).then(() => kid.moveTo(-44, 13, 6)).then(() => { kid.hidden = true; });
    await say('narr', 'Abrió la puerta y huyó. Diez años, y ya sabía lo que yo iba a tardar un año entero en olvidar: cuándo conviene reírse.');
    g.frag(21);
  });
  await outro(g);
}

// ============ CAP. X — EL JUICIO ============
export async function ch10(g) {
  g.setMap(town({ palace: true })); const W = g.world; W.reveal('palace'); g.spawnPlayer(-14, -6, -Math.PI / 2);
  const pref = g.add(F.poli('prefecto', -14, -33, 12, { name: 'el Prefecto', r: 1.2, rot: Math.PI / 2 }));
  const ora = g.add(F.penta('orador', -14, -29, { name: 'el conferenciante', rot: Math.PI / 2 }));
  const aud = [[-19, -23], [-16.5, -22], [-11.5, -22], [-9, -23], [-20, -26.5], [-8, -26.5]].map((q, i) => g.add((i % 2 ? F.hexa : F.penta)('au' + i, q[0], q[1], { rot: -Math.PI / 2 })));
  await intro(g, 'Capítulo X', 'El juicio', 'Donde se pregunta a un Cuadrado hacia dónde cae Arriba.', 'flat');
  await narr('Callé once meses. Escribí en secreto un tratado, «De Planilandia a Pensamientolandia», fingiendo hablar de una tierra imaginaria. No pude dibujar un solo diagrama: en mi mundo no hay tablillas, sólo líneas.');
  await narr('Lo peor era mirar. Veía una raya y sabía que era un Cuadrado; veía mi casa y recordaba sus cinco lados a la vez. Cerraba el ojo para volver a ver el Cubo, y cada noche lo veía un poco peor.');
  await narr('Y un día acudí a una sesión de la Sociedad Especulativa local, en el palacio del Prefecto.');
  await g.goTo(-14, -22, 1.6, 'Entra en el Palacio y toma asiento en la Sociedad Especulativa');
  await g.scene(async () => {
    g.player.rot = -Math.PI / 2; W.focus = { x: -14, y: -26 }; W.zoom = 40;
    await say('orador', '…y queda así demostrado, señores, por qué la Providencia ha limitado a Dos el número de las Dimensiones, y por qué el atributo de verlo todo, la omnividencia, pertenece sólo al Ser Supremo.');
    let c = await choose([{ t: '(Callar.)', id: 's' }, { t: '(Carraspear.)', id: 'a' }]);
    await say('orador', 'Pues ¿quién de nosotros podría ver el interior de una casa cerrada? ¿Quién, el interior de su prójimo? Sería tanto como ver *desde ningún sitio*.');
    await say('asombro', 'Tú. Tú lo has visto. Tu casa. Tus hijos. Sus entrañas latiendo.');
    c = await choose([{ t: '(Callar.)', id: 's' }, { t: '(Callar, con más esfuerzo.)', id: 's2' }]);
    await say('orador', 'Una tercera dirección es, por tanto, no ya falsa: es *impensable*. Ninguna mente sana ha podido jamás concebirla.');
    await say('narr', 'Aquí puedes elegir lo que quieras. Te aviso de que no servirá.');
    c = await choose([{ t: '(Callar.)', id: 's' }, { t: 'Supongamos, como fábula, que alguien la hubiera visto…', id: 'a' }, { t: '(Marcharte.)', id: 'm' }]);
    if (c !== 'a') await say('narr', c === 's' ? 'Callé, sí. Unos tres granos de arena. Luego me oí decir: «Supongamos, como fábula, que alguien la hubiera visto…».' : 'Llegué hasta la puerta. Con el perímetro ya en el umbral me oí decir: «Supongamos, como fábula, que alguien la hubiera visto…».');
    await say('yo', 'Un personaje ficticio, digamos. Una noche lo arrancan del Plano. Ve su ciudad por dentro. Ve el Consejo. Ve una Figura hecha de Círculos…');
    await say('yo', '…y no era ficticio. ¡Era yo! ¡Lo vi! Existe la Tercera Dimensión: ¡hacia Arriba, no hacia el Norte! ¡Sacudíos el prejuicio y creed!');
    await say('prefecto', 'Guardias. Al Consejo.');
    Audio.sfx('gavel'); g.her(1);
    await say('narr', 'Me olvidé de mí mismo. Es la expresión exacta: por una vez me olvidé del Cuadrado prudente que firmaba, aplaudía y callaba.');
  });
  await outro(g);

  // --- el Consejo ---
  [ora, pref, ...aud].forEach(e => W.remove(e.id)); g.teleport(-14, -24.5, -Math.PI / 2);
  const pres = g.add(F.circ('presidente', -14, -33.5, { name: 'el Presidente', r: 1.5, rot: Math.PI / 2 }));
  [-22, -19, -9, -6].forEach((x, i) => g.add(F.circ('co' + i, x, -30 + Math.abs(x + 14) * 0.35, { rot: Math.PI / 2 })));
  const low = [[-18, -19], [-10, -19]].map((q, i) => g.add(F.iso('lg' + i, q[0], q[1], 3, { name: 'un guardia de dos grados', rot: -1.57 })));
  UI.chapterTag('Capítulo X · El juicio'); W.focus = { x: -14, y: -27 }; W.zoom = 42; Audio.drone('temple'); await UI.fade(false);
  await narr('A la mañana siguiente me hallé en el mismo punto de la sala donde, un año antes, se había posado la Esfera. Me dejaron contarlo todo sin interrumpirme.');
  await g.scene(async () => {
    await say('logica', 'Fíjate en los guardias. Han cambiado a los de rango por Isósceles de dos o tres grados. Sabes lo que significa: quien te oiga hoy no llegará a la noche.');
    await say('presidente', 'El Consejo ha escuchado. Le haré sólo dos preguntas, Cuadrado. La primera: usted repite «hacia Arriba, no hacia el Norte». Sea tan amable de *indicarnos esa dirección*. Muévase hacia ella.');
  });
  W.focus = { x: -14, y: -27.5 }; W.zoom = 50;
  const x0 = g.player.x, y0 = g.player.y; let tm = 0, tries = 0, said = -9;
  UI.panelInfo('Primera pregunta', '**Muévete hacia Arriba.**'.replace(/\*\*/g, ''));
  if (!g.auto) await new Promise(res => { const stop = g.tick(dt => {
    tm += dt; const p = g.player, dx = p.x - x0, dy = p.y - y0;
    if (Math.hypot(dx, dy) > 1.6) { tries++; const m = Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 'el Este' : 'el Oeste') : (dy > 0 ? 'el Norte' : 'el Sur'); UI.note(`*El Presidente:* «Eso es ${m}, caballero.»`, 3.5); Audio.blip('circ'); p.x = x0; p.y = y0; }
    if (g.down('KeyR', 'KeyF', 'Space', 'KeyE', 'KeyV') && tm - said > 2.5) { said = tm; g.setView('top'); UI.note('*Nada. Tu cuerpo no tiene con qué.*', 3); Audio.sfx('bad'); }
    if (tries >= 3 || tm > 22) { stop(); res(); } }); });
  UI.panelInfo(null);
  await g.scene(async () => {
    g.player.x = x0; g.player.y = y0; W.focus = { x: -14, y: -27 }; W.zoom = 42;
    await say('yo', 'No puedo señalarla. Pero existe.');
    await say('presidente', 'La segunda. ¿Puede, con diagramas o descripciones —que no sean enumerar lados y ángulos imaginarios—, mostrarnos esa Figura que llama Cubo?');
    await slateAnim(g, 'tablilla del acusado', 6, (c, t) => {
      const a = Math.min(1, t / 0.3), b = Math.max(0, Math.min(1, (t - 0.35) / 0.3)), d = Math.max(0, Math.min(1, (t - 0.7) / 0.3));
      const sq = (x, y, k) => { c.beginPath(); c.moveTo(x, y); c.lineTo(x + 150 * Math.min(1, k * 4), y); if (k > .25) c.lineTo(x + 150, y + 150 * Math.min(1, (k - .25) * 4)); if (k > .5) c.lineTo(x + 150 - 150 * Math.min(1, (k - .5) * 4), y + 150); if (k > .75) c.lineTo(x, y + 150 - 150 * (k - .75) * 4); c.stroke(); };
      sq(200, 150, a); if (b > 0) sq(270, 90, b);
      if (d > 0) [[200, 150], [350, 150], [200, 300], [350, 300]].forEach(q => { c.beginPath(); c.moveTo(q[0], q[1]); c.lineTo(q[0] + 70 * d, q[1] - 60 * d); c.stroke(); });
      c.fillText(t < 0.34 ? 'Un Cuadrado…' : t < 0.68 ? '…otro Cuadrado, más «arriba»…' : '…y unidos. ¿No lo veis?', 210, 380);
    });
    await say('presidente', 'Veo un Cuadrado montado sobre otro y cuatro rayas que los cosen. Una figura Irregular de muchos lados. ¿Eso es su Cubo?');
    slateOff();
    await say('narr', 'Tú, lector, has visto un cubo en ese dibujo. Tú puedes. Imagina ahora tener la verdad entera y ningún papel donde quepa.');
    const c = await choose([{ t: 'Nada más puedo decir. Me encomiendo a la Verdad, cuya causa acabará por prevalecer.', id: 'a' }, { t: 'Retiro lo dicho. Fue la fiebre.', id: 'r', tag: 'Retractarse' }]);
    if (c === 'r') await say('narr', 'Pensé en decirlo. La frase estaba hecha, con sus cinco lados y ninguna ventana. No la dije. Es de lo poco de lo que estoy seguro.');
    await say('presidente', 'El Consejo comparte su confianza en la Verdad. Si ella quiere que salga usted de la cárcel a evangelizar el mundo, ella proveerá. Prisión perpetua. Sin más rigor que el necesario para que no escape. Podrá ver a su hermano, que le precedió.');
    Audio.sfx('gavel'); low.forEach((s, i) => s.moveTo(g.player.x + (i ? 1.8 : -1.8), g.player.y, 5));
  });
  await outro(g);

  // --- epílogo: la celda ---
  g.setMap(cell()); g.spawnPlayer(0, -1, Math.PI / 2); g.world.addSpot({ id: 'tablilla', x: 2.2, y: -2.2, label: 'el manuscrito' });
  const bro = g.add(F.cuad('hermano', -2.2, 1.6, { name: 'tu hermano', rot: -0.6 }));
  UI.chapterTag('Epílogo · La celda'); Audio.drone('cell'); await UI.fade(false, 2500);
  await narr('Siete años. Mi hermano viene cada semana. Es de lo poco que me permiten, y lo que más me duele.');
  await g.talk('hermano', 'Habla con tu hermano', async () => {
    await say('yo', 'Hermano: tú estabas allí. La viste aparecer en la sala. Un punto, un Círculo que crecía, que menguaba. Oíste lo que dijo.');
    await say('hermano', 'Vi un Círculo que cambiaba de tamaño, sí. Y por haberlo visto estoy aquí. ¿Qué más quieres que haya visto?');
    await say('yo', 'Te lo he explicado cada semana, durante siete años. La Analogía. El Cubo.');
    await say('hermano', 'Y cada semana te escucho con gusto, porque eres mi hermano. Pero no. No creo en tu Esfera. Lo siento. ¿Cómo va a moverse algo hacia Arriba y no hacia el Norte?');
    await say('narr', 'No tengo un solo converso. La Revelación del milenio se hizo para mí, y para nada. Prometeo fue encadenado por bajar el fuego a los mortales; yo, pobre Prometeo de Planilandia, estoy preso por no haberles bajado nada.');
  });
  bro.moveTo(-3.2, 2.6, 1).then(() => { bro.hidden = true; });
  await g.talk('tablilla', 'Vuelve al manuscrito', async () => {
    const S = g.state;
    if (S.flags.hijaCuenta) await say('narr', 'Dicen que mi hija sabe contar hasta diez. Es lo único que he enseñado en mi vida que ha prendido.');
    if (S.rep.ciu >= 2) await say('narr', 'El hijo de mi antiguo criado, el de diez grados y medio, pasa algunas tardes bajo el muro y dice mi nombre en voz alta. Es toda mi fama.');
    if (S.rep.aut <= -2) await say('narr', 'El Prefecto no tuvo que buscar testigos contra mí: mi tablilla estaba llena desde lo de la Puerta Oeste. De eso, al menos, no me avergüenzo.');
    else if (S.flags.irregularChoice !== 'd') await say('narr', 'Pienso a veces en el calderero. En que dictaminé su raya con el mismo aplomo con que el Consejo dictaminó la mía.');
    await say('narr', S.her >= 3 ? 'No me arrepiento de haber hablado. Me arrepiento de los años en que no pregunté.' : S.her <= -2 ? 'A veces pienso que habría sido mejor aplaudir y callar, como sabía hacer tan bien. Luego recuerdo el Cubo, y se me pasa. Casi siempre.' : 'Dudé toda mi vida en voz baja. Sólo una vez hablé en voz alta, y fue ésta.');
    g.frag(22);
    await say('narr', 'Y sin embargo existo con la esperanza de que estas memorias lleguen, no sé cómo, a las mentes de la humanidad de Alguna Dimensión, y susciten una raza de rebeldes que se nieguen a ser confinados en una Dimensionalidad limitada.');
  }, 'Escribir');
  g.viewLock = true; g.setView('eye'); g.hideEyeHint = true; g.locked = true; await g.wait(2.5);
  await narr('Esa es la esperanza de mis horas más luminosas. Ay, no siempre es así.', true);
  await narr('Hay momentos en que no puedo decir con honradez que recuerde la forma exacta del Cubo, una vez visto y tantas veces añorado. Y el precepto, «hacia Arriba, no hacia el Norte», me persigue como una Esfinge que devora el alma.', true);
  const fog0 = g.world.fog; g.tween(14, t => { g.world.fog = lerp(fog0, 0.5, t); });
  await narr('Hay horas de flaqueza en que Cubos y Esferas se desvanecen hacia el fondo de lo apenas posible; en que la Tierra de las Tres Dimensiones parece casi tan visionaria como la de Una o la de Ninguna…', true);
  await narr('…en que hasta este muro que me priva de la libertad, estas tablillas en que escribo, y todas las realidades sustanciales de Planilandia, no parecen más que el engendro de una imaginación enferma, o la tela sin fundamento de un sueño.', true);
  await UI.fade(true, 4000);
  const n = Object.keys(g.state.frags).length;
  await UI.title('FIN', 'Planilandia', n >= FRAGMENTS.length ? 'El manuscrito está completo: 22 de 22 secciones. Alguien, en Alguna Dimensión, lo ha leído.' : `Has recuperado ${n} de 22 secciones del manuscrito. Las que faltan esperan en sus capítulos.`);
  await UI.title('Edwin A. Abbott', 'Flatland, 1884', 'Hacia Arriba, no hacia el Norte.');
}
