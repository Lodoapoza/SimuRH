<?php
/**
 * SimuRH — Installateur web
 * 
 * Usage : uploadez ce fichier sur O2Switch, appelez-le dans votre navigateur,
 * puis supprimez-le après installation.
 * 
 * Exemple : https://cloud.glocal-innov.com/simurh/setup.php
 */

// Configuration
$base_path = __DIR__;
$db_path = $base_path . '/db/simurh.db';
$schema_path = $base_path . '/db/schema.sql';

// Fonction de log
function log_msg(string $msg): void {
    echo "<div style='margin:4px 0;padding:4px 8px;background:#f5f5f5;border-radius:4px;font-family:monospace;'>$msg</div>";
    flush();
}

// Fonction d'erreur
function error_msg(string $msg): void {
    echo "<div style='margin:4px 0;padding:4px 8px;background:#ffe0e0;border-left:3px solid #c00;font-family:monospace;color:#c00;font-weight:bold;'>❌ $msg</div>";
    flush();
}

echo "<!DOCTYPE html><html><head><meta charset='utf-8'><title>SimuRH — Installation</title>";
echo "<style>body{font-family:sans-serif;max-width:600px;margin:40px auto;padding:0 20px;line-height:1.5}</style></head><body>";
echo "<h1>🚀 SimuRH — Installation</h1>";

// Vérifier PHP
echo "<h3>🔍 Vérifications</h3>";

if (version_compare(PHP_VERSION, '8.0', '<')) {
    error_msg("PHP 8.0+ requis (version actuelle : " . PHP_VERSION . ")");
    exit;
}
log_msg("✅ PHP " . PHP_VERSION);

// Vérifier PDO SQLite
if (!class_exists('PDO') || !in_array('sqlite', PDO::getAvailableDrivers())) {
    error_msg("Extension PDO SQLite non disponible. Contactez O2Switch pour l'activer.");
    exit;
}
log_msg("✅ PDO SQLite disponible");

// Vérifier les dossiers
$dirs = [
    'db' => $base_path . '/db',
    'uploads' => $base_path . '/uploads',
    'uploads/simulations' => $base_path . '/uploads/simulations',
    'uploads/resources' => $base_path . '/uploads/resources',
    'uploads/submissions' => $base_path . '/uploads/submissions',
];

foreach ($dirs as $name => $dir) {
    if (!is_dir($dir)) {
        if (@mkdir($dir, 0755, true)) {
            log_msg("✅ Dossier créé : $name");
        } else {
            error_msg("Impossible de créer le dossier : $name");
        }
    } else {
        log_msg("✅ Dossier existant : $name");
    }
}

// Vérifier les permissions d'écriture
$test_file = $base_path . '/db/_test_write.tmp';
if (@file_put_contents($test_file, 'test') !== false) {
    unlink($test_file);
    log_msg("✅ Permissions d'écriture OK");
} else {
    error_msg("⚠️  Permission d'écriture insuffisante dans db/");
}

// Initialiser la base de données
echo "<h3>🗄️ Initialisation de la base de données</h3>";

try {
    // Supprimer l'ancienne base si elle existe
    if (file_exists($db_path)) {
        unlink($db_path);
        log_msg("✅ Ancienne base supprimée");
    }
    
    $db = new PDO('sqlite:' . $db_path);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->exec('PRAGMA journal_mode=WAL');
    $db->exec('PRAGMA foreign_keys=ON');
    
    if (file_exists($schema_path)) {
        $schema = file_get_contents($schema_path);
        $db->exec($schema);
        log_msg("✅ Schéma SQL exécuté");
    } else {
        error_msg("Fichier schema.sql introuvable : $schema_path");
    }
    
    // Vérifier que les tables sont créées
    $tables = $db->query("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")->fetchAll(PDO::FETCH_COLUMN);
    log_msg("✅ Tables créées : " . implode(', ', $tables));
    
    echo "<h3>✅ Installation terminée !</h3>";
    echo "<p>La base de données est prête. Tu peux maintenant :</p>";
    echo "<ul>";
    echo "<li>Tester l'API : <a href='api/health' target='_blank'>api/health</a></li>";
    echo "<li><strong>Supprimer ce fichier setup.php</strong> (important pour la sécurité)</li>";
    echo "</ul>";
    
} catch (Exception $e) {
    error_msg("Erreur : " . $e->getMessage());
}

echo "</body></html>";
