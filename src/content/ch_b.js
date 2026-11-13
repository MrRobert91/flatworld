// Capítulos IV–V: la Sedición Cromática (teatro de la memoria) y el Templo.
import { UI } from '../ui.js';
import { Audio } from '../audio.js';
import { say, choose, narr, F, town, sightRound } from './common.js';
import { intro, outro, townFolk } from './ch_a.js';

const HUES = ['#ff5a4f', '#ffa53b', '#ffe14d', '#59d98e', '#3fc4ff', '#7b74ff', '#e56bff', '#ff8fb0'];
const RED = '#ff4a43', GREEN = '#3fd97a';
const rnd = a => a[Math.floor(Math.random() * a.length)];
const paint = e => { if (e.woman || e.def.n >= 20 || e.sideColors) return false; const k = Math.floor(Math.random() * 8); e.setColors(e.local.map((_, i) => HUES[(k + i * 3) % 8])); return true; };

const agora = () => ({ bounds: { x0: -44, y0: -28, x1: 44, y1: 28 }, fog: 16, palette: 'color', zoom: 56,
  walls: [[-6, 16, 6, 16], [-6, 16, -8, 19], [6, 16, 8, 19]],
  labels: [{ t: 'Mercado', x: -16, y: -8, s: 1.6, a: 0.25 }, { t: 'Tribuna', x: 0, y: 18.4, s: 0.9, a: 0.5 }, { t: 'teatro de la memoria · hace muchos siglos', x: 0, y: -24, s: 0.7, a: 0.4, it: true }] });

function crowd(g, n, mix) {
  const out = [];
  for (let i = 0; i < n; i++) {
    const k = mix[i % mix.length], x = -30 + Math.random() * 60, y = -16 + Math.random() * 26, id = 'c' + i;
    const d = k === 'iso' ? F.iso(id, x, y, 6 + Math.random() * 14) : k === 'mujer' ? F.mujer(id, x, y) : k === 'tri' ? F.tri(id, x, y) : k === 'cuad' ? F.cuad(id, x, y) : k === 'penta' ? F.penta(id, x, y) : k === 'circ' ? F.circ(id, x, y) : F.hexa(id, x, y);
    out.push(g.add({ ...d, ai: { type: 'wander', home: [x, y], r: 6 }, speed: 1.3 + Math.random() }));
  }
  return out;
}

