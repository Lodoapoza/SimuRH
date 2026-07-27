#!/bin/bash
# SimuRH — Déploiement FTP (Slim 4)
set -e

FTP_USER="${FTP_USER:?FTP_USER non défini}"
FTP_PASS="${FTP_PASS:?FTP_PASS non défini}"
FTP_HOST="${FTP_HOST:?FTP_HOST non défini}"
FTP_BASE="${FTP_BASE:?FTP_BASE non défini}"
BACKEND_DIR="$(cd "$(dirname "$0")/../backend" && pwd)"
FTP_OPTS="-s --ftp-create-dirs"

echo "🚀 SimuRH — Déploiement FTP vers $FTP_HOST$FTP_BASE"

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

deploy_dir() {
    local local_dir="$1"
    local remote_dir="$2"
    for file in "$local_dir"/*; do
        if [ -f "$file" ]; then
            deploy_file "$file" "$remote_dir/$(basename "$file")"
        fi
    done
}

deploy_file "$BACKEND_DIR/.htaccess" ".htaccess"
deploy_file "$BACKEND_DIR/composer.json" "composer.json"
deploy_dir "$BACKEND_DIR/public" "public"
deploy_dir "$BACKEND_DIR/src" "src"

echo "✅ Fichiers déployés"
echo "⚠️  Exécutez sur le serveur : cd \$FTP_BASE && composer install --no-dev --optimize-autoloader"
