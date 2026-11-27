# Planilandia — Documento de especificación técnica (SDD)

**Implementación de las mejoras de [`DISENO_JUEGO_COMPLETO.md`](DISENO_JUEGO_COMPLETO.md)**

| | |
|---|---|
| Base de código | `godot/` en `main` @ `30eff92` (Godot 4.7, renderizador Compatibility) |
| Fuera de alcance | `web/` (versión three.js): se congela tal cual |
| Identificadores | Los de las mejoras del documento de diseño (`T-xx`, `P-xx`, `Cn-xx`); aquí se añaden los de componentes (`S-xx`) |
| Idioma del código | Se mantiene la convención actual: GDScript en español, `snake_case`, guion como corrutinas con `await` |

---

## Índice

1. [Objetivos, restricciones y principios técnicos](#1-objetivos-restricciones-y-principios-técnicos)
2. [Arquitectura actual (resumen)](#2-arquitectura-actual-resumen)
3. [Arquitectura objetivo](#3-arquitectura-objetivo)
4. [Modelo de datos](#4-modelo-de-datos)
5. [Componentes nuevos o modificados](#5-componentes-nuevos-o-modificados-s-xx)
6. [Especificación por capítulo](#6-especificación-por-capítulo)
7. [Plataforma y Steam](#7-plataforma-y-steam)
8. [Pruebas](#8-pruebas)
9. [Plan de entregas y prioridades](#9-plan-de-entregas-y-prioridades)
10. [Riesgos](#10-riesgos)

---

## 1. Objetivos, restricciones y principios técnicos

**Objetivos**

- Implementar las mejoras del documento de diseño sin reescribir el motor: el guion por corrutinas (`Ch`, `g.until`, `g.tick`, `ui.say`…) es sólido y se conserva.
- Sacar a Steam builds de Windows, Linux y Steam Deck (Verificado), en español e inglés.
- Mantener la exportación web como demo (Prólogo–III).

**Restricciones**

- **Renderizador Compatibility** (WebGL 2): no hay compute shaders y los sombreadores deben ser GLSL ES 3.0. Todo lo nuevo (lentes, secciones, sombras) se resuelve en CPU con `ImmediateMesh` o en los sombreadores existentes.
- **Un solo hilo** en web: nada de `Thread` en código que se ejecute en la demo.
- **Tamaño:** el `.wasm` comprimido ronda 10 MB. Los recursos nuevos (mesa, láminas, audio) no deben añadir más de **8 MB** a la exportación web.

**Principios**

1. **Todo minijuego nuevo tiene camino automático.** Igual que `feel()` y `sight_round()` hoy, cada función interactiva empieza con `if g.auto or g.bot: return <respuesta por defecto>`. Así `--auto` sigue recorriendo el guion entero sin interfaz.
2. **Datos fuera del código.** Los textos largos, las tablas (marginalia, analogías, relaciones, logros, láminas) y las traducciones van en `data/`. El código de capítulo solo orquesta.
3. **Nada de avisos por elección.** `g.rep()` y `g.her()` dejan de llamar a `ui.toast` (`T-01`).
4. **Compatibilidad de guardado.** Las partidas existentes (`user://planilandia.json`) se migran a la versión 2 sin pérdida.

---

## 2. Arquitectura actual (resumen)

| Fichero | Responsabilidad | Qué cambia |
|---|---|---|
| `scripts/main.gd` | Arranque, menú, cadena de capítulos, autómata de pruebas | Huecos de guardado, apertura y cierre, galería, modo Colegio |
| `scripts/game.gd` (`Game`) | Bucle, entrada por teclas físicas, estado, utilidades de guion | Entrada por `InputMap`, estado v2, expediente, relaciones, marginalia, tabla, transporte en el Espacio |
| `scripts/world.gd` (`World`) | Mapa, muros, figuras, colisiones, cámara, lluvia, efectos | Raíles de cámara, objetos 3D en el plano (secciones, sombras), escucha posicional |
| `scripts/entity.gd` (`Ent`) | Figura: forma, malla, IA, animación | `set_shape()` para secciones dinámicas, estado «levantado» |
| `scripts/eye.gd` + `shaders/eye_*.gdshader` | La vista 1D | Lentes `point` y `flood`; gotas de lluvia como segmentos |
| `scripts/ui.gd` (`UIRoot`, 1154 líneas) | HUD, diálogo, inventario, menú, pausa | Historial, auto-avance, saltar lo leído, pestañas nuevas, franjas de cine, glifos, ajustes |
| `scripts/pad.gd` | Controles táctiles | Se conserva; convive con el mando |
| `scripts/audio.gd` (`Snd`) | Música generativa y efectos | Leitmotivs, audio posicional, mono por mundo |
| `scripts/space.gd` | Mallas de Espaciolandia | Mallas de sólidos para secciones; mesa del lector |
| `scripts/content/ch*.gd` | Capítulos | Las mejoras de la sección 6 |
| `data/book.json` | 22 secciones y 19 saberes | Se divide por idioma y se amplía (sección 4) |

**Convenciones que se mantienen:** el plano usa coordenadas `(x, y)` con `y` = Norte; en 3D, un punto del plano está en `Vector3(x, alt, -y)`. `World.add(dict)` crea figuras a partir de diccionarios (`F_*` en `ch.gd`). Las figuras irregulares se definen con `pts`.

---

## 3. Arquitectura objetivo

```
godot/
  scripts/
    main.gd            (+ huecos, apertura/cierre, galería, Colegio)
    game.gd            (+ InputMap, estado v2, expediente, relaciones, marginalia, tabla, transporte)
    world.gd           (+ escucha 3D, objetos de sección/sombra, raíles)
    entity.gd          (+ set_shape, lifted)
    eye.gd             (+ lentes, lluvia)
    ui.gd              (+ historial, auto, saltar, pestañas, glifos)
    ui/                nuevo: piezas de interfaz que salen de ui.gd
      journal_tabs.gd    pestañas Personas, Analogías, Historial, Galería
      draw_board.gd      pizarra en la que el jugador dibuja (C7-01, C10-04)
      shape_icon.gd      iconos de opciones con siluetas (círculos, polígonos)
      letterbox.gd       franjas de cine y «mantén para saltar»
      glyphs.gd          glifos de teclado/mando según el último dispositivo
    sys/               nuevo: sistemas sin interfaz
      profile.gd         perfil (lo leído, logros, galería, capítulos), huecos de partida
      platform.gd        autoload: Steam (logros, nube) o nada
      cine.gd            raíles de cámara
      geom3.gd           secciones y sombras de poliedros (pura, probada)
      sketch.gd          clasificación de dibujos (grafo de trazos)
      i18n.gd            carga de traducciones y book por idioma
    minigames/         nuevo: minijuegos reutilizables (funciones de Ch movidas aquí)
      sight.gd  feel.gd  cross_street.gd  voices.gd  orient.gd  hymn.gd
      line_section.gd  voice_length.gd  harmony.gd  sphere_predict.gd
      cube_sections.gd  carry.gd  tesseract.gd  restraint.gd  brother.gd
    content/           ch.gd, ch_a…ch_d.gd (+ ch_frame.gd: apertura y cierre)
  data/
    book.es.json  book.en.json       secciones, saberes, marginalia, personas, tabla
    laminas.json                     trazos de las láminas de Abbott
    achievements.json
    i18n/es.po  i18n/en.po  i18n/planilandia.pot
  scenes/desk.tscn                    la mesa del lector (P-01, C10-08)
  tests/run.gd  tests/test_geom3.gd  tests/test_sketch.gd  tests/test_save.gd
  tools/extract_strings.py            genera el .pot desde los capítulos
```

**Autoloads** (en `project.godot`): `App` y `Snd` ya existen. Se añaden `Profile` (`sys/profile.gd`) y `Platform` (`sys/platform.gd`).

**Regla de dependencias:** `sys/*` no depende de `ui` ni de `world`; los `minigames/*` reciben `Game` y `UIRoot` como `Ch`; los capítulos llaman a los minijuegos, nunca al revés.

---

## 4. Modelo de datos

### 4.1 Estado de partida v2 (`user://slot_<n>.json`)

```jsonc
{
  "v": 2,
  "chapter": 3, "max": 3,
  "rep": {"sac": 0, "ciu": 1, "aut": -1},   // se conserva (compatibilidad); ya no se muestra
  "her": 2,                                   // ídem
  "know": {"vista": 1},
  "frags": {"1": 1},
  "flags": {"irregularChoice": "d", "dictamen": "irr", "aciertos": 7},
  // nuevo en v2
  "rel": {"esposa": 0, "nieto": 1, "hija": 0, "hermano": 0, "criado": 1, "calderero": 1, "archivero": 0},
  "record": [ {"id": "gate_protest", "ch": 3, "day": 362, "who": "inspector", "w": 3} ],
  "margins": {"m_p_muescas": 1},
  "ledger": {"1d.ve": 1, "2d.ve": 1},
  "inv": {"estilete": 1},
  "argumentos": ["analogia", "secciones"],    // C10-01
  "stats": {"gate_hits": 7, "gate_trace_off": false, "street_pricks": 0, "play_s": 1834.2}
}
```

- **Migración** (`Profile.migrate(d) -> Dictionary`): si falta `v`, se trata como v1: se añaden los campos nuevos con valores neutros y se copia `user://planilandia.json` a `user://slot_1.json`. El fichero antiguo **no se borra** (se renombra a `planilandia.v1.bak`).
- `record[].text` **no se guarda**: se resuelve por `id` desde `book.<lang>.json` → `record`, para que cambiar de idioma traduzca el expediente.

### 4.2 Perfil (`user://profile.json`, uno por instalación)

```jsonc
{
  "v": 1,
  "lang": "es",
  "max_chapter": 10,                 // desbloquea la selección de capítulos
  "seen": {"9f3a…": 1},              // hash (xxh32 del msgid) de cada línea leída: saltar lo leído
  "picked": {"c1.hija.h": 1},        // opciones elegidas alguna vez (T-09)
  "ach": {"ACH_COIN": 1},            // espejo local de logros
  "gallery": {"lam_1": 1, "m_p_muescas": 1},
  "college": {"sight": 2, "feel": 1} // medallas del modo Colegio: 0 nada, 1 bronce, 2 plata, 3 oro
}
```

La configuración (`user://planilandia_cfg.json`, de `App`) se amplía con: `text_speed` (0–3), `auto_adv` (bool), `difficulty` (`relaxed`/`normal`/`expert`), `patterns` (bool, por defecto `true`), `sound_captions` (bool, `true`), `reduce_motion` (bool), `hold_mode` (`hold`/`toggle`) y `bindings` (diccionario de acciones a eventos).

### 4.3 `book.<lang>.json` (ampliado)

```jsonc
{
  "fragments": [ {"title": "...", "hint": "...", "text": ["..."]} ],   // 22, sin cambios de forma
  "knowledge": { "vista": {"title": "...", "text": "..."} },            // + "secciones", "sombras", "orientacion"
  "margins": [ {"id": "m_p_muescas", "ch": 0, "title": "Las muescas", "text": "..."} ],   // 30
  "people":  { "nieto": {"name": "Tu nieto", "lv": {"-2": "...", "-1": "...", "0": "...", "1": "...", "2": "..."}} },
  "record":  { "gate_protest": {"who": "inspector", "text": "Día 362. Puerta Oeste. ..."} },
  "ledger":  {
    "cols": ["0d", "1d", "2d", "3d", "4d"],
    "rows": ["habitante", "ve", "limites", "no_concibe", "rechazo", "desde_arriba"],
    "cells": { "1d.ve": {"text": "un punto", "anim": "lineland_point"} }
  },
  "argumentos": { "analogia": {"title": "...", "reply_y1": "...", "reply_y4": "...", "reply_y7": "..."} }
}
```

- **Las pistas de los fragmentos** (`hint`) se reescriben para no sugerir que pueden perderse (`T-03`).
- `book.en.json` usa **el texto exacto de Abbott** en `fragments[].text`. Los títulos de sección siguen el original («Of the Nature of Flatland», …).

### 4.4 `achievements.json`

```jsonc
[ {"id": "ACH_GATE", "hidden": false, "stat": null}, {"id": "ACH_MARGIN", "hidden": false, "stat": {"key": "margins", "max": 30}} ]
```

Nombres y descripciones van en los `.po` (claves `ach.ACH_GATE.name` y `ach.ACH_GATE.desc`) y se suben a Steamworks a mano.

### 4.5 `laminas.json`

```jsonc
{ "lam_2": { "paper": "flat", "dur": 8.0, "caption": "lam.2.caption",
    "strokes": [ {"t0": 0.0, "t1": 0.18, "w": 2.0, "pts": [[120,300],[260,180],[400,300],[360,420],[160,420],[120,300]]},
                 {"t0": 0.2, "t1": 0.3, "w": 1.0, "dash": true, "pts": [...]} ],
    "labels": [ {"t": 0.6, "x": 230, "y": 450, "key": "lam.2.l1"} ] } }
```

Coordenadas en el lienzo de 640×480 de `SlateBoard` (ya usado por `slate_anim`). Los trazos se calcan a partir de los grabados del libro (dominio público) con una herramienta vectorial cualquiera y un script de conversión SVG → JSON (`tools/svg2lamina.py`).

---

## 5. Componentes nuevos o modificados (S-xx)

### S-01 · Entrada unificada y mando (`T-10`)

- **InputMap** (registrado al arrancar desde `sys/keys.gd`, para poder reasignar) con las acciones: `move_left/right/up/down`, `run`, `act`, `view`, `journal`, `pause`, `rise`, `sink`, `look_x+/-`, `look_y+/-`, `advance`, `history`, `skip_hold`. Cada una con su tecla actual y su evento de mando (`JoypadButton`/`JoypadMotion` con zona muerta de 0,2).
- `Game._key()` se sustituye por `Input.is_action_pressed()`; `axis()` combina `Input.get_vector("move_left", "move_right", "move_down", "move_up")` (y = Norte) con la palanca táctil, como ahora. La carrera con mando es analógica (la magnitud del stick ya funciona como en la palanca táctil).
- `_unhandled_key_input` pasa a `_unhandled_input` con `event.is_action_pressed(...)`.
- **Vista libre** (Espacio): `look_*` del stick derecho modifica `W.free.yaw/pitch` a 2,2 rad/s (escalado por sensibilidad en ajustes); el ratón sigue igual.
- **Glifos** (`ui/glyphs.gd`): `Glyphs.last` ∈ {`kb`, `xbox`, `ps`, `nintendo`, `deck`, `touch`}, actualizado en `_input` según el tipo de evento y `Input.get_joy_name()`. `Glyphs.of(action) -> String` devuelve un texto BBCode con el icono (fuente de iconos OFL, p. ej. *Kenney Input Prompts*, CC0). **Toda** cadena de interfaz que hoy contiene «E», «V», «WASD»… se genera con `Glyphs.of()`. `Ch.tx(kb, touch)` pasa a `Ch.tx(kb, touch, pad := "")`, y si `pad` está vacío se sustituye `{act}`, `{view}`… en `kb`.
- **Reasignación** en ajustes: una lista de acciones, «pulsa la nueva tecla» y se guarda en `cfg.bindings` como `[{type, code}]`; se aplica con `InputMap.action_erase_events` + `action_add_event` al cargar.
- **Vibración:** `App.rumble(weak, strong, sec)` llama a `Input.start_joy_vibration(0, …)` y a `Input.vibrate_handheld()`; sustituye las llamadas directas a `vibrate_handheld` del VII y del VIII.

**Aceptación:** el juego entero se completa con solo un mando Xbox y con solo el Steam Deck (prueba manual con `--bot` desactivado); ningún texto de la interfaz muestra una tecla de teclado si el último dispositivo fue un mando.

### S-02 · Estado v2, perfil y huecos de guardado (`T-12`)

- `sys/profile.gd` (autoload `Profile`): `load()`, `save()`, `migrate()`, `slot_path(n)`, `list_slots() -> Array[{n, chapter, play_s, date}]`, `mark_seen(msgid)`, `seen(msgid) -> bool`, `mark_picked(key)`, `unlock_gallery(id)`.
- `Game.SAVE` deja de ser constante: `Game.slot` (1–3) y `Game.save()` escribe en `Profile.slot_path(slot)`; además, **autoguardado** al empezar cada bloque (ya ocurre en `main.run`) y en `frag()`.
- **Menú:** «Continuar» carga el último hueco usado; «Nueva partida» abre el selector de huecos (los ocupados piden confirmación doble, como el actual «pulsa otra vez»); «Capítulos» usa `Profile.max_chapter`.
- **Aceptación:** un guardado v1 se migra sin perder fragmentos, saberes ni banderas (prueba `tests/test_save.gd` con un JSON v1 de ejemplo).

### S-03 · Expediente, relaciones y avisos (`T-01`, `T-02`)

```gdscript
# game.gd
func note(id: String, w := 1) -> void           # añade al expediente (idempotente por id)
    # efecto: state.record.append({id, ch = state.chapter, day = DAY[state.chapter], who = book.record[id].who, w})
    # y una señal diegética: si la figura `who` está en escena, late una vez + Snd.sfx("stylus")
func rel(who: String, d: int) -> void           # relaciones, de -2 a 2, sin aviso
func rel_of(who: String) -> int
func record_top(n := 5) -> Array                # por peso descendente; a igualdad, por orden
```

- `rep()` y `her()` **dejan de llamar** a `ui.toast` y a `Snd.sfx`. Se conservan los valores porque los usa el epílogo.
- `DAY` es una tabla que da a cada bloque un día del año: I → 358, II → 359, III → 360, IV → 361, V → 363, VI–VII → 364–365 (la Nochevieja de 1999) y X → día 330 del año 2000.
- **Correspondencia de las elecciones actuales con el expediente** (lista inicial; la definitiva vive en `book.*.json → record`):

  | Elección actual | `note()` | `rel()` |
  |---|---|---|
  | I · hija, «Hasta diez» | — (`hija_cuenta` solo si la madre lo ve, `C1-04`) | `hija +1` |
  | I · criado, «Me alegro por ti» / «No te hagas ilusiones» | — | `criado ±1` |
  | II · calderero, «¿Qué ha visto?» | — | `calderero +1` |
  | III · dictamen «Equilátero» | `gate_false_regular` (w 3) | `calderero +1` |
  | III · «¿No basta con vigilarlo?» | `gate_protest` (w 3) | `calderero +1` |
  | IV · «¡Color para todos!» | `college_color` (w 1) | — |
  | IV · archivero: «Yo también lo pienso» / «Un Cuadrado que mira la mano» / «Una disposición sabia» | — | `archivero +1` / `+1` / `−1` |
  | V · susurro herético en el cántico | `temple_whisper` (w 2) | `hermano -1` (te pisa el lado; cuando exista `C5-01`) |
  | V · «¡Dejad al menos que la madre lo visite!» | `temple_mother` (w 3) | — |
  | V · «Humildemente, pido que se reconsidere» | `temple_appeal` (w 2) | — |
  | VIII · el estilete dejado en el Hospital | `hospital_miracle` (w 2) | `calderero +1` |
  | X · llegar al juicio con el estilete en el inventario | `estilete_en_poder` (w 1) | — |

- **Aceptación:** ninguna elección produce un aviso en pantalla; en el X, el expediente leído coincide con las decisiones tomadas (prueba `--auto` con `--script=heretic` y `--script=orthodox`, ver §8).

### S-04 · Marginalia (`T-03`)

- Los capítulos declaran sus marginalia con `W.add_spot({id = 'm_c1_puerta', x, y, margin = true})`. Un *spot* con `margin = true`:
  - se dibuja como un **brillo de tinta** (efecto `fx` nuevo: `glint`, de 0,6 u de radio, con un ciclo de 2,4 s), visible solo si el jugador está a menos de 6 u;
  - en el ojo, se emite como un segmento de 0,15 u con `lum = 0.9` y color de acento, que se ve como una «chispa» en la línea;
  - tiene un manejador por defecto (`g.on(id, 'Examinar', …)`) que llama a `g.margin(id)`: un sonido de pluma, una línea del narrador (`book.margins[i].text`, primera frase) y el icono del inventario que parpadea. **Sin aviso de texto**.
- `g.margin(id)`: marca `state.margins[id]`, `Profile.unlock_gallery(id)`, y si se completan las de ese capítulo, `Profile.unlock_gallery("lam_<ch>")`.
- **Aceptación:** las 30 marginalia se pueden obtener; ninguna está en el camino obligatorio (verificado con `--auto`, que no las recoge: el recuento final de `--auto` debe ser `margins=0`).

### S-05 · Tabla de analogías (`T-04`)

- `g.ledger(cell: String)`: marca la celda y, si el inventario está cerrado, deja un indicador «nuevo» en la pestaña. Al abrir la pestaña, las celdas nuevas se escriben con una **animación de pluma** (revelado carácter a carácter en 0,8 s por celda, sonido `chalk`).
- `ui/journal_tabs.gd → LedgerGrid` (Control): cuadrícula de 5 × 6; las celdas de la fila `desde_arriba` son pequeños `SubViewport` de 96×64 que dibujan en bucle una animación (`anim`): `lineland_point` (un segmento que aparece y desaparece en una recta), `circle_grow` (círculo que crece y mengua), `voice_inside` (ondas concéntricas) y `?`. Se dibujan con `_draw()` en CPU, sin escenas 3D.
- **Llamadas en el guion** (las exactas están en la sección 6): `C6-01` → `1d.ve`; `C6-03` → `1d.desde_arriba`; `C7-03` → `3d.limites`; `C8-07` → la columna `4d`; `C9-01` → `0d.*`; y así con cada fila.

### S-06 · Lentes del ojo (`T-05`)

- `Eye.lens: String` ∈ {`line`, `point`, `flood`}, transmitido al sombreador `eye_view.gdshader` como `uniform int lens`.
  - `line`: el comportamiento actual.
  - `point`: muestrea solo la columna central de `t_data` (u = 0,5) y dibuja un disco de 7 px lógicos (escalado por `App.dpr()`) en el centro de la pantalla, con el brillo de esa muestra. El resto es el fondo de papel. Transición desde `line`: la línea se **encoge horizontalmente** hacia el centro en 1,2 s (`uniform float squeeze`).
  - `flood`: toda la pantalla toma el color medio de la línea (promedio de 32 muestras), con un latido de ±6 % de luminancia a 0,8 Hz. Transición: el disco de `point` se expande hasta cubrir la pantalla.
- `Game.lenses: Array` (por mundo) y `toggle_view()` recorre la lista en lugar de alternar `top`/`eye`. Valores: Planilandia `["top", "eye"]`; Linealandia `["top", "eye", "king"]` (la lente `king` es `view = "eye"` con `lens = "point"`); Puntolandia `["flood"]` forzada.
- **Lluvia en el ojo** (`C1-02`, `C3-05`): en `Eye.cast()`, después de los muros y figuras, se añaden hasta **64 gotas** de `W.drops` dentro de `fog * 3` como segmentos de 0,12 u **en la dirección de su caída**, con `lum = 0.35` y el color del borde. Al ser objetos que se mueven hacia el Sur, su deriva en la línea es físicamente correcta sin lógica adicional. Las gotas bajo techo (`W._covered`) ya no existen, así que dentro de casa no hay centelleo.
- **Aceptación:** con `--ch=6`, la lente del Rey muestra un único disco cuyo brillo cambia al acercarse un súbdito; el coste de `cast()` con lluvia sigue por debajo de 0,5 ms en el Steam Deck (medido con `Time.get_ticks_usec`).

### S-07 · Audio posicional, leitmotivs y mono (`T-06`)

- **Escucha:** un `AudioListener3D` hijo de `World`, colocado cada fotograma en el ojo del jugador (`Vector3(p.x, 0.2, -p.y)`) y orientado según `p.rot`, **no** según la cámara. Así el sonido corresponde a lo que *oye* el Cuadrado aunque el jugador mire la lámina.
- `Snd.sfx_at(name: String, x: float, y: float, db := 0.0)` y `Snd.loop_at(name, node: Node3D) -> AudioStreamPlayer3D`: grupo de 8 `AudioStreamPlayer3D` en el `World` (`attenuation_model = INVERSE_DISTANCE`, `unit_size = 4.0`, `max_distance = 40`, `panning_strength = 1.0`), con salida al bus de efectos actual.
- El **Grito de Paz** pasa a ser un bucle posicional ligado a cada `Ent` con `woman = true` y una propiedad nueva `cry := true` (desactivada en casa y en el Templo). Reproduce `s_peace` cada 2,8–3,6 s (aleatorio) con un ligero cambio de tono por figura.
- **Subtítulos de sonido** (`T-11`): `Snd.sfx_at` emite la señal `cue(text_key, dir)`; si `cfg.sound_captions`, la UI muestra un rótulo corto en el borde de la línea del ojo («⟨ Grito de Paz») según el signo del ángulo relativo. Se limita a un rótulo cada 1,5 s.
- **Mono:** el bus `Master` recibe un `AudioEffectStereoEnhance` con `pan_pullout = 0.0` (colapsa a mono), activado con `Snd.mono(on)`. Se llama en `ch6()` al entrar y al salir. *(Verificar en las pruebas que `pan_pullout = 0` da mono real en Compatibility; si no, alternativa: `AudioEffectPanner` en cada bus a 0 y `panning_strength = 0` en los reproductores 3D.)*
- **Leitmotivs:** `MOTIFS := {esfera = [[0,7],[2,12],[4,7]], hermano = [[0,3],[2,0]], nieto = [[0,0],[1,4],[2,7],[3,11]]}` (paso, intervalo en semitonos), tocados por `Snd.motif(name, inst := "", invert := false, detune := 0.0)` dentro del secuenciador, cuantizados al compás siguiente y transportados a la tonalidad del modo actual (`MOODS[mood].root`).
- **Aceptación:** con auriculares, en `C2-02` se distingue de qué lado viene una mujer con los ojos cerrados (prueba manual con tres personas).

### S-08 · Raíles de cámara y franjas de cine (`T-07`)

```gdscript
# sys/cine.gd
class_name Cine extends RefCounted
static func play(W: World, keys: Array, skippable := true) -> void   # await
# keys: [{t = 0.0, focus = Vector2(..), zoom = 40.0}, {t = 2.5, focus = .., zoom = .., ease = "inout"}, ...]
# en cam_mode "free": {t, pos = Vector3, look = Vector3, fov = 42.0}
static func orbit(W: World, center: Vector2, from_pitch: float, to_pitch: float, sec: float) -> void   # P-03
```

- `play` interpola `W.focus` y `W.zoom` (o la cámara libre) entre llaves con `App.ease` y muestra las franjas (`ui/letterbox.gd`: dos `ColorRect` que entran en 0,4 s, de un 9 % de la altura cada uno). Si `skippable`, mantener `skip_hold` 1 s salta a la última llave (con un anillo de progreso junto al glifo).
- `orbit` (`P-03`) añade a `World.update_cam` un modo temporal `cam_mode = "orbit"`: la cámara mira a `center` desde una distancia fija y su *pitch* pasa de `from_pitch` a `to_pitch` en `sec` segundos. Al terminar, se cede a `eye_t = 1` con un fundido cruzado de 0,4 s entre la imagen del mundo y la vista del ojo (opacidad de `eye.view`).
- `cfg.reduce_motion`: `shake` y `kick` se multiplican por 0, y las llaves con `fast = true` duplican su duración.

### S-09 · Diálogo: historial, auto-avance, saltar lo leído (`T-09`)

- `UIRoot.log: Array` de `{who, text}` (tope de 200), añadido en `say()` y `narrate()` al terminar de escribirse cada bloque. Pestaña «Historial» en el inventario y botón en la pausa; acción `history`.
- **Velocidad de texto:** `_type_step` usa `CPS = [30, 62, 110, INF][cfg.text_speed]` (la «normal» es la velocidad actual, 62 letras por segundo).
- **Auto-avance:** si `cfg.auto_adv`, al terminar de escribirse un bloque se espera `1.2 + 0.045 * len(text)` s y se avanza solo. Se suspende si hay elecciones o un panel.
- **Saltar lo leído:** mientras `skip_hold` está pulsado, `say()` comprueba `Profile.seen(msgid)` y, si lo está, completa el bloque y avanza a los 0,08 s. Se detiene en la primera línea no leída y en toda elección. El `msgid` es el texto **antes de traducir** (ver S-10), así que funciona en cualquier idioma.
- **Opciones ya elegidas:** `choose()` recibe opciones con `id`; la clave es `"<cap>.<escena>.<id>"`, donde la escena se toma del manejador activo (`g.handlers` conoce el id de la figura) o de un parámetro opcional `key`. Las opciones con la clave en `Profile.picked` muestran un punto de tinta.

### S-10 · Localización (`U6`, §7.3 del diseño)

- **gettext con el texto español como msgid.** `ui.say`, `ui.narrate`, `ui.choose` (campo `t`), `ui.note`, `ui.panel` (título, texto, `label`, `sub`), `g.objective`, `ui.title` y `ui.toast` llaman a `tr()` **internamente**. Así los capítulos no se tocan para traducir.
- **Cadenas con formato:** las que hoy se construyen con `%` antes de llegar a la interfaz (`'%d de cinco, señor…' % hits`) no tendrían traducción. Regla: se escriben como `tr('%d de cinco, señor…') % hits`, y la herramienta de extracción **falla** si encuentra un `%` dentro de un literal pasado a `say/narr/choose/note/objective` sin `tr(`. Ocurrencias actuales que hay que corregir: `ch_a.gd` (tres en el recuento del sargento), `ch.gd` (`sight_round`, el veredicto por defecto), `ch_b.gd` (`'Elige un color para tu lado %s.'`), `ch_d.gd` (el título final) y `game.gd` (los avisos de fragmento).
- `tools/extract_strings.py`: recorre `scripts/**/*.gd` buscando literales en esas llamadas (con un análisis sencillo de literales de GDScript con comillas simples y dobles, escapes y concatenación de una línea) y genera `data/i18n/planilandia.pot`. Las traducciones viven en `es.po` (identidad) y `en.po`, y se cargan con `TranslationServer` desde `sys/i18n.gd`.
- **El cursiva y la negrita** del guion (`*…*`) se conservan en la traducción: el formato lo aplica `ui.fmt()` después de `tr()`.
- `book.<lang>.json` se carga según `Profile.lang`; si falta una clave, se usa el español.
- **Selector de idioma** en ajustes y en el primer arranque (detectando `OS.get_locale_language()`).
- **Aceptación:** `--auto --lang=en` recorre el juego sin una sola cadena sin traducir (la prueba cuenta los `tr()` que devuelven el msgid sin cambios y falla si hay alguno distinto de los nombres propios en una lista blanca).

### S-11 · Pizarra de dibujo (`C7-01`, `C10-04`)

- `ui/draw_board.gd → DrawBoard` (hereda de `SlateBoard` para conservar el aspecto de tiza):
  - una rejilla de **puntos de anclaje** (`anchors: PackedVector2Array`), que en el X son los 8 vértices de la sombra guía y 16 puntos extra repartidos;
  - un cursor (ratón, táctil o stick con velocidad de 420 px/s y ajuste magnético a 18 px del anclaje más cercano);
  - `act` pulsado sobre un anclaje empieza un trazo; al soltarlo sobre otro, lo fija; `view` deshace el último trazo; «Hecho» termina;
  - `await board.draw_until_done(max_s := 90.0) -> Array[Vector2i]` (pares de índices de anclaje).
- `sys/sketch.gd → Sketch.classify(segments) -> String`: construye el grafo (vértices = anclajes usados) y devuelve:
  - `"cube_shadow"` si hay 8 vértices de grado 3 y 12 aristas (la proyección de un cubo, en cualquier perspectiva);
  - `"hexagon"` si hay 6 vértices de grado 2 que forman un ciclo;
  - `"square"` si hay 4 vértices de grado 2 en ciclo;
  - `"empty"` si no hay trazos; si no, `"other"`.
- En `C7-01`, la variante «3³» no clasifica: cualquier trazo produce el rechazo (sonido de tiza y temblor del tablero).
- **Pruebas:** `tests/test_sketch.gd` con 6 casos (sombra estándar, sombra en otra perspectiva, hexágono, cuadrado, cuadrado + 1, vacío).

### S-12 · Geometría de secciones y sombras (`C6-03`, `C7-02`, `C8-05`, `C8-06`)

`sys/geom3.gd` (sin dependencias, estático y probado):

```gdscript
class_name Geom3
# Poliedros convexos en coordenadas locales: {verts: PackedVector3Array, edges: Array[Vector2i]}
static func cube(l := 1.0) -> Dictionary
static func pyramid(l := 1.0, h := 1.2) -> Dictionary      # base cuadrada
static func prism_n(n: int, r := 0.8, h := 1.6) -> Dictionary   # cilindro aproximado (n = 24)
static func cone_n(n: int, r := 0.8, h := 1.6) -> Dictionary
# Sección por el plano y = 0 (el Plano) de un poliedro transformado.
# Devuelve el polígono convexo en coordenadas del Plano (x, y = -z), ordenado CCW, o [] si no corta.
static func section(poly: Dictionary, xf: Transform3D) -> PackedVector2Array
# Sección de una esfera de radio R con centro a altura h: radio del círculo (0 si no corta).
static func sphere_section(R: float, h: float) -> float     # sqrt(R² - h²)
# Sombra: proyecta cada arista sobre y = 0 desde una luz puntual (o direccional si light.w == 0)
static func shadow(poly: Dictionary, xf: Transform3D, light: Vector4) -> Array   # [[Vector2, Vector2], ...]
# Sección de un polígono del Plano por la Recta y = 0 (Linealandia): [x_min, x_max] o [] (ya existe en ch_c.gd; se mueve aquí)
static func line_section(pts: Array) -> Vector2
```

- **Algoritmo de `section`:** para cada arista (a, b) con `a.y * b.y < 0`, el punto `a + (b - a) * (a.y / (a.y - b.y))`; se añaden los vértices con `|y| < 1e-4`; se eliminan duplicados (tolerancia 1e-4); se ordenan por ángulo alrededor del centroide. Como el poliedro es convexo, la sección es convexa.
- **Representación en el Plano:** `Ent.set_shape(pts: PackedVector2Array)` (nuevo) reconstruye `local`, `rad` y la malla (`build()`) sin recrear el nodo. Se usa una figura `secc` con `noCollide` y el color de la Esfera o del Cubo. Actualizar a 30 Hz basta (la malla tiene a lo sumo 6 vértices, salvo el cono y el cilindro, con 24).
- **Representación en el ojo:** la figura `secc` es una `Ent` normal, así que `Eye.cast()` ya la dibuja en la línea. Es la propiedad más valiosa del diseño: **la misma sección se ve en la lámina y en la línea sin código extra**.
- **Sombras:** `World._line()` en un `ImmediateMesh` dedicado (`W.shadow_im`) con el color de tinta al 45 %.
- **Pruebas** (`tests/test_geom3.gd`): un cubo de cara a h = 0 → cuadrado de área l²; de vértice (diagonal vertical) a la altura media → hexágono regular; de vértice a 1/6 de la diagonal → triángulo equilátero; `sphere_section(1, 0.5)` = √0,75; un plano que no corta → `[]`.

### S-13 · Transporte desde Arriba (`C8-03`)

- `minigames/carry.gd → Carry.run(g, target_id, goal: Callable, hint: String) -> bool`.
- **En vuelo:** si el jugador está a menos de 3 u en horizontal de una figura con `carryable = true` y su `alt < 6`, la acción `act` la **toma**: `e.lifted = true`, `e.alt` sigue a `p.alt - 1.2` con suavizado, `e.no_collide = true`, sin sombra (`shadow.visible = false`) y **excluida del ojo** (`Eye.cast` omite las figuras con `alt > 0.3`). Mientras se lleva, se dibuja una línea discontinua vertical hasta el plano (la «plomada») para que el jugador sepa dónde caerá.
- Al soltar `act`, la figura cae en 0,5 s a `alt = 0`. Si cae **dentro de un muro**, se empuja con `W._walls_push` hasta un hueco libre (como ya hace `collide`). Si cae dentro de un edificio *cerrado*, se queda allí: es justo la gracia.
- `goal.call(e) -> bool` decide el éxito (p. ej., «dentro del rectángulo de la alacena»: `Rect2(4.8, 4.0, 1.8, 1.6)` en coordenadas de la casa, ver `ch.gd → town()`, `inner`).
- **Aceptación:** la tablilla se puede llevar desde el salón a la alacena cerrada sin cruzar ningún muro, y la línea del ojo de un planilandés no la ve mientras flota (prueba con `--ch=8 --shots`).

### S-14 · Minijuegos

Cada minijuego es una función `static` o un `RefCounted` en `minigames/`, con la firma `func run(c: Ch, opts := {}) -> Variant` y camino automático. A continuación, los parámetros, la entrada, el éxito y lo que devuelven.

| Id | Minijuego | Entrada | Lógica y parámetros | Devuelve | Diseño |
|---|---|---|---|---|---|
| M-01 | `feel` (v2) | `act` mantenido | Progreso del arco a una velocidad que sube de 0,3/s a 1,2/s en 1,5 s de pulsación continua; soltar la reinicia. Si se supera **0,95/s** con `risky = true`, el arco se tiñe de rojo, hay respingo y `g.hurt(0.4)` y se pierde el 50 % del progreso. Con `cfg.difficulty = relaxed`, el umbral pasa a 1,1. | `{ok: bool, pricks: int}` | `C1-03`, `C2-03` |
| M-02 | `sight` (v2) | panel de opciones | Nuevos `opts`: `spin` (rad/s de giro de la figura), `cloak` (multiplica `lum` por 0,55 y añade `noEye` de vértices), `arc` (la figura llega en arco, no en recta), `queue` (deja la siguiente figura esperando a 15 u), `options_extra` (p. ej., `{id = 'bow', label = 'Inclinarse'}`) y `trace` (forzar o quitar la traza). | id elegido | `C3-01`, `C4-01`, `C4-04` |
| M-03 | `cross_street` | movimiento en el ojo, lámina bloqueada | Tres mujeres con `ai = path` cruzando en perpendicular a 1,6–2,1 u/s, con `cry = true`. Éxito: el jugador llega a una zona objetivo (`Rect2`) en la acera opuesta. Pinchazo: `g.hurt`, aturdimiento y `teleport` a la acera de salida tras 1,2 s. | `{pricks: int, time: float}` | `C2-02` |
| M-04 | `voices` | elegir apartarse o no cuando una voz está a menos de 3 u | Tres fuentes posicionales que se acercan por turnos. La verdadera usa `Snd.talk('hexa')`; las falsas, `Snd.talk('hexa', vibrato = 0.35)` (parámetro nuevo de `talk`: oscilación de tono de 5,5 Hz y ±35 cents en las notas largas). | `[bool, bool, bool]` | `C2-05` |
| M-05 | `orient` | movimiento en el ojo, sin lámina, sin brújula ni flecha | Oculta `ui.compass`, `W.arrow` y `ui.bearing_l`. Añade a `move_player` un `g.pull := Vector2(0, -0.35)` (u/s de deriva hacia el Sur) y vibración débil de 0,08 cada 4 s. Activa la lluvia a mitad de camino (`W.rain` de 0 a 0,8 en 6 s). La esposa en la puerta del Este emite `cry`. A los 90 s aparece el criado (voz que llama, `sfx_at` cada 2 s desde la casa). Éxito: `go_to` de la puerta Oeste. | `{time: float, helped: bool}` | `C3-05` |
| M-06 | `hymn` | `act` a tiempo | 4 golpes en el compás del modo `temple` (54 bpm); ventana de ±150 ms (±250 en relajado). El órgano marca. | aciertos 0–4 | `C5-02` |
| M-07 | `line_section` | movimiento y giro libres del Cuadrado sobre la Recta | Objetivo de longitud `L*` con tolerancia ±0,06 u durante 0,6 s seguidos. Muestra una regla sobre la Recta (marcas cada 0,25 u) y el objetivo como dos muescas rojas. Los tres objetivos son `0.25` (casi un vértice), `2r·sin(45°)` (el lado del Cuadrado) y `2r` (la diagonal); con `r` = el radio del Cuadrado del jugador (0,78). Reacción del Rey a cada cambio de longitud superior a 0,2 u (una frase de un banco de 6, sin repetir). | número de objetivos logrados | `C6-03` |
| M-08 | `voice_length` | ordenar 3 elementos | Cada súbdito canta dos notas (su par grave y agudo) separadas por `0.25 + 0.5 * largo` s. El jugador los ordena con un panel de arrastre (o con flechas en el mando). | `bool` | `C6-02` |
| M-09 | `harmony` | stick (eje X) o arrastre | Tres tonos: el Rey (110 Hz), la soprano (330 Hz) y la tercera voz controlada en el rango 120–200 Hz. La consonancia se mide por la cercanía a 5/4 o 3/2 del Rey (tolerancia de 8 cents) durante 1 s. Los tonos se resintetizan cada 0,4 s con `Snd.tone` y un ligero solapamiento. | `bool` | `C6-04` |
| M-10 | `sphere_predict` | panel con 3 iconos de círculo | Rondas `[0.5, 0.9]` (altura / R). Opciones: el radio correcto (`Geom3.sphere_section`) y dos distractores (`h`, es decir, el error lineal, y `1 - h`). Tras elegir, la Esfera se mueve a esa altura y la sección real se ajusta en el Plano y en la línea. | aciertos 0–2 | `C7-02` |
| M-11 | `cube_sections` | panel con 4 siluetas | Tres pasadas (cara, arista, vértice) con el Cubo a 1,2 u/s en `y`; la sección se recalcula con `Geom3.section` cada fotograma. Ronda inversa: un sólido oculto entre `pyramid`, `cone_n(24)` y `prism_n(24)` tumbado; el jugador ve solo la sección en la lámina y elige el sólido entre 4 iconos 3D (mallas en un `SubViewport` de 96 px). | `{pred: 0..3, hidden: bool}` | `C8-05` |
| M-12 | `shadow_turn` | stick o arrastre para girar el Cubo | Luz puntual fija sobre el Cubo; la sombra se dibuja con `Geom3.shadow` cada fotograma. «Hecho» guarda `state.flags.shadow_xf` (la base del Cubo) para `C10-04`. | `Basis` | `C8-06` |
| M-13 | `tesseract` | stick izquierdo X y stick derecho Y | Sustituye el giro automático actual de `ch8()` por dos ángulos controlados (XW e YZ); se conserva la proyección actual (`k = 2.6 / (3.2 - w)`). El logro `ACH_TESS` se da al acumular 2π en cada ángulo. | — | `C8-07` |
| M-14 | `restraint` | `act` mantenido | Barra que **sube sola** mientras habla el conferenciante (velocidad por frase, de 0,2 a 0,5/s) y que el jugador frena manteniendo `act` (−0,6/s). En la tercera frase, la subida es de 2,0/s y la barra se rompe siempre. | — | `C10-02` |
| M-15 | `brother` | depende del argumento | Una visita = un argumento de `state.argumentos`: `analogia` reutiliza la tabla de `C7-03` (rellenar 2 celdas), `secciones` reutiliza `sphere_predict` (1 ronda), `sombras` reutiliza `DrawBoard` y `lineland` reutiliza `voice_length`. Las respuestas del hermano salen de `book.argumentos[id].reply_y1/y4/y7`. | — | `C10-06` |

**Regla para todos:** con `cfg.difficulty = relaxed`, cada minijuego de deducción (M-02, M-04, M-08, M-10, M-11) permite **un segundo intento** tras un fallo, con una pista de `logica`.

### S-15 · Mesa del lector (`P-01`, `C10-08`)

- `scenes/desk.tscn`: una escena 3D independiente, cargada por `content/ch_frame.gd`. Contiene una mesa, una lámpara (`OmniLight3D` cálida; en Compatibility se admiten 8 luces por objeto), el libro abierto (malla con una textura de la portada original de 1884, de dominio público) y la **hoja de papel**. Los modelos se generan en `tools/blender_assets.py` (función nueva `build_desk()`), exportados a `assets/models/escritorio.glb` (presupuesto de 3 MB con las texturas a 1024 px).
- **La hoja muestra la celda**: al arrancar `ch_frame.opening()` se hace un render del mapa `cell()` en un `SubViewport` de 1024×1024 con la cámara de lámina, y su textura se aplica a la hoja. La cámara de la mesa baja con `Cine.play` (en modo libre) hasta quedar perpendicular a la hoja, con el mismo encuadre que la cámara del mundo; en ese momento se hace un **fundido cruzado de 0,5 s** a la escena real. El encuadre se calcula para que el cambio sea invisible (mismo FOV, misma escala).
- **Cierre** (`ch_frame.closing()`): el proceso inverso, y después la **sombra del teseracto** sobre la mesa: un `MeshInstance3D` con las aristas del teseracto proyectadas (la misma función de `ch8()`) sobre el plano de la mesa con `Geom3.shadow`, a una opacidad del 0 % al 35 % al 0 % en 2 s.
- **Dedicatoria:** `Label3D` sobre la mesa, con el texto de `tr('dedicatoria.full')`, revelado línea a línea.
- **Aceptación:** la transición mesa → celda no muestra saltos de escala ni de posición en 1080p ni en 1280×800 (capturas con `--shots`).

### S-16 · Láminas ilustradas (`T-08`)

- `ui.lamina(id) -> void` (await): muestra la `SlateBoard` a pantalla completa con el papel del capítulo y dibuja los trazos de `laminas.json` según su `[t0, t1]` (cada trazo progresa con su longitud recorrida), con sonido de pluma. Mantener `skip_hold` o tocar salta.
- Sustituye la llamada a `ui.title()` en `ChA.intro()`: se muestra primero la lámina y después el título sobre el mundo. Se añade el parámetro `lam: String` a `intro()`.
- **Galería** (menú principal): rejilla con las láminas desbloqueadas (al ver el capítulo) y con las de las marginalia (al completarlas). Al pulsar una, se vuelve a dibujar.

### S-17 · Interfaz: inventario y ajustes

- **Inventario** con 5 pestañas: *Manuscrito* (existente), *Saberes* (existente), *Personas* (nueva, `T-02`, sustituye a «Posición social»), *Analogías* (nueva, S-05) e *Historial* (nueva, S-09). La herejía deja de mostrarse.
- **Ajustes** (menú y pausa), por grupos: *Texto* (velocidad, auto-avance, tamaño, tipo de letra), *Juego* (dificultad, mantener o pulsar), *Accesibilidad* (patrones, subtítulos de sonido, reducir movimiento), *Controles* (reasignar, sensibilidad, invertir Y) y *Sonido* (música, efectos, voces) e *Idioma*.
- **Patrones de color** (`C4-07`): `flat.gdshader` recibe `uniform int pattern` por lado (0–8). En el fragmento se superpone un rayado procedural en el espacio del mundo: 45°, −45°, horizontal, vertical, punteado, cruzado, rayado fino y ondulado, con una opacidad del 35 %. `Ent.set_colors()` asigna el índice del patrón según el color (tabla `HUES` → patrón).

---

## 6. Especificación por capítulo

Para cada capítulo: los cambios de código, ordenados como aparecen en el guion. «→» indica la llamada al componente.

### Apertura y Prólogo (`ch_frame.gd`, `ch_a.gd: prologue()`)

| Id | Implementación |
|---|---|
| P-01 | `main.run()`: si `i == 0` y no `Profile.seen_opening`, primero `await ch_frame.opening()` (S-15). |
| P-02 | `cell()` añade `labels` con 7 grupos de muescas (`t = '||||'`, con `it = true`, en la pared Norte) y el *spot* `m_p_muescas` (S-04). |
| P-03 | En la orden de la moneda: `await Cine.orbit(W, Vector2(0, 2.2), PI/2, 0.02, 3.5)` y `g.set_view('eye')` al terminar (S-08). Tres `text_plane` de tiza que aparecen al 20 %, 55 % y 85 % del recorrido. |
| P-04 | Tras `talk_end(o)`: pantalla en negro 4 s y `say('presidente', 'Sea tan amable de indicarnos esa dirección.')` con el retrato en silueta. Solo en la primera partida (`Profile`). |
| P-05 | Se divide la `ui.note` inicial en cuatro avisos encadenados (girar → avanzar → lente → acción), cada uno se oculta con `g.until()` al cumplirse su acción. |
| P-06 | Cambio de texto. |

### Capítulo I (`ch_a.gd: ch1()`)

| Id | Implementación |
|---|---|
| C1-01 | `alacena` pasa a `g.all(...)`. Su manejador: `act` mantenido 0,8 s (la llave), luego `W.focus` sobre la alacena y `W.zoom = 14`, y se dibujan dentro dos cofres y dos tablillas (`Ent` con `noCollide` y `carryable = false`, ids `cofre1`, `cofre2`, `tab1`, `tab2`). Se guarda `flags.alacena_vista = 1`. |
| C1-02 | `f_tejado` añade una fase: `g.set_view('eye')`, `g.view_lock = true`, `g.objective('Mira al Norte')`; éxito con `absf(App.ang_diff(p.rot, PI/2)) < 0.25` durante 1 s. `W.rain` ya está a 1,0. Requiere la lluvia en el ojo (S-06). |
| C1-03 | `f_nieto` se reescribe: las 3 rondas de `feel()` (M-01, `risky = false`) sobre figuras de juguete (`F_tri/F_cuad/F_penta` con `r = 0.5`, `noCollide`), con `ui.fade` a negro salvo el arco. Se conservan las líneas existentes sobre las casas antes y después. `g.rel('nieto', +1)` si acierta 2 o más. |
| C1-04 | Opción «Hasta diez» → minijuego de 10 pulsaciones con la esposa en `ai = path` por el pasillo. Si la esposa está a menos de 6 u y el jugador pulsa, se descubre → elección de mentira o verdad → `g.note('hija_cuenta')` o no. `ACH_COUNT` si no te descubre. |
| C1-05 | La esposa recibe `ai = {type='path', pts=[...]}` entre su cuarto y el salón con la punta por delante y `cry = true` (S-07) mientras el jugador está a menos de 8 u, hasta que se inicia su conversación. |
| C1-06 | `stroll` para hijos (`hijo` y 3 más, ahora ocultos en el I), criado y nietos, con rutas dentro de la casa. |

### Capítulo II (`ch_a.gd: ch2()`, `town_folk()`)

| Id | Implementación |
|---|---|
| C2-01 | En `f_noble`: `await Cine.play(W, [...])` con 5 llaves por la calle, cada una con `focus` en una figura de `town_folk()` de la clase nombrada en ese momento; `ui.say` y `Cine.play` corren en paralelo (el raíl se lanza sin `await`). |
| C2-02 | Se intercala antes de `mercader`: `await CrossStreet.run(self, {women = 3, from = Rect2(...), to = Rect2(...)})` (M-03). `g.stats.street_pricks`. |
| C2-03 | `feel(o)` → `Feel.run(self, o, {risky = true})` (M-01). |
| C2-04 | Nuevo personaje `colega` (Pentágono) junto al `medico`; un `choose` de 3 pasos con orden; fallo → `g.note('mala_presentacion', 1)`. Opcional. |
| C2-05 | `f_voz` → `Voices.run(self)` (M-04); el resto del texto se conserva según el resultado. |
| C2-06 | *Spot* `m_c2_hospital` junto a la puerta del Hospital, con `sfx_at('compress')` en bucle cada 3 s (efecto nuevo, generado en `make_audio.py`). |
| C2-07 | `town()` amplía `bounds.x0` a −120 y añade al Oeste de la Puerta un campo con 14 árboles (segmentos verticales en `walls` con `lum` 0,6 y un estilo de dibujo propio: tronco y dos trazos, `tree = true`, sin rayado de sección). |

### Capítulo III (`ch_a.gd: ch3()`)

| Id | Implementación |
|---|---|
| C3-01 | El bucle de 5 se sustituye por la lista de 8 rondas: `[{k='mujer'}, {k='cuad'}, {k='iso'}, {k='penta', spin=0.6}, {k='hexa', spin=0.8, arc=true}, {k='tri', spin=0.4}, {k='circ', cloak=true, options_extra=[BOW]}, {k='cuad', arc=true}]`, con `queue = true` (M-02). Los veredictos por defecto se generan con `tr()`. |
| C3-02 | `hits` sobre 8; con `cfg.difficulty == 'expert'` (sin traza) y 8/8 → `ACH_GATE_P`. Las muescas del sargento: `ui.eye_tally(n)`, un contador en el borde de la línea. |
| C3-03 | Durante el `sight_round('irr')`: `ui.split_view(true)` (un `SubViewport` con la cámara de lámina en la mitad inferior, 3 s), luego `false`. Coste: un segundo render del mundo durante 3 s; aceptable. |
| C3-04 | Si `g.rel_of('calderero') >= 1`: el calderero deja caer el estilete (`Ent` pequeña, `carryable = true`) al pasar junto al jugador; `state.inv.estilete = 1` al recogerlo con `act`. |
| C3-05 | Sustituye `go_to(-41, 13.3, …)` por `await Orient.run(self, {to = Vector2(-41, 13.3)})` (M-05) con la hora a «noche» (`W.set_palette('flat_night')`: la misma paleta con fondo un 12 % más oscuro y la niebla a 9). |
| C3-06 | Nueva escena corta en casa (`set_map(town())`, la esposa y el nieto), con `choose` de 2 opciones y `g.rel('nieto', +1)` si el jugador le cuenta lo del calderero. |

### Capítulo IV (`ch_b.gd: ch4()`)

| Id | Implementación |
|---|---|
| C4-01 | En el Colegio, un *spot* `examen` opcional → 3 `sight_round` con `F_poli(…, 10|11|12)`, `arc = true` y `spin = 0.3`. `ACH_TRIBUNAL` con 3/3. |
| C4-02 | En el primer pigmento: `W.focus = p` y `W.zoom = 8` durante 1,8 s, y `Snd.chord_once('color_first')` (acorde Mmaj9 con arpa y cuerdas). |
| C4-03 | Al pasar al ojo en el mercado: `g.tween(6, …)` que alterna `W.desaturate` (0 ↔ 1) dos veces. `desaturate` es un `uniform` nuevo de `eye_view.gdshader` que convierte la línea a escala de grises. |
| C4-04 | Tras el tribuno: 3 `sight_round` con figuras al azar entre `F_mujer` y `F_circ`, ambas con `set_colors(rojo/verde)`, `turn = PI/2` (de canto) y opciones `[BOW, YIELD]`. El veredicto revela la verdad desde la lámina. |
| C4-05 | Si se cala el fraude: la doncella (`F_mujer` nueva) se aparta; el texto del narrador cambia. |
| C4-06 | `Cine.play` con 3 llaves (artesanos, mujeres, presos) durante el discurso de Pantociclo; las opciones de la elección actual saltan a la llave correspondiente. |
| C4-07 | S-17, patrones. |
| C4-08 | Tras «En media hora…»: `Snd.drone('none')`, `await g.wait(12)` con `W.rain = 0.5`, luego `g.tween(4, …)` que quita los colores lado a lado (`set_colors` con un lado gris más cada 0,3 s). |

### Capítulo V (`ch_b.gd: ch5()`)

| Id | Implementación |
|---|---|
| C5-01 | `F_cuad('hermano', 31.5, -26, …)` en la fila de los Profesionales; conversación con `g.talk_begin` antes de que empiece el oficio (el `go_to` a la fila ahora es a su lado). En la opción herética del cántico: `hermano` se mueve 0,3 u hacia ti, sacudida de 0,2 y `say('hermano', 'Aquí no, hermano.')`. Leitmotiv `hermano` en la primera línea. |
| C5-02 | Antes de la respuesta coral: `await Hymn.run(self)` (M-06). Si `0` aciertos → `g.note('temple_silent', 1)`. |
| C5-03 | Al medir al niño: el arco de `feel()` se extrae a `World.draw_angle(v: Vector2, a0, a1, t)` y se reutiliza aquí, animado en 1,5 s. |
| C5-04 | Escena nueva al final del capítulo, en casa: la tablilla rota (`Ent` irregular en dos mitades), `choose` de 3; la tercera opción → un minijuego de 15 s para alinear las dos mitades girándolas con el stick (encajan con un ángulo menor de 6° y una distancia menor de 0,1 u). Se ajustan las líneas del novicio sobre el tema para que citen `flags.excusa`. |
| C5-05 | *Spot* visual sin interacción: si `flags.novicio_c`, el novicio hace una pausa de 0,6 s (`e.pause = 0.6`) en `Vector2(44, -8)`. |
| C5-06 | El final del capítulo: el Cuadrado en el estudio; `slate_anim` de una línea que crece; `ui.fade` hacia el papel de calco (`dream`) en lugar de hacia negro. |

### Capítulo VI (`ch_c.gd: ch6()`)

| Id | Implementación |
|---|---|
| C6-01 | En la pregunta «¿Cómo veis?»: `g.lenses = ['top', 'eye', 'king']`, `g.set_view('king')` forzado durante 6 s, y después `eye`. `g.ledger('1d.ve')`, `g.ledger('2d.ve')`. |
| C6-02 | Antes del matrimonio: `await VoiceLength.run(self, ['m1', 'm3', 'm4'])` (M-08). |
| C6-03 | Sustituye el `g.until(on_line…)` único por `await LineSection.run(self, [0.25, side, diag])` (M-07); el código de la sección dorada pasa a `Geom3.line_section`. `ACH_KING` con 3/3. `g.ledger('1d.desde_arriba')`. |
| C6-04 | Opcional en la pregunta del matrimonio: `await Harmony.run(self)` (M-09). Al casar: tres `wom.call()` nuevos a 0,4 u del Rey con un `pop`. |
| C6-05 | `Snd.mono(true)` al entrar y `false` al despertar; durante el tramo del jugador fuera de la Línea (`not g.on_line`), `Snd.mono_mix(0.5)` (mezcla parcial). |
| C6-06 | Tras «¡Guerra al intruso!»: el código actual de `st.osc` se sustituye por súbditos que avanzan hacia `g.player.x` a 4 u/s; el éxito se da con `g.player.y > 2` o `< -2`, y si algún súbdito toca la sección antes, hay un pinchazo leve. |

### Capítulo VII (`ch_c.gd: ch7()`)

| Id | Implementación |
|---|---|
| C7-01 | La pizarra de 3² → `DrawBoard` con 16 anclajes en rejilla de 4×4; el jugador traza los 8 segmentos y el resto de la animación actual sigue. En la pregunta de 3³: `DrawBoard` en modo `reject`. |
| C7-02 | Antes de «Mira lo que ocurre si me elevo»: `await SpherePredict.run(self, sph, [0.5, 0.9])` (M-10). Si `flags.king_sections >= 2`, una línea de `asombro`. `ACH_SPHERE` con 2/2. `g.ledger('2d.desde_arriba')` (el círculo que crece y mengua). |
| C7-03 | La segunda `slate_anim` se sustituye por `ui.fill_table(...)`: una tabla de 4×2 donde el jugador asigna números (panel con fichas; en el mando, cursor de celda + fichas). `g.ledger('3d.limites')`. |
| C7-04 | Tras «falta una»: `g.go_to(-23.3, 20.4, 1.2, 'Comprueba tu alacena')`; al llegar, `act` mantenido 0,8 s y `W.focus` en la alacena, que se dibuja con `cofre1`, `cofre2` y solo `tab1` (la otra es el *spot* `tab` del suelo del salón, ya existente). La línea de `logica` es un sonido sin texto (`Snd.sfx('chalk_break')`). |
| C7-05 | En el toque: `g.player.guts.visible = true` durante 3 s, un `fx_add('spark')` *dentro* de la figura y `App.rumble(0.3, 0.6, 0.4)`. |
| C7-06 | Se intercalan 2 objetivos pequeños: `g.until(eye.sees('esfera'))` («gírate hacia la voz») tras los saltos de la Esfera. |

### Capítulo VIII (`ch_d.gd: ch8()`)

| Id | Implementación |
|---|---|
| C8-01 | El `g.tween(5, …)` del ascenso se sustituye por `Cine.play` en modo libre con 3 llaves (9 s): `pitch = 0.02, dist = 30` (a ras: la ciudad es una raya) → `pitch = 0.4, alt = 6` → `pitch = 1.05, alt = 13`. El cambio a `Snd.drone('space')` se hace en la segunda llave. |
| C8-02 | Antes del Consejo: `await g.all(...)` sobre 3 *spots* obligatorios (`h_alacena`, `h_nieto`, `h_acta`) y 3 marginalia opcionales. Cada *spot* de Espacio se activa con `Vector2(p.x - s.x, p.y - s.y).length() < 4 and p.alt < 8` (variante de `go_to` para vuelo: `g.fly_to(x, y, r, alt_max, text)`). |
| C8-03 | Al montar el mapa de `ch8()` se crea `tab2` (`carryable = true`) en el suelo del salón, en la posición del *spot* `tab` del VII (−30,2; 8,6), y la alacena con `cofre1`, `cofre2` y `tab1`. Tras el último hallazgo: `await Carry.run(self, 'tab2', func(e): return ALACENA_RECT.has_point(Vector2(e.x, e.y)), 'Devuelve la tablilla a tu alacena')` (S-13). `ACH_CUPBOARD`. Opcional: el estilete al Hospital (`flags.estilete_hospital`). |
| C8-04 | `town()` recibe una opción `hospital_room`: un recinto cerrado (`inner`) en el Hospital con el calderero en uno de dos estados según `flags.dictamen` y `flags.irregularChoice`. *Spot* opcional `h_calderero`. `ACH_TINKER`. |
| C8-05 | Tras el Cubo construido (código actual): `await CubeSections.run(self, cube)` (M-11). Se añade el saber `secciones`. La tabla no cambia aquí: la celda `2d.desde_arriba` ya se rellenó con la Esfera (`C7-02`). |
| C8-06 | `await ShadowTurn.run(self, cube)` (M-12). Saber `sombras`. |
| C8-07 | El `stop_tess` automático se sustituye por `Tesseract.run(self, tess)` (M-13), que dura hasta que termina el diálogo de la Cuarta. `g.ledger('4d.*')` y `g.ledger('3d.desde_arriba')` (la celda que queda en «?»). |
| C8-08 | La caída: `Cine.play` en modo libre de 4 s, el inverso de `C8-01`. |

### Capítulo IX (`ch_d.gd: ch9()`)

| Id | Implementación |
|---|---|
| C9-01 | Al llegar a 6 u del Punto: `g.lenses = ['flood']` y `g.set_view('flood')`; `eye.view` a pantalla completa (`eye.layout(1.0, …)`) aunque `cam_mode == 'free'`. Las entradas del jugador alteran un `uniform float hue_shift` (±0,03 por acción). `g.ledger('0d.*')`. |
| C9-02 | El bucle de 2 elecciones pasa a `while` hasta agotar las 4 opciones o elegir «(Callar.)». La Esfera se ríe: `Snd.motif('esfera', 'bell')` acelerado al doble. `ACH_SILENT`. |
| C9-03 | Antes del minijuego actual de «Arriba», 2 intentos: `SpherePredict` en modo demostración (el jugador hace crecer y menguar un círculo con el stick; sin acierto) y `DrawBoard` con la sombra guía. Respuestas del nieto según `g.rel_of('nieto')`. |
| C9-04 | Antes de «¡Ja, ja, ja!»: si `rel_of('nieto') >= 1`, `await g.wait(2)` con `nieto.face(puerta)`, `W.focus` sobre el heraldo al otro lado del muro y `Snd.motif('nieto', invert = true, detune = 0.3)`. |
| C9-05 | Antes de `a.outro()`: montaje de 3 planos de 12 s cada uno (`DrawBoard` en modo `reject`, el Cubo borroso en `Space.make_cube()` con `dim` animado y la tablilla con el título). |

### Capítulo X (`ch_d.gd: ch10()`)

| Id | Implementación |
|---|---|
| C10-01 | Al principio, en el estudio: `ui.panel('El tratado', …, cards)` con los saberes disponibles de la lista `['analogia', 'secciones', 'sombras', 'lineal', 'punto']`; se eligen 2 (3 si `rel_of('archivero') >= 1`). `state.argumentos`. |
| C10-02 | Cada `choose([{t = '(Callar.)'}…])` de la Sociedad se acompaña de `Restraint.run(self, speed)` en paralelo (M-14). |
| C10-03 | Antes de la primera pregunta: `for r in g.record_top(5): await say(r.who, tr(book.record[r.id].text))`. Si `record.is_empty()`: la línea alternativa del Presidente y `ACH_FILE`. |
| C10-04 | La `slate_anim` de la segunda pregunta → `DrawBoard` con anclajes de la sombra de `flags.shadow_xf` (o una por defecto) + 16 extra; `Sketch.classify()` decide la respuesta del Presidente. |
| C10-05 | Tras la sentencia: según `stats.gate_hits >= 7` → el sargento (`F_iso`) entre los guardias baja la cabeza (`rot` + `pause`). |
| C10-06 | El epílogo de la celda se reescribe como un bucle de 3 visitas `[1, 4, 7]`: `ui.chapter_tag('Año %d' …)`, las muescas de la pared crecen (`labels`), la visita del hermano y `Brother.run(self, argumento)` (M-15), y su respuesta. En la visita 7: el hermano con `sc = 0.92` y `speed = 0.6` (más viejo) y su línea final. Leitmotiv `hermano` lento. |
| C10-07 | Las frases del cierre del manuscrito se amplían con `rel` e `inv` (tabla de condiciones en `book.*.json → epilogue`, evaluada en orden). |
| C10-08 | Tras la última frase: `await ch_frame.closing()` (S-15). |
| C10-09 | `Profile.unlock_gallery('prefacio')` y `Profile.unlock_mode('college')`. |

### Modo Colegio (`content/college.gd`, nuevo)

Un mapa (el interior del Colegio) con 5 *spots*, uno por minijuego (M-01, M-02, M-03, M-11 y la ronda inversa). Cada uno ejecuta 5 rondas de dificultad creciente con los mismos parámetros que en la historia. Las medallas se guardan en `Profile.college`. Acceso desde el menú principal una vez desbloqueado.

---

## 7. Plataforma y Steam

- **`sys/platform.gd`** (autoload `Platform`): `is_steam() -> bool`, `unlock(id)`, `set_stat(key, v)`, `cloud_enabled() -> bool` y `overlay_active() -> bool`. Implementación con **GodotSteam** (GDExtension) si `Engine.has_singleton("Steam")`; si no, no hace nada salvo el espejo local en `Profile.ach`. La versión web y las pruebas no cargan la extensión.
- **Steam Cloud:** configurado en Steamworks (*Auto-Cloud*) sobre `user://slot_*.json` y `user://profile.json`. No requiere código.
- **Pausa con el overlay:** si `Platform.overlay_active()` pasa a `true` durante el juego, se abre la pausa.
- **`export_presets.cfg`:** se añaden los presets *Windows Desktop* (x86_64) y *macOS* (universal, opcional) a los actuales *Web* y *Linux*. `tools/export.sh` acepta `--steam` para exportar las tres plataformas de escritorio a `build/steam/<plataforma>/` (**sin** versionar en git, al contrario que `build/web` y `build/linux`).
- **Demo** (`App.demo`, definido por una característica de exportación `demo`): `main.run()` se detiene al terminar el bloque III y muestra una pantalla de «lista de deseos» con el enlace a la tienda (`OS.shell_open`). La exportación web se hace siempre en modo demo.
- **Steam Deck:** resolución por defecto de 1280×800; la interfaz ya escala por puntos (`App.fit`). Se comprueba que ningún texto baje de 9 px lógicos en el tamaño «normal», y que el teclado en pantalla no se necesite nunca (no hay entrada de texto).
- **Rendimiento:** objetivo de 60 fps estables en el Steam Deck en todas las escenas (el VIII es la más cara: mundo completo + cámara libre + teseracto); se mide con `--shots` y el monitor de rendimiento.

---

## 8. Pruebas

### 8.1 Automatizadas (sin interfaz)

| Comando | Qué comprueba |
|---|---|
| `godot --headless --path godot -- --auto --ch=0 --quit --log` | Recorre todo el guion (ya existe). Debe terminar con `FIN OK frags=22 margins=0`. |
| `… -- --auto --script=heretic --quit --log` | Igual, eligiendo siempre la opción con `tag` de herejía o cuestionar. Comprueba que `record` tenga al menos 4 entradas (6 cuando existan `hospital_miracle` y `estilete_en_poder`) y que el X lea 5. |
| `… -- --auto --script=orthodox --quit --log` | Siempre la ortodoxa: `record` vacío y la línea alternativa del Presidente. |
| `… -- --auto --lang=en --quit --log` | Sin cadenas sin traducir (S-10). |
| `godot --headless --path godot -- --test` | Pruebas unitarias (`tests/run.gd`, lanzado desde `main.gd` para que existan los autoloads): `test_geom3`, `test_sketch`, `test_save` (migración v1 → v2) y `test_i18n` (todo msgid del `.pot` existe en `en.po`). |
| `python3 godot/tools/extract_strings.py --check` | Falla si hay cadenas con `%` sin `tr()` o si el `.pot` está desactualizado. |

`--script=<nombre>` es un parámetro nuevo: en `ui.choose`, con `g.auto`, en lugar de la opción 1 se elige según la política (`heretic`: la primera con `tag` en {Herejía, Cuestionar, Osadía, Atreverse, La verdad}; `orthodox`: la primera sin `tag`, o con {Obedecer, Ortodoxia, La mentira}).

### 8.2 Autómata con interfaz

`--bot` (ya existe) recorre la interfaz real. Se amplía para que los minijuegos M-03, M-05, M-07 y S-13 (los de movimiento) usen el camino automático, igual que hoy `feel()` con `g.bot`.

### 8.3 Pruebas manuales por hito

- **Lista de comprobación** por capítulo con cada `Cn-xx`: se juega con teclado, con mando y en táctil (`--touch --dpr=2.6`), y en el Steam Deck desde el hito M3.
- **Prueba de juego externa** en M1, M4 y M6, con 5 personas que no conozcan el libro. Se mide la duración por capítulo (`stats.play_s` por bloque, guardado en el perfil) y se pregunta en una frase qué han entendido de la Tercera Dimensión. Objetivo: 65–75 min de mediana y, en la pregunta final, que al menos 4 de 5 expliquen la analogía de las secciones con sus palabras.

---

## 9. Plan de entregas y prioridades

### 9.1 Prioridades

- **P0** — imprescindible para publicar; por sí solo lleva el juego a unos 60 minutos.
- **P1** — pulido que distingue al juego y lo acerca a los 70 minutos.
- **P2** — opcional, tras el lanzamiento o si sobra tiempo.

| Prioridad | Identificadores |
|---|---|
| P0 | S-01 (mando), S-02 (huecos y migración), S-03 (expediente, sin avisos), S-05 (tabla), S-06 (lentes), S-07 (solo posicional), S-09 (historial, velocidad), S-10 (inglés), S-12, S-13, S-15 · P-01, P-03 · C1-01, C1-03 · C2-02 · C3-01, C3-05 · C5-01 · C6-01, C6-03 · C7-02, C7-04 · C8-01, C8-02, C8-03, C8-05, C8-06 · C10-03, C10-04, C10-06, C10-08 · §7 completo salvo macOS |
| P1 | S-04 (marginalia), S-08 (raíles), S-11, S-14 (resto), S-16, S-17, leitmotivs y mono · P-02, P-04, P-05, P-06 · C1-02, C1-04, C1-05 · C2-01, C2-03, C2-05 · C3-02, C3-03, C3-04, C3-06 · C4-02, C4-04, C4-06, C4-07, C4-08 · C5-02, C5-03, C5-04 · C6-02, C6-05, C6-06 · C7-01, C7-03, C7-05, C7-06 · C8-04, C8-07, C8-08 · C9-01, C9-03, C9-04, C9-05 · C10-01, C10-02, C10-07, C10-09 |
| P2 | C1-06 · C2-04, C2-06, C2-07 · C4-01, C4-03, C4-05 · C5-05, C5-06 · C6-04 · C9-02 · C10-05 · modo Colegio · idiomas adicionales · macOS |

### 9.2 Hitos (una persona a tiempo completo; estimación orientativa)

| Hito | Contenido | Semanas | Resultado verificable |
|---|---|---|---|
| **M0 · Cimientos** | S-01, S-02, S-03, S-09, S-10 (infraestructura y `.pot`), S-07 (posicional), S-08, `tests/run.gd` | 3 | El juego actual completo con mando, en tres huecos, sin avisos, con historial y con el `.pot` generado. Todas las pruebas automáticas en verde. |
| **M1 · Parte I** | P-01…P-06, C1, C2, C3; S-04, S-06 (lluvia), M-01…M-05 | 3,5 | Demo de Steam jugable (Prólogo–III, ≈ 22 min). **Primera prueba externa.** |
| **M2 · Colores y Templo** | C4, C5; patrones; M-06 | 2 | IV–V completos. |
| **M3 · Linealandia y la Esfera** | C6, C7; S-06 (lentes), S-11, S-12 (parte 2D), M-07…M-10; mono | 2,5 | VI–VII completos; la analogía «sección propia → sección de la Esfera» funciona. |
| **M4 · Espaciolandia** | C8; S-12 (3D), S-13, M-11…M-13 | 3 | VIII completo, a 60 fps en el Deck. **Segunda prueba externa.** |
| **M5 · Final** | C9, C10, S-15, S-16, M-14, M-15; galería | 2,5 | El juego completo de principio a fin, en español. |
| **M6 · Publicación** | Inglés completo, §7, logros, Deck, S-17, accesibilidad, modo Colegio (si da tiempo), corrección de errores | 3 | *Release candidate*. **Tercera prueba externa.** |
| **Total** | | **≈ 19,5** | |

Orden justificado: M0 primero porque el mando y la localización tocan todas las cadenas y entradas, y hacerlo al final multiplica el trabajo. M1 produce la demo, que es lo que necesita la página de la tienda (Next Fest) mientras se hace el resto.

---

### 9.3 Estado: M0 implementado

Rama `diseno-juego-completo`. Lo hecho, y en qué se aparta de lo especificado arriba:

| Componente | Estado | Notas |
|---|---|---|
| S-01 Entrada y mando | Hecho | Acciones en `sys/keys.gd` (no en `project.godot`); A/B también en `ui_accept`/`ui_cancel`. Menús, pausa, inventario y ajustes navegables con foco; las respuestas (`choose`) y los paneles (`panel`) con cruceta o stick y A. Glifos **de texto** (`ui/glyphs.gd`: «A», «Cruz», «RB»…); la fuente de iconos queda para M6. `Ch.tx(kb, touch, pad)` devuelve la plantilla con `{act}`, `{view}`, `{move}`… y la interfaz la rellena. Reasignación de teclas (no de mando) en Ajustes. `App.rumble`. Stick derecho: mirada libre y giro en el ojo. |
| S-02 Estado v2, perfil, huecos | Hecho | Autoload `Profile` (`sys/profile.gd`). Escritura atómica (temporal + renombrar; en web, directa). Menú: Continuar, Nueva partida (elige hueco; los ocupados piden confirmación), Cargar partida, Capítulos (por perfil). `stats.play_s` cuenta el tiempo. `--auto` no lee ni escribe partidas (`--save` lo fuerza). |
| S-03 Expediente y relaciones | Hecho | `g.note/record_top/record_text/rel/rel_of`; sin avisos en `rep()`/`her()`. Anotaciones enganchadas en III, IV y V; `hospital_miracle` y `estilete_en_poder` tienen texto pero esperan a `C8-04` y al X. La pestaña «Posición» pasa a ser **«Personas»** (siete relaciones con frase, `book.people`). |
| S-07 Audio posicional | Hecho (solo posicional) | `AudioListener3D` en el ojo del Cuadrado; `Snd.sfx_at` con 8 reproductores 3D; subtítulos de sonido con dirección. El Grito de Paz ya es posicional donde suena hoy; el bucle por figura (`Ent.cry`) se añade con `C2-02` (M1). Leitmotivs y mono, en M3. |
| S-08 Raíles y franjas | Hecho | `Cine.play` (llaves de foco/zoom o de cámara libre), `Cine.orbit` (para `P-03`), `ui/letterbox.gd` con «mantén para saltar». Reducir movimiento. Aún no lo usa ningún capítulo (prueba: `--cinetest`). |
| S-09 Lectura | Hecho | Historial (pestaña, H/R3, pausa), velocidad de texto, avance automático, saltar lo leído (Ctrl/B), punto de tinta en las respuestas ya elegidas. La clave de una elección es el capítulo más un hash de sus textos. |
| S-10 Localización | Infraestructura | `I18n.t()` dentro de `say/narrate/choose/note/panel/panel_info/objective/title/toast/chapter_tag` y en los nombres de quien habla. `book.json` → `book.es.json` (y `book.<lang>.json` opcional). `tools/extract_strings.py` (910 textos) y `--check`. `en.po` sin traducir (M6); `--lang=en` informa de cuántos textos faltan. |
| Pruebas | Hecho | `-- --test` (86 comprobaciones: migración, perfil, i18n, teclas y glifos, raíles), `--script=heretic/orthodox`, `--lang=en`, y el autómata `--bot` recorre el juego entero. Para probar el mando sin mando: `--inject`. |

### 9.4 Estado: M1 implementado

Prólogo y capítulos I–III con las mejoras del diseño. Lo hecho y en qué se aparta:

| Id | Estado | Notas |
|---|---|---|
| P-01 Mesa del lector | Hecho | `content/ch_frame.gd`. En lugar de una escena aparte con un render a textura, la mesa (madera, libro abierto por la portada de 1884 y la dedicatoria, lápiz rojo, regla, lámpara con luz) se construye **en el mismo espacio 3D que el Plano**, alrededor del suelo recortado al tamaño de un folio. El último encuadre del descenso es exactamente el de la cámara de lámina (`ChFrame.lamina_cam`), así que no hace falta fundido cruzado. Sin modelos de Blender. Se ve al empezar el Prólogo y se salta manteniendo pulsado. `--noframe` la omite. |
| P-02 Muescas | Hecho | 7 grupos «IIII» en la pared Norte y nota al margen. |
| P-03 Moneda | Hecho | `Cine.orbit` alrededor de la moneda (3,5 s) desde el lado del jugador, con «círculo», «elipse» y «línea» de tiza, y fundido a la línea del ojo. |
| P-04 Gancho | Hecho | En negro, una sola vez por perfil (`Profile.data.seen_hook`). |
| P-05 Tutorial | Hecho | Girar → avanzar → mirar → lente → acción, cada aviso se va al cumplirse. |
| P-06 Tablilla | Hecho | «Quizá ya me estás leyendo». |
| C1-01 Alacena | Hecho | Obligatoria; llave mantenida (0,8 s, `s_lock`); desde la lámina se ven `cofre1/2` y `tab1/2`. |
| C1-02 Lluvia | Hecho, con cambio | Se hace **fuera de casa**, al salir por la puerta Oeste: bajo techo no llueve y el centelleo no se vería. |
| C1-03 Juego de los ángulos | Hecho | `minigames/feel.gd` con `toy` y `blind` (venda: `shaders/blindfold.gdshader`). |
| C1-04 Hasta diez | Hecho | La esposa patrulla; descubierto → mentira o verdad (`hija_cuenta`). `ACH_COUNT`. |
| C1-05 Esposa | Hecho | Va y viene de punta con su Grito de Paz (`Ent.cry`); si te pincha, «¿No me oías?». |
| C1-06 Casa viva | Hecho | Nietos que se persiguen, hijos que van y vienen, uno sale a su consulta, criado barriendo. |
| C2-01 Escala viva | Hecho | `Cine.play` sin franjas bajo el diálogo (parámetros nuevos `bands` y `stop`). El diagrama del inventario queda para P1. |
| C2-02 Cruzar la calle | Hecho | `minigames/cross_street.gd`. El comerciante está en la acera Norte; al acercarse, se cruza en el ojo con niebla 5. `ACH_STREET`. |
| C2-03 Comerciante | Hecho | `feel` con `risky`. |
| C2-04 Presentación | Hecho | Colega del médico; tres pasos en orden; fallo → `mala_presentacion`. |
| C2-05 Voces | Hecho | `minigames/voices.gd`; `Snd.voice_at` con vibrato (38 centésimas) en las falsas. `ACH_EAR`. |
| C2-06 Hospital | Hecho | Celador, nota al margen y golpes posicionales (`s_compress`). |
| C2-07 Árboles | Hecho | `map.trees` (trazo y dos ramas), `bounds.x0 = -120`, nota de los viajeros. |
| C3-01 Cola de la Puerta | Hecho | 8 rondas: quietas, girando (`spin`, `arc`), de incógnito (`cloak`, «Inclinarse»); la siguiente espera en la niebla; campanilla a los 15 s. Ofensa al Círculo → `gate_circle_offense`. |
| C3-02 Nota del perito | Hecho | `ui.eye_tally`; 8/8 en «perito» (sin traza) → `ACH_GATE_P`. Ajuste nuevo: dificultad de las deducciones (relajada con segundo intento, normal, perito). |
| C3-03 Plano partido | Hecho | `ui.split_view`: un `SubViewport` con la cámara de lámina en el 44 % inferior durante 3 s. |
| C3-04 Estilete | Hecho | Si fuiste amable con el calderero: lo deja caer, se recoge, `state.inv.estilete`; se ve en «Personas». |
| C3-05 A casa sin lámina | Hecho | `minigames/orient.gd`, paleta `flat_night`, tirón del Sur (`g.pull`), lluvia a mitad de camino, la esposa grita en la puerta del Este, el criado llama a los 90 s. `ACH_HOME`. |
| C3-06 Cena tarde | Hecho | Elección contar/callar; `rel nieto +1`. |
| S-04 Marginalia | Hecho | 14 notas en Prólogo–III (`book.margins`): brillo de tinta a menos de 6 u, chispa en la línea del ojo, pluma (`s_quill`). Se leen en el Manuscrito, «Notas al margen». |
| S-06 Lluvia en el ojo | Hecho | Hasta 64 gotas como dos trazos cortos (en la caída y de través). Las lentes `point` y `flood`, en M3. |
| Logros | Local | `g.achieve` guarda en el perfil y avisa; la subida a Steam llega con `Platform` (M6). |

Efectos nuevos (`tools/make_audio.py --extra`, en WAV porque no requiere ffmpeg): `lock`, `quill`, `compress`, `chime`, `hum`. Pruebas: `-- --test` (130 comprobaciones, incluida la de que todo id de nota, anotación y logro tenga texto), las cuatro pasadas `--auto` y el autómata. Parámetros nuevos para probar: `--until=N` (para después del capítulo N), `--botdt=s` (autómata más lento, para capturas) y `--noframe`.

### 9.5 Estado: M2 implementado

Capítulos IV y V con las mejoras del diseño:

| Id | Estado | Notas |
|---|---|---|
| C4-01 Examen | Hecho | Mesa del tribunal en el Colegio (opcional): tres `sight_round` con `poli10/11/12` (nuevo), `far = 8.5`, en arco y girando. `ACH_TRIBUNAL` y nota «Tres años para esto». |
| C4-02 Primer color | Hecho | Primer plano de 1,8 s y `Snd.chord_once` (Maj9 con arpa, cuerdas y campana). |
| C4-03 Gris y color | Hecho | `Eye.desat` → `u_desat` en `eye_view.gdshader`; 6 s alternando dos veces. |
| C4-04 ¿Mujer o Sacerdote? | Hecho | Tres figuras mitad rojas, mitad verdes, de canto; opciones `BOW` y `YIELD` (nueva). |
| C4-05 Fraude | Hecho | La doncella se aparta si calas al Isósceles, y el narrador se corrige. |
| C4-06 Tres planos | Hecho | Sin `Cine.play`: el foco va a los artesanos, a las mujeres (que giran de punta hacia los soldados) y, según la elección, a ellas o a los presos. |
| C4-07 Patrones | Hecho | `shaders/pattern.gdshaderinc`: 8 rayados, elegidos por el **tono** del color (no hace falta etiquetar nada). En la lámina, `Ent.build` añade una banda rayada junto a cada lado pintado; en la línea del ojo, el rayado se superpone a la tinta. Ajuste «Colores con patrón» (activado por defecto). |
| C4-08 Silencio | Hecho | 12 s sin música con lluvia; luego el color se va lado a lado. |
| C5-01 Hermano | Hecho | En la fila de los Profesionales; conversación antes del oficio; si susurras, te pisa el lado («Aquí no, hermano») y `rel hermano −1`. El leitmotiv queda para M3. |
| C5-02 Cántico | Hecho | `minigames/hymn.gd` (M-06). 0 aciertos → `temple_silent`; 3–4 → el coro; 4 → `ACH_HYMN`. Sustituye a «(Mover la boca sin voz)». |
| C5-03 Medición | Hecho | El arco de 60° se dibuja en el vértice del niño (1,5 s). |
| C5-04 La excusa | Hecho, con cambio | Al **empezar** el capítulo (por la mañana, en casa), para que el novicio pueda referirse a lo que hiciste (`flags.excusa`). La tercera opción es un minijuego: girar la mitad suelta hasta que encaje (6°), 15 s como máximo. |
| C5-05 Gimnasio | Hecho | Rótulo del Gimnasio y pausa del novicio ante él si le preguntaste por sus lados. |
| C5-06 Puente | Hecho | El Cuadrado dibuja una Línea en su tablilla y el fundido va al papel lila del sueño; el fundido vuelve solo al papel de siempre al desaparecer. |

Notas al margen: 7 más (pasquín, vitrina, poema, examen, ujier, tablas de lados, fila de las mujeres). `--try=` admite `exam`, `woman`, `hymn` y `mend`.

---

## 10. Riesgos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| GodotSteam sin una versión compatible con Godot 4.7 en el momento de publicar | Media | Alto | `Platform` está aislado: si no hay extensión, el juego funciona sin logros. Alternativa: usar la última versión estable de Godot compatible para la build de Steam (el proyecto no usa nada exclusivo de 4.7) o el SDK de Steamworks vía GDExtension propia. Decidir en M0. |
| La traducción con `tr()` implícito rompe las cadenas con formato | Alta | Medio | La herramienta `extract_strings.py --check` en la integración continua, y las ocurrencias actuales ya están listadas (S-10). |
| El audio posicional no se percibe bien en altavoces de portátil | Media | Medio (C2-02, C3-05) | Los subtítulos de sonido con dirección (S-07) están activados por defecto y el parpadeo del vaivén en el ojo es una segunda pista visual. |
| La deducción de secciones (M-10, M-11) resulta demasiado difícil para el público general | Media | Medio | Las opciones son siluetas (no números), el fallo enseña la respuesta animada, y el modo relajado da un segundo intento. Se mide en la segunda prueba externa. |
| El rendimiento del VIII en el Deck (mundo completo + sección + sombra + teseracto) | Baja | Medio | La sección y la sombra son, a lo sumo, 24 vértices en CPU; el teseracto, 32 aristas. Si hace falta, el `Eye.cast` se desactiva en el modo libre (ya ocurre) y las entrañas se dibujan solo en los edificios cercanos. |
| `ui.gd` (1154 líneas) crece sin control | Alta | Medio | Las piezas nuevas van a `ui/` (sección 3); `ui.gd` solo las instancia. Límite orientativo: que `ui.gd` no pase de 1300 líneas. |
| El alcance no cabe en el calendario | Media | Alto | La lista P0 es un juego completo por sí sola (≈ 60 min). P1 y P2 se recortan por orden sin dejar mecánicas a medias: cada `Cn-xx` es independiente salvo las dependencias marcadas (`C1-01` → `C7-04` → `C8-03`; `C8-06` → `C10-04`; `C10-01` → `C10-06`). |
