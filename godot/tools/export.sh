#!/bin/bash
# Exporta Planilandia (Godot) para web y Linux en godot/build/.
# Requiere Godot 4.7 con sus plantillas de exportación instaladas.
set -e
cd "$(dirname "$0")/.."
mkdir -p build/web build/linux
touch build/.gdignore
godot --headless --import >/dev/null 2>&1 || true
godot --headless --export-release Web
godot --headless --export-release Linux
echo "Listo: build/web/index.html y build/linux/planilandia.x86_64"
