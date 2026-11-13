// Prólogo y capítulos I–III: la celda, la casa, la calle, la Puerta Oeste.
import { UI } from '../ui.js';
import { Audio } from '../audio.js';
import { say, choose, narr, F, P, town, sightRound, feel, CLASSES } from './common.js';

export async function intro(g, num, title, sub, drone) {
  UI.chapterTag(`${num} · ${title}`); Audio.drone(drone); g.setView('top'); g.world.eyeT = 0;
  await UI.title(num, title, sub); await UI.fade(false);
}
export async function outro(g) { g.objective('', null); await UI.fade(true); UI.closeDlg(); }
export const cell = () => ({ bounds: { x0: -14, y0: -14, x1: 14, y1: 14 }, fog: 9, palette: 'cell', zoom: 30,
  buildings: [{ id: 'cell', x: 0, y: 0, R: 5.2, n: 4, rot: 45, sealed: false }], labels: [] });

// ============ PRÓLOGO ============
export async function prologue(g) {
  g.setMap(cell()); g.spawnPlayer(0, -1, Math.PI / 2);
  g.showStrip = false; g.viewLock = true; g.setView('eye'); g.world.eyeT = 1; g.hideEyeHint = true;
  UI.chapterTag('Prólogo · La celda'); Audio.drone('cell');
  await UI.fade(false, 2500);
  await narr('Siete años llevo en esta celda.');
  await narr('Esa raya pálida que tienes delante no es un defecto de tu vista. Es *todo* lo que ve un habitante de mi mundo: una línea, más clara donde la pared está cerca, más oscura donde se aleja.');
  UI.note('Gira con **A / D**. Avanza con **W / S**.'.replace(/\*\*/g, ''), 60); g.objective('Mira a tu alrededor (A / D)');
  const r0 = g.player.rot; let turned = 0, last = r0;
  await g.until(Object.assign(() => { turned += Math.abs(g.player.rot - last); last = g.player.rot; return turned > 2.2; }, { auto() { } }));
  g.objective('');
  await narr('Cuatro paredes. Las reconozco por cómo se apagan en la niebla: así se deduce aquí un ángulo. Me costó años de colegio aprenderlo.');
  await narr('Pero tú no eres de aquí. Tú vienes de un mundo con una dirección de sobra. Voy a concederte, lector, lo que a mí me costó la libertad: *mirar desde arriba*.');
  g.viewLock = false; g.hideEyeHint = false; g.objective('Pulsa V para elevarte sobre el plano');
  await g.until(Object.assign(() => g.view === 'top' && g.world.eyeT < 0.05, { auto() { g.setView('top'); } }));
  g.objective(''); g.showStrip = true;
  await narr('Ese soy yo. Un Cuadrado. Cuatro lados iguales, cuatro ángulos rectos: un caballero de la clase profesional, o eso era.');
  await narr('Arriba, en ese marco, sigue mi ojo: lo que yo veo mientras tú me ves a mí. Ningún compatriota mío ha contemplado jamás esta lámina. Disfrútala con un poco de culpa.');
  const coin = g.add(F.circ('moneda', 0, 2.2, { name: 'una moneda', noGuts: true, r: 0.7 }));
  await narr('Los de tu mundo lo entendéis con una moneda sobre la mesa. Desde arriba: un círculo. Baja ahora el ojo hasta el borde de la mesa y dime qué queda de ella.');
  g.objective('Colócate frente a la moneda y pulsa V');
  await g.until(Object.assign(() => g.view === 'eye' && g.world.eyeT > 0.95 && g.eye.hits.some(h => h === 'moneda'), { auto() { } }));
  g.objective('');
  await narr('Una línea. Triángulo, cuadrado, círculo, esposa, sacerdote: aquí todos somos, unos para otros, una línea que brilla y se apaga.');
  g.frag(1); g.learn('linea');
  await narr('Llamo a mi mundo Planilandia. No porque nosotros lo llamemos así, sino para que tú lo entiendas.');
  g.setView('top'); g.world.remove('moneda');
  g.world.addSpot({ id: 'tablilla', x: 2.2, y: -2.2, label: 'la tablilla' });
  await g.talk('tablilla', 'Acércate a la tablilla y empieza a escribir (E)', async () => {
    await say('narr', 'Me permiten tablillas. Supongo que piensan que un loco que escribe es un loco ocupado.');
    await say('narr', 'Lo contaré todo, en orden. Cada página que recuperes conmigo irá al manuscrito —*pulsa J para leerlo*—. Cuando esté completo, quizá alguien, en Alguna Dimensión, lo lea.');
    await say('narr', 'Empezaré por la última semana del año 1999 de nuestra era. Por mi casa. Por la lluvia.');
  }, 'Escribir');
  await outro(g);
}

