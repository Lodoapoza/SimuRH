<?php
/**
 * SimuRH — Établissements
 * GET   /api/establishments           — liste
 * POST  /api/establishments           — créer
 * GET   /api/establishments/status    — statut détaillé (trial limits, etc.)
 */

$db = get_db();

// Route plus spécifique en premier
if ($resource === 'establishments' && $action === 'status') {
    handleStatus();
    return;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $db->query('SELECT id, name, city, country FROM establishments ORDER BY name');
    json_response($stmt->fetchAll());
}

elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    require_fields($input, ['name']);
    
    $name = clean_input($input['name']);
    $city = clean_input($input['city'] ?? '');
    
    // Vérifier doublon
    $stmt = $db->prepare('SELECT id FROM establishments WHERE name = ?');
    $stmt->execute([$name]);
    if ($stmt->fetch()) {
        error_response('Cet établissement existe déjà');
    }
    
    $stmt = $db->prepare('INSERT INTO establishments (name, city) VALUES (?, ?)');
    $stmt->execute([$name, $city]);
    
    json_response([
        'id' => (int)$db->lastInsertId(),
        'name' => $name,
        'city' => $city
    ], 201);
}

else {
    error_response('Méthode non autorisée', 405);
}

/**
 * GET /api/establishments/status
 * Retourne le statut détaillé d'un établissement (pour la page licence)
 */
function handleStatus() {
    global $db;
    
    $user = require_auth();
    $estabId = $user['establishment_id'];
    
    // Infos établissement
    $stmt = $db->prepare('SELECT id, name, city, country, license_status FROM establishments WHERE id = ?');
    $stmt->execute([$estabId]);
    $estab = $stmt->fetch();
    
    if (!$estab) {
        error_response('Établissement introuvable', 404);
    }
    
    // Compter les simulations
    $stmt = $db->prepare('SELECT COUNT(*) as cnt FROM simulations WHERE establishment_id = ?');
    $stmt->execute([$estabId]);
    $simCount = (int)$stmt->fetch()['cnt'];
    
    // Compter les étudiants
    $stmt = $db->prepare("
        SELECT COUNT(DISTINCT u.id) as cnt
        FROM users u
        WHERE u.establishment_id = ? AND u.role = 'student'
    ");
    $stmt->execute([$estabId]);
    $studentCount = (int)$stmt->fetch()['cnt'];
    
    // Calculer les jours restants pour la licence
    $stmt = $db->prepare("SELECT expiry_date FROM licenses WHERE establishment_id = ? AND status = 'active' ORDER BY id DESC LIMIT 1");
    $stmt->execute([$estabId]);
    $license = $stmt->fetch();
    
    $daysLeft = 0;
    if ($license && $license['expiry_date']) {
        $expiry = new DateTime($license['expiry_date']);
        $now = new DateTime();
        $daysLeft = max(0, (int)$now->diff($expiry)->format('%a'));
    }
    
    json_response([
        'id' => (int)$estab['id'],
        'name' => $estab['name'],
        'city' => $estab['city'],
        'license_status' => $estab['license_status'],
        'simulation_count' => $simCount,
        'student_count' => $studentCount,
        'days_left' => $daysLeft,
        'expiry_date' => $license['expiry_date'] ?? null,
        'trial_limits' => [
            'max_simulations' => LICENSE_TRIAL_SIMULATIONS,
            'max_students' => LICENSE_TRIAL_STUDENTS,
        ],
    ]);
}
