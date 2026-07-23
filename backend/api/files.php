<?php
/**
 * SimuRH — Fichiers (download)
 * GET /api/files/{id} → Télécharger un fichier
 */

$db = get_db();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET' && $id) {
    $user = require_auth();
    
    // Chercher dans simulation_files d'abord
    $stmt = $db->prepare('SELECT * FROM simulation_files WHERE id = ?');
    $stmt->execute([$id]);
    $file = $stmt->fetch();
    
    // Sinon dans resources
    if (!$file) {
        $stmt = $db->prepare('SELECT file_path as filename, file_type FROM resources WHERE id = ?');
        $stmt->execute([$id]);
        $file = $stmt->fetch();
        if ($file) {
            $file['original_name'] = basename($file['filename']);
        }
    }
    
    if (!$file) error_response('Fichier introuvable', 404);
    
    $filepath = UPLOADS_PATH . '/' . $file['filename'];
    if (!file_exists($filepath)) error_response('Fichier non trouvé sur le serveur', 404);
    
    $mime = $file['file_type'] ?: mime_content_type($filepath) ?: 'application/octet-stream';
    $name = $file['original_name'] ?? basename($filepath);
    
    header('Content-Type: ' . $mime);
    header('Content-Disposition: attachment; filename="' . $name . '"');
    header('Content-Length: ' . filesize($filepath));
    readfile($filepath);
    exit;
}

else {
    error_response('Méthode non autorisée', 405);
}
