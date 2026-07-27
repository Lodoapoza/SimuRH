#!/bin/bash
# SimuRH — Déploiement Slim 4
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/../backend" && pwd)"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ Dossier backend/ introuvable"
    exit 1
fi
cd "$PROJECT_DIR"

SSH_KEY="${SSH_KEY:?SSH_KEY non défini}"
SSH_USER="${SSH_USER:?SSH_USER non défini}"
SSH_HOST="${SSH_HOST:?SSH_HOST non défini}"
REMOTE_PATH="${REMOTE_PATH:?REMOTE_PATH non défini}"

echo "🚀 Déploiement SimuRH vers $REMOTE_PATH"

ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${SSH_USER}@${SSH_HOST}" \
    "mkdir -p ${REMOTE_PATH}/public ${REMOTE_PATH}/src ${REMOTE_PATH}/uploads/simulations ${REMOTE_PATH}/uploads/resources ${REMOTE_PATH}/uploads/submissions"

rsync -avz --delete -e "ssh -i $SSH_KEY" \
    --exclude '.DS_Store' \
    ./public/ \
    ./src/ \
    ./composer.json \
    ./.htaccess \
    "${SSH_USER}@${SSH_HOST}:${REMOTE_PATH}/"

ssh -i "$SSH_KEY" "${SSH_USER}@${SSH_HOST}" "cd ${REMOTE_PATH} && cp -n .env.example .env 2>/dev/null; composer install --no-dev --optimize-autoloader"

echo "✅ Déploiement terminé"
