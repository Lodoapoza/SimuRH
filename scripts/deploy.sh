#!/bin/bash
# SimuRH — Déploiement vers O2Switch
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/../backend" && pwd)"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Dossier backend/ introuvable"
    exit 1
fi
cd "$PROJECT_DIR"

SSH_KEY="$HOME/.ssh/id_rsa_o2switch"
SSH_USER="sc3sidaou"
SSH_HOST="109.234.164.11"
REMOTE_PATH="/home2/sc3sidaou/simurh.glocal-innov.com"

echo "🚀 Déploiement SimuRH vers $REMOTE_PATH"

if [ ! -f "$SSH_KEY" ]; then
    echo "❌ Clé SSH introuvable : $SSH_KEY"
    exit 1
fi

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${SSH_USER}@${SSH_HOST}" \
    "mkdir -p ${REMOTE_PATH}/api ${REMOTE_PATH}/db ${REMOTE_PATH}/uploads/simulations ${REMOTE_PATH}/uploads/resources ${REMOTE_PATH}/uploads/submissions"

rsync -avz --delete -e "ssh -i $SSH_KEY" \
    --exclude '.DS_Store' \
    --exclude 'uploads/' \
    --exclude '*.db' \
    ./config.php \
    ./setup.php \
    ./.htaccess \
    ./api \
    ./db \
    "${SSH_USER}@${SSH_HOST}:${REMOTE_PATH}/"

ssh -i "$SSH_KEY" "${SSH_USER}@${SSH_HOST}" "cd ${REMOTE_PATH} && php db/init.php"

echo ""
echo "✅ Déploiement terminé !"
echo "📱 API : https://simurh.glocal-innov.com/api/health"