export async function ch4(g) {
  // --- el Colegio ---
  g.setMap(town({ school: true })); g.spawnPlayer(-41, 13.3, -Math.PI / 2); townFolk(g);
  const W = g.world;
  g.add(F.hexa('archivero', 18, 23, { name: 'el viejo archivero', r: 0.95, rot: -1.57 }));
  ['e1', 'e2', 'e3'].forEach((id, i) => g.add({ ...F.poli(id, 13 + i * 4, 17 + (i % 2) * 2, 6 + i, { r: 0.55, name: 'un estudiante' }), ai: { type: 'wander', home: [14 + i * 4, 17], r: 2.5 }, speed: 1.6 }));
  g.on('e1', 'Hablar', async () => { await say('estudiante', 'Si suspendo el examen final de Vista, señor, no seré ni noble ni plebeyo. A los suspendidos no los quiere nadie. Dicen que de ahí salen todos los revoltosos.'); });
  g.on('e2', 'Hablar', async () => { await say('estudiante', 'Tres años para distinguir un Decágono de un Dodecágono en movimiento. Mi padre dice que es lo único que nos separa de los que palpan.'); });
  await intro(g, 'Capítulo IV', 'El tiempo de los colores', 'Donde un viejo recuerda que el mundo no siempre fue una línea gris.', 'flat');
  const ic = g.flag('irregularChoice');
  await narr(ic === 's' || ic === undefined ? 'No dormí bien. A la mañana siguiente fui al Colegio de Vista, con el pretexto de consultar un tratado. En realidad quería que alguien me dijera que mirar y callar era lo correcto.' : ic === 'o' ? 'Dormí bien, lo confieso. A la mañana siguiente fui al Colegio de Vista a consultar un tratado. Me sentía un buen ciudadano.' : 'No dormí. A la mañana siguiente fui al Colegio de Vista; quería saber si siempre habíamos sido así.');
  await g.goTo(18, 12.5, 2.2, 'Ve al Colegio de Vista, al este por la Calle Mayor');
  W.reveal('school');
  await g.talk('archivero', 'Habla con el viejo archivero', async () => {
    await say('archivero', 'El perito de la Puerta. Ya se sabe por aquí lo del calderero. ¿Viene a por absolución? No la doy: soy archivero.');
    await say('archivero', 'Doy otra cosa. ¿Sabe usted que hubo un tiempo en que no hacía falta mirar con tanto esfuerzo, ni palpar a nadie? Un tiempo en que cada cual llevaba escrito por fuera lo que era… o lo que quería ser.');
    const c = await choose([{ t: 'El Color. Sé que está prohibido nombrarlo.', id: 'a' }, { t: 'Cuentos de viejos.', id: 'b' }]);
    await say('archivero', c === 'a' ? 'Aquí dentro, entre tablillas, se puede nombrar. Flojito.' : 'Cuentos, sí. Con ciento cuarenta mil muertos al final. Siéntese.');
    await say('archivero', 'Cierre el ojo. Los del Colegio lo llamamos el Teatro de la Memoria. Durante un rato será usted otro: un Pentágono al que la historia llama Cromatistes.');
  });
  await outro(g);

  // --- teatro de la memoria: Cromatistes ---
  g.setMap(agora()); g.spawnPlayer(-20, -12, 0.4, { n: 5, r: 0.85, name: 'Cromatistes' });
  let folk = crowd(g, 34, ['iso', 'tri', 'cuad', 'hexa', 'iso', 'penta', 'mujer', 'tri', 'iso', 'circ']);
  UI.chapterTag('Teatro de la memoria · Cromatistes'); Audio.drone('color'); g.setView('top'); await UI.fade(false);
  await narr('Mira: el mismo mundo, siglos atrás. Todo líneas pálidas, como hoy. Y tú, un Pentágono cualquiera que una tarde, revolviendo tierras y óxidos en su taller, da con algo que no tiene nombre.');
  if (!g.auto) {
    const cols = [];
    for (let i = 0; i < 5; i++) {
      const c = await UI.panel('Los pigmentos', `Elige un color para tu lado ${['primero', 'segundo', 'tercero', 'cuarto', 'quinto'][i]}.`, HUES.map(h => ({ swatch: h, id: h })));
      cols.push(c); g.player.setColors([...cols, ...Array(5 - cols.length).fill('#ece5d0')]); Audio.tone(300 + i * 80, 0.5, 'sine', 0.1);
    }
  } else g.player.setColors(HUES.slice(0, 5));
  await narr('Primero pintaste tu casa. Luego a tus esclavos, a tu padre, a tus hijos, a tus nietos. Por último, a ti. Y saliste al mercado.');
  let painted = 0; g.objective('Pasea por el mercado. Que te vean.');
  const stop = g.tick(() => { const p = g.player; for (const e of folk) if (Math.hypot(e.x - p.x, e.y - p.y) < 3.6 && paint(e)) { painted++; Audio.tone(400 + painted * 35, 0.4, 'sine', 0.07); } });
  await g.until(Object.assign(() => painted >= 12, { auto() { folk.forEach(paint); } }));
  stop(); folk.forEach(paint); g.objective('');
  await narr('Nadie tropezaba contigo. Nadie tenía que palparte ni calcular tus ángulos: te *veían*. En dos generaciones no quedaba figura sin pintar, salvo las Mujeres y los Sacerdotes, que no tienen lados.');
  await g.scene(async () => {
    g.setView('eye'); await g.wait(1.5);
    await narr('Míralo con el ojo de un planilandés. Ya no es una raya gris: cada cual lleva su clase a la vista. Fue la infancia del Arte. Inmoral, anárquica… y bellísima.');
    await g.wait(1.2); g.setView('top');
  });
  g.frag(8);
  await narr('Pero si un soldado se pinta como un noble, ¿en qué se distinguen? El Reconocimiento por la Vista dejó de estudiarse. Y los de abajo empezaron a decir, cada vez con más razón, que eran iguales a los de arriba.');

  // --- el Proyecto de Ley ---
  g.add({ id: 'agitador', pts: Array.from({ length: 26 }, (_, i) => { const a = i / 26 * Math.PI * 2; return [Math.cos(a) * (1 + 0.13 * Math.cos(a * 2 + 0.5)), Math.sin(a) * 0.9]; }), noEye: true, voice: 'iso', x: 0, y: 14, rot: -1.57, name: 'el tribuno' }).setColors(HUES);
  const pri = g.add(F.circ('cura', 9, 12, { name: 'un Sacerdote', rot: -2 })), dam = g.add(F.mujer('damaC', -8, 12, { name: 'una mujer', rot: -1 }));
  await g.talk('agitador', 'Años después. Escucha al tribuno, junto a la Tribuna', async () => {
    await say('agitador', '¡Ciudadanos de todos los ángulos! ¿Quién sigue sin color en Planilandia? ¡Ellos! Los Círculos, que nos gobiernan. Y ellas, que no tienen voto ni lados.');
    await say('agitador', 'Proyecto de Ley del Color Universal: ¡que todos se pinten! Y como ni mujeres ni sacerdotes tienen lados, sea roja la mitad de cada cual que lleva el ojo y la boca, y verde la otra mitad.');
    pri.setColors(Array.from({ length: 30 }, (_, i) => (i < 8 || i > 22) ? RED : GREEN)); dam.setColors([RED, GREEN, GREEN, RED]); Audio.sfx('her');
    await say('logica', 'Piensa lo que eso significa visto *de canto*. Una mujer: línea mitad roja, mitad verde. Un sacerdote: línea mitad roja, mitad verde.');
    await say('agitador', '¡Cualquier mujer podrá ser tomada por un Círculo, y tratada como tal! ¡Y cualquier Círculo, por una mujer! ¿Quién se opondrá? ¿Vuestras esposas?');
    await say('narr', 'Era diabólico, y era brillante. Lo ideó un Círculo Irregular, a quien una indulgencia insensata perdonó la vida de niño. Las mujeres apoyaron la Ley en masa. Tres años estuvo el Estado al borde del abismo.');
    const c = await choose([{ t: '(Gritar con la multitud.) ¡Color para todos!', id: 'h', tag: 'Herejía' }, { t: '(Callar.) Esto acabará en sangre.', id: 's' }, { t: '(Abuchear.) ¡Demagogo irregular!', id: 'o' }]);
    if (c === 'h') { await say('voces', '¡Color! ¡Color! ¡Color!'); g.her(1); } else if (c === 'o') { await say('voces', '(Te empujan. Aquí eres minoría.)'); g.her(-1); }
    g.frag(9);
  }, 'Escuchar');

  // --- el fraude ---
  await narr('Un ejército de Isósceles había vencido ya a los Polígonos. Entonces ocurrió, aquí mismo, en el mercado, un incidente pequeño. Míralo tú. Con el ojo.');
  await g.scene(async () => {
    g.player.x = -14; g.player.y = -6; g.player.rot = 0; g.world.camX = -14; g.world.camY = -6;
    folk.forEach(e => { if (Math.abs(e.y + 6) < 4 && e.x > -16) { e.y += 9; e.ai.home[1] += 9; } });
    g.viewLock = true; g.setView('eye'); const f0 = g.world.fog; g.world.fog = 4; await g.wait(1.3);
    const twelve = Array.from({ length: 12 }, (_, i) => HUES[(i * 3) % 8]);
    const a = await sightRound(g, 'iso', { deg: 9, colors: twelve, near: 3, title: 'En el mercado', text: 'Se te acerca alguien con doce colores y la voz redonda de un gran señor. ¿Qué es?',
      options: [{ id: 'dode', label: 'Dodecágono', sub: 'doce colores' }, { id: 'iso', label: 'Isósceles', sub: 'una cuña' }, { id: 'hexa', label: 'Hexágono', sub: 'un noble menor' }],
      verdict: a => a === 'iso' ? 'Lo has calado: un Isósceles de cuatro grados, pintado con los doce colores de un Dodecágono.' : 'Era un Isósceles de cuatro grados, pintado con los doce colores de un Dodecágono. *El color miente mejor que la voz.*' });
    g.world.fog = f0; g.setView('top'); g.viewLock = false;
    await narr('Así engañó a una doncella, huérfana de un noble Polígono. Hubo boda. Cuando ella descubrió el fraude, se quitó la vida. La noticia corrió de casa en casa, y las mujeres empezaron a mirar la Ley con otros ojos.');
  });

  // --- Pantociclo ---
  const pan = g.add(F.circ('pantociclo', 0, 22, { name: 'Pantociclo', r: 1.5, rot: -1.57 })); await pan.moveTo(0, 13.2, 3);
  g.npc('agitador').moveTo(-5, 11, 2);
  const guards = [0, 1, 2, 3].map(i => g.add(F.iso('pg' + i, -9 + i * 6, 20, 14, { name: 'un preso armado', rot: -1.57 })));
  await g.talk('pantociclo', 'Asamblea extraordinaria. Acude ante el Círculo Supremo', async () => {
    await say('pantociclo', 'Ciudadanos. Los Círculos hemos decidido ceder. Aceptamos la Ley del Color. Sólo os pido, antes de votar, que me escuchéis una última vez.');
    await say('narr', 'Habló casi un día entero. Nadie supo después repetir sus frases, sólo lo que hicieron.');
    await say('pantociclo', 'Artesanos: hoy vuestros hijos pueden nacer Equiláteros y subir. Cuando nada distinga a un noble de un obrero, ¿a qué subirán? Lo que ganáis en pintura lo perdéis en hijos.');
    await say('pantociclo', 'Mujeres: recordad a la doncella del mercado. Con el Color, ningún honor de esposa está a salvo de un impostor de cuatro grados.');
    const c = await choose([{ t: '(Mirar a las mujeres. Están girando.)', id: 'a' }, { t: '(Mirar a los presos armados junto a la Tribuna.)', id: 'b' }, { t: '(Gritar.) ¡Es una trampa!', id: 'c', tag: 'Cuestionar' }]);
    if (c === 'c') await say('logica', 'Nadie te oye. Un día entero de discurso lo ha preparado todo; tu grito llega con un día de retraso.');
    await say('pantociclo', '¡Antes la muerte que el Color!');
    Audio.sfx('gavel');
    UI.closeDlg();
    // la matanza
    for (const gd of guards) gd.moveTo(-5 + Math.random() * 2, 11 + Math.random(), 9);
    await g.wait(0.8); g.world.remove('agitador'); Audio.sfx('stab');
    const isos = folk.filter(e => e.def.iso); let k = 0;
    for (const e of isos) { setTimeout(() => { e.hidden = true; e.noCollide = true; Audio.sfx('stab'); }, g.auto ? 0 : 500 + k++ * 330); e.speed = 7; e.ai = { type: 'wander', home: [0, 0], r: 8 }; }
    await g.wait(1 + isos.length * 0.33);
    await narr('A una señal, las mujeres retrocedieron de punta sobre los soldados. Los artesanos las imitaron. Los presos tomaron las salidas. Los Isósceles, creyéndose traicionados, se revolvieron unos contra otros.');
    await narr('En media hora no quedaba ninguno. Ciento cuarenta mil, muertos por los ángulos de sus compañeros.');
    for (const e of W.ents.values()) if (e.sideColors) e.setColors(null);
    W.setPalette('flat'); Audio.drone('flat'); Audio.sfx('fall');
    await g.wait(1.5);
    await narr('Después vinieron las purgas: todo Triángulo sospechoso, destruido sin medición. Y el Color quedó abolido. Hoy sólo un viviente conoce el secreto de fabricarlo: el Círculo Supremo.');
    g.frag(10); g.learn('color');
  }, 'Escuchar');
  await outro(g);

  // --- de vuelta ---
  g.setMap(town({ school: true })); W.reveal('school'); g.spawnPlayer(18, 20.5, Math.PI / 2);
  g.add(F.hexa('archivero', 18, 23, { name: 'el viejo archivero', r: 0.95, rot: -1.57 }));
  UI.chapterTag('Capítulo IV · El tiempo de los colores'); await UI.fade(false);
  await g.talk('archivero', 'Abre el ojo. Habla con el archivero', async () => {
    await say('archivero', 'Ya está. Vuelve usted a ser una raya gris entre rayas grises. ¿Qué le ha parecido?');
    const c = await choose([{ t: 'Que era hermoso. Y que nos lo quitaron.', id: 'h', tag: 'Herejía' }, { t: 'Que el Color era una mentira peligrosa. Hicieron bien.', id: 'o', tag: 'Ortodoxia' }, { t: 'Que Pantociclo no convenció a nadie: los enfrentó.', id: 'l', lock: g.knows('clases') ? null : 'requiere conocer las clases' }]);
    if (c === 'h') { await say('archivero', 'Baje la voz. …Sí. Yo también lo pienso, los días de lluvia.'); g.her(1); }
    if (c === 'o') { await say('archivero', 'Eso dice el manual. Tiene usted buena memoria para los manuales.'); g.her(-1); g.rep('sac', 1); }
    if (c === 'l') { await say('archivero', 'Ah. Un Cuadrado que mira la mano y no la boca. Tenga cuidado con ese ojo, perito: aquí se premia ver ángulos, no ver *eso*.'); g.her(1); }
    await say('archivero', 'Mañana hay ceremonia en el Templo. Vaya. Conviene que lo vean a usted allí, después de lo de la Puerta.');
  });
  await outro(g);
}

