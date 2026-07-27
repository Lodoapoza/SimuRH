<?php

namespace SimuRH\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use SimuRH\Database;
use SimuRH\Helpers;

class AuthController
{
    use Helpers;

    public function register(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $this->requireFields($input, ['name', 'phone', 'password', 'role', 'establishment_name']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $name = $this->cleanInput($input['name']);
        $email = $this->cleanInput($input['email'] ?? '');
        $phone = $this->cleanInput($input['phone']);
        $password = $input['password'];
        $role = $input['role'];
        $estName = $this->cleanInput($input['establishment_name']);
        $estCity = $this->cleanInput($input['establishment_city'] ?? '');

        if (!in_array($role, ['professor', 'student'])) {
            return $this->error($response, 'Le rôle doit être "professor" ou "student"');
        }
        if (strlen($password) < 4) {
            return $this->error($response, 'Mot de passe trop court (min 4 caractères)');
        }

        $stmt = $db->prepare('SELECT * FROM establishments WHERE name = ?');
        $stmt->execute([$estName]);
        $est = $stmt->fetch();

        if (!$est) {
            $stmt = $db->prepare('INSERT INTO establishments (name, city) VALUES (?, ?)');
            $stmt->execute([$estName, $estCity]);
            $estId = (int)$db->lastInsertId();
        } else {
            $estId = (int)$est['id'];
        }

        if ($email) {
            $stmt = $db->prepare('SELECT id FROM users WHERE email = ?');
            $stmt->execute([$email]);
            if ($stmt->fetch()) {
                return $this->error($response, 'Cet email est déjà utilisé');
            }
        }

        $hash = password_hash($password, PASSWORD_BCRYPT);
        $token = $this->generateToken();

        $stmt = $db->prepare('INSERT INTO users (establishment_id, name, email, phone, password_hash, role, api_token) VALUES (?, ?, ?, ?, ?, ?, ?)');
        $stmt->execute([$estId, $name, $email, $phone, $hash, $role, $token]);
        $userId = (int)$db->lastInsertId();

        return $this->json($response, [
            'token' => $token,
            'user' => [
                'id' => $userId,
                'name' => $name,
                'email' => $email,
                'phone' => $phone,
                'role' => $role,
                'establishment_id' => $estId,
                'establishment_name' => $estName,
            ],
        ], 201);
    }

    public function login(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $this->requireFields($input, ['phone', 'password']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $phone = $this->cleanInput($input['phone']);
        $password = $input['password'];

        $stmt = $db->prepare('SELECT u.*, e.name as establishment_name, e.license_status
                              FROM users u
                              JOIN establishments e ON u.establishment_id = e.id
                              WHERE u.phone = ? OR u.email = ?');
        $stmt->execute([$phone, $phone]);
        $user = $stmt->fetch();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            return $this->error($response, 'Téléphone/email ou mot de passe incorrect', 401);
        }

        $token = $this->generateToken();
        $stmt = $db->prepare('UPDATE users SET api_token = ? WHERE id = ?');
        $stmt->execute([$token, $user['id']]);

        return $this->json($response, [
            'token' => $token,
            'user' => [
                'id' => (int)$user['id'],
                'name' => $user['name'],
                'email' => $user['email'],
                'phone' => $user['phone'],
                'role' => $user['role'],
                'establishment_id' => (int)$user['establishment_id'],
                'establishment_name' => $user['establishment_name'],
                'license_status' => $user['license_status'],
            ],
        ]);
    }

    public function me(Request $request, Response $response): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('SELECT name FROM establishments WHERE id = ?');
        $stmt->execute([$user['establishment_id']]);
        $est = $stmt->fetch();

        return $this->json($response, [
            'id' => (int)$user['id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'phone' => $user['phone'],
            'role' => $user['role'],
            'establishment_id' => (int)$user['establishment_id'],
            'establishment_name' => $est['name'] ?? '',
        ]);
    }
}