// ============ CAP. I — LA CASA ============
export async function ch1(g) {
  g.setMap(town()); g.spawnPlayer(-28, 22.5, -Math.PI / 2); g.world.rain = 1; g.showStrip = true; g.viewLock = false;
  const W = g.world;
  g.add(F.mujer('esposa', -21.5, 12, { name: 'tu esposa', ai: { type: 'wander', home: [-21.5, 10.5], r: 2.2 }, speed: 1.2 }));
  g.add(F.mujer('hija', -21.8, 9, { name: 'tu hija', r: 0.8, sway: 1.4 }));
  g.add(F.hexa('nieto', -34.5, 9, { name: 'tu nieto menor', r: 0.6, ai: { type: 'wander', home: [-34.5, 9.5], r: 2 }, speed: 2 }));
  g.add(F.hexa('nieto2', -33.2, 8.6, { name: 'tu otro nieto', r: 0.66, rot: 1 }));
  g.add(F.penta('hijo', -28, 9, { name: 'tu hijo mayor', rot: 1.2 }));
  g.add(F.iso('criado', -36.2, 15.6, 10, { name: 'el criado', rot: -1.2 }));
  W.addSpot({ id: 'tejado', x: -28, y: 27, label: 'el vértice del tejado' });
  W.addSpot({ id: 'alacena', x: -23.3, y: 20.4, label: 'la alacena' });
  await intro(g, 'Capítulo I', 'La casa de cinco lados', 'Donde se aprende de dónde viene la lluvia y por qué puerta entra cada cual.', 'home');
  await narr('Mi estudio, bajo el vértice del tejado. Muévete con **WASD** o las flechas.'.replace(/\*\*/g, ''));
  await narr('Aquel día llovía. Siempre que empiezo a recordar, llueve.');

  g.on('alacena', 'Examinar', async () => {
    await say('narr', 'Mi alacena, cerrada con llave por sus cuatro lados. Dentro: dos cofres de dinero y dos tablillas de cuentas.');
    await say('logica', 'Cerrada por sus cuatro lados está cerrada del todo. No existe otro lado por el que entrar.');
    if (g.state.max >= 8) await say('asombro', 'Y sin embargo.');
  });
  g.on('hija', 'Hablar', async () => {
    await say('hija', '¡Padre! Mira: ya meneo la espalda sin pensar. La institutriz dice que tengo un vaivén muy distinguido.');
    await say('narr', 'En las familias de rango, el vaivén del extremo posterior se enseña como un arte. Avisa de tu presencia a quien viene detrás. Las hijas de los Círculos lo ejecutan con un ritmo que da envidia.');
    await say('hija', '¿Me enseñarás a contar, como al nieto? Sólo hasta diez.');
    const c = await choose([{ t: 'Las niñas no necesitan contar, hija.', id: 'o' }, { t: 'Cuando tu madre no mire. Hasta diez.', id: 'h', tag: 'Herejía' }, { t: '(Cambiar de tema.) Qué bien meneas la espalda.', id: 's' }]);
    if (c === 'o') { await say('hija', 'Ya. Eso dice la institutriz.'); g.her(-1); }
    if (c === 'h') { await say('hija', '¡Uno, dos, tres…!'); await say('decoro', 'Hace trescientos años que la ley prohíbe exactamente esto.'); g.her(1); g.flag('hijaCuenta', 1); }
    if (c === 's') await say('hija', '¿Verdad que sí?');
  });
  g.on('hijo', 'Hablar', async () => {
    await say('hijo', 'Padre. Salgo a visitar enfermos. Un Hexágono con un lado inflamado; nada grave, pero paga bien.');
    await say('narr', 'Mis cuatro hijos son Pentágonos: un lado más que yo, como manda la Naturaleza. Médicos todos. Hombres rectos. Jamás les he oído una pregunta que no supieran ya contestar.');
  });
  g.on('nieto2', 'Hablar', async () => { await say('nieto', '(Tu otro nieto dormita, con la quietud perfecta de seis lados bien educados.)'); });

  await g.all({
    tejado: { label: 'Examinar', fn: async () => {
      await say('narr', 'El vértice de mi casa apunta al Norte, como el de todas. La lluvia viene siempre de allí, a intervalos fijos, y el tejado la parte en dos.');
      await say('logica', 'No hay sol ni estrellas en este mundo. Para orientarte tienes dos cosas: la lluvia, y un tirón leve y constante hacia el Sur. Las mujeres y los ancianos lo notan más.');
      await say('narr', 'Tampoco hay ventanas. ¿Para qué? La luz está en todas partes, dentro y fuera, de día y de noche. Nadie sabe de dónde viene.');
      const c = await choose([{ t: '¿Y nadie lo ha investigado?', id: 'q' }, { t: 'Así ha sido siempre.', id: 'o' }]);
      if (c === 'q') { await say('narr', 'Antaño era la pregunta favorita de los sabios. Hoy esa investigación paga un impuesto ruinoso, y los manicomios están llenos de quienes creyeron tener la respuesta.'); await say('recelo', 'Toma nota: en este país las preguntas tienen precio.'); }
      else await say('narr', 'Eso respondía yo también. Es una frase muy cómoda, con cinco lados y ninguna ventana.');
      g.frag(2); g.learn('norte');
    } },
    nieto: { fn: async () => {
      await say('nieto', '¡Abuelo! Estoy jugando a adivinar ángulos. ¿Por qué nuestra casa tiene cinco lados y no cuatro, como tú?');
      const c = await choose([{ t: 'Porque lo manda la ley, y con eso basta.', id: 'o' }, { t: 'Piénsalo: ¿qué pasa si tropiezas con una esquina?', id: 'm' }]);
      if (c === 'o') { await say('nieto', 'Pero la ley tendrá un porqué…'); await say('narr', 'Tenía la mala costumbre de los niños listos: no aceptar la primera respuesta.'); }
      await say('nieto', '¡Ya sé! Las esquinas de una casa cuadrada pinchan más que las de una de cinco lados. Y como las paredes brillan menos que las personas, uno no las ve venir en la niebla.');
      await say('narr', 'Exacto. Por eso las casas triangulares se prohibieron hace siglos, salvo cuarteles y polvorines, y las cuadradas pagan impuesto. En las ciudades, cinco lados como mínimo.');
      g.learn('casas');
      await say('nieto', 'Abuelo, ¿y si hubiera una casa que no pinchara por *ningún* lado?');
      await say('asombro', 'Seis lados y ya hace preguntas que tú, con cuatro, no te has hecho nunca.');
      if (c === 'm') g.flag('nietoCurioso', 1);
    }, again: async () => { await say('nieto', '¿Jugamos luego a los ángulos, abuelo?'); } },
    esposa: { fn: async () => {
      await say('decoro', 'Has entrado en los aposentos del Este. Aquí se anuncia uno, y se mira dónde se pisa.');
      await say('esposa', 'Esposo. No te había oído. Deberías hablar al acercarte; ya sabes lo que le pasó a mi primo.');
      await say('narr', 'Mi esposa es una Línea recta, como todas las mujeres: una aguja. Vista de costado, un trazo. Vista de punta, casi nada: un brillo, y luego el pinchazo.');
      g.setView('eye'); await UI.sleep(1600);
      await say('logica', 'Mírala con tu ojo. Cuando gira hacia ti, desaparece. Por eso la ley la obliga a menearse.');
      g.setView('top');
      await say('esposa', 'He oído que en casa del boticario la mujer estornudó al volverse. Él ya no está. Ella no recordaba nada a la media hora; cenó tan tranquila.');
      const c = await choose([{ t: 'Por eso existen las leyes, querida: la puerta del Este, el Grito de Paz.', id: 'o' }, { t: '¿Y a ti no te pesa gritar por la calle toda tu vida?', id: 'h', tag: 'Herejía' }, { t: 'Mi amor, mi deber es protegerte. (Lengua de mujeres.)', id: 'm' }]);
      if (c === 'o') { await say('esposa', 'Sí, esposo. Las leyes son sabias.'); await say('narr', 'Toda casa, una puerta al Este sólo para ellas. En la calle, el Grito de Paz sin interrupción, bajo pena de muerte. Así vivíamos tranquilos. Nosotros.'); g.her(-1); }
      if (c === 'h') { await say('esposa', '¿Pesarme? Qué preguntas haces. No sé… nunca lo he pensado. No me han enseñado a pensarlo.'); await say('recelo', 'Lo ha dicho sin rencor. Eso es lo que debería inquietarte.'); g.her(1); }
      if (c === 'm') { await say('esposa', 'Lo sé. Y el mío, quererte.'); await say('logica', '«Amor». «Deber». Con ellas usas palabras que entre varones no significan nada. Ya ni notas el cambio de idioma.'); }
      g.frag(4); g.learn('mujeres');
    }, again: async () => { await say('esposa', 'Abrígate el perímetro si sales. Hay niebla.'); } },
    criado: { fn: async () => {
      await say('criado', '¿El señor va a salir? Le abro. Cuidado en la calle, que hoy no se ve un ángulo a dos pasos.');
      await say('narr', 'Un Isósceles de diez grados. Soldados y obreros lo son todos: dos lados largos, una base mínima, una punta que da miedo. Apenas se les considera figuras.');
      await say('criado', 'Mi chico ha salido de diez grados y medio, señor. Medio grado más que yo. A este paso, en cien generaciones, un biznieto mío será Equilátero.');
      const c = await choose([{ t: 'Es un buen muchacho. Me alegro por ti.', id: 'a' }, { t: 'No te hagas ilusiones por encima de tu ángulo.', id: 'b' }, { t: '(Asentir sin decir nada.)', id: 'c' }]);
      if (c === 'a') { await say('criado', 'Dios… quiero decir, los Círculos se lo paguen, señor.'); g.rep('ciu', 1); }
      if (c === 'b') { await say('criado', 'No, señor. Claro que no, señor.'); g.rep('ciu', -1); }
      await say('logica', 'Entre los tuyos, cada hijo gana un lado entero. Entre los suyos, medio grado, y sólo si trabajan sin tacha. Alguien diseñó esa diferencia.');
      g.learn('herencia');
    } },
  }, 'Recorre tu casa: el tejado, tu nieto, tu esposa, el criado');

  await narr('Tenía que salir. Por la puerta del Oeste, la ancha: la de los varones.');
  let warned = false;
  const stop = g.tick(() => { const p = g.player; if (!warned && Math.hypot(p.x + 19.4, p.y - 13.3) < 2.2) { warned = true; UI.note('*Decoro* — Esa es la puerta del Este. Es de ellas. Un caballero no la cruza.', 5); Audio.sfx('bad'); } });
  await g.goTo(-41, 13.3, 1.8, 'Sal a la calle por la puerta del Oeste');
  stop();
  await outro(g);
}

