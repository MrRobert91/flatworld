# Planilandia — Un romance de muchas dimensiones

Aventura narrativa basada en *Flatland* (Edwin A. Abbott, 1884).
Vives la historia como el Cuadrado: descubres las reglas de su sociedad, recibes la visita
de la Esfera y pagas el precio de haber visto la tercera dimensión.

## Dos versiones

El repositorio contiene dos versiones del mismo juego, cada una en su carpeta:

| Carpeta | Versión | Para qué |
|---|---|---|
| [`godot/`](godot/) | **Godot 4.7 + Blender** | La versión principal: exporta a web y a Linux, con controles táctiles rehechos para móvil. |
| [`web/`](web/) | three.js (original) | Sitio estático sin compilación; se conserva tal cual. |

Las dos comparten guion, capítulos y mecánicas. Cada carpeta tiene su propio README con cómo ejecutarla.

## Diseño del juego completo

- [`docs/DISENO_JUEGO_COMPLETO.md`](docs/DISENO_JUEGO_COMPLETO.md): análisis del estado actual y mejoras, capítulo a capítulo, para llegar a un juego de ~70 minutos para Steam.
- [`docs/SDD_JUEGO_COMPLETO.md`](docs/SDD_JUEGO_COMPLETO.md): especificación técnica para implementarlas (componentes, datos, pruebas, hitos).
