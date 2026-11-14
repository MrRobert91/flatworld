# Planilandia — versión Godot

Port completo del juego a **Godot 4.7** (renderizador Compatibility, para que funcione en WebGL 2 y en móviles),
con los modelos de Espaciolandia y el icono hechos en **Blender**.

## Ejecutar

```bash
godot --path godot              # abre el juego (o ábrelo desde el editor)
godot --path godot -- --touch   # fuerza los controles táctiles con el ratón
godot --path godot -- --ch=6    # salta al capítulo 6
```

## Exportar (web y Linux)

Con las plantillas de exportación de Godot 4.7 instaladas:

```bash
godot/tools/export.sh
# → godot/build/web/index.html          (sírvelo por HTTP: python3 -m http.server -d godot/build/web)
# → godot/build/linux/planilandia.x86_64
```

La exportación web es de un solo hilo: no necesita cabeceras COOP/COEP y se puede alojar en cualquier
servidor estático. En la web los parámetros van en la URL: `?ch=6`, `?touch`.
`godot/build/` no se versiona.

## Qué cambia respecto a la versión three.js

Mismas mecánicas, capítulos y texto. Además:

- **Linealandia:** el Rey y sus súbditos ya no giran para hablarte; no pueden salir de su Línea.
- **Movimiento:** palanca flotante analógica (aparece donde apoyas el pulgar; inclinar más es correr),
  aceleración suave, la cámara se adelanta al movimiento y queda una estela al correr.
- **Inventario:** el manuscrito, los saberes y la posición social se abren con un icono en la parte
  superior (o con J en teclado). El icono se oculta durante los diálogos.
- **Diálogos:** bloques de texto completos en la parte inferior, con las respuestas en una lista
  minimalista bajo el bloque (mismas opciones, etiquetas y bloqueos).
- **Sin cargas:** los capítulos se encadenan en la misma escena; el rótulo de capítulo aparece sobre
  el mundo ya dibujado y se salta con un toque. Los sonidos se sintetizan en segundo plano.
- **Vista 1D en la GPU:** el trazado de rayos de «el ojo» es un sombreador, no un bucle por fotograma.

## Estructura

```
project.godot · main.tscn · export_presets.cfg
scripts/main.gd        arranque, menú, cadena de capítulos
scripts/game.gd        bucle, entrada, guardado, utilidades de guion
scripts/world.gd       mundo plano: mapa, muros, colisiones, cámara
scripts/entity.gd      figuras · geo.gd  mallas
scripts/eye.gd         la vista 1D · shaders/eye_*.gdshader
scripts/ui.gd          HUD, diálogos, inventario, menú · pad.gd  controles táctiles
scripts/audio.gd       sonido procedural · space.gd  objetos de Espaciolandia
scripts/content/       ch.gd (base y minijuegos) · ch_a…ch_d.gd (capítulos)
data/book.json         las 22 secciones y los saberes
assets/models/         espacio.glb (generado con Blender)
tools/                 blender_assets.py · espacio.blend · export.sh
```

Para regenerar los modelos y el icono: `blender --background --python godot/tools/blender_assets.py`.

## Pruebas

```bash
godot --headless --path godot -- --auto --ch=0 --quit --log   # recorre todo el guion sin interfaz
godot --path godot -- --bot --speed=5 --ch=0 --quit --log     # un autómata juega con la interfaz real
```

El autómata salta a los objetivos y elige al azar; no prueba los minijuegos que piden entrada manual
(palpar un ángulo, la lección del nieto, la primera pregunta del juicio).

Las fuentes (IM Fell English, Cormorant Garamond) se distribuyen bajo SIL OFL; las licencias están en
`assets/fonts/`.