// ============ CAP. V — EL TEMPLO ============
export async function ch5(g) {
  const map = town({ temple: true });
  [['Círculos', -33], ['Nobleza', -29.6], ['Profesionales', -26], ['Equiláteros', -22.4], ['Isósceles', -18.8]].forEach(([t, y]) => map.labels.push({ t, x: 19.4, y, s: 0.55, a: 0.5, it: true }));
  map.labels.push({ t: 'mujeres', x: 41.2, y: -19.5, s: 0.55, a: 0.5, it: true });
  g.setMap(map); const W = g.world; W.reveal('temple'); g.spawnPlayer(30, -4, -Math.PI / 2);
  const up = { rot: -Math.PI / 2 }, row = (ids, mk, y, xs) => xs.map((x, i) => g.add(mk(ids + i, x, y, up)));
  g.add(F.circ('circulo', 30, -37, { name: 'el Círculo oficiante', r: 1.5, rot: Math.PI / 2 }));
  row('tc', (id, x, y, o) => F.circ(id, x, y, o), -33, [24, 27, 33, 36]);
  row('tn', (id, x, y, o) => F.poli(id, x, y, 6 + (x % 5), o), -29.6, [23, 26, 29, 32, 35]);
  row('tp', (id, x, y, o) => (x % 2 ? F.penta(id, x, y, o) : F.cuad(id, x, y, o)), -26, [23, 25.5, 28, 32.5, 35, 37]);
  row('tt', (id, x, y, o) => F.tri(id, x, y, o), -22.4, [22, 24.5, 27, 29.5, 32, 34.5, 37]);
  row('ti', (id, x, y, o) => F.iso(id, x, y, 8 + (x % 9), o), -18.8, [23, 25, 27, 29, 31, 33, 35, 37]);
  [-28, -25, -22, -19].forEach((y, i) => g.add(F.mujer('tm' + i, 41.2, y, { rot: Math.PI })));
  await intro(g, 'Capítulo V', 'Atiende a tu Configuración', 'Donde los Círculos explican por qué nadie tiene la culpa, y a quién se castiga de todos modos.', 'temple');
  await narr('El Templo de los Círculos. Tantos lados que desde dentro la pared parece no tener ninguno.');
  await g.goTo(30, -12, 2, 'Entra en el Templo');
  await narr('Cada clase tiene su fila; más cerca del altar cuantos más lados. Busca la tuya.');
  let scold = false;
  const stop = g.tick(() => { if (!scold && g.player.y < -27.9 && Math.abs(g.player.x - 30) < 11) { scold = true; UI.note('*Un ujier te cierra el paso con un ángulo muy educado.* «La fila de los Profesionales está detrás, caballero.»', 5); g.rep('sac', -1); g.player.y = -27; } });
  await g.goTo(30, -26, 1.1, 'Ocupa tu sitio en la fila de los Profesionales');
  stop(); g.player.rot = -Math.PI / 2;
  await g.scene(async () => {
    W.focus = { x: 30, y: -29 }; W.zoom = 44;
    await say('circulo', 'Hijos del Plano. Hay una sola ley, y cabe en cuatro palabras. Decidlas conmigo.');
    const c = await choose([{ t: '«Atiende a tu Configuración.»', id: 'o' }, { t: '(Mover la boca sin voz.)', id: 's' }, { t: '(Susurrar.) ¿Y quién atiende a la del calderero?', id: 'h', tag: 'Herejía', lock: g.flag('irregularChoice') ? null : '—' }]);
    await say('voces', '«ATIENDE A TU CONFIGURACIÓN.»');
    if (c === 'o') { g.rep('sac', 1); }
    if (c === 'h') { await say('decoro', 'El Pentágono de tu izquierda se ha apartado medio paso. Te ha oído.'); g.her(1); g.rep('sac', -1); }
    await say('circulo', 'Lo que sois, lo sois por vuestros ángulos. El ladrón Isósceles no elige robar: su vértice roba por él. No lo culpamos. No culpamos a nadie.');
    await say('circulo', 'Y como él no puede evitar ser un daño para sus vecinos, el Magistrado no puede evitar hacerlo consumir. Así, sin culpa y sin rencor, todo queda en orden.');
    await say('logica', 'Sigue el razonamiento: si nadie es culpable, nadie merece castigo. Y sin embargo castigan. El silogismo cojea de un lado. Irregular, diríase.');
    await say('narr', 'Los llamamos Círculos, pero ninguno lo es. Son Polígonos de lados tan numerosos y pequeños que no se distinguen. Del Círculo Supremo se dice, por cortesía, que tiene diez mil. Palparlo para comprobarlo sería impensable.');
    g.frag(11); g.learn('config');
    // presentación del recién nacido
    const pa = g.add(F.iso('padre', 27, -14, 58, { name: 'el padre' })), ma = g.add(F.mujer('madre', 29, -13.5, { name: 'la madre' })), be = g.add(F.tri('bebe', 28, -14.6, { r: 0.38, name: 'el niño' }));
    Audio.sfx('bell');
    await say('circulo', 'Hoy hay júbilo. A un obrero de cincuenta y nueve grados y medio le ha nacido un hijo. Que lo traigan.');
    await Promise.all([pa.moveTo(28.6, -34.6, 3.5), ma.moveTo(31.6, -34.4, 3.5), be.moveTo(30, -34.8, 3.5)]);
    W.focus = { x: 30, y: -31 }; W.zoom = 38;
    await say('circulo', 'La Junta Sanitaria y Social ha medido. Sesenta grados. Sesenta. Sesenta. Lo declaramos Regular: un Equilátero.');
    await say('voces', '(Un murmullo de fila en fila. En la de los Isósceles, algo parecido a un sollozo de orgullo.)');
    await say('padre', 'Gracias, Reverencia. Gracias. Cien generaciones, y me ha tocado a mí verlo.');
    const ad = g.npc('tt3'); await ad.moveTo(30, -31.5, 3);
    await say('circulo', 'Un Regular no puede criarse entre puntas. Será adoptado por este Equilátero sin hijos. Padre: jura no volver a verlo.');
    await say('padre', '…Lo juro.');
    await say('madre', '¿Adónde lo llevan? Esposo, ¿adónde llevan al niño?');
    const c2 = await choose([{ t: '(Aplaudir con la asamblea.)', id: 'o' }, { t: '(Bajar el ojo.)', id: 's' }, { t: '(En voz alta.) ¡Dejad al menos que la madre lo visite!', id: 'h', tag: 'Cuestionar' }]);
    be.ai = { type: 'follow', target: 'tt3', dist: 1, speed: 4 }; ad.moveTo(30, -11, 3).then(() => { ad.hidden = true; be.hidden = true; });
    if (c2 === 'o') { await say('narr', 'Aplaudí. Era un día de fiesta, y yo un ciudadano que sabía cuándo se aplaude.'); g.rep('sac', 1); g.her(-1); }
    if (c2 === 's') await say('narr', 'Miré al suelo, que en mi mundo es mirar a ninguna parte.');
    if (c2 === 'h') { await say('circulo', 'El caballero de cuatro lados confunde la piedad con la Geometría. La madre lo habrá olvidado antes de la cena: su Configuración no retiene. ¿No es una misericordia?'); await say('madre', '¿Qué niño?', ); await say('recelo', 'No. Ha dicho «¿qué niño?» porque tres ujieres la están mirando.'); g.her(1); g.rep('sac', -2); g.rep('ciu', 1); }
    await say('narr', 'Esa es la esperanza que sostiene a los de abajo: que un día les nazca un hijo que les quiten. Los Círculos la llaman válvula de seguridad.');
    await Promise.all([pa.moveTo(27, -18.8, 3), ma.moveTo(41.2, -16.5, 3)]);
    await say('circulo', 'Id en orden. Atended a vuestra Configuración.');
    W.focus = null; W.zoom = W.baseZoom;
  });
  g.add(F.circ('novicio', 38, -13.5, { name: 'un Círculo joven', r: 0.85, rot: 2.5 }));
  await g.talk('novicio', 'Un Círculo joven te hace una seña junto a la salida', async () => {
    await say('novicio', 'Lo he observado durante el oficio, Cuadrado. Tiene usted el perímetro inquieto. Pregunte: prefiero una duda dicha que una pensada.');
    let asked = 0; const done = {};
    while (asked < 2) {
      const c = await choose([
        { t: 'Si la falta es de la Configuración, ¿por qué reprendo a mi nieto?', id: 'a', lock: done.a && 'ya preguntado' },
        { t: '¿Por qué no se enseña a leer a las mujeres?', id: 'b', lock: done.b && 'ya preguntado' },
        { t: '¿Cuántos lados tiene usted, en verdad?', id: 'c', lock: done.c && 'ya preguntado', tag: 'Osadía' },
        { t: 'Nada más, Reverencia.', id: 'x' }].filter(o => !o.lock), true);
      if (c === 'x') break; done[c] = 1; asked++;
      if (c === 'a') {
        await say('yo', 'El pequeño Hexágono alegó que un cambio de temperatura fue demasiado para su perímetro. Que la culpa no era suya sino de su Configuración.');
        await say('novicio', '¿Y qué le respondió usted?');
        await say('yo', 'Que, en ese caso, una buena reprimenda le fortalecería la Configuración.');
        await say('novicio', 'Je. Heterodoxo, pero práctico. Así gobernamos también nosotros, sólo que sin reírnos.');
      }
      if (c === 'b') {
        await say('novicio', 'Hace trescientos años, el Círculo Supremo decretó que, siendo ellas pobres en Razón y ricas en Emoción, educarlas era malgastar la tablilla. Desde entonces no leen ni cuentan.');
        await say('logica', 'Y desde entonces tú hablas dos lenguas. Con ella: «amor», «deber», «piedad». Con ellos: «anticipación de beneficios», «necesidad». Dos idiomas, casi dos mentes.');
        const d = await choose([{ t: 'Temo que esa doble carga sea excesiva para los jóvenes. Humildemente, pido que se reconsidere.', id: 'h', tag: 'Apelar' }, { t: 'Una disposición sabia.', id: 'o' }]);
        if (d === 'h') { await say('novicio', 'Humildemente anotado. No lo repita ante el oficiante: él no distingue una apelación de una sedición, y a veces tiene razón.'); g.her(1); g.flag('apelo', 1); }
        else { await say('novicio', 'Eso decimos.'); g.her(-1); }
        g.learn('bilingue');
      }
      if (c === 'c') {
        await say('novicio', 'Qué pregunta tan de palpador. Unos cuatrocientos. Mi padre tenía trescientos cincuenta; entre nosotros no rige eso de un lado por generación.');
        await say('novicio', 'A mi hermano mayor lo llevaron de niño al Gimnasio Neoterapéutico, a que le fracturasen el marco para ganar lados. Sobrevive uno de cada diez. Él no fue ése.');
        await say('asombro', 'Lo dice con la misma voz con que antes dijo «misericordia».'); g.rep('sac', -1);
      }
    }
    await say('novicio', 'Vaya a casa. Faltan dos noches para el milenio; dicen que en esas fechas la gente ve cosas. Usted no vea nada.');
    g.frag(12);
  });
  await narr('Volví a casa bajo una niebla espesa. Era el penúltimo día del año 1999. Me entretuve hasta tarde con mi vicio de siempre, la Geometría, y me dormí sobre las tablillas.');
  await outro(g);
}
