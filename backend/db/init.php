<?php
/**
 * Initialisation de la base de données
 * 
 * Usage : php db/init.php
 */

require_once __DIR__ . '/../config.php';

try {
    $db = get_db();
    $schema = file_get_contents(__DIR__ . '/schema.sql');
    $db->exec($schema);
    echo "✅ Base de données initialisée : " . DB_PATH . "\n";
} catch (Exception $e) {
    echo "❌ Erreur : " . $e->getMessage() . "\n";
    exit(1);
}
