#!/bin/bash
# SimuRH — Déploiement FTP vers O2Switch
# Usage: ./scripts/deploy-ftp.sh

set -e

FTP_USER="sc3sidaou"
FTP_PASS="LS@2025*"
FTP_HOST="cloud.glocal-innov.com"
FTP_BASE="/cloud.glocal-innov.com/public_html/simurh"
BACKEND_DIR="$(cd "$(dirname "$0")/../backend" && pwd)"
FTP_OPTS="-s --ftp-create-dirs"

echo "🚀 SimuRH — Déploiement FTP vers O2Switch"
echo "   Host: $FTP_HOST$FTP_BASE"
echo ""

deploy_file() {
    local local_path="$1"
    local remote_name="$2"
    
    if [ ! -f "$local_path" ]; then
        echo "   ⚠️  Fichier introuvable : $local_path"
        return
    fi
    
    echo "   📤 $remote_name"
    curl -s -u "$FTP_USER:$FTP_PASS" $FTP_OPTS \
        -T "$local_path" \
        "ftp://$FTP_HOST$FTP_BASE/$remote_name"
}

echo "📁 Déploiement des fichiers..."

# Config
deploy_file "$BACKEND_DIR/config.php" "config.php"

# .htaccess
deploy_file "$BACKEND_DIR/.htaccess" ".htaccess"

# DB
deploy_file "$BACKEND_DIR/db/schema.sql" "db/schema.sql"
deploy_file "$BACKEND_DIR/db/init.php" "db/init.php"

# API
for php_file in "$BACKEND_DIR/api/"*.php; do
    filename=$(basename "$php_file")
    deploy_file "$php_file" "api/$filename"
done

echo ""
echo "✅ Fichiers déployés !"
echo ""

# Initialiser la base de données via HTTP
echo "🗄️  Initialisation de la base de données..."
INIT_URL="https://$FTP_HOST/simurh/db/init.php"
echo "   Appel : $INIT_URL"
echo "   ⚠️  Tu dois exécuter cette URL dans ton navigateur ou lancer : php db/init.php sur O2Switch"
echo ""

echo "🔗 API : https://$FTP_HOST/simurh/api/health"
echo "📱 Prêt pour l'app Flutter !"
