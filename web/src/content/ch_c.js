// Capítulos VI–VII: la visión de Linealandia y el Forastero de Espaciolandia.
import * as THREE from 'three';
import { UI } from '../ui.js';
import { Audio } from '../audio.js';
import { GAS, lerp, ease } from '../world.js';
import { say, choose, narr, F, town, slateAnim, slateOff } from './common.js';
import { intro, outro } from './ch_a.js';

const quad = (color, op = 1) => { const m = new THREE.Mesh(new THREE.PlaneGeometry(1, 1), new THREE.MeshBasicMaterial({ color, transparent: true, opacity: op, depthWrite: false })); m.rotation.x = -Math.PI / 2; return m; };

// ============ CAP. VI — LINEALANDIA ============
export async function ch6(g) {
  g.setMap({ bounds: { x0: -52, y0: -18, x1: 52, y1: 18 }, fog: 22, palette: 'dream', zoom: 44,
    labels: [{ t: 'Linealandia', x: 0, y: -12.5, s: 1.5, a: 0.3 }, { t: 'un sueño · penúltima noche del año 1999', x: 0, y: -14.6, s: 0.65, a: 0.4, it: true }] });
  const W = g.world; g.spawnPlayer(3, -7, Math.PI / 2);
  const line = quad(0xb4a8e0, 0.35); line.scale.set(110, 0.035, 1); line.position.y = 0.006; W.fx.add(line);
  const sec = quad(GAS, 1); sec.position.y = 0.05; sec.visible = false; W.fx.add(sec);
  const folk = [];
  const man = (id, x, r, name) => folk.push(g.add({ id, woman: true, sway: 0, r, voice: 'rey', x, y: 0, name: name || 'un súbdito', rot: 0, x0: x }));
  const wom = (id, x) => folk.push(g.add({ id, woman: true, sway: 0, r: 0.07, voice: 'mujer', x, y: 0, name: 'una súbdita (un Punto)', rot: 0 }));
  man('rey', 0, 1.6, 'la Línea más larga');
  wom('w1', 3); man('m1', 8.6, 0.9); wom('w2', 11); man('m2', 13.6, 0.7); wom('w3', 16); man('m3', 19, 0.8); wom('w4', 22); man('m4', 26, 0.6);
  wom('w5', -3); man('m5', -6.2, 0.8); wom('w6', -8.6); man('m6', -11.4, 0.9); wom('w7', -14); man('m7', -17, 0.7); wom('w8', -20); man('m8', -24, 0.85);
  folk.forEach(e => { e.x0 = e.x; });
  let t = 0, osc = 1;
  g.tick(dt => {
    t += dt; folk.forEach(e => { e.x = e.x0 + Math.sin(t * 0.9) * 0.45 * osc; });
    // sección del Cuadrado sobre la Línea: lo único que de él existe para Linealandia
    const p = g.player.worldPts(); let lo = 1e9, hi = -1e9;
    for (let i = 0; i < 4; i++) { const a = p[i], b = p[(i + 1) % 4]; if ((a[1] > 0) !== (b[1] > 0)) { const x = a[0] + (b[0] - a[0]) * (-a[1] / (b[1] - a[1])); lo = Math.min(lo, x); hi = Math.max(hi, x); } }
    sec.visible = hi > lo; if (sec.visible) { sec.scale.set(hi - lo, 0.14, 1); sec.position.set((lo + hi) / 2, 0.05, 0); }
    g.onLine = hi > lo;
  });
  await intro(g, 'Capítulo VI', 'El Rey de la Línea', 'Donde un Cuadrado se siente, por una noche, infinitamente superior.', 'dream');
  await narr('Soñé. Vi una multitud de pequeñas Líneas —mujeres, pensé— y entre ellas puntos brillantes, todos moviéndose adelante y atrás sobre una misma Recta, al mismo compás. Un gorjeo confuso salía de ellos.');
  await g.talk('rey', 'Dirígete a la Línea más larga', async () => {
    await say('yo', 'Mujer, ¿qué significa este concurso, este extraño gorjeo, este ir y venir sobre una sola recta?');
    await say('rey', 'No soy mujer. Soy el Monarca del mundo. ¿Y tú desde dónde te entrometes en mi reino de Linealandia? No te veo. Sólo oigo una voz que no viene ni de delante ni de detrás.');
    await say('logica', 'Estás a su costado. Para él no existe el costado: su mundo es esa Recta, y nada más. Lo que no está en ella, no está.');
    const done = {};
    for (let n = 0; n < 3; n++) {
      const c = await choose([
        { t: '¿Qué es tu reino?', id: 'a', lock: done.a && 1 }, { t: '¿Cómo veis? ¿Cómo os reconocéis?', id: 'b', lock: done.b && 1 },
        { t: '¿Y cómo os casáis, si no podéis cruzaros?', id: 'c', lock: done.c && 1 }].filter(o => !o.lock));
      done[c] = 1;
      if (c === 'a') { await say('rey', 'El universo: la Línea. Se extiende sin fin hacia delante y hacia atrás. Cada súbdito tiene dos vecinos y los tendrá hasta la muerte, pues nadie puede adelantar a nadie. Los varones somos Líneas; las mujeres, Puntos.'); await say('rey', 'Yo mido seis pulgadas y cuatrocientas cincuenta y siete milésimas. Soy el más largo. Por eso reino.'); }
      if (c === 'b') { await say('rey', '¿Ver? Vemos lo que hay que ver: un Punto. Delante de mí, el extremo de mi vecina; detrás, el de la otra. Nada más hay.'); await say('rey', 'Nos conocemos por la voz. Cada varón tiene dos bocas, una en cada extremo: grave en una, tenor en la otra. Escucha.');
        Audio.tone(110, 1.2, 'square', 0.07); Audio.tone(165, 1.0, 'square', 0.06, 0, 0.42);
        await say('logica', 'Dos notas, y una llega algo después que la otra. Del retraso deducen la longitud del que canta. Miden con el oído lo que no pueden ver.'); }
      if (c === 'c') { await say('rey', '¿Cruzarnos? ¿Tocarnos? Qué idea tan baja. La vecindad es eterna; el matrimonio se celebra a distancia, cantando. Cada varón, dos esposas: soprano y contralto.');
        [110, 165, 330, 440].forEach((f, i) => Audio.tone(f, 1.8, i < 2 ? 'square' : 'sine', 0.05, 0, i * 0.3));
        await say('rey', 'Cuando las tres voces casan en armonía, la unión está hecha, aunque los esposos disten mil leguas. Así nacen tres: dos niñas y un varón.'); await say('asombro', 'Un mundo entero construido con sonido, porque no hay sitio para nada más. Y está *satisfecho*.'); }
    }
    g.frag(13); g.learn('lineal');
    await say('yo', 'Majestad: vuestro reino no es el universo. Es una Línea dentro de un Plano. Yo estoy fuera de ella, y desde aquí os veo a todos a la vez.');
    await say('rey', 'Demuéstralo. Muévete de «izquierda a derecha», como tú dices, y que yo lo vea.');
  });
  await narr('Atravesé su mundo. Fíjate en la franja dorada: es lo único de mí que existía para ellos.');
  g.objective('Entra en la Línea: cruza la Recta al este del Rey', { x: 5.6, y: 0 });
  await g.until(Object.assign(() => g.onLine && Math.abs(g.player.x - 5.6) < 2.4, { auto() { g.player.x = 5.6; g.player.y = 0; } }));
  await g.scene(async () => {
    Audio.sfx('her');
    await say('rey', '¡Una Línea! ¡Ha surgido una Línea de la nada, entre mi esposa y mi vecino! ¿Eres tú, voz?');
    await say('logica', 'Ve tu sección: el tramo de ti que corta su Recta. No a ti. Si giras, tu «longitud» cambia, y para él es brujería.');
  });
  g.objective('Ahora sal de la Línea, hacia el Norte', { x: 5.6, y: 6 });
  await g.until(Object.assign(() => !g.onLine && g.player.y > 3, { auto() { g.player.y = 6; } }));
  g.objective('', null);
  await g.scene(async () => {
    await say('rey', '¡Ha desaparecido! No se ha movido adelante ni atrás: se ha *desvanecido*. Eso no es moverse. Eso es un truco de mago.');
    await say('yo', 'No he desaparecido. Estoy al Norte de vos. Y veo a vuestros vecinos: decidme si miento.');
    const c = await choose([{ t: 'Al Este tenéis una mujer; tras ella, un varón.', id: 'ok' }, { t: 'Al Este tenéis un varón; tras él, una mujer.', id: 'no' }, { t: 'Al Este, dos mujeres seguidas.', id: 'no2' }]);
    if (c === 'ok') await say('rey', 'Cierto. Pero eso lo sabe cualquiera con oídos. Los habrás oído cantar.');
    else await say('rey', 'Falso. Ni siquiera eso sabes. *(Mira la lámina: al Este del Rey hay un Punto, y luego una Línea.)*');
    await say('rey', 'Si fueras un hombre de juicio escucharías a la razón. Me pides creer que hay otra Línea además de la que mis sentidos me muestran, y otro movimiento además del que hago cada día. ¿Hay algo más ridículo?');
    const d = await choose([
      { t: '¡Ser obcecado! Te crees la perfección y no ves más que un Punto. Yo soy una Línea de Líneas: un Cuadrado.', id: 'r', tag: 'Soberbia' },
      { t: 'Yo tampoco lo habría creído, Majestad. No sé cómo decíroslo mejor.', id: 'h', tag: 'Humildad' }]);
    if (d === 'r') { await say('yo', 'Y aun yo, infinitamente superior a ti, soy poca cosa entre los grandes nobles de Planilandia.'); await say('narr', 'Lo dije así, palabra por palabra. Infinitamente superior. Guarda esa frase: volverá.'); g.flag('soberbia', 1); }
    else { await say('narr', 'Me habría gustado decir eso. Dije otra cosa: que yo era infinitamente superior a él. Guarda esa frase: volverá.'); g.her(1); }
    await say('rey', '¡A mí, mis Líneas! ¡A mí, mis Puntos! ¡Guerra al intruso!');
    UI.closeDlg(); osc = 0; Audio.sfx('herald');
    folk.forEach((e, i) => { e.x0 = e.x0 + (g.player.x - e.x0) * 0.6; Audio.tone(110 + i * 23, 2.5, 'square', 0.02, 1.5, i * 0.05); });
    await g.tween(2.2, k => { osc = k * 3; W.zoom = 44 - k * 14; });
    g.frag(14);
  });
  Audio.sfx('bell');
  await UI.fade(true, 700);
  W.fx.remove(line); W.fx.remove(sec);
  await narr('…y me despertó la campana del desayuno.', true);
  await narr('Me reí del Rey toda la mañana. Qué criatura tan limitada, tan segura de que su Recta era todo cuanto había.', true);
}

