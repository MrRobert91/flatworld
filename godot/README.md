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

`godot/build/web/` y `godot/build/linux/` **se versionan**: la web es lo que despliega el Dockerfile y
`build/linux/planilandia.x86_64` es un ejecutable listo para descargar y lanzar (`chmod +x` si hace falta).
Tras cambiar el juego, vuelve a ejecutar `godot/tools/export.sh` y sube `build/web/` y `build/linux/` en el mismo commit.

## Docker y despliegue

La imagen sirve `build/web/` con nginx y precomprime el `.wasm` (39 MB → 10 MB en la red):

```bash
cd godot
docker compose up --build       # http://localhost:8080
# o bien
docker build -t planilandia-godot . && docker run --rm -p 8080:80 planilandia-godot
```

La imagen no compila nada: sólo copia la exportación ya versionada, así que el servicio de despliegue
no necesita Godot.

**Sliplane** (u otro servicio que construya desde el repositorio):

| Ajuste | Valor |
|---|---|
| Repositorio / rama | este repo, `main` |
| Dockerfile | `godot/Dockerfile` |
| Contexto de Docker | `godot` |
| Puerto | `80` (HTTP) |
| Comprobación de salud | `/` |

No hacen falta variables de entorno ni volúmenes: la partida se guarda en el navegador de cada jugador.

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

## Aspecto: el cuaderno de dibujo técnico

Todo el mundo está dibujado a tinta sobre papel milimetrado: fibra y grano de papel, cuadrícula fina y
maestra, rayado de sección en figuras y edificios, y los trazos de construcción de un delineante
(circunferencias circunscritas, centros, lados prolongados más allá del vértice, el marco de la lámina).
Cada mundo es una lámina distinta: papel crema (Planilandia), papel de calco (el sueño de Linealandia),
papel de acuarela (el tiempo de los colores), papel gris (la celda) y un cianotipo (Espaciolandia).

## Interfaz y accesibilidad

- La interfaz se mide en puntos del dispositivo (`App.fit`), no en píxeles: en un móvil de alta densidad
  el texto y los botones tienen el tamaño de cualquier aplicación nativa (botones de 48 puntos o más).
- Texto oscuro sobre cartelas de papel, con contraste alto; los colores de cada personaje se oscurecen
  para leerse sobre papel.
- Ajustes en el menú y en la pausa: tamaño de interfaz (pequeño, normal, grande, muy grande), sonido y
  pantalla completa. Se guardan en `user://planilandia_cfg.json`.
- Menú de pausa (botón ☰ o Esc) con acceso al manuscrito y salida al menú.
- Para probar un móvil en escritorio: `godot -- --touch --dpr=2.6` con una ventana de 2280×820.

## La visión del ojo

Sigue siendo la línea que describe el libro, y la niebla sigue siendo lo que permite leerla, pero ahora:

- la claridad cae deprisa dentro de cada figura desde su punto más cercano (un ángulo agudo se pierde
  al instante; un Pentágono, con suavidad), en vez de depender sólo de la distancia absoluta;
- cada lado se sombrea un poco según su inclinación respecto a la mirada, y los vértices dejan una marca leve;
- una figura delante de otra queda separada por un corte fino; los muros llevan un rayado y las figuras no;
- bajo la línea hay una regla graduada cada 5°, y el perfil de claridad cuando se aprende el
  Reconocimiento por la Vista.

## Vida de las escenas

- **Quién habla:** la figura que habla late y emite ondas de color; las que están cerca se vuelven hacia
  ella y la cámara se desliza a medio camino (también desde el Espacio). Cuando habla «la multitud», late toda.
- **Paseantes con recado:** la gente de la calle va de puerta en puerta (`ai = {type = "stroll", pts = [...]}`),
  arranca y frena con suavidad, y se detiene a saludarse al cruzarse.
- **La matanza del Color:** las mujeres retroceden de punta, los presos rematan, los artesanos se apartan;
  cada caído gira, se encoge y deja una marca en el papel (`World.slay`).
- **Lluvia:** gotas que caen del Norte y rompen contra tejados, muros y figuras; dentro de las casas no llueve.
- **Pinchazos:** chocar de frente con la punta de una Mujer o de un Isósceles hiere (retroceso, sacudida,
  destello); con un vértice de Equilátero o de Cuadrado la reacción es menor; con más lados no pincha.
  Para probarlo: `godot -- --ch=2 --prick=iso` (o `mujer`, `tri`, `cuad`, `penta`).
- **Espaciolandia:** la misma lámina de Planilandia vista desde Arriba, con el Norte arriba.

## Estructura

```
project.godot · main.tscn · export_presets.cfg
Dockerfile · docker-compose.yml · docker/nginx.conf   imagen de la exportación web
build/web/             exportación web (versionada)
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
