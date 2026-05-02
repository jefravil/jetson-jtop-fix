#!/usr/bin/env bash
# ==============================================================================
# fix_jtop_jetpack622.sh
# Fix para jtop "JetPack Missing" en Jetson Orin con JetPack 6.2.2 (L4T 36.5.0)
# Autor: basado en fix de Jefferson Ramirez
# Uso: chmod +x fix_jtop_jetpack622.sh && sudo ./fix_jtop_jetpack622.sh
# ==============================================================================

set -e

# ── Colores ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${CYAN}[INFO]${NC}  $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Verificar root ─────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    log_error "Este script debe ejecutarse como root. Usa: sudo ./fix_jtop_jetpack622.sh"
    exit 1
fi

echo ""
echo "======================================================"
echo "   Fix jtop JetPack Missing — JetPack 6.2.2 / L4T 36.5"
echo "======================================================"
echo ""

# ── 1. Verificar que jtop está instalado ───────────────────────────────────────
log_info "Verificando instalación de jtop..."
if ! python3 -c "import jtop" &>/dev/null; then
    log_warn "jtop no está instalado. Instalando jetson-stats..."
    pip3 install jetson-stats
    log_ok "jetson-stats instalado."
else
    log_ok "jtop encontrado."
fi

# ── 2. Localizar jetson_variables.py ──────────────────────────────────────────
log_info "Localizando jetson_variables.py..."
JTOP_FILE=$(python3 -c "import jtop, os; print(os.path.join(os.path.dirname(jtop.__file__), 'core/jetson_variables.py'))")

if [[ ! -f "$JTOP_FILE" ]]; then
    log_error "No se encontró el archivo: $JTOP_FILE"
    exit 1
fi
log_ok "Archivo encontrado: $JTOP_FILE"

# ── 3. Hacer backup ────────────────────────────────────────────────────────────
BACKUP="${JTOP_FILE}.bak_$(date +%Y%m%d_%H%M%S)"
log_info "Creando backup en: $BACKUP"
cp "$JTOP_FILE" "$BACKUP"
log_ok "Backup creado."

# ── 4. Verificar si el mapeo ya existe ────────────────────────────────────────
if grep -q '"36.5.0"' "$JTOP_FILE"; then
    log_warn "El mapeo de L4T 36.5.0 ya existe en el archivo. No se necesita el fix."
    echo ""
    log_info "Versiones detectadas en el archivo:"
    grep '\"36\.' "$JTOP_FILE"
    echo ""
    log_ok "jtop ya está configurado correctamente para JetPack 6.2.2."
    exit 0
fi

# ── 5. Aplicar fix según la versión que sirva de ancla ───────────────────────
log_info "Aplicando fix para L4T 36.5.0 → JetPack 6.2.2..."

# Intenta anclar después de 36.4.4 (JP 6.2.1), si existe
if grep -q '"36.4.4"' "$JTOP_FILE"; then
    sed -i 's/"36.4.4": "6.2.1",/"36.4.4": "6.2.1",\n            "36.5.0": "6.2.2",/' "$JTOP_FILE"
    log_ok "Fix aplicado (anclado tras entrada 36.4.4)."

# Si no, ancla después de 36.4.3 (JP 6.2)
elif grep -q '"36.4.3"' "$JTOP_FILE"; then
    sed -i 's/"36.4.3": "6.2",/"36.4.3": "6.2",\n            "36.5.0": "6.2.2",/' "$JTOP_FILE"
    log_ok "Fix aplicado (anclado tras entrada 36.4.3)."

# Fallback: insertar al inicio del bloque JP6
elif grep -q '# -------- JP6 --------' "$JTOP_FILE"; then
    sed -i '/# -------- JP6 --------/a\            "36.5.0": "6.2.2",' "$JTOP_FILE"
    log_ok "Fix aplicado (insertado en bloque JP6)."

else
    log_error "No se encontró un punto de anclaje conocido en el archivo."
    log_warn "Restaurando backup..."
    cp "$BACKUP" "$JTOP_FILE"
    log_error "No se pudo aplicar el fix automáticamente. Edita manualmente: $JTOP_FILE"
    exit 1
fi

# ── 6. Verificar que el mapeo quedó bien ──────────────────────────────────────
log_info "Verificando resultado..."
if grep -q '"36.5.0"' "$JTOP_FILE"; then
    log_ok "Mapeo confirmado en el archivo:"
    grep '\"36\.' "$JTOP_FILE"
else
    log_error "El mapeo no fue escrito correctamente. Restaurando backup..."
    cp "$BACKUP" "$JTOP_FILE"
    exit 1
fi

# ── 7. Reiniciar servicio jtop ────────────────────────────────────────────────
log_info "Reiniciando servicio jtop..."
if systemctl is-active --quiet jtop.service; then
    systemctl restart jtop.service
    log_ok "Servicio jtop reiniciado."
else
    log_warn "El servicio jtop no estaba activo. Intentando iniciar..."
    systemctl start jtop.service || log_warn "No se pudo iniciar el servicio. Puede requerir reboot."
fi

# ── 8. Listo ──────────────────────────────────────────────────────────────────
echo ""
echo "======================================================"
log_ok "Fix aplicado exitosamente."
echo ""
echo "  Corre 'jtop' y verifica que JetPack 6.2.2 aparezca"
echo "  correctamente en la pantalla de info."
echo ""
echo "  Si sigue apareciendo Missing, ejecuta:"
echo "    sudo reboot"
echo "======================================================"
echo ""
