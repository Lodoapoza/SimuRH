<?php
/**
 * SimuRH — Établissements
 * GET  /api/establishments
 * POST /api/establishments
 */

$db = get_db();

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
