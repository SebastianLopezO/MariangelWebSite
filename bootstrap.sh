#!/bin/bash
set -e

CONFIG_FILE="repos.conf"
SERVICES_DIR="services"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Verificar carpeta de servicios y limpiarla
if [ -d "$SERVICES_DIR" ]; then
  echo "🧹 Limpiando builds previos en $SERVICES_DIR..."
  rm -rf "$SERVICES_DIR"/*
else
  echo "📂 Creando carpeta $SERVICES_DIR..."
  mkdir -p "$SERVICES_DIR"
fi

# Verificar archivo de configuración
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ No se encontró $CONFIG_FILE"
  exit 1
fi

# Leer repos del archivo de configuración
echo "📖 Leyendo repos de $CONFIG_FILE..."
while IFS='=' read -r key value; do
  # Ignorar comentarios y líneas vacías
  [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

  service=$(echo "$key" | xargs)
  repo=$(echo "$value" | xargs)
  tmpdir="$SERVICES_DIR/${service}-tmp"   # repo clonado temporal
  final="$SERVICES_DIR/$service"          # carpeta final limpia

  echo "-------------------------------------"
  echo "⬇️  Procesando servicio: $service"
  echo "📦 Repo: $repo"

  # Clonar o actualizar (si existe tmp lo borro siempre)
  rm -rf "$tmpdir"
  echo "📥 Clonando $service..."
  git clone "$repo" "$tmpdir"

  # Construir con Vite
  echo "🛠️  Construyendo $service..."
  pushd "$tmpdir" > /dev/null
  npm install
  npm run build
  popd > /dev/null

  # Copiar dist al destino final
  echo "📂 Moviendo build de $service a $final"
  rm -rf "$final"
  mkdir -p "$final"
  cp -r "$tmpdir/dist/"* "$final/"

  # Eliminar repo temporal
  echo "🧹 Limpiando temporales de $service"
  rm -rf "$tmpdir"

  echo "✅ $service listo en $final"
  echo "-------------------------------------"

done < <(grep "=" "$CONFIG_FILE")

echo "🎉 Todos los proyectos fueron construidos y copiados en $SERVICES_DIR/"

# Build final de Docker
echo "🐳 Levantando servicios con Docker Compose..."
cd "$BASE_DIR"
docker compose up -d --build

echo "✅ Bootstrap finalizado con éxito. Todo corriendo en Docker Compose."
