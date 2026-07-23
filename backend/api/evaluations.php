<?php
/**
 * SimuRH — Évaluations
 * POST /api/evaluations              → Noter un groupe
 * GET  /api/evaluations?simulation=X → Voir les notes
 * GET  /api/rankings?simulation=X    → Classement automatique
 */

$db = get_db();
$method = $_SERVER['REQUEST_METHOD'];

// GET /api/rankings?simulation=X
if ($method === 'GET' && $id === 'rankings') {
    $user = require_auth();
    $sim_id = (int)($_GET['simulation'] ?? 0);
    
    if (!$sim_id) error_response('Paramètre simulation requis');
    
    $stmt = $db->prepare('
        SELECT 
            g.name as group_name,
            e.total_score,
            e.comments,
            e.evaluated_at,
            COUNT(gm.user_id) as member_count
        FROM groups_tbl g
        JOIN evaluations e ON e.submission_id = (
            SELECT id FROM submissions WHERE group_id = g.id LIMIT 1
        )
        LEFT JOIN group_members gm ON gm.group_id = g.id
        WHERE g.simulation_id = ?
        GROUP BY g.id
        ORDER BY e.total_score DESC
    ');
    $stmt->execute([$sim_id]);
    $results = $stmt->fetchAll();
    
    // Ajouter le rang
    $rank = 0;
    $prev_score = null;
    foreach ($results as &$row) {
        if ($row['total_score'] !== $prev_score) {
            $rank++;
            $prev_score = $row['total_score'];
        }
        $row['rank'] = $rank;
    }
    
    json_response($results);
}

// POST /api/evaluations
elseif ($method === 'POST') {
    $user = require_auth('professor');
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    
    require_fields($input, ['submission_id', 'scores']);
    $submission_id = (int)$input['submission_id'];
    $scores = $input['scores']; // Tableau associatif
    $comments = $input['comments'] ?? '';
    
    // Vérifier que le rendu existe et appartient à une simulation du prof
    $stmt = $db->prepare('
        SELECT sub.*, s.professor_id 
        FROM submissions sub
        JOIN simulations s ON sub.simulation_id = s.id
        WHERE sub.id = ?
    ');
    $stmt->execute([$submission_id]);
    $sub = $stmt->fetch();
    
    if (!$sub) error_response('Rendu introuvable', 404);
    if ($sub['professor_id'] != $user['id']) error_response('Ce rendu ne vous appartient pas', 403);
    
    // Calculer le score total
    $total_score = 0;
    if (is_array($scores)) {
        foreach ($scores as $key => $value) {
            $total_score += (float)$value;
        }
    }
    
    // Vérifier si une évaluation existe déjà → mise à jour
    $stmt = $db->prepare('SELECT id FROM evaluations WHERE submission_id = ?');
    $stmt->execute([$submission_id]);
    $existing = $stmt->fetch();
    
    if ($existing) {
        $stmt = $db->prepare('UPDATE evaluations SET scores = ?, total_score = ?, comments = ?, evaluated_at = CURRENT_TIMESTAMP WHERE id = ?');
        $stmt->execute([json_encode($scores, JSON_UNESCAPED_UNICODE), $total_score, $comments, $existing['id']]);
    } else {
        $stmt = $db->prepare('INSERT INTO evaluations (submission_id, professor_id, scores, total_score, comments) VALUES (?, ?, ?, ?, ?)');
        $stmt->execute([$submission_id, $user['id'], json_encode($scores, JSON_UNESCAPED_UNICODE), $total_score, $comments]);
    }
    
    json_response([
        'success' => true,
        'total_score' => $total_score,
        'comments' => $comments
    ]);
}

// GET /api/evaluations?simulation=X
elseif ($method === 'GET') {
    $user = require_auth('professor');
    $sim_id = (int)($_GET['simulation'] ?? 0);
    
    $stmt = $db->prepare('
        SELECT 
            e.id,
            e.total_score,
            e.scores,
            e.comments,
            e.evaluated_at,
            g.name as group_name,
            sub.id as submission_id
        FROM evaluations e
        JOIN submissions sub ON e.submission_id = sub.id
        JOIN groups_tbl g ON sub.group_id = g.id
        WHERE sub.simulation_id = ?
        ORDER BY e.total_score DESC
    ');
    $stmt->execute([$sim_id]);
    
    json_response($stmt->fetchAll());
}

else {
    error_response('Méthode non autorisée', 405);
}
