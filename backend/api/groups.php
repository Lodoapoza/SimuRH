<?php
/**
 * SimuRH — Groupes
 * POST   /api/groups                → Créer un groupe
 * POST   /api/groups/join           → Rejoindre un groupe
 * GET    /api/groups?simulation=X   → Liste groupes d'une simulation
 * PUT    /api/groups/{id}/leader    → Changer le chef
 * DELETE /api/groups/{id}/members/{uid} → Retirer un membre
 * DELETE /api/groups/{id}           → Supprimer le groupe (chef seulement)
 */

$db = get_db();
$method = $_SERVER['REQUEST_METHOD'];

// GET /api/groups?simulation=X
if ($method === 'GET') {
    $user = require_auth();
    $sim_id = (int)($_GET['simulation'] ?? 0);
    
    if (!$sim_id) error_response('Paramètre simulation requis');
    
    $stmt = $db->prepare('
        SELECT g.*, u.name as leader_name
        FROM groups_tbl g
        LEFT JOIN users u ON g.leader_id = u.id
        WHERE g.simulation_id = ?
        ORDER BY g.name
    ');
    $stmt->execute([$sim_id]);
    $groups = $stmt->fetchAll();
    
    // Pour chaque groupe, charger les membres
    foreach ($groups as &$group) {
        $stmt = $db->prepare('
            SELECT u.id, u.name, u.email,
                   CASE WHEN g.leader_id = u.id THEN 1 ELSE 0 END as is_leader
            FROM group_members gm
            JOIN users u ON gm.user_id = u.id
            JOIN groups_tbl g ON gm.group_id = g.id
            WHERE gm.group_id = ?
        ');
        $stmt->execute([$group['id']]);
        $group['members'] = $stmt->fetchAll();
        
        // Vérifier si un rendu a été soumis
        $stmt = $db->prepare('SELECT id, submitted_at FROM submissions WHERE group_id = ?');
        $stmt->execute([$group['id']]);
        $sub = $stmt->fetch();
        $group['has_submission'] = !empty($sub);
        $group['submitted_at'] = $sub['submitted_at'] ?? null;
    }
    
    json_response($groups);
}

// POST /api/groups (créer)
elseif ($method === 'POST' && !$id) {
    $user = require_auth('student');
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    
    require_fields($input, ['simulation_id', 'name']);
    $sim_id = (int)$input['simulation_id'];
    $name = clean_input($input['name']);
    
    // Vérifier que la simulation existe et est active
    $stmt = $db->prepare('SELECT id, status FROM simulations WHERE id = ?');
    $stmt->execute([$sim_id]);
    $sim = $stmt->fetch();
    if (!$sim) error_response('Simulation introuvable', 404);
    if ($sim['status'] !== 'active') error_response('La simulation n\'est pas active');
    
    // Vérifier que l'étudiant n'est pas déjà dans un groupe pour cette simulation
    $stmt = $db->prepare('
        SELECT 1 FROM group_members gm
        JOIN groups_tbl g ON gm.group_id = g.id
        WHERE gm.user_id = ? AND g.simulation_id = ?
    ');
    $stmt->execute([$user['id'], $sim_id]);
    if ($stmt->fetch()) error_response('Vous êtes déjà dans un groupe pour cette simulation');
    
    // Compter les groupes existants
    $stmt = $db->prepare('SELECT COUNT(*) as cnt FROM groups_tbl WHERE simulation_id = ?');
    $stmt->execute([$sim_id]);
    $count = (int)$stmt->fetch()['cnt'];
    
    // Vérifier max_groups
    $stmt = $db->prepare('SELECT max_groups FROM simulations WHERE id = ?');
    $stmt->execute([$sim_id]);
    $max = (int)$stmt->fetch()['max_groups'];
    if ($count >= $max) error_response('Nombre maximum de groupes atteint');
    
    // Créer le groupe avec le créateur comme chef
    $db->beginTransaction();
    try {
        $stmt = $db->prepare('INSERT INTO groups_tbl (simulation_id, name, leader_id) VALUES (?, ?, ?)');
        $stmt->execute([$sim_id, $name, $user['id']]);
        $group_id = $db->lastInsertId();
        
        $stmt = $db->prepare('INSERT INTO group_members (group_id, user_id) VALUES (?, ?)');
        $stmt->execute([$group_id, $user['id']]);
        
        $db->commit();
        
        json_response([
            'id' => (int)$group_id,
            'name' => $name,
            'leader_id' => (int)$user['id'],
            'member_count' => 1
        ], 201);
    } catch (Exception $e) {
        $db->rollBack();
        error_response('Erreur lors de la création du groupe', 500);
    }
}

// POST /api/groups/join
elseif ($method === 'POST' && $id === 'join') {
    $user = require_auth('student');
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    
    require_fields($input, ['group_id']);
    $group_id = (int)$input['group_id'];
    
    // Vérifier que le groupe existe
    $stmt = $db->prepare('SELECT g.*, s.status FROM groups_tbl g JOIN simulations s ON g.simulation_id = s.id WHERE g.id = ?');
    $stmt->execute([$group_id]);
    $group = $stmt->fetch();
    if (!$group) error_response('Groupe introuvable', 404);
    if ($group['status'] !== 'active') error_response('La simulation n\'est plus active');
    
    // Vérifier que l'étudiant n'est pas déjà dans un groupe
    $stmt = $db->prepare('
        SELECT 1 FROM group_members gm
        JOIN groups_tbl g ON gm.group_id = g.id
        WHERE gm.user_id = ? AND g.simulation_id = ?
    ');
    $stmt->execute([$user['id'], $group['simulation_id']]);
    if ($stmt->fetch()) error_response('Vous êtes déjà dans un groupe pour cette simulation');
    
    $stmt = $db->prepare('INSERT INTO group_members (group_id, user_id) VALUES (?, ?)');
    $stmt->execute([$group_id, $user['id']]);
    
    json_response(['success' => true, 'group_id' => $group_id], 201);
}

// PUT /api/groups/{id}/leader (changer chef)
elseif ($method === 'PUT' && $id && $action === 'leader') {
    $user = require_auth('student');
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    
    require_fields($input, ['user_id']);
    $new_leader_id = (int)$input['user_id'];
    
    // Vérifier que l'utilisateur est le chef actuel
    $stmt = $db->prepare('SELECT * FROM groups_tbl WHERE id = ? AND leader_id = ?');
    $stmt->execute([$id, $user['id']]);
    if (!$stmt->fetch()) error_response('Seul le chef de file peut transférer le rôle', 403);
    
    // Vérifier que le nouveau chef est membre
    $stmt = $db->prepare('SELECT 1 FROM group_members WHERE group_id = ? AND user_id = ?');
    $stmt->execute([$id, $new_leader_id]);
    if (!$stmt->fetch()) error_response('Cet utilisateur n\'est pas membre du groupe');
    
    $stmt = $db->prepare('UPDATE groups_tbl SET leader_id = ? WHERE id = ?');
    $stmt->execute([$new_leader_id, $id]);
    
    json_response(['success' => true, 'new_leader_id' => $new_leader_id]);
}

// DELETE /api/groups/{id}/members/{uid}
elseif ($method === 'DELETE' && $id && $action === 'members' && $segments[3]) {
    $user = require_auth();
    $member_id = (int)$segments[3];
    
    // Seul le chef ou le membre lui-même peut quitter/être retiré
    $stmt = $db->prepare('SELECT * FROM groups_tbl WHERE id = ?');
    $stmt->execute([$id]);
    $group = $stmt->fetch();
    if (!$group) error_response('Groupe introuvable', 404);
    
    if ($user['id'] !== $group['leader_id'] && $user['id'] !== $member_id) {
        error_response('Seul le chef de file peut retirer un membre', 403);
    }
    
    // Si le chef quitte, donner le lead au prochain membre
    if ($member_id === $group['leader_id']) {
        $stmt = $db->prepare('SELECT user_id FROM group_members WHERE group_id = ? AND user_id != ? LIMIT 1');
        $stmt->execute([$id, $member_id]);
        $next = $stmt->fetch();
        if ($next) {
            $stmt = $db->prepare('UPDATE groups_tbl SET leader_id = ? WHERE id = ?');
            $stmt->execute([$next['user_id'], $id]);
        } else {
            // Plus personne → supprimer le groupe
            $db->prepare('DELETE FROM groups_tbl WHERE id = ?')->execute([$id]);
            json_response(['success' => true, 'group_deleted' => true]);
        }
    }
    
    $db->prepare('DELETE FROM group_members WHERE group_id = ? AND user_id = ?')->execute([$id, $member_id]);
    
    json_response(['success' => true]);
}

// DELETE /api/groups/{id}
elseif ($method === 'DELETE' && $id) {
    $user = require_auth();
    
    $stmt = $db->prepare('SELECT * FROM groups_tbl WHERE id = ? AND leader_id = ?');
    $stmt->execute([$id, $user['id']]);
    if (!$stmt->fetch()) error_response('Seul le chef peut supprimer le groupe', 403);
    
    $db->prepare('DELETE FROM groups_tbl WHERE id = ?')->execute([$id]);
    json_response(['success' => true, 'deleted' => true]);
}

else {
    error_response('Méthode non autorisée', 405);
}
