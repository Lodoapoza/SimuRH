#!/bin/bash
set -e

echo "========================================"
echo "  SimuRH - Push vers GitHub"
echo "========================================"
echo ""
echo "Ce script va :"
echo "  1. Créer le repo GitHub 'SimuRH' (si besoin)"
echo "  2. Push le code"
echo "  3. Activer GitHub Actions pour build APK"
echo ""

read -p "Nom d'utilisateur GitHub : " GH_USER
read -s -p "Token GitHub (Settings > Developer settings > Personal access tokens) : " GH_TOKEN
echo ""

# Créer le repo si besoin
echo ""
echo "📦 Création du repo GitHub..."
curl -s -o /dev/null -w "%{http_code}" -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/repos/$GH_USER/SimuRH" > /tmp/gh_check 2>&1
if [ "$(cat /tmp/gh_check)" = "200" ]; then
  echo "   Repo existe déjà"
else
  curl -s -H "Authorization: token $GH_TOKEN" \
    -d '{"name":"SimuRH","description":"App mobile de simulations RH pour établissements d\'enseignement","private":false}' \
    "https://api.github.com/user/repos" > /dev/null 2>&1
  echo "   ✅ Repo SimuRH créé"
fi

# Configurer le remote et push
REPO_URL="https://$GH_USER:$GH_TOKEN@github.com/$GH_USER/SimuRH.git"
cd "$(dirname "$0")"
git remote set-url origin "$REPO_URL" 2>/dev/null || git remote add origin "$REPO_URL"
git branch -M main
git push -u origin main

echo ""
echo "========================================"
echo "  ✅ Push terminé !"
echo "========================================"
echo ""
echo "📱 Build APK automatique :"
echo "   https://github.com/$GH_USER/SimuRH/actions"
echo ""
echo "   Les résultats : Actions > build-apk > latest > artifact"
echo ""
echo "🔄 Pour déployer le backend :"
echo "   ./scripts/deploy.sh"