// ============ CAP. VII — EL FORASTERO ============
const emerge = (g, e, to, sec = 2.4) => { const s0 = e.scale; e.hidden = false; return g.tween(sec, t => { e.scale = Math.max(0.001, lerp(s0, to, ease(t))); }).then(() => { e.hidden = to < 0.02; }); };

export async function ch7(g) {
  g.setMap(town()); const W = g.world; W.rain = 1; g.spawnPlayer(-30, 11, Math.PI);
  const wife = g.add(F.mujer('esposa', -25.5, 12.5, { name: 'tu esposa', rot: 2.6 }));
  const kid = g.add(F.hexa('nieto', -34.5, 10.5, { name: 'tu nieto menor', r: 0.6, rot: 0 }));
  await intro(g, 'Capítulo VII', 'El Forastero', 'Última noche del año 1999. Donde alguien entra sin usar ninguna puerta.', 'home');
  await narr('El último día del milenio. El repiqueteo de la lluvia anunciaba la noche. Mis hijos se habían retirado; quedaba el pequeño, esperando su lección.');
  await g.talk('nieto', 'Dale a tu nieto su lección de Geometría', async () => {
    await say('nieto', '¡Abuelo! Hoy tocan los cuadrados de los números.');
    await slateAnim(g, 'tablilla de lecciones', 5, (c, t) => {
      const u = 70, x0 = 215, y0 = 320, a = Math.min(1, t / 0.3), b = Math.max(0, Math.min(1, (t - 0.35) / 0.45));
      c.beginPath(); c.arc(x0, y0, 5, 0, 7); c.fill();
      c.beginPath(); c.moveTo(x0, y0); c.lineTo(x0 + 3 * u * a, y0); c.stroke();
      if (b > 0) { c.globalAlpha = 0.5; for (let i = 0; i <= 3; i++) { c.beginPath(); c.moveTo(x0 + i * u, y0); c.lineTo(x0 + i * u, y0 - 3 * u * b); c.stroke(); }
        for (let j = 1; j <= 3; j++) if (b >= j / 3 - 0.01) { c.beginPath(); c.moveTo(x0, y0 - j * u); c.lineTo(x0 + 3 * u, y0 - j * u); c.stroke(); } c.globalAlpha = 1;
        c.beginPath(); c.moveTo(x0, y0 - 3 * u * b); c.lineTo(x0 + 3 * u, y0 - 3 * u * b); c.stroke(); }
      c.fillText(t < 0.33 ? 'Un Punto que se mueve 3 pulgadas traza una Línea: 3' : t < 0.82 ? 'La Línea, moviéndose paralela a sí misma…' : '…traza un Cuadrado de 3 por 3:  3² = 9', 110, 380);
    });
    await say('yo', 'Un Punto que se mueve tres pulgadas traza una Línea de tres. La Línea, moviéndose paralela a sí misma, traza un Cuadrado de tres por tres. Nueve pulgadas cuadradas: tres al cuadrado.');
    await say('nieto', 'También me has enseñado a elevar números a la *tercera* potencia. Entonces 3³ tiene que significar algo en Geometría. ¿Qué significa?');
    const c = await choose([{ t: 'Nada en absoluto. La Geometría sólo tiene Dos Dimensiones.', id: 'o' }, { t: 'No lo sé. Nunca me lo había preguntado.', id: 'h', tag: 'Herejía' }]);
    if (c === 'h') { await say('narr', 'Eso habría sido lo honrado. Dije: «Nada en absoluto; la Geometría sólo tiene Dos Dimensiones».'); g.her(1); }
    await say('nieto', 'Pero mira: si el Punto hace la Línea, y la Línea hace el Cuadrado… entonces el Cuadrado, moviéndose *de algún modo* paralelo a sí mismo, que no veo cómo, hará *algo*, que no veo qué, de tres pulgadas en todos los sentidos. Y eso será 3³.');
    await say('asombro', 'Lo ha dicho. Con seis lados y diez años. Algo en ti ha oído un crujido.');
    await say('yo', 'Vete a la cama.');
    slateOff();
  });
  kid.moveTo(-33.6, 8.6, 2.2);
  await g.goTo(-27.6, 12, 1.2, 'Siéntate en el salón, junto a tu esposa');
  let sph;
  await g.scene(async () => {
    g.player.rot = -Math.PI / 2;
    await say('narr', 'El reloj de arena dejaba caer los últimos granos del año, del siglo, del milenio. Yo rumiaba la impertinencia del crío.');
    await say('yo', 'El chico es tonto.');
    Audio.sfx('sphere');
    await say('esfera', 'El chico no es tonto. Y 3³ tiene un significado geométrico evidente.');
    sph = g.add(F.circ('esfera', -28, 9.3, { name: 'el Forastero', r: 1.7, tint: 0x9fe8e0, noGuts: true })); sph.scale = 0.001;
    W.focus = { x: -28, y: 12 }; W.zoom = 36;
    await emerge(g, sph, 0.55, 2.6);
    await say('narr', 'Había una Figura en el salón. No había entrado por ninguna puerta. Primero fue un punto; luego una raya que crecía.');
    await say('esposa', '¡Esposo! ¿Cómo ha entrado esta persona? Me prometiste que no habría ventiladores en la casa nueva.');
    await say('yo', 'Parece una Mujer vista de lado… pero su brillo cambia. Pálpala tú, querida; a mí no me corresponde.');
    await wife.moveTo(-26.6, 9, 1.5);
    await say('esposa', '¡Oh! No hay ángulo. No hay ni rastro de ángulo. ¡Es un Círculo perfecto! Perdone Vuestra Reverencia la torpeza de una pobre mujer.');
    wife.moveTo(-21.5, 10, 2.4);
    await emerge(g, sph, 1, 2);
    g.frag(15);
    // --- las palabras ---
    await say('esfera', 'No soy un Círculo. Vengo del Espacio: de la tierra de las Tres Dimensiones. Tú conoces el Largo y el Ancho. Yo te traigo la Altura.');
    let c = await choose([{ t: '¿Altura? Señaladme hacia dónde cae.', id: 'a' }, { t: 'El Espacio es esto, señor: Norte, Sur, Este y Oeste.', id: 'b' }]);
    await say('esfera', c === 'a' ? 'No puedo señalarla dentro de tu Plano. Es una dirección que corta en ángulo recto al Norte-Sur *y* al Este-Oeste a la vez. Hacia Arriba, no hacia el Norte.' : 'Eso que llamas Espacio es un Plano. Hay otra dirección, perpendicular a todas las tuyas a la vez. Hacia Arriba, no hacia el Norte.');
    await say('logica', 'Perpendicular a Norte y a Este a la vez. Tal dirección no existe. La frase es gramatical y no significa nada.');
    await say('esfera', 'Me llamas Círculo. Soy muchos Círculos en uno: infinitos, de todos los tamaños, apilados. Lo que ves es sólo la rebanada de mí que corta tu mundo. Mira lo que ocurre si me elevo.');
    Audio.tone(330, 2.5, 'sine', 0.08, 2);
    await emerge(g, sph, 0.001, 2.8); await g.wait(0.8);
    await say('yo', '¡Ha menguado hasta un punto y… se ha ido!');
    sph.x = -26.6; sph.y = 9.6; Audio.sfx('sphere'); await emerge(g, sph, 1, 2.4);
    c = await choose([{ t: 'Un truco de prestidigitador. Como desvanecerse en una Línea.', id: 'a', lock: g.knows('lineal') ? null : 'requiere haber soñado con la Línea' }, { t: 'No habéis ido a ninguna parte. Os habéis encogido.', id: 'b' }]);
    if (c === 'a') { await say('asombro', '«Eso no es moverse, es un truco de mago.» ¿Dónde has oído tú esa frase, hace nada? ¿Quién la decía?'); g.her(1); }
    await say('esfera', 'Probemos con la Analogía, ya que eres matemático.');
    await slateAnim(g, 'el argumento de la Analogía', 3.5, (cx, t) => {
      const y = 150; cx.beginPath(); cx.arc(90, y, 5, 0, 7); cx.fill(); cx.fillText('Punto', 62, y + 70);
      if (t > 0.25) { cx.beginPath(); cx.moveTo(190, y); cx.lineTo(280, y); cx.stroke(); [190, 280].forEach(x => { cx.beginPath(); cx.arc(x, y, 5, 0, 7); cx.fill(); }); cx.fillText('Línea', 208, y + 70); }
      if (t > 0.5) { cx.strokeRect(370, y - 45, 90, 90); [[370, y - 45], [460, y - 45], [370, y + 45], [460, y + 45]].forEach(p => { cx.beginPath(); cx.arc(p[0], p[1], 5, 0, 7); cx.fill(); }); cx.fillText('Cuadrado', 372, y + 70 + 20); }
      if (t > 0.75) { cx.font = "italic 70px Georgia"; cx.fillText('?', 545, y + 24); cx.font = "italic 22px 'Cormorant Garamond', Georgia, serif"; }
      cx.fillText('puntos terminales:      1                  2                        4                       ?', 40, 300);
      cx.fillText('lados:                             0                  2                        4                       ?', 40, 345);
    });
    await say('esfera', 'Un Punto que se mueve engendra una Línea, con dos puntos terminales. Una Línea que se mueve, un Cuadrado, con cuatro. Uno, dos, cuatro. ¿Qué número sigue?');
    c = await choose([{ t: 'Seis.', id: 6 }, { t: 'Ocho.', id: 8 }, { t: 'Dieciséis.', id: 16 }]);
    await say('esfera', c === 8 ? 'Ocho. Exacto: progresión geométrica. El Cuadrado, movido en la dirección nueva, engendra Algo con ocho puntos terminales. Lo llamamos Cubo.' : 'No. Uno, dos, cuatro: cada vez el doble. *Ocho.* El Cuadrado, movido en la dirección nueva, engendra Algo con ocho puntos terminales. Lo llamamos Cubo.');
    await say('esfera', 'Y los lados. El Punto tiene cero. La Línea, dos. El Cuadrado, cuatro. Cero, dos, cuatro. ¿Qué sigue?');
    c = await choose([{ t: 'Seis.', id: 6 }, { t: 'Ocho.', id: 8 }, { t: 'Cinco.', id: 5 }]);
    await say('esfera', c === 6 ? 'Seis. Progresión aritmética. El Cubo está limitado por seis lados, y cada uno es un Cuadrado como tú.' : 'No: cada vez dos más. *Seis.* El Cubo está limitado por seis lados, y cada uno es un Cuadrado como tú.');
    slateOff(); g.learn('analogia'); g.frag(16);
    await say('logica', 'La aritmética es impecable. Y no describe nada que pueda existir. ¿Qué haces con un razonamiento correcto sobre una cosa imposible?');
    c = await choose([{ t: '¡Monstruo! Brujo, sueño o demonio: no soportaré más tus burlas.', id: 'a', tag: 'Embestir' }, { t: 'Seguid. Os lo ruego: seguid hablando.', id: 'h', tag: 'Escuchar' }]);
    if (c === 'h') { await say('narr', 'Ojalá hubiera dicho eso. Me acuerdo de mis ángulos temblando, de la certeza de que se reían de mí en mi propia casa. Embestí.'); g.her(1); }
    W.focus = null; W.zoom = W.baseZoom;
  });
  g.objective('Embiste al Forastero con tu ángulo más duro', 'esfera'); W.mark('esfera'); sph.noCollide = true;
  await g.until(Object.assign(() => Math.hypot(g.player.x - sph.x, g.player.y - sph.y) < 2.1, { auto() { } }));
  W.unmark('esfera'); g.objective('', null); Audio.sfx('bad');
  await g.scene(async () => {
    await emerge(g, sph, 0.001, 0.5); sph.x = -28.4; sph.y = 16.6; await g.wait(0.6); await emerge(g, sph, 1, 1.2);
    await say('esfera', '¿Por qué te niegas a oír razones? Esperaba hallar en ti, hombre de juicio y matemático, un apóstol del Evangelio de las Tres Dimensiones. Sólo se me permite predicarlo una vez cada mil años.');
    await say('esfera', 'Si las palabras no bastan, hechos. Desde donde estoy veo tu alacena, ahí arriba, en el estudio. Cerrada con llave. Dentro: dos cofres de dinero y dos tablillas de cuentas. Voy a bajar a ella y traerte una.');
    await say('logica', 'Entre él y la alacena hay una pared. Y la alacena está cerrada por sus cuatro lados. Por *todos* sus lados.');
    await emerge(g, sph, 0.001, 1.6); await g.wait(1.2); Audio.sfx('pick');
    W.addSpot({ id: 'tab', x: -30.2, y: 8.6, label: 'una tablilla' });
    sph.x = -26.8; sph.y = 10; await emerge(g, sph, 0.8, 1.4);
    await say('esfera', 'Ahí la tienes, en el suelo. Ve luego a tu alacena, si quieres: falta una.');
    await say('yo', '…Es mi tablilla. La de las cuentas del mes.');
    await say('esfera', 'Y ahora, desde aquí arriba, veo algo más: tu interior. Tus entrañas, abiertas como una casa sin tejado. Voy a tocarte el estómago. No te alarmes.');
    Audio.sfx('stab'); g.player.guts.visible = true; W.zoom = 20; await g.wait(1.6); g.player.guts.visible = false; W.zoom = W.baseZoom;
    await say('yo', '¡Ah! Un dolor… *dentro*. Nada me ha tocado el perímetro. Me ha tocado por dentro.');
    await say('asombro', 'Por un instante tú también lo has visto: lo que hay dentro de ti, desde un sitio que no es ningún sitio.');
    const c = await choose([{ t: '(Lanzarte otra vez sobre él, gritando.)', id: 'a' }, { t: '(Quedarte inmóvil.) ¿Qué sois?', id: 'h' }]);
    if (c === 'h') await say('narr', 'No me quedé inmóvil. Grité como un Isósceles y cargué.');
    Audio.sfx('peace');
    await say('esposa', '(Desde sus aposentos.) ¿Esposo? ¿Qué son esas voces? ¡Paz, paz! Voy para allá.');
    await say('esfera', 'O esto termina aquí, o vienes conmigo adonde no hacen falta palabras. ¡Fuera de tu Plano! Una… dos… tres. ¡Hecho!');
    g.frag(17);
    UI.closeDlg(); Audio.sfx('rise'); Audio.drone('none');
    g.tween(3, t => { W.zoom = W.baseZoom - t * 40; g.player.rot += 0.2; });
    await UI.fade(true, 2800);
  });
}
