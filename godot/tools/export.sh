#!/bin/bash
# Exporta Planilandia (Godot) en godot/build/.
#   tools/export.sh           web (demo) y Linux, versionados en git
#   tools/export.sh --steam   además, Linux, Windows y macOS para Steam en build/steam/ (sin versionar)
# Requiere Godot 4.7 con sus plantillas de exportación instaladas (las de Windows y macOS, para --steam).
set -e
cd "$(dirname "$0")/.."
mkdir -p build/web build/linux
touch build/.gdignore
godot --headless --import >/dev/null 2>&1 || true
godot --headless --export-release Web
godot --headless --export-release Linux
echo "Listo: build/web/index.html (demo) y build/linux/planilandia.x86_64"
if [ "$1" = "--steam" ]; then
	mkdir -p build/steam/linux build/steam/windows build/steam/macos
	godot --headless --export-release Linux build/steam/linux/planilandia.x86_64
	godot --headless --export-release "Windows Desktop" build/steam/windows/Planilandia.exe || echo "AVISO: faltan las plantillas de Windows"
	godot --headless --export-release macOS build/steam/macos/Planilandia.zip || echo "AVISO: faltan las plantillas de macOS"
	echo "Listo: build/steam/"
fi
