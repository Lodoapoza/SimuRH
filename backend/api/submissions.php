<?php
/**
 * SimuRH — Rendus (Submissions)
 * GET  /api/submissions?simulation=X    → Tous les rendus (prof)
 * POST /api/submissions                  → Soumettre (étudiant, chef de file)
 */

$db = get_db();
$method = $_SERVER['REQUEST_METHOD'];

// GET /api/submissions?simulation=X
if ($method === 'GET') {
    $user = require_auth();
    $sim_id = (int)($_GET['simulation'] ?? 0);
    
    if (!$sim_id) error_response('Paramètre simulation requis');
    
    // Si étudiant : voir son propre rendu seulement
    if ($user['role'] === 'student') {
        $stmt = $db->prepare('
            SELECT sub.*, g.name as group_name, e.total_score, e.comments, e.scores
            FROM submissions sub
            JOIN groups_tbl g ON sub.group_id = g.id
            LEFT JOIN evaluations e ON e.submission_id = sub.id
            JOIN group_members gm ON gm.group_id = g.id
            WHERE sub.simulation_id = ? AND gm.user_id = ?
        ');
        $stmt->execute([$sim_id, $user['id']]);
    } else {
        // Professeur : tous les rendus
        $stmt = $db->prepare('
            SELECT sub.*, g.name as group_name, u.name as leader_name,
                   e.total_score, e.comments, e.scores, e.evaluated_at
            FROM submissions sub
            JOIN groups_tbl g ON sub.group_id = g.id
            LEFT JOIN users u ON g.leader_id = u.id
            LEFT JOIN evaluations e ON e.submission_id = sub.id
            WHERE sub.simulation_id = ?
            ORDER BY g.name
        ');
        $stmt->execute([$sim_id]);
    }
    
    json_response($stmt->fetchAll());
}

// POST /api/submissions
elseif ($method === 'POST') {
    $user = require_auth('student');
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    
    require_fields($input, ['simulation_id', 'content']);
    $sim_id = (int)$input['simulation_id'];
    $content = $input['content'];
    
    // Vérifier que l'étudiant est chef de file
    $stmt = $db->prepare('
        SELECT g.id as group_id FROM groups_tbl g
        JOIN group_members gm ON gm.group_id = g.id
        WHERE g.simulation_id = ? AND g.leader_id = ? AND gm.user_id = ?
    ');
    $stmt->execute([$sim_id, $user['id'], $user['id']]);
    $group = $stmt->fetch();
    
    if (!$group) error_response('Vous devez être chef de file pour soumettre le travail');
    
    $group_id = $group['group_id'];
    
    // Vérifier si un rendu existe déjà → mise à jour
    $stmt = $db->prepare('SELECT id FROM submissions WHERE group_id = ? AND simulation_id = ?');
    $stmt->execute([$group_id, $sim_id]);
    $existing = $stmt->fetch();
    
    $file_path = null;
    
    // Upload fichier si présent
    if (!empty($_FILES['file'])) {
        $file_path = handle_upload($_FILES['file'], 'submissions/' . $sim_id);
    } elseif (!empty($input['file_path'])) {
        $file_path = $input['file_path'];
    }
    
    if ($existing) {
        $sql = 'UPDATE submissions SET content = ?, submitted_at = CURRENT_TIMESTAMP, synced_at = CURRENT_TIMESTAMP';
        $params = [$content];
        
        if ($file_path) {
            $sql .= ', file_path = ?';
            $params[] = $file_path;
        }
        
        $sql .= ' WHERE id = ?';
        $params[] = $existing['id'];
        $db->prepare($sql)->execute($params);
        
        json_response(['success' => true, 'updated' => true, 'id' => $existing['id']]);
    } else {
        $stmt = $db->prepare('INSERT INTO submissions (group_id, simulation_id, content, file_path, submitted_at) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)');
        $stmt->execute([$group_id, $sim_id, $content, $file_path]);
        
        json_response(['success' => true, 'id' => (int)$db->lastInsertId()], 201);
    }
}

else {
    error_response('Méthode non autorisée', 405);
}