// ============ CAP. II — LA CALLE MAYOR ============
export function townFolk(g) {
  g.add(F.mujer('dama', -18, -2, { name: 'una dama', ai: { type: 'path', pts: [[-18, -2.5], [10, -2.5], [10, 2.5], [-18, 2.5]] }, speed: 1.9 }));
  g.add(F.iso('obrero', -12, 3, 8, { name: 'un obrero', ai: { type: 'wander', home: [-8, 2], r: 5, sx: 2 }, speed: 1.8 }));
  g.add(F.penta('medico', 34, 3, { name: 'un médico', ai: { type: 'wander', home: [36, 2], r: 4, sx: 2 }, speed: 1.5 }));
  g.add(F.iso('sold1', 50, -2, 12, { name: 'un soldado', ai: { type: 'path', pts: [[52, -3], [-55, -3], [-55, 3], [52, 3]] }, speed: 3 }));
  g.add(F.iso('sold2', 48, -2, 12, { name: 'un soldado', ai: { type: 'follow', target: 'sold1', dist: 2.4, speed: 3.2 } }));
  g.add(F.tri('trans', 20, -3, { name: 'un tendero', ai: { type: 'wander', home: [22, -2], r: 6, sx: 2 }, speed: 1.6 }));
  let t = 0; g.tick(dt => { t += dt; if (t > 3.2) { t = 0; const d = g.npc('dama'), p = g.player; if (d && p && Math.hypot(d.x - p.x, d.y - p.y) < 14 && !g.busy) Audio.sfx('peace'); } });
  g.on('dama', 'Saludar', async () => {
    await say('dama', '¡Paz, paz! Buenos días, caballero. Disculpe que no me detenga: si dejo de gritar, me multan; si dejo de menearme, me denuncian.');
    await say('narr', 'El Grito de Paz. De niño me parecía el sonido mismo de la calle, como la lluvia.');
  });
  g.on('obrero', 'Hablar', async () => {
    await say('obrero', '¿Manda algo el señor? Voy al tajo. Dicen que si uno trabaja sin faltar, al hijo le crece el ángulo.');
    await say('obrero', 'Mi abuelo estuvo en una revuelta. Ciento veinte ha habido, cuentan, y todas igual: los Círculos sueltan promesas a unos cuantos, y nos acabamos pinchando entre nosotros.');
    await say('recelo', 'Lo dice sin bajar la voz. O es muy valiente o su ángulo no le da para callar.');
  });
  g.on('medico', 'Hablar', async () => {
    await say('medico', 'Colega. ¿Sabe que en el Hospital han enderezado a un Triángulo que se desviaba un grado entero? Compresiones, extensiones, una trepanación menor. Sobrevivió, incluso.');
    await say('narr', 'El arte de curar la Irregularidad. Se hablaba de él con orgullo, y en voz no muy alta.');
  });
  g.on('trans', 'Hablar', async () => { await say('mercader', 'Tablillas, punzones, sal del Norte. ¿No? Otro día será, señor Cuadrado.'); });
  g.on('sold1', 'Hablar', async () => { await say('soldado', '¡Paso a la ronda! Disculpe el señor: de frente, que de punta no respondo.'); });
}

