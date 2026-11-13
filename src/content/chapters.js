import { prologue, ch1, ch2, ch3 } from './ch_a.js';
import { ch4, ch5 } from './ch_b.js';
import { ch6, ch7 } from './ch_c.js';
import { ch8, ch9, ch10 } from './ch_d.js';
export const CHAPTERS = [
  { name: 'Prólogo · La celda', run: prologue },
  { name: 'I · La casa de cinco lados', run: ch1 },
  { name: 'II · La Calle Mayor', run: ch2 },
  { name: 'III · La Puerta Oeste', run: ch3 },
  { name: 'IV · El tiempo de los colores', run: ch4 },
  { name: 'V · Atiende a tu Configuración', run: ch5 },
  { name: 'VI · El Rey de la Línea', run: ch6 },
  { name: 'VII · El Forastero', run: ch7 },
  { name: 'VIII · Espaciolandia', run: ch8 },
  { name: 'IX · Hacia Arriba, no hacia el Norte', run: ch9 },
  { name: 'X · El juicio', run: ch10 },
];
