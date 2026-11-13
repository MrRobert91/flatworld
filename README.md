# Planilandia — Un romance de muchas dimensiones

Aventura narrativa para navegador (three.js) basada en *Flatland* (Edwin A. Abbott, 1884).
Vives la historia como el Cuadrado: descubres las reglas de su sociedad, recibes la visita
de la Esfera y pagas el precio de haber visto la tercera dimensión.

## Jugar

Es un sitio estático, sin compilación. Los módulos ES necesitan servirse por HTTP:

```bash
python3 -m http.server 8000     # o: npx serve
# abre http://localhost:8000
```

three.js va incluido en `vendor/`; no hace falta instalar nada.

## Controles

| Tecla | Acción |
|---|---|
| WASD / flechas | moverse (Mayús: deprisa) |
| V | cambiar entre **la lámina** (vista cenital) y **el ojo** (vista dentro del plano: una línea) |
| E | hablar · examinar · palpar |
| Espacio / clic | continuar el texto · 1–9 elegir respuesta |
| J | el manuscrito, los saberes y tu posición social |
| M · Esc | sonido · menú |
| Ratón, R / F | en Espaciolandia: mirar alrededor, subir y bajar |

## Qué hay dentro

- **Prólogo + 10 capítulos** que siguen las 22 secciones del libro: la casa pentagonal, la Calle
  Mayor, la Puerta Oeste, la Sedición Cromática, el Templo, Linealandia, el Forastero,
  Espaciolandia, Puntolandia y el juicio.
- **Dos vistas del mismo mundo.** Desde arriba, las figuras son «sombras duras de bordes
  luminosos». Desde dentro, todo es una línea que la niebla apaga con la distancia: se traza
  rayo a rayo en 2D, así que el Reconocimiento por la Vista funciona como lo describe Abbott.
- **El manuscrito.** Cada escena recupera una sección del libro (22 en total), legible con J.
- **Rol social.** Diálogos ramificados con voces interiores; reputación ante el Sacerdocio, la
  Ciudadanía y la Autoridad; una balanza entre ortodoxia y herejía; saberes que desbloquean
  respuestas. Puedes cuestionar, obedecer o callar. Los hechos del libro no cambian.
- **Situaciones, no lecciones:** identificar figuras en la niebla, palpar un ángulo, pintarte con
  los colores prohibidos, ocupar tu fila en el Templo, cruzar el reino de una sola dimensión,
  volar sobre tu propia casa, intentar moverte «hacia Arriba».

## Estructura

```
index.html · css/style.css
src/main.js            arranque y menú
src/game.js            bucle, entrada, guardado, utilidades de guion
src/world.js           mundo plano: geometría, figuras, colisiones, cámara
src/eye.js             la vista 1D (trazado de rayos + niebla)
src/ui.js · audio.js   interfaz DOM · sonido procedural (WebAudio)
src/content/book.js    las 22 secciones y los saberes
src/content/ch_*.js    los capítulos
```

Parámetros de desarrollo: `?ch=N` salta al capítulo N; `?auto` recorre el guion sin esperas.
El progreso se guarda por capítulos en `localStorage`.
