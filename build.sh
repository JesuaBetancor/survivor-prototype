#!/usr/bin/env bash
# Exports the prototype for macOS, Windows and Linux and packages each build for
# sharing. Needs Godot 4.7 with the matching export templates installed.
set -euo pipefail
cd "$(dirname "$0")"

VERSION="0.1.0"
GODOT="${GODOT:-godot}"

rm -rf build
mkdir -p build/windows build/linux build/dist

# Godot exits 0 even when an export fails, so every step is checked by hand.
export_preset() {
	local preset="$1" out="$2"
	echo "--- exporting ${preset}"
	"$GODOT" --headless --path . --export-release "$preset" "$out" >/dev/null 2>&1 || true
	if [[ ! -e "$out" ]]; then
		echo "ERROR: ${preset} export produced nothing at ${out}" >&2
		exit 1
	fi
}

export_preset "macOS"   "build/ParrySurvivor.app"
export_preset "Windows" "build/windows/ParrySurvivor.exe"
export_preset "Linux"   "build/linux/ParrySurvivor.x86_64"
chmod +x build/linux/ParrySurvivor.x86_64

# --- Notes that ship next to each build ------------------------------------
# All three builds are unsigned, so all three operating systems will object.
# Anyone opening one needs to know that up front.

cat > build/windows/LEEME.txt <<'EOF'
Parry Survivor - prototipo
==========================

Ejecuta ParrySurvivor.exe. No hay que instalar nada.

Windows va a mostrar una pantalla azul de SmartScreen que dice
"Windows protegio tu PC". Es porque el ejecutable no esta firmado
(firmarlo cuesta dinero y esto es un prototipo, no un producto).

  -> Pulsa "Mas informacion" y luego "Ejecutar de todas formas".

Algunos antivirus tambien dan falsos positivos con juegos hechos en
Godot. Si el tuyo lo bloquea, es eso.

CONTROLES
  WASD / flechas   moverse
  Espacio o click  parry
  R                reiniciar
  Esc              salir

No hay auto-ataque. Tu unica arma es el parry: solo hace dano a los
enemigos que esten cargando su ataque (los que se ponen amarillos).
EOF

cat > build/linux/LEEME.txt <<'EOF'
Parry Survivor - prototipo
==========================

  chmod +x ParrySurvivor.x86_64
  ./ParrySurvivor.x86_64

Compilado para x86_64. Si tu distro es reciente deberia funcionar sin
instalar nada.

CONTROLES
  WASD / flechas   moverse
  Espacio o click  parry
  R                reiniciar
  Esc              salir

No hay auto-ataque. Tu unica arma es el parry: solo hace dano a los
enemigos que esten cargando su ataque (los que se ponen amarillos).
EOF

mkdir -p "build/ParrySurvivor-macOS"
mv build/ParrySurvivor.app "build/ParrySurvivor-macOS/ParrySurvivor.app"
cat > "build/ParrySurvivor-macOS/LEEME.txt" <<'EOF'
Parry Survivor - prototipo
==========================

Descomprime el zip y arrastra ParrySurvivor.app donde quieras.

macOS va a bloquearlo la primera vez. La app esta firmada ad-hoc y sin
notarizar, asi que Gatekeeper la trata como sospechosa. Puede decir que
esta "danada" - no lo esta, es solo la cuarentena de descarga.

La forma fiable de desbloquearla, en la Terminal:

  xattr -dr com.apple.quarantine /ruta/a/ParrySurvivor.app

Y luego ya se abre con doble click. Alternativa sin terminal:
Ajustes del Sistema -> Privacidad y seguridad -> "Abrir de todas formas".

CONTROLES
  WASD / flechas   moverse
  Espacio o click  parry
  R                reiniciar
  Esc              salir

No hay auto-ataque. Tu unica arma es el parry: solo hace dano a los
enemigos que esten cargando su ataque (los que se ponen amarillos).
EOF

# --- Package ---------------------------------------------------------------
echo "--- packaging"
# ditto, not zip: plain zip mangles the symlinks inside Contents/Frameworks and
# breaks the signature. The note goes in the archive beside the app, since the
# Gatekeeper warning is the first thing anyone opening it will hit.
ditto -c -k --sequesterRsrc --keepParent \
	"build/ParrySurvivor-macOS" "build/dist/ParrySurvivor-${VERSION}-macOS.zip"

(cd build/windows && zip -q -r "../dist/ParrySurvivor-${VERSION}-Windows.zip" .)
# tar rather than zip on Linux, so the executable bit survives the trip.
tar -czf "build/dist/ParrySurvivor-${VERSION}-Linux.tar.gz" -C build/linux .

echo
echo "Listo:"
ls -lh build/dist/*.zip build/dist/*.tar.gz | awk '{printf "  %-46s %s\n", $NF, $5}'
