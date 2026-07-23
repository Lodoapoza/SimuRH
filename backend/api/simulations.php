<?php
/**
 * SimuRH — Simulations
 * GET    /api/simulations              → Liste du professeur
 * POST   /api/simulations              → Créer
 * GET    /api/simulations/{id}         → Détail
 * PUT    /api/simulations/{id}         → Modifier
 * POST   /api/simulations/{id}/launch  → Lancer
 * GET    /api/simulations/join/{code}  → Rejoindre par code (étudiant)
 */

$db = get_db();
$method = $_SERVER['REQUEST_METHOD'];

// GET /api/simulations/join/{code}
if ($method === 'GET' && $id === 'join' && $action) {
    $user = require_auth('student');
    
    $stmt = $db->prepare('
        SELECT s.*, u.name as professor_name, e.name as establishment_name
        FROM simulations s
        JOIN users u ON s.professor_id = u.id
        JOIN establishments e ON s.establishment_id = e.id
        WHERE s.code = ? AND s.status = "active"
    ');
    $stmt->execute([$action]);
    $sim = $stmt->fetch();
    
    if (!$sim) {
        error_response('Code invalide ou simulation inactive', 404);
    }
    
    // Vérifier license essai
    $stmt = $db->prepare('SELECT license_status FROM establishments WHERE id = ?');
    $stmt->execute([$sim['establishment_id']]);
    $est = $stmt->fetch();
    
    if ($est['license_status'] === 'trial') {
        // Compter les étudiants dans cette simulation
        $stmt = $db->prepare('
            SELECT COUNT(DISTINCT gm.user_id) as cnt
            FROM group_members gm
            JOIN groups_tbl g ON gm.group_id = g.id
            WHERE g.simulation_id = ?
        ');
        $stmt->execute([$sim['id']]);
        $count = (int)$stmt->fetch()['cnt'];
        
        if ($count >= LICENSE_TRIAL_STUDENTS) {
            error_response('Version d\'essai limitée à ' . LICENSE_TRIAL_STUDENTS . ' étudiant. L\'établissement doit souscrire à la licence complète.');
        }
    }
    
    json_response($sim);
}

// GET /api/simulations/{id}
if ($method === 'GET' && $id && !$action) {
    $user = require_auth();
    
    $stmt = $db->prepare('
        SELECT s.*, u.name as professor_name,
               (SELECT COUNT(*) FROM groups_tbl WHERE simulation_id = s.id) as group_count,
               (SELECT COUNT(*) FROM submissions WHERE simulation_id = s.id) as submission_count
        FROM simulations s
        JOIN users u ON s.professor_id = u.id
        WHERE s.id = ?
    ');
    $stmt->execute([$id]);
    $sim = $stmt->fetch();
    
    if (!$sim) error_response('Simulation introuvable', 404);
    
    // Charger les fichiers
    $stmt = $db->prepare('SELECT id, original_name, file_type, file_size FROM simulation_files WHERE simulation_id = ?');
    $stmt->execute([$id]);
    $sim['files'] = $stmt->fetchAll();
    
    // Décoder JSON
    $sim['objectives'] = json_decode($sim['objectives'] ?: '[]', true);
    $sim['grading_criteria'] = json_decode($sim['grading_criteria'] ?: '[]', true);
    
    json_response($sim);
}

// GET /api/simulations (liste du professeur)
if ($method === 'GET' && !$id) {
    $user = require_auth('professor');
    
    $stmt = $db->prepare('
        SELECT s.*,
               (SELECT COUNT(*) FROM groups_tbl WHERE simulation_id = s.id) as group_count,
               (SELECT COUNT(*) FROM submissions WHERE simulation_id = s.id) as submission_count
        FROM simulations s
        WHERE s.professor_id = ?
        ORDER BY s.created_at DESC
    ');
    $stmt->execute([$user['id']]);
    $simulations = $stmt->fetchAll();
    
    json_response($simulations);
}

// POST /api/simulations (créer)
if ($method === 'POST') {
    $user = require_auth('professor');
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    
    require_fields($input, ['title', 'context']);
    
    // Vérifier licence essai
    $stmt = $db->prepare('SELECT license_status FROM establishments WHERE id = ?');
    $stmt->execute([$user['establishment_id']]);
    $est = $stmt->fetch();
    
    if ($est['license_status'] === 'trial') {
        $stmt = $db->prepare('SELECT COUNT(*) as cnt FROM simulations WHERE professor_id = ?');
        $stmt->execute([$user['id']]);
        $count = (int)$stmt->fetch()['cnt'];
        if ($count >= LICENSE_TRIAL_SIMULATIONS) {
            error_response('Version d\'essai limitée à ' . LICENSE_TRIAL_SIMULATIONS . ' simulation. Souscrivez à la licence complète.');
        }
    }
    
    $code = generate_simulation_code();
    
    $stmt = $db->prepare('
        INSERT INTO simulations (professor_id, establishment_id, code, title, context, objectives, duration_days, max_groups, grading_criteria)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ');
    $stmt->execute([
        $user['id'],
        $user['establishment_id'],
        $code,
        clean_input($input['title']),
        $input['context'],
        json_encode($input['objectives'] ?? [], JSON_UNESCAPED_UNICODE),
        (int)($input['duration_days'] ?? 14),
        (int)($input['max_groups'] ?? 10),
        json_encode($input['grading_criteria'] ?? [
            ['name' => 'Pertinence de l\'analyse', 'max_score' => 10, 'coefficient' => 2],
            ['name' => 'Qualité de la rédaction', 'max_score' => 10, 'coefficient' => 1],
            ['name' => 'Respect des consignes', 'max_score' => 5, 'coefficient' => 1],
            ['name' => 'Présentation', 'max_score' => 5, 'coefficient' => 1]
        ], JSON_UNESCAPED_UNICODE)
    ]);
    
    json_response([
        'id' => (int)$db->lastInsertId(),
        'code' => $code,
        'title' => clean_input($input['title'])
    ], 201);
}

// PUT /api/simulations/{id}
if ($method === 'PUT' && $id && !$action) {
    $user = require_auth('professor');
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    
    // Vérifier propriété
    $stmt = $db->prepare('SELECT * FROM simulations WHERE id = ? AND professor_id = ?');
    $stmt->execute([$id, $user['id']]);
    if (!$stmt->fetch()) error_response('Simulation introuvable ou accès refusé', 404);
    
    $updates = [];
    $params = [];
    foreach (['title', 'context', 'objectives', 'duration_days', 'max_groups', 'grading_criteria'] as $field) {
        if (isset($input[$field])) {
            $updates[] = "$field = ?";
            $params[] = is_array($input[$field]) ? json_encode($input[$field], JSON_UNESCAPED_UNICODE) : $input[$field];
        }
    }
    
    if (empty($updates)) error_response('Aucun champ à mettre à jour');
    
    $params[] = $id;
    $sql = 'UPDATE simulations SET ' . implode(', ', $updates) . ' WHERE id = ?';
    $db->prepare($sql)->execute($params);
    
    json_response(['success' => true]);
}

// POST /api/simulations/{id}/launch
if ($method === 'POST' && $id && $action === 'launch') {
    $user = require_auth('professor');
    
    $stmt = $db->prepare('SELECT * FROM simulations WHERE id = ? AND professor_id = ?');
    $stmt->execute([$id, $user['id']]);
    if (!$stmt->fetch()) error_response('Simulation introuvable', 404);
    
    $stmt = $db->prepare('UPDATE simulations SET status = "active" WHERE id = ?');
    $stmt->execute([$id]);
    
    json_response(['success' => true, 'message' => 'Simulation lancée']);
}

// POST /api/simulations/{id}/files (upload fichier)
if ($method === 'POST' && $id && $action === 'files') {
    $user = require_auth('professor');
    
    if (empty($_FILES['file'])) error_response('Aucun fichier fourni');
    
    $file = $_FILES['file'];
    $path = handle_upload($file, 'simulations/' . $id);
    
    $stmt = $db->prepare('INSERT INTO simulation_files (simulation_id, filename, original_name, file_type, file_size) VALUES (?, ?, ?, ?, ?)');
    $stmt->execute([$id, $path, $file['name'], $file['type'], $file['size']]);
    
    json_response([
        'id' => (int)$db->lastInsertId(),
        'filename' => $file['name'],
        'path' => $path
    ], 201);
}

// GET /api/simulations/{id}/files
if ($method === 'GET' && $id && $action === 'files') {
    $stmt = $db->prepare('SELECT id, original_name, file_type, file_size, uploaded_at FROM simulation_files WHERE simulation_id = ?');
    $stmt->execute([$id]);
    json_response($stmt->fetchAll());
}

else {
    error_response('Méthode non autorisée', 405);
}
