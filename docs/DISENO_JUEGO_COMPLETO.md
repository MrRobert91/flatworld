# Planilandia — De demo narrativa a juego completo

**Análisis del contenido actual y propuesta de mejoras, capítulo a capítulo**

| | |
|---|---|
| Versión analizada | `main` @ `30eff92` (versión Godot 4.7, carpeta `godot/`) |
| Objetivo | Un juego corto y muy pulido para Steam: **65–75 minutos** en la primera partida, con la historia completa de *Flatland* (E. A. Abbott, 1884) |
| Documento técnico asociado | [`SDD_JUEGO_COMPLETO.md`](SDD_JUEGO_COMPLETO.md): especificación para implementar todo lo que aquí se propone |
| Convención | Cada mejora lleva un identificador (`P-03`, `C4-02`, `T-07`…) que el SDD reutiliza |

---

## Índice

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Análisis del estado actual](#2-análisis-del-estado-actual)
3. [Pilares de diseño](#3-pilares-de-diseño-el-filtro-de-cada-propuesta)
4. [Estructura objetivo y presupuesto de tiempo](#4-estructura-objetivo-y-presupuesto-de-tiempo)
5. [Sistemas transversales](#5-sistemas-transversales)
6. [Capítulo a capítulo](#6-capítulo-a-capítulo)
7. [Contenido para Steam](#7-contenido-y-requisitos-para-steam)
8. [Revisión de cohesión](#8-revisión-de-cohesión-y-de-diseño)
9. [Lo que se descarta, y por qué](#9-lo-que-se-descarta-y-por-qué)

---

## 1. Resumen ejecutivo

El juego actual es una **adaptación fiel, bien escrita y con una identidad visual muy fuerte** (el cuaderno de dibujo técnico, el ojo 1D). Recorre los 22 capítulos del libro en 11 bloques jugables. Falla en tres cosas:

1. **Se lee mucho más de lo que se juega.** Hay unas 7.700 palabras de diálogo, unos 38 minutos de lectura a 200 palabras por minuto. Las acciones que de verdad piden habilidad o deducción suman **entre 6 y 8 minutos**. El resto es caminar hasta un punto y pulsar «Hablar».
2. **Las mecánicas aparecen una vez y no vuelven.** El tacto se usa una vez (el comerciante) y el oído otra (la voz en la niebla). La lección de la Línea dura un cruce. El ojo 1D, el gran invento del juego, apenas se usa fuera de la Puerta Oeste. Nada de lo aprendido en la Parte I se *usa* en la Parte II.
3. **Las analogías dimensionales se cuentan, no se juegan.** El argumento central del libro —«lo que tú eres para el Rey de la Línea, la Esfera lo es para ti»— está en el texto, pero el jugador nunca lo *ejecuta* con sus manos en los dos sentidos.

La propuesta **no infla el juego con relleno**. Hace tres cosas:

- **Convertir cada idea del libro en un verbo jugable** y hacer que ese verbo vuelva transformado en otra dimensión. Ejemplo: palpar un ángulo en el Plano → calcular una sección en la Línea → predecir una sección en el Espacio.
- **Dar peso a las decisiones** con un expediente oculto que el Consejo lee en el juicio, con personajes que recuerdan lo que les hiciste y con un epílogo jugable en la celda que usa todo lo aprendido.
- **Pulir la experiencia:** mando y Steam Deck, inglés (el texto original de Abbott es de dominio público), historial de diálogo, accesibilidad, logros, cinemáticas de cámara y un marco narrativo (el lector sobre su mesa) que cierra la última analogía: **tú eres el habitante de Espaciolandia que lee el manuscrito**.

Duración resultante: **unos 70 minutos** en la primera partida (≈ 45 % de juego activo), más **10–15 minutos** de contenido opcional (marginalia, modo Colegio, logros).

---

## 2. Análisis del estado actual

### 2.1 Historia y guion

**Estructura.** Once bloques jugables que cubren las 22 secciones del libro, cada una un «fragmento del manuscrito» (`data/book.json`):

| Bloque | Secciones del libro | Contenido |
|---|---|---|
| Prólogo · La celda | §1 | Marco: el Cuadrado escribe preso. La moneda. |
| I · La casa de cinco lados | §2, §4 | Lluvia, Norte, casas, mujeres, herencia. |
| II · La Calle Mayor | §3, §5 | Clases, tacto, oído. |
| III · La Puerta Oeste | §6, §7 | Vista; el calderero Irregular. |
| IV · El tiempo de los colores | §8, §9, §10 | Teatro de la memoria: Cromatistes, la Ley, la matanza. |
| V · Atiende a tu Configuración | §11, §12 | Templo, el niño Equilátero, el Círculo joven. |
| VI · El Rey de la Línea | §13, §14 | Sueño de Linealandia. |
| VII · El Forastero | §15, §16, §17 | Llegada de la Esfera, Analogía, la alacena. |
| VIII · Espaciolandia | §18, §19 | Vuelo, el Consejo, el Cubo, la Cuarta. |
| IX · Hacia Arriba, no hacia el Norte | §20, §21 | Puntolandia; el nieto. |
| X · El juicio | §22 | Sociedad Especulativa, juicio, celda. |

**Lo mejor del guion (hay que conservarlo):**

- **Las voces interiores** (`logica`, `recelo`, `decoro`, `asombro`) funcionan como un coro crítico que comenta lo que el Cuadrado no se atreve a pensar. Es el mejor recurso del juego para que el jugador *piense* sin sermones.
- **El narrador poco fiable desde la celda.** Frases como «Ojalá hubiera dicho eso… Embestí» o «en una celda, la memoria es generosa con uno mismo» resuelven con elegancia la tensión entre la elección del jugador y un final fijo. Es la clave de diseño de todo el juego y la base de varias propuestas.
- **Las rimas internas ya sembradas:** «Eso no es moverse, es un truco de mago» (el Rey) → la misma frase en boca del Cuadrado ante la Esfera; «infinitamente superior… guarda esa frase: volverá»; el 3³ del nieto; la alacena cerrada «por sus cuatro lados».
- **El calderero Irregular**, invención del juego, da un rostro al §7 y anticipa el juicio: «dictaminé su raya con el mismo aplomo con que el Consejo dictaminó la mía».

**Problemas de guion:**

| # | Problema | Dónde |
|---|---|---|
| G1 | **El hermano aparece por primera vez en el Consejo (VIII)**, y su condena es el clímax emocional de la Parte II. Sin presentación previa, el jugador no siente la pérdida. | `ch_d.gd: ch8` |
| G2 | **El nieto** es el personaje más importante (3³, la traición de la risa), pero tiene una sola escena antes de la lección. Su «¡Ja, ja, ja!» duele poco porque no hay vínculo. | I, VII, IX |
| G3 | **Las elecciones se cuentan, pero no cambian nada**: solo alteran 3 o 4 frases del epílogo. Un jugador atento lo nota en el capítulo III. | Todo |
| G4 | **Varias escenas clave se narran en lugar de jugarse**: la excusa del nieto por «la temperatura» (§12) se resume en una conversación con el novicio; los once meses de silencio y el tratado (§22) caben en dos párrafos. | V, X |
| G5 | **La Parte II va mucho más deprisa que la I.** Del capítulo VI al X hay más conceptos nuevos por minuto que en todo el resto. Espaciolandia, el momento cumbre, dura unos 4 minutos. | VI–X |
| G6 | **El final no tiene un remate a la altura.** Los créditos llegan tras un fundido; la dedicatoria del libro («a los habitantes del ESPACIO EN GENERAL») no aparece, y es justo el giro que convierte al lector en el siguiente Cuadrado. | X |

### 2.2 Mecánicas

| Mecánica | Dónde se usa | Profundidad | Diagnóstico |
|---|---|---|---|
| Moverse en el plano (palanca, WASD) | Todo | Media: aceleración, choques reales, pinchazos | Bien hecha. |
| Alternar lámina (desde arriba) / ojo (1D) | Todo | Alta como idea; baja como uso | El ojo es **opcional** casi siempre: el jugador racional juega desde arriba y nunca *necesita* mirar como un planilandés. |
| Reconocimiento por la vista (`sight_round`) | III (7 rondas), IV (1) | Media: traza dorada, niebla | Es la mejor mecánica del juego, pero tiene una sola dificultad, figuras siempre de vértice y sin consecuencia. |
| Reconocimiento por el tacto (`feel`) | II (1 vez) | Baja: mantener E y elegir de una lista | Se introduce y se abandona. El riesgo («despacio: un ángulo agudo hiere») no existe en el juego. |
| Reconocimiento por el oído | II (1 diálogo) | Ninguna: es una elección de texto | Solo se cuenta. |
| Pigmentos y contagio del Color | IV | Baja pero vistosa | Bonita; dura un minuto. |
| Sección en la Línea (`on_line`) | VI (1 cruce) | Baja | El germen de la mejor analogía del juego, desaprovechado. |
| Vuelo libre en Espaciolandia | VIII | Media | Se usa solo para ir de A a B. No hay nada que *hacer* desde Arriba. |
| Analogía numérica (pizarra) | VII, VIII | Baja: test de opción múltiple | Correcta, pero pasiva. |
| «Muévete hacia Arriba» | IX, X | Alta como idea: el control no puede | Muy bueno: el juego niega una dirección al jugador. Hay que conservarlo. |
| Herejía / reputación (`her`, `rep`) | Todo | Visible, pero sin efecto | Sus avisos interrumpen y convierten las elecciones en un juego de puntos («Hacia la herejía»). No cambian nada jugable. |
| Saberes (`learn`) | Todo | Desbloquean 4 opciones de diálogo | Buen sistema, infrautilizado. |
| Fragmentos del manuscrito (`frag`) | Todo | **Todos están en el camino obligatorio** | Las pistas de `book.json` sugieren que se pueden perder, pero no es posible. Es un coleccionable falso. |

### 2.3 Contenido y duración

| Bloque | Duración actual estimada | Juego activo |
|---|---|---|
| Prólogo | 3 min | girar, alternar vista, encarar la moneda |
| I | 5 min | caminar entre 4 conversaciones |
| II | 5 min | 1 tacto, caminar |
| III | 5 min | 7 rondas de vista, 1 dictamen |
| IV | 6 min | 5 pigmentos, pasear, 1 ronda de vista |
| V | 4 min | caminar a la fila |
| VI | 3,5 min | 1 cruce de la Línea |
| VII | 4,5 min | 2 preguntas de aritmética, 1 embestida |
| VIII | 4 min | 3 vuelos, 1 ascenso |
| IX | 3,5 min | acercarse al Punto; la lección |
| X | 4 min | «muévete hacia Arriba» |
| **Total** | **≈ 30–40 min** (según velocidad de lectura) | **≈ 6–8 min** |

### 2.4 Gráficos y presentación

**Fortalezas.** La dirección de arte es el gran activo comercial: tinta sobre papel milimetrado, trazos de construcción, una lámina distinta por mundo (crema, calco, acuarela, gris, cianotipo), sombras duras, el ojo 1D trazado en la GPU, la cámara que se adelanta, la llegada en barrido a Espaciolandia y los fundidos de papel empapado. Se distingue a primera vista en una tienda.

**Carencias:**

- **Las cinemáticas son estáticas.** Las escenas clave (la matanza, la Esfera en el salón, el Consejo) usan casi solo `focus` + `zoom`. Faltan planos con intención: travelling, inclinación de cámara, ritmo de cortes.
- **El ojo 1D no tiene apoyo didáctico en los momentos clave.** Cuando la Esfera crece en el salón, el jugador no ve a la vez la lámina y la línea con la sección marcada.
- **Espaciolandia es la misma lámina vista de lado, con un fondo.** Falta el *vértigo*: la ciudad vista por primera vez *con grosor nulo*, los interiores abiertos como maquetas, las entrañas latiendo.
- **No hay ilustraciones del libro.** Las figuras originales de Abbott (casa pentagonal, mujeres, Linealandia, el Cubo) son de dominio público y encajan perfectamente con la estética.
- **La ciudad está vacía fuera de la Calle Mayor:** no hay aldeas, árboles (el §2 los menciona) ni campo abierto.

### 2.5 Audio

Muy por encima de lo habitual en un juego indie de este tamaño: música generativa por estado de ánimo, capa de tensión dinámica, lluvia continua, murmullo de voz. Le faltan **audio posicional** (el Grito de Paz, la clave del §4, no tiene dirección), **firmas sonoras de mundo** (Linealandia debería *sonar* a una sola dimensión: todo por un único canal) y **temas reconocibles**: un leitmotiv para la Esfera, otro para el hermano y otro para el nieto.

### 2.6 Interfaz y controles

**Bien resuelto:** escalado por puntos del dispositivo, diálogos paginados, palanca flotante, menú de pausa, tamaños de letra, tres tipografías.

**Carencias:**

| # | Carencia | Impacto en Steam |
|---|---|---|
| U1 | **No hay soporte de mando** (ninguna referencia a `Joypad` en el código). | Bloqueante: el sello «Verificado» de Steam Deck exige mando completo y glifos correctos. |
| U2 | No hay historial de diálogo ni auto-avance; no se pueden saltar textos ya leídos. | Muy pedido en juegos narrativos y necesario para rejugar. |
| U3 | Los avisos de reputación y herejía aparecen en cada elección e interrumpen la lectura. | Ruido y sensación de juego de puntos. |
| U4 | No se pueden reasignar teclas. | Accesibilidad. |
| U5 | El capítulo IV depende de **rojo frente a verde**, el par que confunden los daltónicos más comunes. | Accesibilidad. Además, se puede resolver *dentro de la ficción* (ver `C4-07`). |
| U6 | Solo español. | El mercado hispanohablante es una fracción de Steam. **El inglés es imprescindible**, y el texto fuente es de dominio público. |
| U7 | Hay un solo hueco de guardado y «Nueva partida» lo borra. | Rejugar para ver otras elecciones obliga a perder la partida. |

### 2.7 Resumen del diagnóstico

> La base técnica y artística es excelente y el guion es fiel y con voz propia. Lo que falta es **diseño de juego**: que cada idea del libro pase por las manos del jugador al menos dos veces, en dos dimensiones distintas, y que lo que el jugador hace deje huella.

---

## 3. Pilares de diseño (el filtro de cada propuesta)

Cada mejora de este documento cumple al menos dos de estos pilares. Lo que no los cumple está en la sección 9.

1. **Verlo es entenderlo.** Cada idea dimensional se *juega*, no se lee. Si un concepto solo existe como diálogo, falta una mecánica.
2. **Toda lección rima.** Lo que el Cuadrado aprende en el Plano vuelve una dimensión arriba o abajo: el jugador hace con el Rey de la Línea lo que la Esfera le hará a él.
3. **Enseñar → practicar → girar → pagar.** Cada mecánica se presenta sin riesgo, se practica, recibe un giro que la complica y vuelve en la Parte II con un significado nuevo.
4. **Fidelidad.** Lo que se añade viene del libro (se cita la sección) o es una consecuencia directa de sus reglas. El texto de Abbott manda sobre cualquier invención.
5. **La celda recuerda.** Las decisiones no cambian el destino (el libro tiene un final), pero sí *quién lo acompaña, qué recuerda y cómo lo cuenta*. El narrador poco fiable es el sistema de consecuencias.
6. **Pulido antes que cantidad.** Nunca más de **90 segundos de texto sin una acción del jugador**. Cada pantalla responde a cada entrada.

---

## 4. Estructura objetivo y presupuesto de tiempo

Se mantienen los once bloques (son los capítulos del menú) y se añade un **marco** (apertura y cierre en la mesa del lector).

| Bloque | Actual | Objetivo | Juego activo objetivo | Mecánica estrella nueva |
|---|---|---|---|---|
| Apertura · La mesa del lector | — | 1,5 min | cámara | Descenso al papel (`P-01`) |
| Prólogo · La celda | 3 | 4 | 60 % | La moneda que se inclina (`P-03`) |
| I · La casa | 5 | 7 | 45 % | El juego de los ángulos con el nieto: tacto sin riesgo (`C1-03`) |
| II · La Calle Mayor | 5 | 7,5 | 50 % | Cruzar la calle por el oído (`C2-02`) |
| III · La Puerta Oeste | 5 | 7,5 | 60 % | Rondas de vista con giro y Círculo de incógnito (`C3-01`); volver a casa sin lámina (`C3-05`) |
| IV · Los colores | 6 | 8 | 45 % | «¿Mujer o Sacerdote?» (`C4-04`) |
| V · El Templo | 4 | 6,5 | 35 % | El hermano (`C5-01`); la excusa del nieto, jugada (`C5-04`) |
| VI · Linealandia | 3,5 | 7 | 55 % | Hazte tan largo como la Reina (`C6-03`); la vista del Rey (`C6-01`) |
| VII · El Forastero | 4,5 | 6,5 | 40 % | Predecir la sección de la Esfera (`C7-02`); abrir la alacena (`C7-04`) |
| VIII · Espaciolandia | 4 | 9,5 | 60 % | Ver por dentro y coger desde Arriba (`C8-02`, `C8-03`); secciones y sombras del Cubo (`C8-05`, `C8-06`) |
| IX · Puntolandia y el nieto | 3,5 | 5 | 40 % | La vista del Punto (`C9-01`) |
| X · El juicio y la celda | 4 | 7,5 | 45 % | Dibujar el Cubo (`C10-04`); siete años de visitas (`C10-06`) |
| Cierre · La mesa del lector | — | 1,5 min | cámara | La dedicatoria (`C10-08`) |
| **Total** | **≈ 35** | **≈ 79 lectura pausada / ≈ 68 lectura rápida** | **≈ 48 %** | |

Opcional: marginalia (≈ 8 min), modo Colegio (≈ 5–10 min), segunda partida para ver otras ramas.

**Curva de intensidad** (de 1, calma, a 5, clímax): Prólogo 2 · I 1 · II 2 · III 3 (el calderero) · IV 5 (la matanza) · V 2 · VI 3 · VII 4 · VIII 5 · IX 3 (el nieto) · X 4 → celda 2 → cierre 3. Alterna picos y valles, como el libro: dos cumbres (IV y VIII) y un descenso final melancólico.

---

## 5. Sistemas transversales

### T-01 · El expediente (sustituye a los avisos de herejía y reputación)

- **Qué:** el contador `her` y las tres reputaciones (`sac`, `ciu`, `aut`) siguen existiendo por dentro, pero **dejan de anunciarse con avisos**. En su lugar, cada decisión significativa añade una **anotación** a un expediente que el jugador no ve hasta el juicio. La anotación lleva quién la escribió, la fecha (días del año 1999) y la frase: «Día 362. Puerta Oeste. El perito Cuadrado cuestiona la consunción de un Irregular. —Inspector de Configuración».
- **Señal diegética:** cuando se apunta algo, un personaje cercano hace el gesto (el Inspector rasca su tablilla) y suena un trazo de punzón. No hay texto en pantalla. Ya existe un precedente perfecto: «Ha apuntado algo en su tablilla. No era el ángulo del calderero.»
- **Pago:** en el capítulo X el Presidente **lee el expediente** (las 3–5 entradas de más peso) antes de la primera pregunta (`C10-03`). El jugador descubre que el Estado lo observaba desde el capítulo III.
- **Por qué:** quita el «juego de puntos», da peso a las decisiones y es fiel al §22: el Cuadrado ya era sospechoso antes de hablar.

### T-02 · Personas que recuerdan (relaciones)

Se sustituye la «Posición social» abstracta del inventario por **siete relaciones con nombre**: esposa, nieto, hija, hermano, criado, calderero y archivero. Cada una tiene de −2 a +2 y una frase de estado en el inventario («Tu nieto: te mira como a quien sabe cosas»). Efectos concretos:

| Relación | Efecto |
|---|---|
| Nieto ≥ +1 | En el IX, antes de reírse, duda: «Abuelo… ¿de verdad?» (dos segundos de silencio, luego la risa). La traición duele más. |
| Hija ≥ +1 (aprendió a contar) | En la celda, el Cuadrado recibe una tablilla con diez muescas, sin firma. |
| Criado ≥ +1 | El hijo del criado (10,5°) dice su nombre bajo el muro (ya existe con `rep.ciu`, se reasigna). |
| Calderero (según el dictamen) | En el VIII, desde Arriba, el jugador lo ve en el Hospital (`C8-04`): vivo y reconfigurado o en la sala de consunción. |
| Archivero ≥ +1 | En el X le presta al Cuadrado una tablilla en blanco para el tratado (`C10-01`). |
| Hermano | Tono de las visitas en la celda (`C10-06`). |

### T-03 · Marginalia (coleccionables con sentido)

- **Qué:** 30 notas opcionales, unas 3 por capítulo, que el Cuadrado escribe **al margen** del manuscrito. Se descubren al examinar detalles que no están en el camino obligatorio y cada una amplía un hecho del libro. Se listan en cada capítulo de la sección 6.
- **Se señalan** con un brillo de tinta muy leve en la lámina, solo visible a menos de 6 unidades, y en la línea del ojo con una marca de vértice. Así recompensan mirar con el ojo.
- **Los fragmentos del manuscrito siguen siendo obligatorios** (son la historia). Se corrigen las pistas de `book.json` que sugieren lo contrario.
- **Pago:** completar las marginalia de un capítulo desbloquea su **lámina ilustrada** (`T-08`) en la galería, y completar todas da un logro y una línea extra en la celda: «He llenado los márgenes. Nadie lee los márgenes. Por eso escribo en ellos».

### T-04 · La tabla de analogías (pestaña nueva del inventario)

El corazón didáctico del juego. Una tabla que **se rellena sola** a medida que el jugador vive cada mundo:

| | Puntolandia (0D) | Linealandia (1D) | Planilandia (2D) | Espaciolandia (3D) | ¿4D? |
|---|---|---|---|---|---|
| Habitante | el Punto | el Rey | el Cuadrado | la Esfera | ? |
| Cómo ve | nada fuera de sí | un punto | una línea | una superficie con luz y sombra | ? |
| Límites | 0 | 2 puntos | 4 lados | 6 caras | 8 cubos |
| Lo que no puede concebir | el Dos | el costado | el Arriba | la Cuarta | ? |
| Su frase de rechazo | «Ello inventa palabras sin objeto» | «Eso es un truco de mago» | «¿Cómo va a moverse algo hacia Arriba y no hacia el Norte?» | «Visiones del cerebro» | ? |
| Qué ve quien llega de arriba | su voz dentro de sí | una línea que aparece y desaparece | un círculo que crece y mengua | ? | |

- Las celdas se rellenan en el momento exacto en que el jugador lo *vive*, con una animación de pluma. La columna «¿4D?» se rellena en el VIII, con el teseracto, y su última celda queda en «?» para siempre.
- Las celdas de la fila «Qué ve quien llega de arriba» son **pequeñas animaciones en bucle**, no texto.
- En la celda (`C10-06`), la tabla es el «arsenal» de argumentos con los que el Cuadrado intenta convencer a su hermano.

### T-05 · Tres lentes y un indicador de «visión»

El botón de vista (V / botón del ojo / Y en el mando) alterna entre lentes según el mundo:

| Mundo | Lentes disponibles |
|---|---|
| Planilandia | Lámina (desde arriba) · Ojo (línea 1D) |
| Linealandia | Lámina · Ojo del Cuadrado (línea) · **Ojo del Rey** (un punto, `C6-01`) |
| Espaciolandia | Vuelo libre · Ojo del Cuadrado proyectado sobre el plano (para ver lo que ven los de abajo) |
| Puntolandia | **Ojo del Punto**: la pantalla entera de un solo color (`C9-01`) |

Además, **se hace necesario el ojo en momentos concretos**: en las escenas con `view_lock` el juego decide la lente, y en cuatro retos (II, III, IV y X) se juega *sin lámina* (ver cada capítulo). Así el ojo deja de ser un adorno opcional.

### T-06 · Leitmotivs y audio posicional

- **Tres temas** cortos (4–6 notas), tocados por el secuenciador generativo dentro del modo de cada escena: **la Esfera** (intervalo de quinta ascendente, con campana), **el hermano** (una tercera menor descendente, con cuerdas) y **el nieto** (un arpegio de celesta que sube y no resuelve: la pregunta sin respuesta). Sonarán transformados: el tema del nieto, invertido, en su risa del IX; el del hermano, solo y lento, en la celda.
- **Audio posicional** para el Grito de Paz, las voces en la niebla y los heraldos: panorama y volumen según la posición relativa al ojo del jugador. Es imprescindible para `C2-02` y `C3-05`.
- **Firma sonora de mundo:** en Linealandia toda la mezcla pasa a **mono** (una sola dimensión de sonido) y en Espaciolandia se abre a estéreo amplio con reverberación larga. El jugador *oye* la dimensión sin que nadie se lo explique.

### T-07 · Cámara y cinemáticas

Una pequeña herramienta de raíles de cámara (detallada en el SDD) para planos con intención. Reglas de estilo:

- **Planilandia:** fuera de la transición lámina↔ojo (que baja la cámara *al* plano y es la mirada del planilandés), la cámara nunca se inclina. El Plano se filma desde arriba, como una lámina: travelling paralelo al papel y zoom.
- **Espaciolandia:** la cámara se inclina *libremente* por primera vez, y orbita. Esa primera vista oblicua coincide con el primer «Arriba» del Cuadrado. **Reservar la vista oblicua para la tercera dimensión** es la regla de cámara más importante del documento.
- **Excepción deliberada:** el Prólogo hace una órbita lenta alrededor de la moneda (`P-03`) y la apertura desciende desde la mesa (`P-01`). Ambas son el punto de vista del lector, que es tridimensional.
- **Franjas de cine** (bandas negras arriba y abajo) solo en las escenas que no admiten control. Se saltan manteniendo pulsado (1 s) el botón de avanzar.

### T-08 · Láminas de Abbott (interludios ilustrados)

Al empezar cada bloque, en lugar del rótulo de capítulo solo, aparece una **lámina ilustrada** de 6–10 segundos: una de las figuras originales del libro (dominio público) **trazada a pluma en tiempo real** sobre el papel del capítulo, con el rótulo debajo. Se salta con un toque. Lista:

| Bloque | Lámina |
|---|---|
| Prólogo | La moneda vista desde arriba y de canto |
| I | La casa pentagonal con sus dos puertas (figura del §2) |
| II | La escala de las clases, del Isósceles al Círculo |
| III | Un ángulo en la niebla: los lados que se apagan (figuras del §6) |
| IV | Una mujer mitad roja, mitad verde, junto a un Sacerdote igual |
| V | El Templo y sus filas |
| VI | Linealandia: la Recta con las Líneas y los Puntos (figura del §13) |
| VII | La Esfera atravesando el plano: tres secciones apiladas (figura del §16) |
| VIII | Punto → Línea → Cuadrado → Cubo |
| IX | Un punto solo en el centro de la lámina |
| X | El dibujo del Cubo que el Consejo no entiende |

Las láminas quedan en la **galería** del menú, junto a las de las marginalia.

### T-09 · Diálogo y lectura

- **Historial** (pestaña del inventario y botón en la pausa) con las últimas 200 intervenciones, con color e icono del personaje.
- **Auto-avance** opcional (tiempo proporcional a la longitud del texto) y **velocidad de texto** (lenta, normal, rápida, instantánea).
- **Saltar texto ya leído** (mantener pulsado): solo avanza rápido por las líneas que ya se vieron en cualquier partida. Imprescindible para rejugar.
- **Elecciones con memoria:** en una segunda partida, las opciones ya elegidas alguna vez llevan una marca discreta (un punto de tinta).
- **Nada de avisos por elección** (`T-01`). Solo quedan dos: «Manuscrito · sección n» y «Nuevo saber».

### T-10 · Controles

- **Mando completo** (Xbox, PlayStation, Switch Pro y Steam Deck) con glifos dinámicos que cambian según el último dispositivo usado.

  | Acción | Teclado | Mando |
  |---|---|---|
  | Mover | WASD / flechas | stick izquierdo |
  | Girar (en el ojo) | A / D | stick izquierdo X o stick derecho X |
  | Acción / palpar | E | A / Cruz |
  | Lente (vista) | V / Tab | Y / Triángulo |
  | Inventario | J | Menú (Options) |
  | Pausa | Esc | Ver (Share) |
  | Subir / bajar (Espacio) | R / F | RB / LB |
  | Mirar (Espacio) | ratón | stick derecho |
  | Avanzar texto | Espacio / clic | A |
  | Historial | H | stick derecho, pulsado |

- **Vibración con significado:** el tirón del Sur (`C3-05`), los pinchazos, el toque en las entrañas (VII) y el «¡SILENCIO!» de la Esfera (ya existen `vibrate_handheld`; se amplía a mando).
- **Reasignación de teclas** en ajustes.
- **Modo de giro en el ojo:** con la vista de ojo, el stick izquierdo pasa a controles de tanque (girar y avanzar), que ahora solo funcionan bien con teclado.

### T-11 · Accesibilidad

- **Patrones además de color** en todo el capítulo IV (`C4-07`), activados por defecto.
- **Subtítulos de sonido** para pistas que solo se oyen: «(Grito de Paz, a tu izquierda)», «(una voz redonda, al frente)». Activados por defecto en `C2-02` y `C3-05`, con un indicador de dirección en el borde de la línea del ojo.
- **Reducir movimiento:** desactiva la sacudida y el latido de cámara y suaviza los barridos de Espaciolandia.
- **Dificultad de deducción** (relajada / normal / perito) para las rondas de vista, tacto y secciones: más tiempo, la traza dorada siempre visible y una segunda oportunidad. «Perito» oculta la traza y da logros propios.
- **Mantener pulsado o pulsar una vez** para las acciones que exigen mantener (palpar, subir).

### T-12 · Guardado

Tres huecos de partida, autoguardado al empezar cada bloque y en cada fragmento, y **Steam Cloud**. «Nueva partida» pide un hueco y nunca borra sin confirmar. La selección de capítulos se desbloquea por perfil (no por partida), para poder revisitar escenas.

---

## 6. Capítulo a capítulo

Formato de cada capítulo: **lo que hay**, **lo que funciona**, **lo que falla** y las **mejoras** numeradas, con el detalle suficiente para implementarlas. Las citas de sección se refieren al libro (Parte I: §1–12; Parte II: §13–22).

---

### Apertura · La mesa del lector *(nuevo)*

**P-01 · El descenso al papel.** Plano 3D (es lo único en 3D antes del capítulo VIII): una mesa de madera a la luz de una lámpara, un libro abierto con la portada de *Flatland* (1884) y una hoja de papel milimetrado al lado. La cámara —el lector— baja despacio hacia la hoja, que llena el encuadre. Al tocarla, la cámara se **endereza en vertical** y la imagen se convierte en la lámina de la celda vista desde arriba. Dura 25 segundos y solo se ve en la primera partida; después se puede saltar.

- **Por qué:** cierra el bucle de la analogía. El jugador es tridimensional y mira el Plano desde Arriba, como la Esfera. Todo lo que el juego llama «lámina» es, literalmente, la vista del lector.
- **Texto** (sobreimpreso, en la tipografía caligráfica): la dedicatoria del libro, abreviada: «*A los habitantes del ESPACIO EN GENERAL… para que aspiren más y más alto a los secretos de CUATRO, CINCO o incluso SEIS Dimensiones.*» En el cierre (`C10-08`) aparece completa.
- **Audio:** la lámpara zumba, el reloj de la habitación suena y, al entrar en el papel, todo se vuelve seco y cercano. El sonido también «pierde una dimensión».

---

### Prólogo · La celda (§1)

**Lo que hay.** Celda cuadrada. El Cuadrado narra; el jugador gira en el ojo, pasa a la lámina y mira la moneda de canto. Fragmento 1, saber «linea». La tablilla.

**Lo que funciona.** El primer minuto solo con la línea es un gancho excelente. «Disfrútala con un poco de culpa» define el tono.

**Lo que falla.** La transición lámina→ojo ya inclina la cámara hasta el plano, pero dura 0,8 s y no se centra en la moneda: no da tiempo a ver el círculo convertirse en elipse y luego en raya, que es el argumento entero. No hay gancho narrativo hacia delante: ¿por qué está preso? Los controles se explican todos a la vez.

**Mejoras:**

- **P-02 · El recuento de los siete años.** En la pared de la celda, 7 grupos de muescas (la lámina las muestra como rayas de tiza en la pared). Examinarlas da la marginalia «Las muescas»: «Siete años. Al principio contaba días; luego, visitas de mi hermano; ahora cuento solo años, que son menos y pesan igual». Presenta al hermano en la primera línea del juego, lo que resuelve en parte el problema `G1`.
- **P-03 · La moneda que se inclina.** Esa primera vez, la transición lámina→ojo es una **versión lenta y centrada**: 3,5 s en lugar de 0,8, con la cámara orbitando *alrededor de la moneda* (no del Cuadrado) y bajando de la vertical a la horizontal, mientras la moneda pasa de círculo a elipse y de elipse a raya. Tres marcas de tiza aparecen al vuelo junto a la moneda («círculo», «elipse», «línea»). Al llegar a la horizontal, un fundido cruzado la sustituye por la línea del ojo, que muestra exactamente esa raya. El jugador ve la *transformación* con sus ojos de lector. Las transiciones siguientes vuelven a la duración normal.
- **P-04 · El gancho del juicio.** Tras la tablilla, una frase de 4 segundos en negro, con la voz del Presidente: «*Sea tan amable de indicarnos esa dirección.*» Corte. El jugador no sabe aún qué significa. Se paga en el X.
- **P-05 · Tutorial escalonado.** Las instrucciones de control aparecen **una a una**, cuando hacen falta: girar → avanzar → cambiar de lente → acción. Cada una se oculta al usarla, nunca por tiempo.
- **P-06 · La tablilla habla de ti.** La última línea, «Cuando esté completo, quizá alguien, en Alguna Dimensión, lo lea», pasa a ser: «…quizá alguien, en Alguna Dimensión, lo lea. Quizá ya me estás leyendo». Un guiño breve y fiel al tono de Abbott, que se dirige a sus «felices lectores».

**Marginalia:** las muescas (`P-02`) · la puerta de la celda, sin cerradura por dentro («¿Para qué? Adónde iría un Cuadrado que ha visto el Arriba») · el cántaro de agua, que en la lámina se ve *por dentro* (la primera vez que el jugador ve un interior que el Cuadrado no puede ver).

---

### Capítulo I · La casa de cinco lados (§2, §4)

**Lo que hay.** Recorrido por la casa con cuatro conversaciones obligatorias (tejado, nieto, esposa, criado) y tres opcionales (hija, hijo, alacena). Saberes: norte, casas, mujeres, herencia.

**Lo que funciona.** La casa está muy bien escrita. La esposa en el ojo («Cuando gira hacia ti, desaparece») es un gran momento. El aviso de la puerta del Este es un buen detalle.

**Lo que falla.** Es un museo de conversaciones: el jugador camina de cartel en cartel. El nieto tiene 6 líneas y es el personaje más importante de la historia. La alacena es opcional, pero su pago (VII) es obligatorio: muchos jugadores no la habrán visto.

**Mejoras:**

- **C1-01 · La alacena, obligatoria e inventariada.** Se añade al grupo obligatorio. El jugador la abre con la llave (acción mantenida, sonido de cerrojo) y, **desde la lámina**, ve dentro: dos cofres, **dos tablillas**. El Cuadrado no puede verlo («Cerrada por sus cuatro lados»), pero el jugador sí, porque es tridimensional. La voz `asombro` se reserva para la segunda partida, como ya ocurre.
- **C1-02 · La lluvia que orienta.** En la primera salida al tejado, la lámina muestra las gotas cayendo **siempre de Norte a Sur**. La voz `logica` invita a «cerrar la lámina y orientarte solo por la lluvia»: en el ojo, cada gota es un **centelleo** fugaz en la línea, y como todas caen hacia el Sur, el centelleo **se desliza**: mirando al Este, de izquierda a derecha; mirando al Oeste, al revés; mirando al Norte, se queda quieto y se aviva (las gotas vienen hacia ti). Es física real del Plano, no un icono. Ejercicio sin riesgo de 20 segundos («mira al Norte»), que prepara `C3-05`.
- **C1-03 · El juego de los ángulos (tutorial de tacto sin riesgo).** El nieto tiene unas **figuras de juguete** de madera, romas: triángulo, cuadrado, pentágono y hexágono. Te propone su juego: «Yo te pongo una delante, tú la palpas con los ojos cerrados y adivinas». Tres rondas de `feel()` con la lámina y el ojo bloqueados (pantalla en negro con solo el arco del ángulo dibujándose). Si palpas deprisa, el nieto se ríe: «¡Así, en la calle, te pinchas!». Sustituye la conversación actual del nieto (las líneas buenas se conservan). Ganancia triple:
  1. presenta el tacto sin riesgo antes del comerciante (ver *enseñar → practicar → girar*);
  2. da al nieto una escena de juego compartido, la base del vínculo (`G2`);
  3. siembra la idea de «adivinar una figura sin verla», que es literalmente lo que el Cuadrado intentará hacer con el Cubo.
- **C1-04 · La hija aprende a contar (opción herética jugable).** Si eliges «Cuando tu madre no mire. Hasta diez», empieza un minijuego de 30 segundos: el Cuadrado pone diez guijarros en fila (pulsar una vez por guijarro, con ritmo) y la hija cuenta en voz alta. Si la madre pasa por el pasillo (patrulla visible en la lámina), hay que **parar** a tiempo. Si te descubre, la esposa dice: «¿Qué le estás enseñando a la niña?» y elige el jugador: mentir («A menearse») o la verdad. Esto alimenta el expediente (`T-01`) y la relación con la hija (`T-02`), y paga en la celda la tablilla de diez muescas.
- **C1-05 · La esposa, con su ritmo.** Antes de su conversación, la esposa se acerca **de punta** por el pasillo de los aposentos. En el ojo es un punto que tiembla y en la lámina se ve venir. El Grito de Paz suena posicional (`T-06`). Si el jugador no se aparta, sufre un pinchazo leve (ya implementado) y la esposa dice: «¡Esposo! ¿No me oías?». Es una presentación de 10 segundos del peligro que luego es mecánica en `C2-02`.
- **C1-06 · La casa respira.** Rutinas visibles en la lámina: los hijos salen por la puerta Oeste a sus consultas, el criado barre la entrada y los nietos juegan a perseguirse. Cuesta poco (`stroll` ya existe) y transmite «hogar» antes de que el Cuadrado lo pierda.

**Marginalia:** la puerta del Este, de cerca («Estrecha. Ellas entran de lado; nosotros no entraríamos ni de lado») · el reloj de arena del salón (reaparece en el VII) · el libro de cuentas del criado, con su ángulo escrito al margen por un inspector.

---

### Capítulo II · La Calle Mayor (§3, §5)

**Lo que hay.** Calle con paseantes, tres encuentros obligatorios (el noble, el comerciante con el tacto, la voz en la niebla) y varios opcionales (dama, obrero, médico, tendero, soldado, calderero). Saberes: clases, tacto, oído.

**Lo que funciona.** El noble explicando la escala de clases es una gran escena. La voz falsa del Isósceles es una idea perfecta. El calderero devolviendo el estilete prepara el capítulo III.

**Lo que falla.** El oído es solo una elección de texto. Las mujeres de la calle no son un peligro jugable, cuando todo el §4 trata de eso. La calle no tiene un «reto» propio.

**Mejoras:**

- **C2-01 · La escala de clases, viva.** Mientras el noble explica la jerarquía, la cámara hace un **travelling lateral** por la calle y se detiene en un ejemplo de cada clase que pasa en ese momento (las figuras son reales, no ilustraciones). Al terminar, la escala se dibuja en el inventario («Nuevo saber: la escala de las figuras») como diagrama, no como texto.
- **C2-02 · Cruzar la calle por el oído (reto nuevo).** Para llegar a la tienda del comerciante hay que cruzar la Calle Mayor **en vista de ojo** (la lámina se bloquea: «el comerciante está en la otra acera, y la niebla de hoy no deja ver ni un ángulo»). Por la calle pasan tres mujeres; de canto se ven como líneas, pero de punta casi desaparecen. Lo que el jugador tiene para orientarse:
  - el **Grito de Paz posicional** (`T-06`), más fuerte cuanto más cerca, con panorama izquierda y derecha;
  - el **vaivén**, que al menearse hace parpadear el punto en el ojo;
  - **subtítulos de sonido** con dirección (`T-11`).

  Si te pinchan, retrocedes, sufres un aturdimiento leve y la voz `decoro` comenta: «Por esto existe la ley». No hay derrota: se repite desde la acera. Duración: 45–90 segundos. Es **el §4 hecho juego**: el jugador entiende *con el cuerpo* por qué Planilandia obliga a gritar y a menearse.
- **C2-03 · El comerciante, con riesgo de verdad.** El `feel()` del comerciante recibe el giro: **si mantienes la acción demasiado rápido** (más de un umbral de velocidad), el comerciante «da un respingo» y te pincha (`g.hurt`). Ya existe el texto «Despacio: un ángulo agudo hiere»; ahora es verdad. Primero practicado con el nieto (`C1-03`), ahora con riesgo.
- **C2-04 · Presentación entre caballeros (§5).** Escena opcional: el médico te presenta a un colega («Permítame pedirle que palpe y sea palpado por mi amigo el señor Pentágono»). Hay que elegir en orden las fórmulas de cortesía correctas (tres pasos); si fallas el orden, el colega se ofende y lo apunta en tu expediente. Es corta, cómica y fiel: el libro describe la presentación como el método de las clases altas.
- **C2-05 · La voz en la niebla, jugada.** El encuentro de «la voz» pasa a ser un reto de oído: **tres voces** se acercan en la niebla (posicionales) y solo una es de un Hexágono de verdad. Las otras dos son Isósceles que imitan la voz. La pista es diegética: las voces altas *imitadas* tiemblan en las notas largas, porque «el Isósceles empuja la garganta» (efecto de vibrato en la síntesis). Debes apartarte ante la verdadera y no ante las falsas. Acertar da el saber «oído» con el texto actual; fallar da el mismo saber con el comentario de `logica` ya escrito («El oído, solo, no es de fiar»).
- **C2-06 · El Hospital, desde fuera.** Si el jugador se acerca al Hospital de Reconfiguración, oye a través del muro un golpe rítmico (compresiones) y un quejido. Un celador Pentágono en la puerta: «Aquí no se entra sin volante, caballero». Es una marginalia que siembra `C8-04`.
- **C2-07 · Los árboles y el camino de las aldeas (§2).** Al oeste de la Puerta, fuera de la ciudad, se añade un tramo de campo abierto con **árboles** (líneas verticales en la lámina, «más oscuros que los muros, sin tejado») y la marginalia del §2 sobre los viajeros que esperan la lluvia para orientarse. Ese tramo se usa en `C3-05`.

**Marginalia:** el puesto de un charlatán que vende «polvos para crecer un lado» (el tendero lo desmiente) · el banco de piedra donde se sienta el calderero, con cuarenta años de marcas · un cartel de la Junta Sanitaria con la tabla de ángulos legales.

---

### Capítulo III · La Puerta Oeste (§6, §7)

**Lo que hay.** Dos rondas de práctica y cinco reales de reconocimiento por la vista; el dictamen del calderero; el Inspector; la elección moral; la vuelta a casa.

**Lo que funciona.** Es el mejor capítulo jugable. La traza dorada es una gran ayuda didáctica. La escena del calderero es la más fuerte de la Parte I.

**Lo que falla.** Todas las figuras llegan de vértice, quietas y en el mismo orden. No hay presión ni sorpresas. La vuelta a casa es un `go_to` sin contenido.

**Mejoras:**

- **C3-01 · La cola de la Puerta: rondas con giro.** Las cinco rondas reales pasan a ser **ocho**, en tres tandas:
  1. **De vértice, quietas** (como ahora): Mujer, Cuadrado, Isósceles.
  2. **Girando:** la figura gira lentamente al acercarse (`wobble` alto), así que a veces muestra un lado y a veces un vértice. El jugador debe **esperar el momento** en que la traza muestra el vértice, o deducir la figura del lado. Pentágono, Hexágono.
  3. **De incógnito:** un Círculo viene envuelto en una capa de viaje que oculta su brillo; en el ojo es casi indistinguible de un Polígono de muchos lados. Hay una opción nueva: «**Inclinarse**» (la reverencia ante un posible Círculo). El libro es claro: confundir a un Círculo es una ofensa grave. Si lo tomas por un Hexágono, el Círculo se descubre: «Hexágono, me ha llamado», y se anota en tu expediente. Si te inclinas ante quien no lo merece, el sargento se ríe.

  La **cola** es visible: tras cada ronda, la siguiente figura espera en la niebla (en la lámina se ve la fila) y suena una campanilla si tardas más de 15 segundos. Hay presión, pero no castigo.
- **C3-02 · Puntuación del perito.** El sargento lleva la cuenta en su tablilla (aparece como una fila de muescas en el borde de la línea del ojo). Al final da una nota con tres tramos, como ahora, más una cuarta: «Ocho de ocho sin la traza: ni en el Colegio» (logro «Ojo de Colegio», `T-11` modo perito).
- **C3-03 · El dictamen con ironía dramática.** Durante el dictamen del calderero, la cámara hace un **plano partido** durante 3 segundos: arriba, la línea del ojo (lo que ve el Cuadrado); abajo, la lámina (lo que ve el jugador: tres lados desiguales). El jugador *sabe* la verdad que el Cuadrado tiene que decidir si dice. Luego desaparece la mitad de abajo y se elige.
- **C3-04 · Una segunda mirada al calderero.** Si el jugador lo trató con amabilidad en el II, el calderero, mientras se lo llevan, **deja caer algo**: el estilete del Cuadrado, que vuelve a recibir. Se convierte en el **objeto de inventario «el estilete del calderero»**, que reaparece en el VIII (desde Arriba, el Cuadrado lo puede dejar en la celda del Hospital: `C8-04`) y en el X (en el expediente: «Se halló en su poder un estilete de un Irregular»).
- **C3-05 · Volver a casa sin lámina (reto de orientación, §2).** Anochece y la niebla se cierra. La voz `decoro`: «Un caballero no camina por la calle con la mirada en otra Dimensión», y la lámina queda **bloqueada**: solo el ojo. Hay que volver desde la Puerta Oeste a casa, unos 40 metros con dos giros, usando lo enseñado en `C1-02` y `C2-02`:
  - la **lluvia**, que empieza a mitad del trayecto, indica el Norte (el centelleo que se desliza o se queda quieto, de `C1-02`);
  - el **tirón al Sur**, que es una leve deriva del movimiento hacia el Sur y una vibración muy suave en el mando;
  - las **voces** de la calle (posicionales), cada vez menos;
  - el **Grito de Paz de tu esposa** al acercarte a la casa: te espera en la puerta del Este, como guía final.

  Sin derrota: si pasan 90 segundos, el criado sale a buscarte con un farol (una voz que te llama). Fiel al §2 («me he visto obligado a quedarme quieto durante horas, esperando la lluvia») y muy evocador: el jugador vive la ceguera cotidiana del planilandés justo después de haber juzgado a otro por lo que se ve.
- **C3-06 · La cena tarde (puente).** Al llegar, una escena de 20 segundos: la esposa, la cena fría y el nieto despierto. «¿Qué has hecho hoy, abuelo?» Elige: contar lo del calderero o callar. Si lo cuentas, el nieto pregunta: «¿Y si el calderero viera con otros ojos, abuelo? ¿Y si desde algún sitio se le viera regular?». Siembra el capítulo VIII.

**Marginalia:** el registro del sargento, con las faltas de ortografía de un Isósceles · un Polígono del Colegio que practica a escondidas en la Puerta · la piedra miliar del camino de las aldeas.

---

### Capítulo IV · El tiempo de los colores (§8, §9, §10)

**Lo que hay.** El Colegio y el archivero; el Teatro de la memoria como Cromatistes (pigmentos, contagio del color, ver en color con el ojo); el tribuno y la Ley; el fraude del Isósceles pintado; Pantociclo; la matanza; la vuelta.

**Lo que funciona.** Es el capítulo más espectacular. La línea del ojo en color es un gran momento visual. La matanza está bien coreografiada. El fraude con `sight_round` es una gran elección de diseño.

**Lo que falla.** El Colegio es solo un pasillo hasta el archivero. La Ley del Color se explica, pero el jugador no **vive** su peligro (no distinguir a una mujer de un sacerdote). Hay un problema de accesibilidad con el rojo y el verde.

**Mejoras:**

- **C4-01 · El examen final del Colegio (opcional, con nueva lente).** En el Colegio, un tribunal examina a un estudiante: distinguir un **Decágono de un Dodecágono en movimiento**. El jugador puede presentarse como «oyente» a hacer el examen: tres rondas de `sight_round` con Polígonos de 10, 11 y 12 lados que se mueven en arco. Es dificilísimo y se nota. Da la marginalia «Tres años para esto» y el logro «Tribunal del Colegio». Demuestra *por qué* el Color fue un alivio: lo que en gris es casi imposible, en color es trivial.
- **C4-02 · El primer color, escena de cámara.** Cuando Cromatistes elige su primer pigmento, la cámara se acerca hasta que el primer lado coloreado llena media pantalla y suena un acorde mayor que la música nunca ha tocado antes en el juego (el modo `color`). Es el primer color de un mundo gris. Debe *sentirse* como tal.
- **C4-03 · Ver en color: la comparación.** En la vista de ojo del mercado pintado, la lente alterna en bucle (lenta, dos veces) entre **la línea gris** y **la línea en color** de la misma escena. El jugador ve lo que se ganó en un solo vistazo. La voz `asombro`: «Ahora lo ves todo a la primera. Tú, que tardaste años en el Colegio».
- **C4-04 · ¿Mujer o Sacerdote? (minijuego nuevo, §9).** Tras el discurso del tribuno, un **ejemplo vivido**: el jugador, como Cromatistes, está en el mercado ya con la Ley aprobada «en el ensayo». Tres figuras mitad rojas y mitad verdes se acercan **de canto** en vista de ojo. Hay que decidir para cada una: «**Inclinarse**» (Sacerdote) o «**Ceder el paso**» (Mujer). En el ojo son **idénticas**. Es imposible acertar salvo por azar, y ese es el punto. Consecuencias inmediatas, cómicas y luego inquietantes: te inclinas ante una mujer y se ríe; cedes el paso a un Sacerdote y te ordena arrodillarte. La voz `logica`: «No es que no sepas. Es que **no se puede saber**. Eso era la Ley: borrar la diferencia». Fiel y muy didáctico: muestra un *límite de información* propio de la dimensión.
- **C4-05 · El fraude con consecuencias.** El `sight_round` del Isósceles pintado se mantiene. Si lo calas, la doncella cercana te oye y se aparta de él, pero la historia sigue igual (el narrador: «Ese día, en el teatro, la salvé. En la historia, no la salvó nadie»). Es el narrador poco fiable aplicado a la memoria histórica.
- **C4-06 · Pantociclo: el discurso en tres planos.** Durante el discurso, la cámara alterna **tres planos** según a quién se dirige: los artesanos (que bajan la cabeza), las mujeres (que **giran de punta hacia los soldados**: el jugador puede verlo venir en la lámina) y los presos armados que se colocan. La elección actual («Mirar a las mujeres» / «a los presos») mueve la cámara a ese plano. El jugador *ve* la conspiración armarse.
- **C4-07 · Patrones de sección: accesibilidad dentro de la ficción.** Cada color se acompaña de un **rayado de dibujo técnico** distinto (el juego ya usa rayado de sección): rojo, rayado a 45°; verde, punteado; y así los 8 tonos. Está activado por defecto en la opción «colores con patrón». Además de accesible, es coherente con el mundo: el teatro de la memoria es una lámina de delineante.
- **C4-08 · Después de la matanza: el silencio.** Tras el «En media hora no quedaba ninguno», **12 segundos sin música ni texto**: la plaza vacía, las marcas de los caídos en el papel (`World.slay` ya las deja) y la lluvia. Luego el color se drena de las figuras, lado a lado. El juego necesita un momento sin nada que hacer, justo aquí.

**Marginalia:** el pasquín de la Ley del Color en el tablón del Colegio (ya lo sugiere la pista del fragmento 9) · un fragmento de poema de la época del Color («los versos rimaban en tonos») · el tarro de pigmento sellado que el Círculo Supremo guarda bajo llave (se ve en una vitrina del Colegio, vacía).

---

### Capítulo V · Atiende a tu Configuración (§11, §12)

**Lo que hay.** El Templo con sus filas; la doctrina; el niño Equilátero que la Junta adopta; el Círculo joven con tres preguntas.

**Lo que funciona.** El niño adoptado y la madre que olvida son de lo mejor del juego. Las respuestas del novicio son brillantes.

**Lo que falla.** Es el capítulo más pasivo. La excusa del nieto por «la temperatura» (§12) se cuenta en lugar de jugarse. No presenta al hermano, que en el libro es justo un hombre de rango del Consejo.

**Mejoras:**

- **C5-01 · El hermano, en el Templo (resuelve G1).** El hermano del Cuadrado, Escribano Mayor del Consejo, está en la fila de los Profesionales, a tu lado. Antes del oficio hay una conversación de 6–8 líneas: es cálido, irónico y prudente («Tú y yo, cuatro lados cada uno, y sin embargo a ti te llaman a la Puerta y a mí me dejan copiando actas»). Te invita a pasar el primer día del año 2000 en su casa, después de la sesión del Consejo, y hace una broma sobre «los iluminados del milenio» que luego es terrible. Durante el oficio, si eliges la opción herética, **él te pisa el lado** discretamente («Aquí no, hermano»). Así tiene voz, humor y miedo propios antes de su condena en el VIII.
- **C5-02 · El cántico con ritmo.** La respuesta «Atiende a tu Configuración» se convierte en un pequeño ritmo: cuatro sílabas tónicas que se pulsan a tiempo con la asamblea, con el órgano marcando. Si aciertas, te fundes con el coro (la voz `decoro` lo aprueba). Si no pulsas, tu silencio se oye y se apunta en el expediente («Mueve la boca sin voz»). Convierte la elección actual «(Mover la boca sin voz)» en acción.
- **C5-03 · La medición del niño, vista.** Cuando la Junta mide al recién nacido, la cámara se acerca a su vértice y se dibuja el arco de 60° con la misma animación que el `feel()` del jugador. El jugador reconoce el gesto: **lo mismo que hiciste tú con el comerciante decide hoy la vida de una familia**.
- **C5-04 · La excusa de la temperatura, jugada (§12, resuelve G4).** Al volver a casa, el nieto ha roto una tablilla de su hermano. El nieto alega: «No fue culpa mía, abuelo: un cambio brusco de temperatura fue demasiado para mi perímetro. La culpa es de mi Configuración». Tres opciones:
  - «Entonces una buena reprimenda te fortalecerá la Configuración» (la respuesta del libro);
  - «Tienes razón: nadie tiene la culpa» (la doctrina llevada al extremo, que el nieto aprovecha: «¡Entonces tampoco me castigarás si rompo otra!»);
  - «Lo que importa no es de quién es la culpa, sino que se arregle» (el nieto la arregla contigo: minijuego de 15 segundos para unir dos mitades de la tablilla girándolas, con un guiño al tacto).

  La conversación del novicio sobre ese tema se reescribe para **referirse a lo que el jugador hizo**, no para contarlo.
- **C5-05 · El Gimnasio Neoterapéutico, de reojo.** Al salir del Templo, el novicio pasa junto a un edificio de puertas cerradas; si el jugador eligió la pregunta «¿Cuántos lados tiene usted?», el novicio se detiene ante esa puerta medio segundo y no dice nada. Un detalle visual que paga su historia del hermano muerto.
- **C5-06 · Puente a la noche.** El final («me dormí sobre las tablillas») muestra al Cuadrado en su estudio, en la lámina, haciendo Geometría: **dibuja una Línea en su tablilla**. Fundido a la Línea, que se alarga y se convierte en Linealandia. Es un corte de cámara que une el V con el VI por la imagen.

**Marginalia:** el ujier y su ángulo «muy educado» · las tablas de lados del Círculo Supremo («diez mil, por cortesía») · las mujeres en su fila lateral, que en la lámina se ven moverse al ritmo del vaivén.

---

### Capítulo VI · El Rey de la Línea (§13, §14)

**Lo que hay.** El sueño; el Rey responde a tres preguntas (el reino, cómo ven, cómo se casan); el Cuadrado entra y sale de la Línea; el Rey no le cree; la guerra.

**Lo que funciona.** El Rey está muy bien escrito, la sección dorada del Cuadrado sobre la Recta es una gran idea visual, y la frase «infinitamente superior» está sembrada a la perfección.

**Lo que falla.** Es la **mejor oportunidad de analogía del juego** y dura tres minutos. El jugador solo cruza la Línea una vez. No ve nunca lo que ve el Rey. Las voces y el matrimonio por sonido son ruido, no juego.

**Mejoras:**

- **C6-01 · La vista del Rey (lente nueva, `T-05`).** Al preguntar «¿Cómo veis?», el Rey dice: «Mira como yo, si puedes». La lente cambia a **Ojo del Rey**: la pantalla entera se reduce a **un punto en el centro**, con el brillo de lo que tiene delante (la vecina más cercana). Al acercarse una figura, el punto brilla más; al alejarse, se apaga. El jugador ve *menos de lo que nunca ha visto*. Luego la lente vuelve a **Ojo del Cuadrado** (la línea) y la diferencia se siente como un alivio: **la línea, que en el Prólogo era una cárcel, ahora es una riqueza**. Es el momento en que la analogía cambia de sentido para el jugador.
- **C6-02 · Medir con el oído (minijuego, §13).** El Rey: «Yo te reconozco por la voz. Escucha a mis súbditos y dime quién es el más largo». Tres súbditos cantan su par de notas (bocas en los dos extremos) con un **retraso proporcional a su longitud**. El jugador los ordena de más corto a más largo. La primera vez es ingenuo: hay que *escuchar el intervalo*. El indicador visual en el ojo (un trazo entre las dos notas) es opcional para accesibilidad. Convierte una explicación en un pequeño acertijo musical, muy fiel al §13.
- **C6-03 · Hazte tan largo como la Reina (la clave de la analogía).** Tras «Demuéstralo», el Rey no se conforma con un cruce. Plantea **tres retos de sección**: «Si de verdad eres Línea de Líneas, sé ahora tan corto como mi esposa… ahora tan largo como yo… ahora **más largo que nadie en mi reino**». El jugador debe **girar el Cuadrado mientras lo atraviesa** para que su sección sobre la Recta mida lo pedido:
  - corta: entrar por un **vértice** (la sección empieza en un punto);
  - un lado: entrar **de frente** (la sección mide el lado);
  - la más larga: alinear la **diagonal** con la Recta (√2 veces el lado).

  La sección dorada ya se calcula en `ch_c.gd`; solo falta mostrar su longitud como una **regla** sobre la Recta y una **marca del objetivo**. El Rey reacciona a cada cambio de longitud: «¡Crece! ¡Mengua! ¡Brujería!». Esto es exactamente lo que la Esfera le hará al Cuadrado en el VII (crecer y menguar sin moverse); el jugador lo hace **primero**, con sus manos. Cuando llegue la Esfera, lo reconocerá. Es la mejora de más valor del documento.
- **C6-04 · El matrimonio por armonía (juguete musical, §13).** Pregunta opcional del Rey sobre el matrimonio: tres voces (el Rey, la soprano y la contralto) y el jugador ajusta **la tercera** con el stick hasta que el acorde «casa» (de disonante a consonante, con el retardo de una nota que se resuelve). Al casar, nacen tres puntos diminutos en la Recta. Dura 30 segundos. Es curioso, encantador y hace sentir lo que el Rey describe: un mundo entero construido con sonido.
- **C6-05 · El audio pasa a mono (`T-06`).** Toda la escena suena en un solo canal. Cuando el Cuadrado sale de la Línea, su voz vuelve a tener panorama durante un instante. Es un efecto casi subliminal que hace *oír* la dimensión.
- **C6-06 · La guerra, con huida.** El «¡A mí, mis Líneas!» termina en una **huida jugable de 10 segundos**: los súbditos se lanzan (en su única dirección) contra tu sección. Para escapar solo hay que **salir de la Recta**: hacia el Norte o hacia el Sur, cualquiera de las dos direcciones que para ellos no existen. La lección es instantánea: el escape está en la dimensión de más. Luego suena la campana del desayuno.

**Marginalia:** el súbdito más corto, que nunca ha visto a su vecino de delante · la «distancia de mil leguas» del matrimonio, medida en la lámina (los esposos están en los extremos) · la sombra del Cuadrado sobre la Recta *antes* de entrar: no se ve nada.

---

### Capítulo VII · El Forastero (§15, §16, §17)

**Lo que hay.** La lección del 3³ con el nieto; la Esfera aparece y crece; la esposa la palpa; la Analogía en la pizarra (dos preguntas); la embestida; la alacena; el toque en las entrañas; la abducción.

**Lo que funciona.** La escena de la pizarra del nieto es preciosa; la aparición de la Esfera, muy buena; la elección «¿Dónde has oído esa frase?» es un acierto de escritura.

**Lo que falla.** El jugador mira cómo crece la Esfera, pero no tiene *herramientas* para entenderla. La alacena se resuelve en un diálogo. El ritmo de la escena intermedia, con tres bloques de texto seguidos, supera los 90 segundos.

**Mejoras:**

- **C7-01 · El nieto pregunta, el abuelo dibuja.** En la pizarra del 3², el jugador **dibuja** el cuadrado de 3×3 trazando las líneas con el stick o el ratón (los trazos se ajustan a la cuadrícula). Cuando el nieto pregunta por 3³, el jugador puede **intentar** dibujar «el siguiente paso» en la pizarra: cualquier trazo cae en el mismo plano y la pizarra lo rechaza con un chirrido de tiza. Es el primer «no puedes» del juego y prepara el X.
- **C7-02 · Predice la sección de la Esfera (deducción).** Antes de que la Esfera se eleve, dice: «Ya que eres matemático: si me elevo **la mitad** de mi radio, ¿qué tamaño tendré para ti?». El jugador elige entre tres tamaños de círculo dibujados en la lámina. La respuesta correcta es √(1−¼) ≈ 0,87 del radio, y la intuición falla: casi todos eligen la mitad. La Esfera se eleva y el círculo se ajusta al tamaño real. Con dos rondas basta (subir la mitad y subir casi todo). Une con `C6-03`: **tú ya hiciste crecer y menguar tu sección ante el Rey**; la voz `asombro` lo dice si el jugador completó ese reto: «Esto ya lo has hecho tú. Del otro lado».
- **C7-03 · La Analogía, construida.** La tabla de la pizarra (puntos terminales y lados) la rellena el jugador **arrastrando números** a las casillas, en lugar de elegir de una lista. La última casilla del Cubo se ilumina al acertar. Al terminar, la tabla se copia sola a la **tabla de analogías** del inventario (`T-04`), con la columna 3D por primera vez.
- **C7-04 · La alacena: compruébalo tú (resuelve el pago del I).** Tras «Ahí la tienes, en el suelo», un objetivo jugable: «**Comprueba tu alacena**». El jugador sube al estudio, abre la llave (acción mantenida) y, en la lámina, ve dentro: dos cofres y **una sola tablilla**. En el I contó dos (`C1-01`). La voz `logica` se queda sin frase y suena un trazo de tiza roto. Es el momento en que el jugador comprende que la Esfera ve lo que él veía desde la lámina. Luego vuelve al salón para el toque en las entrañas.
- **C7-05 · El toque, con vista de entrañas.** En el toque al estómago, el plano se acerca al Cuadrado, que se vuelve **translúcido** (ya existe `guts`) y un punto de luz (el «dedo» de la Esfera) aparece *dentro* del cuerpo sin cruzar el perímetro. Vibración en el mando. Ahora mismo es un destello de 1,6 segundos; debe durar 3 y ser legible.
- **C7-06 · Ritmo.** Se parten los tres bloques largos de la Esfera con micro-acciones: girar hacia ella cuando cambia de sitio (la cámara no la sigue sola) y retroceder cuando se acerca. Ningún tramo pasa de 90 segundos sin entrada.

**Marginalia:** el reloj de arena con los últimos granos del milenio (del I) · la tablilla del nieto con su 3³ escrito «en tres pisos», a escondidas · la puerta del salón, cerrada: la Esfera no la usó.

---

### Capítulo VIII · Espaciolandia (§18, §19)

**Lo que hay.** El ascenso; ver la casa por dentro; volar al Consejo; la Esfera aparece ante el Consejo; el hermano condenado; el Cubo construido; la Cuarta Dimensión con el teseracto; la caída.

**Lo que funciona.** Es la cumbre visual del juego: ascenso en barrido, entrañas visibles, la construcción del Cubo, el teseracto que gira.

**Lo que falla.** Dura cuatro minutos, menos que el capítulo de la casa. En Espaciolandia **no hay nada que hacer**: el jugador vuela de un punto a otro. El vuelo no aprovecha la idea principal del §18: **desde Arriba se ve y se alcanza el interior de todo**. El Cubo solo se mira.

**Mejoras:**

- **C8-01 · El primer vistazo: el vértigo.** El ascenso de 5 segundos se alarga a **9** con tres tiempos: primero, la cámara sigue a ras del plano (se ve la ciudad como una lámina **sin grosor**, una hoja infinitamente fina vista de canto: solo una raya); luego la cámara se eleva y la raya se *abre* en la ciudad entera; por último se inclina hasta la vista oblicua, la primera del juego (`T-07`). La música entra en el modo `space` en el instante en que la raya se abre. Es el momento más importante del juego: **el jugador ve Planilandia de canto, como él mismo veía la moneda**.
- **C8-02 · Ver por dentro (exploración desde Arriba).** Antes de ir al Consejo, un objetivo libre: «**Mira dentro de lo que nunca has visto**» con tres hallazgos (y otros tres opcionales). Cada hallazgo se registra al sobrevolarlo de cerca:
  1. **La alacena**, con la tablilla que falta en el suelo del salón (obligatorio).
  2. **Tu nieto, dormido**, y bajo su almohada la tablilla del 3³ «en tres pisos» (obligatorio; une con la marginalia del VII).
  3. **El cofre del Prefecto**, en el Palacio: dentro, el **acta del Consejo** ya escrita *antes* de la sesión, con la condena incluida (obligatorio). Un gran detalle de ironía política, fiel al espíritu del §18 (el Consejo lleva mil años repitiendo la misma resolución).
  4. *(Opcional)* El calderero (`C8-04`).
  5. *(Opcional)* Las entrañas de una mujer que **late de otra manera**: está embarazada. Detalle delicado, sin texto explícito; solo la voz `asombro`: «Dos vidas en una línea».
  6. *(Opcional)* Un Círculo que se mide los lados a solas en su casa: **son muchos menos de los que dice**. La voz `recelo`: «Por cortesía, decían».
- **C8-03 · Coger desde Arriba (mecánica nueva).** La Esfera: «Ahora hazlo tú. Lo que yo hice con tu alacena». Acción **Tomar**: desde el vuelo, el jugador baja hasta casi tocar el plano sobre un objeto, lo **levanta fuera del Plano** (el objeto deja de proyectar sombra, desaparece de la línea del ojo de los planilandeses y se ve flotando en 3D) y lo deja en otro sitio, **sin cruzar ningún muro**. Reto: **devuelve la tablilla a la alacena cerrada**. Al soltarla dentro, la alacena sigue cerrada por sus cuatro lados. El jugador hace el milagro que lo dejó boquiabierto en el VII. Uso opcional: llevar el estilete del calderero a su celda del Hospital (`C8-04`).
- **C8-04 · El calderero, desde Arriba (pago del III).** Si el jugador sobrevuela el Hospital de Reconfiguración, ve al calderero según el dictamen y la elección del III:
  - dictaminado *Irregular* sin protesta: una sala con marcas en el papel, como las de la matanza. Ya no está;
  - con protesta del jugador: en una camilla, comprimido en un marco que le **fuerza los ángulos**. Está vivo y *casi* regular. La voz `asombro`: «Desde aquí se ve que sus tres lados están bien. Solo son distintos»;
  - si se le llevó el estilete (`C8-03`), al día siguiente (en el IX) el heraldo menciona «un milagro en el Hospital» que nadie se explica.

  El momento emocional de la Parte II que mejor rima con la Parte I.
- **C8-05 · Las secciones del Cubo (minijuego, el gran acertijo dimensional).** Tras construir el Cubo, la Esfera lo **hace atravesar el Plano**. Antes de cada pasada, el jugador ve la orientación del Cubo en 3D y debe **predecir qué figura verán los planilandeses** (lo que aparecerá en la lámina), eligiendo entre cuatro siluetas:
  1. de cara: un **cuadrado** que aparece, se queda igual y desaparece;
  2. de arista: un **rectángulo** que se ensancha y se estrecha;
  3. de vértice: un **triángulo** que crece, se convierte en **hexágono** y vuelve a triángulo.

  Tras cada predicción, el Cubo pasa y la sección se dibuja **en el Plano** (como figura de la lámina) y **en la línea del ojo** (como la vería un planilandés). La tercera pasada es la «sorpresa didáctica»: un hexágono salido de un cubo. Después, **una ronda inversa**: la Esfera hace pasar un sólido **oculto** (un cono, un cilindro tumbado o una pirámide) y el jugador, viendo solo la sucesión de secciones en la lámina, adivina qué era. Es justo lo que el Cuadrado debería haber hecho con la Esfera en el VII y no pudo. Cierra el círculo: **tacto (II) → sección propia (VI) → sección de la Esfera (VII) → secciones del Cubo (VIII)**.
- **C8-06 · La sombra del Cubo (siembra del juicio).** La Esfera enciende una luz sobre el Cubo, que proyecta **una sombra sobre el Plano**: dos cuadrados desplazados y cuatro rayas que los cosen. La Esfera: «Esto es lo único que tus compatriotas podrían ver de él: su sombra». El jugador gira el Cubo con el stick y la sombra cambia en el Plano. Se guarda la orientación preferida del jugador. En el X, el dibujo que el Cuadrado hace ante el Consejo **es esa sombra** (`C10-04`), y el jugador reconoce el dibujo.
- **C8-07 · El teseracto, manejable.** En la escena de la Cuarta Dimensión, el jugador puede **girar el teseracto** con dos ejes (stick izquierdo: rotación en el plano XW; stick derecho: rotación en YZ). Mientras gira, el Cubo interior atraviesa el exterior, y la voz `asombro` comenta la clave: «Es la sombra de una sombra. Igual que la sombra del Cubo en tu Plano». La tabla de analogías rellena la columna 4D: 16 puntos, 32 aristas, 24 caras, 8 cubos. La última celda («Qué ve quien llega de arriba») se queda en «?».
- **C8-08 · La caída, más larga y física.** La caída son ahora 2 segundos. Pasa a 4: la cámara cae girando, la ciudad se aplana otra vez hasta volver a ser una raya (el inverso exacto de `C8-01`) y la imagen se apaga *en* la raya. El jugador ve la tercera dimensión cerrarse.

**Marginalia:** las seis opcionales de `C8-02` cuentan como marginalia de este capítulo · la Sala del Consejo vista desde arriba, con las marcas de mil años en el suelo, el mismo sitio donde «ha vuelto a ocurrir».

---

### Capítulo IX · Hacia Arriba, no hacia el Norte (§20, §21)

**Lo que hay.** Puntolandia (el Punto y sus monólogos, dos preguntas); el despertar; el heraldo; los hijos; la esposa; la lección con el nieto («Mueve el cuadrado hacia Arriba») y la traición.

**Lo que funciona.** La lección del nieto (el control que no permite el Arriba) es una idea de diseño excelente. Los monólogos del Punto son fieles y divertidos.

**Lo que falla.** Puntolandia es una conversación en el vacío. La traición del nieto no duele lo suficiente (`G2`, que se resuelve en parte con `C1-03`, `C3-06` y `C5-04`).

**Mejoras:**

- **C9-01 · La vista del Punto (lente final, `T-05`).** «Ello llena todo el Espacio»: al acercarse, la lente cambia sola al **Ojo del Punto**: la pantalla entera es **un solo color** que late. No hay línea, ni punto, ni borde. Cualquier entrada del jugador (moverse, hablar) produce un leve cambio de tono que el Punto interpreta como su propio pensamiento («¡Ah, Ello se ha movido en Ello!»). La tabla de analogías completa la columna 0D. Es el cierre de la escala de lentes: lámina → línea → punto → **todo**.
- **C9-02 · Hablarle al Punto (las tres respuestas, todas).** Las tres opciones actuales se mantienen, pero se pueden elegir **las tres** (ahora solo dos), y una cuarta aparece tras las otras: «**(Callar.)**». El Punto: «¡Silencio! Ello descansa en Ello. ¡Ah, la perfección de no decir!». La Esfera, por primera vez, **se ríe**. Un momento de humanidad del Maestro antes de su sentencia final.
- **C9-03 · La lección del nieto, con todo lo aprendido.** El minijuego actual («mueve el cuadrado hacia Arriba») recibe **dos intentos más** con lo que el jugador aprendió:
  1. **Secciones:** el Cuadrado intenta explicar la Esfera con su sección. Minijuego: hacer crecer y menguar un círculo dibujado. El nieto: «Es un círculo que cambia de tamaño, abuelo».
  2. **Sombras:** dibuja la sombra del Cubo (`C8-06`). El nieto: «Son dos cuadrados cosidos. Como los que dibujas cuando te aburres».
  3. **Arriba:** el minijuego actual.

  Cada fracaso es más doloroso porque el nieto *quiere* entender (si la relación es alta, se le nota: pausas, preguntas buenas). Luego llega el heraldo y la risa.
- **C9-04 · La risa, con el tema del nieto invertido.** Mientras el nieto ríe, suena su leitmotiv (`T-06`) invertido y desafinado. Si la relación es ≥ +1, antes de reír hay **dos segundos de silencio** en los que el nieto mira la puerta (la lámina muestra al heraldo al otro lado del muro: el jugador ve lo que el niño teme). Luego: «¡Ja, ja, ja!». El jugador entiende que el niño no lo traiciona: **lo protege**.
- **C9-05 · Los once meses (montaje).** Tras la huida del nieto, un **montaje de 40 segundos** con tres escenas cortas sin diálogo, solo acción:
  1. el Cuadrado intenta dibujar el Cubo en su tablilla y todo trazo cae en el plano (con la mecánica de `C7-01`);
  2. intenta recordar el Cubo con el ojo cerrado: la imagen del Cubo, cada vez más borrosa, en tres flashes;
  3. escribe el título del tratado: «*De Planilandia a Pensamientolandia*».

  Cubre el §22 (que ahora es un párrafo) sin inflarlo.

**Marginalia:** el Punto «oye» la voz del jugador en su propia voz · la trampilla del sótano, que no existe (si eliges la mentira, el jugador puede buscarla y no la encuentra) · el tablero de juego del nieto, con las figuras de `C1-03` ordenadas por lados.

---

### Capítulo X · El juicio (§22) y la celda

**Lo que hay.** La Sociedad Especulativa (el conferenciante y tres elecciones que no sirven); la confesión; el Consejo y sus dos preguntas (moverse hacia Arriba; dibujar el Cubo); la sentencia; la celda con el hermano; el cierre del manuscrito; los créditos.

**Lo que funciona.** «Aquí puedes elegir lo que quieras. Te aviso de que no servirá» es de lo mejor del juego. La primera pregunta es perfecta. La frase final del libro está bien colocada.

**Lo que falla.** El juicio no sabe nada del jugador (las decisiones de diez capítulos no aparecen). La segunda pregunta es una animación, no un intento. La celda es una conversación y un monólogo. El final se queda corto (`G6`).

**Mejoras:**

- **C10-01 · El tratado (preparación jugable).** Antes de la Sociedad Especulativa, en el estudio: el jugador elige **con qué argumentos** escribe el tratado, eligiendo entre los saberes que conoce (Analogía, Secciones, Sombras, Linealandia, Puntolandia). Cada uno es una tarjeta del inventario. Si el archivero tiene buena relación, le presta una «tablilla en blanco» y se puede elegir uno más. Los argumentos elegidos **son los que el Cuadrado usará** en el juicio y con el hermano.
- **C10-02 · La Sociedad Especulativa, con contención física.** Las tres elecciones de «callar» se acompañan de una **acción de contención**: mantener pulsado un botón mientras el conferenciante dice algo que el jugador *sabe* falso (la barra de «callar» se llena y se vacía según cada frase). La tercera vez la barra se rompe sola. Es la misma idea que el texto («Te aviso de que no servirá»), pero sentida en el pulgar.
- **C10-03 · El Presidente lee el expediente (`T-01`).** Antes de la primera pregunta: «Antes de oírle, el Consejo ha leído lo que de usted se sabe». Se leen 3–5 entradas del expediente, elegidas por peso, con la voz de su autor (el Inspector, el ujier, el sargento…). Si el expediente está casi vacío (un jugador muy ortodoxo), el Presidente: «Nada. Un Cuadrado ejemplar. Eso es lo que más nos inquieta». Las dos variantes funcionan y las dos son fieles.
- **C10-04 · La segunda pregunta: dibuja tú el Cubo.** El jugador **dibuja** en la tablilla del acusado, trazando líneas entre puntos con el stick o el ratón. El juego ofrece como guía tenue la sombra que el jugador eligió en `C8-06`, aunque puede dibujar lo que quiera. El Presidente responde según lo dibujado:
  - la sombra del Cubo: «Un Cuadrado montado sobre otro y cuatro rayas que los cosen. Una figura Irregular de muchos lados» (la frase actual);
  - un hexágono (la sección de vértice): «Un Hexágono. ¿Pretende usted que un Cuadrado engendra Hexágonos?»;
  - otra cosa: «Rayas, caballero».

  La voz del narrador se mantiene: «Tú, lector, has visto un cubo en ese dibujo. Tú puedes». **Ahora el lector lo ha dibujado él mismo.**
- **C10-05 · La sentencia y los testigos.** Tras la sentencia, si la relación lo permite, una figura del pasado reacciona en la sala: el sargento de la Puerta (que te apuntó 8/8) baja la cabeza, o el ujier del Templo sonríe. Dura 5 segundos y no tiene diálogo.
- **C10-06 · Siete años: las visitas del hermano (epílogo jugable).** La celda deja de ser un monólogo y pasa a **tres visitas** (año 1, año 4 y año 7), con un fundido de muescas en la pared entre una y otra (`P-02`). En cada visita el Cuadrado intenta convencer al hermano con **uno de los argumentos del tratado** (`C10-01`), con un minijuego breve tomado de lo que el jugador ya hizo (dibujar una sección, contar puntos terminales, imitar la voz del Rey de la Línea…). El hermano responde siempre con amor y con una objeción perfectamente razonable desde el Plano:
  - Analogía: «Un razonamiento correcto sobre una cosa imposible. Me lo dijiste tú, hace años».
  - Secciones: «Un círculo que cambia de tamaño. Lo vi. Por eso estoy aquí».
  - Linealandia: «Un sueño de un hombre que se dormía sobre las tablillas».

  Ninguna funciona (el libro: *no tengo un solo converso*). En el año 7 el hermano llega más viejo y **es él quien pregunta**: «Cuéntame otra vez lo del Cubo. Me gusta cómo se te iluminan los lados». No cree, pero escucha. Es fiel y es el final emocional que el juego merece.
- **C10-07 · El cierre del manuscrito (con todo lo que el jugador hizo).** Se mantienen las frases de epílogo según las variables y se añaden las de las relaciones (`T-02`): la tablilla de diez muescas de la hija, el hijo del criado bajo el muro, el calderero (según `C8-04`) y el nieto («Mi nieto tiene ya diecisiete años y seis lados. No ha venido nunca. Me dicen que da clases de Geometría, y que a veces, cuando un alumno pregunta por 3³, tarda en contestar»). Esta última línea aparece siempre: es la esperanza del libro, encarnada en el único que hizo la pregunta.
- **C10-08 · El cierre: la mesa del lector.** Tras la última frase del libro («…la tela sin fundamento de un sueño»), la niebla se cierra en la celda hasta dejar un punto. Corte a la mesa del lector (`P-01`), al revés: la cámara **sale del papel** y se eleva. La hoja de la mesa muestra la celda dibujada a tinta. La dedicatoria completa del libro aparece sobre la mesa, línea a línea. Por último, la cámara sigue subiendo y sobre la mesa se proyecta, durante dos segundos, una **sombra que no corresponde a nada de la habitación**: dos cubos cosidos por sus vértices, la sombra de un teseracto. Fundido a negro. «*Hacia Arriba, no hacia el Norte.*» Créditos.
  - **Por qué:** el jugador ha sido la Esfera durante todo el juego (miraba la lámina desde Arriba). El final le dice que quizá alguien lo mira a él desde Arriba. Es la «raza de rebeldes que se nieguen a ser confinados en una Dimensionalidad limitada» de la última página, y lo que la dedicatoria pide: aspirar a la Cuarta.
- **C10-09 · Tras los créditos.** Se desbloquea el **Prefacio del Editor a la segunda edición** (el texto real de 1884, dominio público), en el que el editor responde a los críticos del Cuadrado. Se presenta como un documento de la galería. Además se abre el **modo Colegio** (`7.2`).

**Marginalia:** la silla vacía del hermano en la celda (año 7) · las muescas del año 7, con una de más que el Cuadrado no hizo · el banco de la Sociedad Especulativa, con el nombre del Cuadrado grabado por un compañero.

---

## 7. Contenido y requisitos para Steam

### 7.1 Logros (24)

| Id | Nombre | Condición |
|---|---|---|
| `ACH_COIN` | Una moneda sobre la mesa | Completar el Prólogo |
| `ACH_TOYS` | El juego de los ángulos | Acertar las 3 figuras del nieto (`C1-03`) |
| `ACH_COUNT` | Hasta diez | Enseñar a contar a la hija sin que la madre te vea (`C1-04`) |
| `ACH_STREET` | Ni un pinchazo | Cruzar la calle sin ser herido (`C2-02`) |
| `ACH_VOICE` | Oído fino | Distinguir la voz verdadera a la primera (`C2-05`) |
| `ACH_GATE` | Ojo de Colegio | 8/8 en la Puerta Oeste |
| `ACH_GATE_P` | Perito | 8/8 en la Puerta Oeste sin traza |
| `ACH_CIRCLE` | Reverencia | Inclinarse ante el Círculo de incógnito (`C3-01`) |
| `ACH_HOME` | Por la lluvia | Volver a casa sin que el criado salga a buscarte (`C3-05`) |
| `ACH_TRIBUNAL` | Tribunal del Colegio | Aprobar el examen del Decágono (`C4-01`) |
| `ACH_FRAUD` | Lo has calado | Descubrir al Isósceles pintado |
| `ACH_HYMN` | Una sola voz | Cántico perfecto en el Templo (`C5-02`) |
| `ACH_KING` | Línea de Líneas | Superar los tres retos de sección ante el Rey (`C6-03`) |
| `ACH_WED` | Las tres voces | Casar el acorde de Linealandia (`C6-04`) |
| `ACH_SPHERE` | La raíz de tres cuartos | Predecir bien las dos secciones de la Esfera (`C7-02`) |
| `ACH_CUPBOARD` | Cerrada por sus cuatro lados | Devolver la tablilla a la alacena desde Arriba (`C8-03`) |
| `ACH_HEX` | Un hexágono salido de un cubo | Predecir la sección de vértice (`C8-05`) |
| `ACH_HIDDEN` | Adivina el sólido | Acertar la ronda inversa (`C8-05`) |
| `ACH_TESS` | La sombra de una sombra | Girar el teseracto 360° en ambos ejes |
| `ACH_TINKER` | Desde aquí se ve | Visitar al calderero desde Arriba |
| `ACH_SILENT` | La perfección de no decir | Callar ante el Punto |
| `ACH_FILE` | Cuadrado ejemplar | Llegar al juicio con el expediente vacío |
| `ACH_MARGIN` | Nadie lee los márgenes | Todas las marginalia |
| `ACH_END` | Alguna Dimensión | Terminar el juego |

### 7.2 Modo Colegio (desbloqueable)

Una sala del Colegio de Vista con **los minijuegos sueltos**, con dificultad creciente y puntuación: reconocimiento por la vista (incluido el Decágono), tacto, cruzar la calle, secciones del Cubo y adivinar el sólido. Cada uno tiene tres medallas (bronce, plata y oro, en tinta). Prolonga la vida del juego sin tocar la narrativa y es material excelente para un tráiler y para streamers.

### 7.3 Localización

- **Inglés** (prioridad P0). El texto original de *Flatland* (1884) es de dominio público: los fragmentos del manuscrito y las citas pueden usar **el texto exacto de Abbott**, lo que es un argumento de venta («el texto original, jugable»). El diálogo nuevo se traduce.
- Después (P2): francés, alemán, portugués de Brasil, chino simplificado y japonés, que son los mercados donde *Flatland* es conocido. Se mide antes de decidir.

### 7.4 Requisitos técnicos y de tienda

- **Plataformas:** Windows, Linux y Steam Deck (Verificado); macOS opcional. La versión web se mantiene como demo jugable de los capítulos Prólogo, I y II (sirve de embudo hacia la tienda).
- **Steam Deck:** mando completo, glifos, texto legible a 1280×800 (ya escala por puntos), sin texto bajo 9 px y teclado en pantalla no necesario.
- **Demo de Steam** (Next Fest): Prólogo → final del capítulo III (≈ 22 minutos), con el cliffhanger del calderero.
- **Tráiler** (60–90 s), que cuenta la escalera de dimensiones: la línea del ojo → la lámina → la Línea del Rey → la Esfera creciendo → el ascenso de `C8-01` → la sombra del teseracto. Las capturas salen de las cinemáticas de `T-07`.

---

## 8. Revisión de cohesión y de diseño

He revisado el conjunto de propuestas como un todo, con cuatro preguntas: ¿cuenta una sola historia?, ¿las mecánicas forman un sistema?, ¿es fiel?, ¿funciona como videojuego?

### 8.1 ¿Cuenta una sola historia?

El arco del Cuadrado es el del libro: **complacencia → revelación → soberbia → condena → esperanza dudosa**. Las propuestas lo refuerzan con tres hilos de personaje que antes no existían o eran débiles:

| Hilo | Siembra | Desarrollo | Pago |
|---|---|---|---|
| **El nieto** (la pregunta) | `C1-03` el juego de los ángulos | `C3-06` la cena · `C5-04` la temperatura · VII 3³ | `C9-03`/`C9-04` la risa que protege · `C10-07` «tarda en contestar» |
| **El hermano** (el amor sin fe) | `P-02` las muescas · `C5-01` el Templo | VIII la condena | `C10-06` siete años de visitas |
| **El calderero** (juzgar lo que no se ve) | II el estilete | III el dictamen · `C3-04` | `C8-04` desde Arriba · X el expediente |

Los tres se cierran en el capítulo X. Ningún hilo queda abierto ni se añade un personaje que no haga falta: la hija y el criado ya existían y solo reciben un pago en la celda.

### 8.2 ¿Las mecánicas forman un sistema?

Sí. La escalera de **percepción** es el espinazo del juego, y cada peldaño se juega en los dos sentidos:

```
     PERCIBIR (lo que ve el de dentro)                 ACTUAR (lo que hace el de fuera)
0D   Ojo del Punto: todo un color (C9-01)              tu voz, que él cree suya (C9-02)
1D   Ojo del Rey: un punto (C6-01)                     tu sección ante el Rey (C6-03)
2D   Ojo del Cuadrado: una línea (todo el juego)       coger desde Arriba (C8-03)
3D   Lámina y vuelo: la vista del lector (P-01, VIII)  la sombra del teseracto en tu mesa (C10-08)
```

Y la escalera de **deducción**, que pasa por todas las dimensiones:

```
tacto sin riesgo (C1-03) → tacto con riesgo (C2-03) → vista (III) → vista imposible (C4-04)
→ tu sección (C6-03) → la sección de la Esfera (C7-02) → secciones del Cubo (C8-05)
→ adivinar el sólido (C8-05) → dibujar el Cubo (C10-04) → convencer al hermano (C10-06)
```

Comprobación del pilar 3 (*enseñar → practicar → girar → pagar*), mecánica a mecánica:

| Mecánica | Enseñar | Practicar | Girar | Pagar |
|---|---|---|---|---|
| Tacto | nieto (I) | comerciante (II) | el respingo que pincha (II) | la medición del niño (V) · la sección (VI) |
| Vista | práctica (III) | 8 rondas (III) | girando, de incógnito (III) · color (IV) | ¿mujer o sacerdote? (IV) |
| Oído | la esposa (I) | cruzar la calle (II) | voces falsas (II) | medir con el oído (VI) · volver a casa (III) |
| Orientación | lluvia (I) | — | sin lámina (III) | «muévete hacia Arriba»: la dirección que no está (IX, X) |
| Sección | — | tu sección (VI) | la Esfera (VII) | el Cubo, el sólido oculto (VIII) · el juicio (X) |
| Ver por dentro | la alacena desde la lámina (I) | — | la alacena vacía (VII) | coger desde Arriba (VIII) |

No hay mecánicas huérfanas. Las dos que solo aparecen una vez son **juguetes** deliberados y cortos (el cántico del V y la armonía del VI) que dan variedad en los capítulos más dialogados.

### 8.3 ¿Es fiel?

- Todo lo añadido sale de una sección del libro (citada en cada propuesta) o de sus reglas internas: la sombra y las secciones del Cubo son la extensión natural del §16 y §18; la vista del Rey es literal en el §13; los árboles, en el §2; la presentación, en el §5; el Decágono, en el §6; la excusa del nieto, en el §12; el tratado sin diagramas, en el §22.
- **Invenciones del juego** (como el calderero, que ya existía): el hermano en el Templo (`C5-01`), las visitas del hermano (`C10-06`), el acta escrita de antemano (`C8-02`) y el nieto adulto (`C10-07`). Las cuatro son coherentes con el libro: el hermano existe y lo visita en prisión; el Consejo repite su resolución cada mil años; el libro termina con la esperanza puesta en una generación futura. Ninguna cambia un hecho del original.
- **El final no cambia.** El Cuadrado no tiene ningún converso, está preso y duda. Las decisiones cambian lo que recuerda y quién lo acompaña (pilar 5).
- **Riesgo de tono:** el capítulo IV y la misoginia institucional de Planilandia. El juego ya los trata con la ironía de Abbott (sátira, no apología). Las propuestas `C1-04` (la hija aprende a contar) y la escena opcional de la mujer embarazada vista desde Arriba (`C8-02.5`) mantienen ese enfoque: la mirada del juego está del lado de quien la ley oprime. Para la tienda conviene una nota que explique la sátira victoriana, como hace el Prefacio del Editor (`C10-09`).

### 8.4 ¿Funciona como videojuego?

- **Ritmo:** la proporción de juego activo pasa de ~20 % a ~48 %. Ningún tramo pasa de 90 segundos sin entrada (se ha revisado capítulo a capítulo: `C7-06` y `C9-05` existen precisamente por eso).
- **Fracaso amable:** ningún reto bloquea. Cada uno tiene una salida diegética (el criado con el farol, la cola que avanza, el nieto que se ríe del error). Es lo correcto para un juego narrativo de una hora que se compra por la historia.
- **Variedad de entradas:** movimiento con riesgo (II, III), deducción visual (III, IV, VIII), deducción numérica (VII), ritmo (V), afinación (VI), dibujo (VII, X), manipulación 3D (VIII) y contención (X). No se repite el mismo tipo de reto dos capítulos seguidos.
- **Curva de dificultad:** es suave hasta el III, plana en el V (descanso narrativo), sube en VI–VIII, cae en el IX (emoción, no habilidad) y en el X el juego **niega** la habilidad: el jugador no puede ganar el juicio. El cierre es un descenso deliberado, como en el libro.
- **Rejugabilidad honesta:** tres huecos de guardado, saltar lo leído, marcas de opciones ya elegidas, el expediente y las relaciones, que cambian escenas visibles (`C8-04`, `C9-04`, `C10-03`, `C10-07`), y el modo Colegio. No promete ramas que no existen.
- **Alcance:** son 85 propuestas (12 transversales y 73 de capítulo), ordenadas por prioridad en el SDD. El **núcleo P0** (que por sí solo lleva el juego a ~60 minutos y lo hace vendible) es: `T-01`, `T-04`, `T-06` (solo el audio posicional), `T-09`, `T-10`, inglés, `P-01`, `C1-01`, `C1-03`, `C2-02`, `C3-01`, `C3-05`, `C5-01`, `C6-01`, `C6-03`, `C7-02`, `C7-04`, `C8-01`, `C8-02`, `C8-03`, `C8-05`, `C8-06`, `C10-03`, `C10-04`, `C10-06` y `C10-08`. El resto pule y amplía.

**Conclusión de la revisión.** Las propuestas no son una lista de añadidos sino un único rediseño alrededor de una idea: **el jugador recorre la escalera de dimensiones en los dos sentidos, con las manos, y acaba en el peldaño de arriba sin saber si hay otro**. Eso es *Flatland*, y es un buen videojuego.

---

## 9. Lo que se descarta, y por qué

| Idea | Por qué no |
|---|---|
| Finales alternativos (el Cuadrado convence al Consejo o escapa) | Traiciona el libro y el pilar 5. El valor del final está en que no se puede ganar. |
| Combate (contra los Isósceles, la guerra de la Línea como acción) | Cambia el género. La guerra del VI se resuelve con *la idea* (salir de la Recta), no con reflejos. |
| Mundo abierto o misiones secundarias sin relación con el libro | Diluye. Las marginalia cubren la curiosidad con contenido fiel. |
| Árbol de habilidades o mejoras | No hay progresión mecánica que mejorar: los saberes ya son la «progresión», y se usan en el X. |
| Voces dobladas completas | Coste alto y pérdida de la estética del murmullo (las voces generativas por clase son parte del encanto). Como mucho, una voz para la dedicatoria del cierre. |
| Visitar Espaciolandia «de verdad» (una ciudad 3D de Esferas) | El libro nunca lo muestra y el misterio es esencial: la Esfera tampoco ve la Cuarta. El único 3D fuera del Plano es la mesa del lector, y por una razón. |
| Un capítulo jugable de Pensamientolandia | El libro solo la nombra como título del tratado. Inventarla rompería la regla de fidelidad. |
| Muerte o «fin de partida» en los retos | Va contra un juego que se compra por la historia. Los fallos son diegéticos y nunca hacen repetir más de 30 segundos. |