export async function ch2(g) {
  g.setMap(town()); g.spawnPlayer(-41, 13.3, -Math.PI / 2); g.world.rain = 0.25; townFolk(g);
  g.add(F.hexa('noble', -30, -2.5, { name: 'un Hexágono ocioso', rot: 0.5 }));
  g.add(F.tri('mercader', 6, 2.5, { name: 'un comerciante', rot: -1 }));
  g.add({ id: 'irregular', pts: [[0.95, 0], [-0.3, 0.8], [-0.62, -0.38]], voice: 'tri', x: -48, y: 2.4, name: 'un calderero', rot: 0.2 });
  g.world.addSpot({ id: 'voz', x: 26, y: -5.5, label: 'una voz en la niebla' });
  await intro(g, 'Capítulo II', 'La Calle Mayor', 'Donde se aprende quién es quién, y cómo averiguarlo sin perder un ángulo.', 'flat');
  await narr('La Calle Mayor. Desde arriba la ves entera; yo veía rayas que se cruzaban en la niebla. Prueba a recorrerla con mi ojo (**V**), si te atreves.'.replace(/\*\*/g, ''));

  g.on('irregular', 'Hablar', async o => {
    await say('irregular', 'Buenos días, señor. ¿Algún punzón que afilar? ¿Una bisagra? Llevo cuarenta años en esta esquina.');
    const c = await choose([{ t: 'Hoy no, buen hombre.', id: 'n' }, { t: 'Permítame palparle, por cortesía.', id: 'p', lock: g.knows('tacto') ? null : 'aún no dominas el tacto' }, { t: '¿Cuarenta años? ¿Y qué ha visto en ellos?', id: 'q' }]);
    if (c === 'p') { await say('irregular', 'Ah… hoy llevo prisa, señor. Otro día. Con su permiso.'); await say('recelo', 'Nadie con prisa lleva cuarenta años en la misma esquina.'); g.flag('sospecha', 1); }
    if (c === 'q') { await say('irregular', 'He visto que a quien no molesta, a veces lo dejan en paz. Con eso me basta. Tenga: se le había caído este estilete.'); await say('narr', 'Me devolvió un estilete que yo no había echado en falta. Recuerdo que pensé: qué equilátero tan decente.'); g.flag('amable', 1); g.rep('ciu', 1); }
  });

  await g.all({
    noble: { fn: async () => {
      await say('noble', 'Un Cuadrado. Bien, bien. Ustedes sostienen el mundo por abajo, como una buena base. ¿Sabe por qué todo está en orden?');
      await say('noble', 'Porque cada cual sabe lo que es con sólo contarse los lados. Abajo, los Isósceles: soldados, obreros, carne de punta. Luego los Equiláteros, que venden cosas. Luego usted y los Pentágonos: médicos, letrados. Luego *nosotros*, de seis lados en adelante. Y arriba, tantos lados que ya no se cuentan: los Círculos.');
      await say('yo', '¿Y las mujeres?');
      await say('noble', 'Líneas, caballero. De la clase que sean. No tienen lados que contar.');
      const c = await choose([{ t: 'Y cada hijo, un lado más que su padre. Mis nietos ya son como usted.', id: 'a' }, { t: 'Salvo los Isósceles. A ellos la ley no los sube.', id: 'b', lock: g.knows('herencia') ? null : 'ignoras cómo heredan los Isósceles' }]);
      if (c === 'a') await say('noble', 'Je. Sí. No me lo recuerde.');
      if (c === 'b') {
        await say('noble', 'Medio grado por generación, si se portan. Y cuando al fin les nace un Equilátero de verdad, la Junta lo examina, lo certifica… y se lo lleva. Lo adopta una familia Regular. No vuelve a ver a los suyos.');
        await say('noble', 'Es una idea brillante de los Círculos. Les da una esperanza, ¿comprende? Uno entre mil sube, y los otros novecientos noventa y nueve se están quietos.');
        await say('recelo', 'Lo llama «brillante». Busca otra palabra, más tarde, a solas.');
      }
      g.frag(3); g.learn('clases');
    } },
    mercader: { label: 'Presentarse', fn: async o => {
      await say('mercader', 'Señor. Soy hombre a la antigua: *permítame pedirle que me palpe y sea palpado por mí.* Así sabremos con quién tratamos.');
      await say('decoro', 'Entre gente fina, palpar es grosería. Pero él es comerciante, y tú vienes a comprar. Adelante: un solo ángulo basta.');
      await say('logica', 'Recorre su ángulo con tu lado. La abertura te dirá la clase. Y que no se mueva: un sobresalto, y su vértice te atraviesa.');
      let ok = await feel(g, o);
      UI.panelInfo(null);
      if (ok) await say('mercader', 'Sesenta grados justos. Equilátero y a mucha honra. Y usted, cuatro rectos: un caballero.');
      else { await say('mercader', '¡Señor! Sesenta. Tres veces sesenta. ¿Por quién me toma?'); await say('logica', 'Menos de 60°: Isósceles. 60°: Equilátero. 90°: Cuadrado. 108°: Pentágono. 120°: Hexágono. Apréndelo.'); }
      g.learn('tacto');
      await say('mercader', 'Mi bisabuelo, obrero de cincuenta y nueve grados y medio, dio un respingo de reuma mientras lo palpaba un Polígono. Lo atravesó de parte a parte. La familia bajó grado y medio. Cinco generaciones tardamos en llegar a sesenta.');
      await say('narr', 'Esa misma historia se cuenta en mi familia, de mi propio antepasado. Puede que todas las familias de Planilandia tengan un abuelo que estornudó.');
      g.frag(5);
    } },
    voz: { label: 'Escuchar', fn: async () => {
      Audio.tone(262, 0.5, 'triangle', 0.1); await UI.sleep(500);
      await say('noble', '(Una voz, entre la niebla.) ¡Paso, paso a un Hexágono! ¡Aparte, buen hombre, que llevo prisa!');
      await say('logica', 'No lo ves. Sólo tienes su voz: redonda, de muchos lados.');
      const c = await choose([{ t: '(Apartarte con una reverencia.)', id: 'a' }, { t: '(Dudar.) Esa voz es demasiado perfecta.', id: 'b' }]);
      Audio.tone(130, 0.3, 'sawtooth', 0.08);
      g.add(F.iso('farsante', 26, -8.2, 9, { name: 'un Isósceles', rot: 1.57 })); await g.npc('farsante').moveTo(26, -6.6, 3);
      await say('soldado', 'Je. Perdone el señor. A uno le sale la voz que quiere, y con ésa me ahorro los empujones.');
      if (c === 'a') await say('decoro', 'Has hecho una reverencia a diez grados de ángulo. Que no se entere nadie.');
      else await say('logica', 'Bien oído. Las clases bajas tienen la garganta más hábil que nosotros. El oído, solo, no es de fiar.');
      g.learn('oido'); g.npc('farsante').moveTo(40, -4, 4).then(() => g.world.remove('farsante'));
    } },
  }, 'Trata con la gente de la calle: el noble, el comerciante, la voz');

  await g.scene(async () => {
    const s = g.add(F.iso('guardia', g.player.x - 14, g.player.y, 16, { name: 'el sargento' })); Audio.sfx('herald');
    await s.moveTo(g.player.x - 2.2, g.player.y, 7);
    await say('guardia', '¡Señor Cuadrado! Lo busco desde la Puerta Oeste. Falta el perito de vista y entra gente de las aldeas. El Prefecto dice que usted estudió en el Colegio.');
    const c = await choose([{ t: 'Es mi deber. Vamos.', id: 'a' }, { t: '¿Y no pueden palparlos, sencillamente?', id: 'b' }]);
    if (c === 'b') { await say('guardia', '¿Palpar a un Círculo de incógnito, señor? Me consumen esa misma tarde. No: hay que *verlos*. Y ver, ver… eso es cosa de ustedes.'); }
    await say('narr', 'Reconocer por la vista: el arte de mi clase. Me halagó que me llamaran. Eso también conviene que lo sepas.');
    s.ai = { type: 'path', pts: [[-66, 2.2]] }; s.speed = 6;
  });
  await g.goTo(-64, 0, 2.5, 'Ve a la Puerta Oeste, al final de la calle');
  await outro(g);
}

