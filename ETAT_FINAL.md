# SimuRH — État final

## Build CI #42 ✅ SUCCESS

## Phases terminées
- **Licence offline** — HMAC-SHA256, générateur HTML, rate limiting (5 tentatives)
- **Auth locale** — profils professeur/étudiant avec switch
- **Groupes** — création/modification/suppression avec membres
- **Navigation** — HomeGate avec sélection profil (prof/étudiant)
- **Dépollution API** — tous les écrans convertis en SQLite local
- **Serveur HTTP** — shelf embarqué sur le téléphone du prof (port 8080)
- **Routes API** — GET simulations/groups/submissions/evaluations, POST submissions
- **Connectivité** — écran prof (IP/port) + écran étudiant (saisie IP)
- **Nettoyage O2Switch** — api_service, auth_service, file_service supprimés
- **Robustesse** — licence re-validée au démarrage, rate limiting

## Prochaine étape possible
- Phase 3D: Rafraîchissement auto du dashboard (Timer.periodic 5s)
- QR code natif (mobile_scanner + qr_flutter)
