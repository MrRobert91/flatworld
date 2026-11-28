#!/bin/bash
# Exporta Planilandia (Godot) en godot/build/.
#   tools/export.sh           web (demo) y Linux, versionados en git
#   tools/export.sh --steam   además, Linux, Windows y macOS para Steam en build/steam/ (sin versionar)
#   tools/export.sh --release además de lo de --steam, Android (APK) y la web completa en build/steam/ (sin versionar)
# Requiere Godot 4.7 con sus plantillas de exportación instaladas (las de Windows y macOS, para --steam;
# las de Android, el JDK 17 y el SDK de Android configurados en el editor, para --release).
# El APK se firma con la clave de publicación indicada en GODOT_ANDROID_KEYSTORE_RELEASE_PATH/_USER/_PASSWORD.
set -e
cd "$(dirname "$0")/.."
mkdir -p build/web build/linux
touch build/.gdignore
godot --headless --import >/dev/null 2>&1 || true
godot --headless --export-release Web
godot --headless --export-release Linux
echo "Listo: build/web/index.html (demo) y build/linux/planilandia.x86_64"
if [ "$1" = "--steam" ] || [ "$1" = "--release" ]; then
	mkdir -p build/steam/linux build/steam/windows build/steam/macos
	godot --headless --export-release Linux build/steam/linux/planilandia.x86_64
	godot --headless --export-release "Windows Desktop" build/steam/windows/Planilandia.exe || echo "AVISO: faltan las plantillas de Windows"
	godot --headless --export-release macOS build/steam/macos/Planilandia.zip || echo "AVISO: faltan las plantillas de macOS"
	echo "Listo: build/steam/"
fi
if [ "$1" = "--release" ]; then
	mkdir -p build/steam/android build/steam/web_full
	godot --headless --export-release Android build/steam/android/planilandia.apk || echo "AVISO: no se pudo exportar Android (plantillas, JDK, SDK o clave)"
	godot --headless --export-release "Web (completo)" build/steam/web_full/index.html
	echo "Listo: build/steam/android/ y build/steam/web_full/"
fi
