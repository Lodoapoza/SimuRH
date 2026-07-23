# SimuRH — Spécification fonctionnelle & technique

## 1. Présentation

**SimuRH** est une application mobile Android de simulation de gestion RH destinée aux établissements d'enseignement supérieur (écoles de commerce, management, GRH) en Afrique de l'Ouest.

Le professeur crée des cas pratiques de gestion RH, les étudiants les traitent en groupe (même hors ligne), et l'application gère le suivi, la notation et le classement automatique.

## 2. Acteurs

| Acteur | Rôle |
|--------|------|
| **Professeur** | Crée et gère les simulations, note les groupes, partage des ressources |
| **Étudiant** | Rejoint un groupe, traite la simulation, soumet le travail |
| **Chef de file** | Membre du groupe désigné pour compiler et soumettre le rendu (remplaçable) |
| **Établissement** | Entité qui achète la licence (via le professeur ou l'administration) |

## 3. Parcours utilisateur

### 3.1 Installation et première connexion (tous)

1. Téléchargement de l'app (Google Play Store ou APK direct)
2. Inscription : nom, email, téléphone, mot de passe
3. Choix du profil : **Professeur** ou **Étudiant**
4. Sélection de l'établissement dans une liste (ou ajout s'il n'existe pas)

### 3.2 Professeur — Parcours complet

1. **Accueil** → tableau de bord : simulations en cours/terminées, notifications
2. **Créer une simulation** :
   - Titre, contexte/mise en situation
   - Objectifs pédagogiques (liste d'étapes à réaliser)
   - Documents joints (PDF, images, tableaux)
   - Durée (date de début → date de rendu)
   - Nombre de groupes
   - Grille d'évaluation (critères personnalisables avec coefficients)
   - Code unique généré automatiquement (ex: `RH-2026-A3`)
3. **Lancer** → les étudiants peuvent rejoindre avec le code
4. **Suivi** : voit la progression des groupes (qui a sync, qui a rendu)
5. **Évaluation** : après les présentations, note chaque groupe sur l'app
   - Saisie des notes par critère
   - Commentaires par groupe
   - Possibilité d'ajuster les points
6. **Classement automatique** : l'app calcule le classement final selon la grille
7. **Publication** : les étudiants voient leurs notes, le classement, les commentaires

### 3.3 Professeur — Fonctionnalités additionnelles

- **Ressources pédagogiques** : partager des PDF, cours, modules avec les étudiants
- **Archives** : consulter les simulations des années précédentes
- **Exporter** : classement, notes (PDF, CSV)

### 3.4 Étudiant — Parcours complet

1. **Accueil** → saisir le code de simulation fourni par le professeur
2. **Rejoindre ou créer un groupe** :
   - Si premier du groupe → devient chef de file
   - Si rejoint → le chef peut le remplacer plus tard
3. **Téléchargement** : la simulation et tous les documents sont téléchargés en cache local
4. **Travail hors ligne** :
   - Consultation des documents, même sans Internet
   - Préparation des réponses (texte, fichiers)
   - Le chef de file compile et prépare le rendu final
5. **Sync** : dès qu'une connexion est disponible, les données sont synchronisées
6. **Résultats** : après notation, voit la note, le classement, les commentaires du prof

## 4. Gestion des licences

### 4.1 Modèle

Licence **annuelle par établissement**, achetée via l'application.

| Type | Description | Prix (FCFA) |
|------|-------------|-------------|
| **Essai** | 1 seul étudiant, 1 simulation max | Gratuit |
| **Établissement** | Illimité (professeurs, simulations, étudiants) | 150 000 /an |

### 4.2 Cycle

1. Le professeur installe l'app, choisit son établissement
2. L'app vérifie le statut de la licence en ligne
3. Si payée → accès complet / Si essai → limitations
4. Pour acheter : paiement intégré via CinetPay (Orange Money, MTN, carte)
5. Activation immédiate après confirmation du paiement

### 4.3 Gestion in-app

- Écran de sélection d'établissement au premier lancement
- Si l'établissement n'existe pas → formulaire d'ajout avec validation
- Statut de la licence affiché dans les paramètres
- Bouton "Souscrire" ou "Renouveler"

## 5. Architecture technique

### 5.1 Stack

| Couche | Technologie | Justification |
|--------|------------|---------------|
| **Backend API** | PHP 8+ (vanilla, sans framework) | Stack maîtrisée, hébergement O2Switch existant |
| **Base de données** | SQLite | Simple, pas de gestion MySQL, déjà utilisé avec succès |
| **Stockage fichiers** | Système de fichiers (dossier `/uploads/`) | PDF, images, documents |
| **App mobile** | Flutter (MVP) | Cross-platform, offline-first, SQLite locale |
| **Paiement** | CinetPay API | Mobile Money, cartes, adapté UEMOA |

### 5.2 Architecture de données

```
┌─────────────────────────────────────────────────────────┐
│                    App Flutter                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │ SQLite locale │  │ Cache fichiers│  │ WorkManager  │   │
│  │ (offline)     │  │ (PDF, etc.)  │  │ (sync bg)    │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                  │                  │           │
└─────────┼──────────────────┼──────────────────┼───────────┘
          │ HTTPS (quand     │                  │
          │ connecté)        │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────┐
│                  Serveur O2Switch                        │
│                                                          │
│  ┌──────────────────────┐  ┌────────────────────────┐   │
│  │ API PHP              │  │ Stockage fichiers       │   │
│  │ /api/*               │  │ /uploads/simulations/   │   │
│  │                      │  │ /uploads/resources/     │   │
│  └──────────┬───────────┘  └────────────────────────┘   │
│             │                                            │
│             ▼                                            │
│  ┌──────────────────────┐                                │
│  │ SQLite (simurh.db)   │                                │
│  └──────────────────────┘                                │
└─────────────────────────────────────────────────────────┘
```

### 5.3 Base de données — Tables SQLite

```sql
-- Établissements
CREATE TABLE establishments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    city TEXT,
    country TEXT DEFAULT 'Mali',
    license_status TEXT DEFAULT 'trial',   -- trial, active, expired
    license_key TEXT,
    license_start DATE,
    license_end DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Utilisateurs
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    establishment_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    phone TEXT,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL CHECK(role IN ('professor', 'student')),
    api_token TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (establishment_id) REFERENCES establishments(id)
);

-- Simulations
CREATE TABLE simulations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    professor_id INTEGER NOT NULL,
    establishment_id INTEGER NOT NULL,
    code TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    context TEXT NOT NULL,
    objectives TEXT,           -- JSON array d'objectifs
    duration_days INTEGER,
    max_groups INTEGER,
    grading_criteria TEXT,     -- JSON: [{name, max_score, coefficient}]
    status TEXT DEFAULT 'draft',  -- draft, active, closed
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (professor_id) REFERENCES users(id),
    FOREIGN KEY (establishment_id) REFERENCES establishments(id)
);

-- Documents d'une simulation
CREATE TABLE simulation_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    simulation_id INTEGER NOT NULL,
    filename TEXT NOT NULL,
    original_name TEXT NOT NULL,
    file_type TEXT,
    file_size INTEGER,
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE
);

-- Groupes d'étudiants
CREATE TABLE groups (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    simulation_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    leader_id INTEGER,          -- NULL tant qu'aucun chef désigné
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE,
    FOREIGN KEY (leader_id) REFERENCES users(id)
);

-- Membres d'un groupe
CREATE TABLE group_members (
    group_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id),
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Rendus des groupes
CREATE TABLE submissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    group_id INTEGER NOT NULL,
    simulation_id INTEGER NOT NULL,
    content TEXT,               -- Texte/notes du groupe
    file_path TEXT,             -- Fichier déposé
    submitted_at DATETIME,
    synced_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
    FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE
);

-- Évaluations (notes du professeur)
CREATE TABLE evaluations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    submission_id INTEGER NOT NULL,
    professor_id INTEGER NOT NULL,
    scores TEXT,                -- JSON: {criteria_name: score}
    total_score REAL,
    comments TEXT,
    evaluated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (submission_id) REFERENCES submissions(id) ON DELETE CASCADE,
    FOREIGN KEY (professor_id) REFERENCES users(id)
);

-- Ressources pédagogiques
CREATE TABLE resources (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    professor_id INTEGER NOT NULL,
    establishment_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT NOT NULL,
    file_type TEXT,
    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (professor_id) REFERENCES users(id),
    FOREIGN KEY (establishment_id) REFERENCES establishments(id)
);

-- Transactions (paiements)
CREATE TABLE payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    establishment_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,         -- en FCFA
    payment_method TEXT,             -- orange_money, mtn, card
    cinetpay_transaction_id TEXT,
    status TEXT DEFAULT 'pending',   -- pending, completed, failed
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (establishment_id) REFERENCES establishments(id)
);
```

## 6. API REST — Endpoints

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/api/auth/register` | Inscription |
| POST | `/api/auth/login` | Connexion (retourne token) |
| GET | `/api/establishments` | Liste des établissements |
| POST | `/api/establishments` | Ajouter un établissement |
| GET | `/api/license/status` | Statut licence établissement |
| POST | `/api/simulations` | Créer une simulation |
| GET | `/api/simulations` | Simulations du professeur |
| GET | `/api/simulations/join?code=X` | Rejoindre par code |
| GET | `/api/simulations/{id}` | Détail simulation |
| PUT | `/api/simulations/{id}` | Modifier simulation |
| POST | `/api/simulations/{id}/launch` | Lancer la simulation |
| POST | `/api/simulations/{id}/files` | Uploader un fichier |
| GET | `/api/simulations/{id}/files` | Liste des fichiers |
| POST | `/api/groups` | Créer un groupe |
| POST | `/api/groups/join` | Rejoindre un groupe |
| PUT | `/api/groups/{id}/leader` | Changer chef de file |
| DELETE | `/api/groups/{id}/members/{uid}` | Retirer un membre |
| GET | `/api/submissions?simulation=X` | Voir les rendus |
| POST | `/api/submissions` | Soumettre un rendu |
| POST | `/api/evaluations` | Noter un groupe |
| GET | `/api/rankings?simulation=X` | Classement |
| GET | `/api/resources` | Ressources disponibles |
| POST | `/api/resources` | Ajouter une ressource |
| GET | `/api/files/{id}` | Télécharger un fichier |
| POST | `/api/license/purchase` | Initier un paiement |
| POST | `/api/license/cinetpay-webhook` | Webhook CinetPay |

## 7. Offline / Sync

Principe : **offline-first**. L'app mobile est toujours utilisable sans connexion.

### 7.1 Stockage local (Flutter)

- SQLite locale miroir des données serveur
- Fichiers PDF/images en cache (avec Hive ou fichier)
- WorkManager pour les tâches de fond

### 7.2 Stratégie de sync

| Type | Sens | Déclencheur |
|------|------|-------------|
| Simulation créée par le prof | Local → Serveur | Connexion disponible |
| Étudiant rejoint un groupe | Local → Serveur | Connexion disponible |
| Rendu soumis | Local → Serveur | Connexion disponible |
| Nouvelles simulations | Serveur → Local | Au premier lancement + refresh |
| Notes et classement | Serveur → Local | Sync périodique |

### 7.3 Résolution de conflits

- **Last-write-wins** pour les rendus (le plus récent gagne)
- Pas de modification concurrente complexe dans la V1

## 8. Maquette navigation

### Professeur

```
Accueil
 ├─ Simulations en cours
 │   └─ Détail simulation
 │       ├─ Groupes et progression
 │       ├─ Rendu du groupe X → Évaluation
 │       └─ Classement
 ├─ Créer une simulation
 ├─ Ressources
 ├─ Archives
 └─ Paramètres
     ├─ Établissement & licence
     └─ Profil
```

### Étudiant

```
Accueil
 ├─ Rejoindre (code)
 ├─ Ma simulation en cours
 │   ├─ Contexte & objectifs
 │   ├─ Documents
 │   ├─ Mon groupe
 │   └─ Rendre le travail
 ├─ Résultats (notes, classement)
 └─ Ressources du cours
```

## 9. Roadmap MVP

| Phase | Durée | Livrable |
|-------|-------|----------|
| **P0 — API PHP** | 3-5 jours | API REST opérationnelle sur O2Switch |
| **P1 — Auth + Établissement** | 2 jours | Inscription, login, choix établissement, licence |
| **P2 — Simulations** | 3 jours | Création, code, fichiers, liste |
| **P3 — Groupes** | 2 jours | Création, chef, membres |
| **P4 — Offline + Sync** | 3 jours | Flutter SQLite, cache, sync |
| **P5 — Évaluation + Classement** | 3 jours | Notation, classement auto |
| **P6 — Licence + Paiement** | 3 jours | CinetPay, essai, full |

**Total MVP : ~3 semaines**

## 10. Glossaire

| Terme | Définition |
|-------|-----------|
| **Simulation** | Cas pratique de gestion RH avec contexte, objectifs, documents |
| **Groupe** | Équipe d'étudiants travaillant sur une simulation |
| **Chef de file** | Membre du groupe qui compile et soumet le rendu |
| **Rendu** | Travail final soumis par le groupe (texte + fichier) |
| **Sync** | Synchronisation des données entre l'app et le serveur |
| **Licence** | Abonnement annuel de l'établissement |
