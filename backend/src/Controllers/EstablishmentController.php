<?php

namespace SimuRH\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use SimuRH\Database;
use SimuRH\Helpers;
use SimuRH\Settings;

class EstablishmentController
{
    use Helpers;

    public function list(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $stmt = $db->query('SELECT id, name, city, country FROM establishments ORDER BY name');
        return $this->json($response, $stmt->fetchAll());
    }

    public function get(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();
        $stmt = $db->prepare('SELECT id, name, city, country FROM establishments WHERE id = ?');
        $stmt->execute([$args['id']]);
        $est = $stmt->fetch();

        if (!$est) {
            return $this->error($response, 'Établissement introuvable', 404);
        }

        return $this->json($response, $est);
    }

    public function create(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $this->requireFields($input, ['name']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $name = $this->cleanInput($input['name']);
        $city = $this->cleanInput($input['city'] ?? '');

        $stmt = $db->prepare('SELECT id FROM establishments WHERE name = ?');
        $stmt->execute([$name]);
        if ($stmt->fetch()) {
            return $this->error($response, 'Cet établissement existe déjà');
        }

        $stmt = $db->prepare('INSERT INTO establishments (name, city) VALUES (?, ?)');
        $stmt->execute([$name, $city]);

        return $this->json($response, [
            'id' => (int)$db->lastInsertId(),
            'name' => $name,
            'city' => $city,
        ], 201);
    }

    public function status(Request $request, Response $response): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $estabId = $user['establishment_id'];

        $stmt = $db->prepare('SELECT id, name, city, country, license_status, license_end FROM establishments WHERE id = ?');
        $stmt->execute([$estabId]);
        $estab = $stmt->fetch();

        if (!$estab) {
            return $this->error($response, 'Établissement introuvable', 404);
        }

        $stmt = $db->prepare('SELECT COUNT(*) as cnt FROM simulations WHERE establishment_id = ?');
        $stmt->execute([$estabId]);
        $simCount = (int)$stmt->fetch()['cnt'];

        $stmt = $db->prepare("SELECT COUNT(DISTINCT u.id) as cnt FROM users u WHERE u.establishment_id = ? AND u.role = 'student'");
        $stmt->execute([$estabId]);
        $studentCount = (int)$stmt->fetch()['cnt'];

        $daysLeft = 0;
        if ($estab['license_end']) {
            $expiry = new \DateTime($estab['license_end']);
            $now = new \DateTime();
            $daysLeft = max(0, (int)$now->diff($expiry)->format('%a'));
        }

        return $this->json($response, [
            'id' => (int)$estab['id'],
            'name' => $estab['name'],
            'city' => $estab['city'],
            'license_status' => $estab['license_status'],
            'simulation_count' => $simCount,
            'student_count' => $studentCount,
            'days_left' => $daysLeft,
            'expiry_date' => $estab['license_end'] ?? null,
            'trial_limits' => [
                'max_simulations' => Settings::get('LICENSE_TRIAL_SIMULATIONS'),
                'max_students' => Settings::get('LICENSE_TRIAL_STUDENTS'),
            ],
        ]);
    }
}
