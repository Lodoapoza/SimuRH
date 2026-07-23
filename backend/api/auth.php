<?php
/**
 * SimuRH — Auth endpoints
 * POST /api/auth/register
 * POST /api/auth/login
 * GET  /api/auth/me
 */

$db = get_db();

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === null) {
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    
    if ($id === 'register') {
        require_fields($input, ['name', 'phone', 'password', 'role', 'establishment_name']);
        
        $name     = clean_input($input['name']);
        $email    = clean_input($input['email'] ?? '');
        $phone    = clean_input($input['phone']);
        $password = $input['password'];
        $role     = $input['role'];
        $est_name = clean_input($input['establishment_name']);
        $est_city = clean_input($input['establishment_city'] ?? '');
        
        if (!in_array($role, ['professor', 'student'])) {
            error_response('Le rôle doit être "professor" ou "student"');
        }
        if (strlen($password) < 4) {
            error_response('Mot de passe trop court (min 4 caractères)');
        }
        
        // Chercher ou créer l'établissement
        $stmt = $db->prepare('SELECT * FROM establishments WHERE name = ?');
        $stmt->execute([$est_name]);
        $est = $stmt->fetch();
        
        if (!$est) {
            $stmt = $db->prepare('INSERT INTO establishments (name, city) VALUES (?, ?)');
            $stmt->execute([$est_name, $est_city]);
            $est_id = $db->lastInsertId();
        } else {
            $est_id = $est['id'];
        }
        
        // Vérifier email unique si fourni
        if ($email) {
            $stmt = $db->prepare('SELECT id FROM users WHERE email = ?');
            $stmt->execute([$email]);
            if ($stmt->fetch()) {
                error_response('Cet email est déjà utilisé');
            }
        }
        
        // Créer l'utilisateur
        $hash  = password_hash($password, PASSWORD_BCRYPT);
        $token = generate_token();
        
        $stmt = $db->prepare('INSERT INTO users (establishment_id, name, email, phone, password_hash, role, api_token) VALUES (?, ?, ?, ?, ?, ?, ?)');
        $stmt->execute([$est_id, $name, $email, $phone, $hash, $role, $token]);
        $user_id = $db->lastInsertId();
        
        json_response([
            'token' => $token,
            'user' => [
                'id' => (int)$user_id,
                'name' => $name,
                'email' => $email,
                'phone' => $phone,
                'role' => $role,
                'establishment_id' => (int)$est_id,
                'establishment_name' => $est_name
            ]
        ], 201);
    }
    
    elseif ($id === 'login') {
        require_fields($input, ['phone', 'password']);
        
        $phone    = clean_input($input['phone']);
        $password = $input['password'];
        
        $stmt = $db->prepare('SELECT u.*, e.name as establishment_name, e.license_status 
                              FROM users u 
                              JOIN establishments e ON u.establishment_id = e.id 
                              WHERE u.phone = ? OR u.email = ?');
        $stmt->execute([$phone, $phone]);
        $user = $stmt->fetch();
        
        if (!$user || !password_verify($password, $user['password_hash'])) {
            error_response('Téléphone/email ou mot de passe incorrect', 401);
        }
        
        // Renouveler le token
        $token = generate_token();
        $stmt = $db->prepare('UPDATE users SET api_token = ? WHERE id = ?');
        $stmt->execute([$token, $user['id']]);
        
        json_response([
            'token' => $token,
            'user' => [
                'id' => (int)$user['id'],
                'name' => $user['name'],
                'email' => $user['email'],
                'phone' => $user['phone'],
                'role' => $user['role'],
                'establishment_id' => (int)$user['establishment_id'],
                'establishment_name' => $user['establishment_name'],
                'license_status' => $user['license_status']
            ]
        ]);
    }
    
    else {
        error_response('Action non reconnue');
    }
}

// GET /api/auth/me
elseif ($_SERVER['REQUEST_METHOD'] === 'GET' && $id === 'me') {
    $user = require_auth();
    $stmt = $db->prepare('SELECT name, email, phone, role, establishment_id FROM establishments WHERE id = ?');
    $stmt->execute([$user['establishment_id']]);
    $est = $stmt->fetch();
    
    json_response([
        'id' => (int)$user['id'],
        'name' => $user['name'],
        'email' => $user['email'],
        'phone' => $user['phone'],
        'role' => $user['role'],
        'establishment_id' => (int)$user['establishment_id'],
        'establishment_name' => $est['name'] ?? ''
    ]);
}

else {
    error_response('Méthode non autorisée', 405);
}
