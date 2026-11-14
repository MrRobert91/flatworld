# Planilandia (versión Godot): sirve la exportación web con nginx.
# Contexto de construcción: esta carpeta (godot/). La exportación está versionada en build/web/.
FROM nginx:1.27-alpine
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY build/web/ /usr/share/nginx/html/
# precomprime lo pesado una sola vez, en vez de en cada petición
RUN cd /usr/share/nginx/html && gzip -9 -k index.wasm index.pck index.js
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
