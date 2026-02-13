#!/bin/bash
set -e

CONFIG_FILE="repos.conf"
SERVICES_DIR="services"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

SERVICE_NAME="$1"

if [ -z "$SERVICE_NAME" ]; then
  echo "❌ Debes especificar el nombre del servicio. Ejemplo:"
  echo "   ./bootstrap-single.sh pregrados"
  exit 1
fi

# Verificar archivo de configuración
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ No se encontró $CONFIG_FILE"
  exit 1
fi

# Buscar el repo del servicio
REPO_URL=$(grep "^$SERVICE_NAME\s*=" "$CONFIG_FILE" | cut -d'=' -f2 | xargs)

if [ -z "$REPO_URL" ]; then
  echo "❌ No se encontró configuración para el servicio '$SERVICE_NAME' en $CONFIG_FILE"
  exit 1
fi

TMP_DIR="$SERVICES_DIR/${SERVICE_NAME}-tmp"
FINAL_DIR="$SERVICES_DIR/$SERVICE_NAME"

echo "-------------------------------------"
echo "⬇️  Procesando servicio: $SERVICE_NAME"
echo "📦 Repo: $REPO_URL"

# Clonar o actualizar repo
rm -rf "$TMP_DIR"
echo "📥 Clonando $SERVICE_NAME..."
git clone "$REPO_URL" "$TMP_DIR"

# Construir con Vite
echo "🛠️  Construyendo $SERVICE_NAME..."
pushd "$TMP_DIR" > /dev/null
npm install
npm run build
popd > /dev/null

# Copiar build al destino final
echo "📂 Moviendo build de $SERVICE_NAME a $FINAL_DIR"
rm -rf "$FINAL_DIR"
mkdir -p "$FINAL_DIR"
cp -r "$TMP_DIR/dist/"* "$FINAL_DIR/"

# Limpiar temporales
echo "🧹 Limpiando temporales..."
rm -rf "$TMP_DIR"

# Reconstruir con Docker Compose
echo "🐳 Actualizando contenedores..."
cd "$BASE_DIR"
docker compose up -d --build

echo "✅ Servicio '$SERVICE_NAME' desplegado correctamente."
echo "-------------------------------------"
