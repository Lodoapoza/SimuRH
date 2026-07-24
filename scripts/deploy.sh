#!/bin/bash
# SimuRH — Déploiement vers O2Switch
# Usage: ./scripts/deploy.sh

set -e

# Chemin racine du projet (on remonte de scripts/ vers backend/)
PROJECT_DIR="$(cd "$(dirname "$0")/../backend" && pwd)"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Dossier backend/ introuvable"
    exit 1
fi

cd "$PROJECT_DIR"

SSH_KEY="$HOME/.ssh/id_rsa_o2switch"
SSH_USER="sc3sidaou"
SSH_HOST="109.234.164.11"
REMOTE_PATH="/home2/sc3sidaou/cloud.glocal-innov.com/public_html/simurh"

echo "🚀 Déploiement SimuRH vers O2Switch..."

# Vérifier que la clé SSH existe
if [ ! -f "$SSH_KEY" ]; then
    echo "❌ Clé SSH introuvable : $SSH_KEY"
    exit 1
fi

# Créer le dossier distant
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${SSH_USER}@${SSH_HOST}" "mkdir -p ${REMOTE_PATH}/api ${REMOTE_PATH}/db ${REMOTE_PATH}/uploads/simulations ${REMOTE_PATH}/uploads/resources ${REMOTE_PATH}/uploads/submissions"

# Sync des fichiers (exclure ce qui ne doit pas partir)
rsync -avz --delete -e "ssh -i $SSH_KEY" \
    --exclude '.DS_Store' \
    --exclude '*.db' \
    --exclude 'uploads/' \
    ./config.php \
    ./api \
    ./db \
    ./.htaccess \
    "${SSH_USER}@${SSH_HOST}:${REMOTE_PATH}/"

echo "✅ Fichiers copiés"

# Initialiser la base de données
ssh -i "$SSH_KEY" "${SSH_USER}@${SSH_HOST}" "cd ${REMOTE_PATH} && php db/init.php"

echo ""
echo "✅ Déploiement terminé !"
echo "📱 API disponible sur : https://cloud.glocal-innov.com/simurh/api/health"