// ============ CAP. III — LA PUERTA OESTE ============
export async function ch3(g) {
  g.setMap(town()); g.spawnPlayer(-64, 0, Math.PI); g.world.rain = 0; townFolk(g);
  const W = g.world, sg = g.add(F.iso('guardia', -66, 2.4, 16, { name: 'el sargento', rot: -1 }));
  await intro(g, 'Capítulo III', 'La Puerta Oeste', 'Donde se trabaja mirando, y se mira a quien no debía ser mirado.', 'flat');
  await g.scene(async () => {
    await say('guardia', 'Aquí, señor: de cara a la Puerta. Vienen de uno en uno por el camino. Usted mira, dice qué son, y yo apunto.');
    await say('logica', 'Recuerda la lección. Hay niebla: lo lejano se apaga. Si la figura viene con un vértice hacia ti, sus lados huyen hacia atrás… y cuanto más agudo el ángulo, más deprisa se oscurecen los extremos.');
    g.learn('vista');
    await say('narr', 'Te dejo una ayuda de estudiante: bajo la línea verás una *traza* dorada. Es el brillo, dibujado como altura. Los quiebros de la traza son vértices; su pendiente, el ángulo.');
    UI.closeDlg();
    g.player.rot = Math.PI; g.viewLock = true; g.setView('eye'); g.locked = true; W.fog = 2.7;
    await g.wait(1.4);
    const v = k => a => a === k ? 'Cierto. *Fíjate en la lámina: así era por arriba.*' : null;
    await narr('Primero, el ejemplo del manual: un Comerciante. Triángulo. Mira qué deprisa se le apagan los extremos.');
    await sightRound(g, 'tri', { options: [CLASSES[2]], text: 'Un Equilátero, vértice al frente. El centro brilla; los extremos caen *muy rápido* en la niebla.', verdict: () => 'Equilátero: lados que huyen deprisa. *Compara la lámina con la línea.*' });
    await narr('Y ahora un Médico: Pentágono. Los extremos se apagan con más pereza; los lados retroceden despacio.');
    await sightRound(g, 'penta', { options: [CLASSES[4]], text: 'Un Pentágono. La traza cae *suave*: lados que retroceden despacio.', verdict: () => 'Pentágono: caída suave. *Así discierne el ojo educado.*' });
    g.frag(6);
    await narr('Ya está. Ahora, de verdad. El sargento apunta.');
    let hits = 0; const seq = ['mujer', 'cuad', 'iso', 'hexa', 'circ'];
    const tips = { mujer: 'Un punto que tiembla, un destello: una Mujer de frente. *Lo más peligroso es lo que menos se ve.*', cuad: 'Ángulo recto: ni tan abrupto como el Triángulo ni tan suave como el Pentágono.', iso: 'Una cuña: casi un punto, y dos lados que se pierden al instante.', hexa: 'Muy poca caída; tres lados visibles si gira un poco.', circ: 'Sin quiebros: una curva de brillo perfecta. *Un Círculo. Inclínate.*' };
    for (const k of seq) { const a = await sightRound(g, k, { verdict: a => (a === k ? 'Cierto. ' : 'No. ') + tips[k] }); if (a === k) hits++; }
    g.flag('aciertos', hits);
    g.setView('top'); g.locked = false; W.fog = 13;
    await say('guardia', hits >= 4 ? `${hits} de cinco, señor. Con ojos así, yo sería Hexágono.` : hits >= 2 ? `${hits} de cinco. No está mal, con esta niebla.` : `${hits} de cinco… Hoy la niebla está muy cerrada, señor. Lo apuntaré así.`);
    if (hits >= 4) g.rep('aut', 1);
    await say('guardia', 'Viene uno más. Ése me lo conozco: el calderero de la esquina. Pero la orden es mirarlos a todos.');
    UI.closeDlg(); g.setView('eye'); g.locked = true; W.fog = 2.7; W.remove('irregular'); await g.wait(1.2);
    const ans = await sightRound(g, 'irr', { keep: true, wobble: 0.5, reveal: false, title: 'Reconocimiento por la vista', text: 'La traza no es simétrica. Un lado se apaga deprisa; el otro, despacio. *El sargento espera tu dictamen.*',
      options: [{ id: 'tri', label: 'Equilátero', sub: 'declararlo Regular' }, { id: 'irr', label: 'Irregular', sub: 'decir lo que ves' }, { id: 'nose', label: 'No sabría decirlo', sub: 'callar' }] });
    g.setView('top'); g.locked = false; W.fog = 13; g.flag('dictamen', ans);
    const ir = g.npc('_s'); W.focus = { x: (ir.x + g.player.x) / 2, y: 0 }; W.zoom = 24;
    await narr('Desde arriba se ve sin esfuerzo: tres lados, ninguno igual a otro. Cuarenta años afilando punzones en una esquina, con ese secreto a cuestas.');
    if (ans === 'tri') {
      await say('yo', 'Equilátero. Regular. Puede pasar.');
      await say('guardia', '¿Regular…? Con perdón, señor: ése camina torcido desde que lo conozco. Voy a palparlo, que para eso no hace falta Colegio.');
      await say('guardia', 'Cincuenta y uno. Setenta y cuatro. Y el otro… cincuenta y cinco. Señor perito: o la niebla le ha engañado, o me ha engañado usted.');
      g.rep('aut', -2); g.rep('ciu', 1); g.her(1);
    } else if (ans === 'irr') {
      await say('yo', 'Irregular. Los lados no casan.');
      await say('guardia', 'Lo que yo decía. Buen ojo, señor.');
      g.rep('aut', 1); g.her(-1);
    } else {
      await say('yo', 'La niebla… no sabría decirlo.');
      await say('guardia', 'Pues lo palpo yo, que para eso no hace falta Colegio. Cincuenta y uno. Setenta y cuatro. Cincuenta y cinco. Irregular como una piedra.');
    }
    await say('irregular', g.flag('amable') ? 'Señor… usted me conoce. Esta mañana le devolví su estilete. No he pinchado a nadie en mi vida.' : 'Señor, por caridad. Cuarenta años en esa esquina. No he pinchado a nadie en mi vida.');
    const ins = g.add(F.penta('inspector', ir.x + 16, 1.5, { name: 'el Inspector' })); await ins.moveTo(ir.x + 2.4, 1.2, 6);
    await say('inspector', 'Inspector de Configuración. ¿Desviación? … Veintitrés grados. Muy por encima del margen. Al Hospital: reconfiguración, si el marco aún cede. Si no, consumo indoloro.');
    await say('irregular', 'A mi edad el marco no cede, señor Inspector. Lo sabe usted.');
    const c = await choose([
      { t: 'Inspector: este hombre no ha hecho daño alguno. ¿No basta con vigilarlo?', id: 'd', tag: 'Cuestionar' },
      { t: 'La ley es dura, pero sin Regularidad no podríamos ni saludarnos.', id: 'o', tag: 'Obedecer' },
      { t: '(Mirar la niebla. No decir nada.)', id: 's', tag: 'Callar' }]);
    g.flag('irregularChoice', c);
    if (c === 'd') {
      await say('inspector', '«No ha hecho daño.» ¿Y cómo lo sabría usted? Usted palpa un ángulo y deduce una persona. Con éste palpa uno y no sabe nada de los otros dos. Si toleramos eso, caballero, se acabó el tacto, la vista y la confianza. Me extraña tener que explicárselo a un Cuadrado.');
      await say('recelo', 'Ha apuntado algo en su tablilla. No era el ángulo del calderero.');
      g.rep('aut', -1); g.rep('sac', -1); g.her(1);
    } else if (c === 'o') {
      await say('inspector', 'Exacto. Da gusto oír a un hombre de sus ángulos.');
      await say('irregular', '(No te mira. Mira la calle, la esquina donde ya no estará.)');
      g.rep('sac', 1); g.her(-1);
    } else {
      await say('inspector', 'Bien. Firme aquí como perito.');
      await say('decoro', 'Has firmado. Callar también tiene letra.');
    }
    await say('narr', 'Entonces yo lo creía. Lo escribí, incluso: que el Irregular incurable debía ser *consumido sin dolor y con misericordia*. Me parecía una frase compasiva.');
    await say('narr', c === 'd' ? 'Recuerdo que aquel día protesté. O quiero recordarlo así: en una celda, la memoria es generosa con uno mismo.' : 'Aquel día no protesté. Eso sí lo recuerdo con exactitud.');
    g.frag(7); g.learn('irregulares');
    UI.closeDlg(); W.focus = null; W.zoom = W.baseZoom;
    ir.moveTo(ir.x + 30, 1.5, 3).then(() => W.remove('_s')); ins.moveTo(ir.x + 33, 1.2, 3).then(() => W.remove('inspector'));
    await g.wait(2.5);
  });
  await narr('Se lo llevaron calle arriba, hacia el Hospital de Reconfiguración. Yo volví a casa. Llegaba tarde a cenar.');
  await g.goTo(-41, 13.3, 2, 'Vuelve a casa');
  await outro(g);
}
