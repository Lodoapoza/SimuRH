<?php
/**
 * SimuRH — Ressources pédagogiques
 * GET  /api/resources?establishment=X
 * POST /api/resources
 * GET  /api/resources/{id}/download
 */

$db = get_db();
$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $user = require_auth();
    $est_id = (int)($_GET['establishment'] ?? $user['establishment_id']);
    
    $stmt = $db->prepare('
        SELECT r.*, u.name as professor_name
        FROM resources r
        JOIN users u ON r.professor_id = u.id
        WHERE r.establishment_id = ?
        ORDER BY r.uploaded_at DESC
    ');
    $stmt->execute([$est_id]);
    
    json_response($stmt->fetchAll());
}

elseif ($method === 'POST') {
    $user = require_auth('professor');
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    
    // Support: soit upload fichier, soit lien direct
    if (!empty($_FILES['file'])) {
        require_fields($input, ['title']);
        
        $path = handle_upload($_FILES['file'], 'resources/' . $user['establishment_id']);
        $file_type = $_FILES['file']['type'];
        
        $stmt = $db->prepare('INSERT INTO resources (professor_id, establishment_id, title, description, file_path, file_type) VALUES (?, ?, ?, ?, ?, ?)');
        $stmt->execute([
            $user['id'],
            $user['establishment_id'],
            clean_input($input['title']),
            clean_input($input['description'] ?? ''),
            $path,
            $file_type
        ]);
        
        json_response([
            'id' => (int)$db->lastInsertId(),
            'title' => clean_input($input['title'])
        ], 201);
    } 
    else {
        require_fields($input, ['title', 'file_path']);
        
        $stmt = $db->prepare('INSERT INTO resources (professor_id, establishment_id, title, description, file_path, file_type) VALUES (?, ?, ?, ?, ?, ?)');
        $stmt->execute([
            $user['id'],
            $user['establishment_id'],
            clean_input($input['title']),
            clean_input($input['description'] ?? ''),
            $input['file_path'],
            $input['file_type'] ?? ''
        ]);
        
        json_response(['id' => (int)$db->lastInsertId()], 201);
    }
}

else {
    error_response('Méthode non autorisée', 405);
}
