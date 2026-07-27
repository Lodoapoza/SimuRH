<?php

namespace SimuRH\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use SimuRH\Database;
use SimuRH\Helpers;
use SimuRH\Settings;

class LicenseController
{
    use Helpers;

    public function validate(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $this->requireFields($input, ['establishment', 'key']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $estId = $input['establishment'];
        $key = $input['key'];

        $stmt = $db->prepare('SELECT license_status, license_key, license_end FROM establishments WHERE id = ?');
        $stmt->execute([$estId]);
        $est = $stmt->fetch();

        if (!$est) {
            return $this->error($response, 'Établissement introuvable', 404);
        }

        if ($est['license_status'] !== 'active') {
            return $this->error($response, 'Licence non active', 403);
        }

        $expectedHmac = strtoupper(hash_hmac('sha256', (string)$estId, $est['license_key']));

        if (!hash_equals($expectedHmac, strtoupper($key))) {
            return $this->error($response, 'Clé de licence invalide', 403);
        }

        $now = new \DateTime();
        $end = $est['license_end'] ? new \DateTime($est['license_end']) : null;
        $valid = $end && $now <= $end;

        if (!$valid) {
            $db->prepare("UPDATE establishments SET license_status = 'expired' WHERE id = ?")->execute([$estId]);
            return $this->error($response, 'Licence expirée', 403);
        }

        return $this->json($response, [
            'valid' => true,
            'expires_at' => $est['license_end'],
            'days_left' => max(0, (int)$now->diff($end)->format('%a')),
        ]);
    }

    public function status(Request $request, Response $response): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('SELECT * FROM establishments WHERE id = ?');
        $stmt->execute([$user['establishment_id']]);
        $est = $stmt->fetch();

        if (!$est) {
            return $this->error($response, 'Établissement introuvable', 404);
        }

        $stmt = $db->prepare("SELECT COUNT(*) as cnt FROM users WHERE establishment_id = ? AND role = 'student'");
        $stmt->execute([$user['establishment_id']]);
        $studentCount = (int)$stmt->fetch()['cnt'];

        $stmt = $db->prepare('SELECT COUNT(*) as cnt FROM simulations WHERE establishment_id = ?');
        $stmt->execute([$user['establishment_id']]);
        $simCount = (int)$stmt->fetch()['cnt'];

        $daysLeft = 0;
        if ($est['license_end']) {
            $end = new \DateTime($est['license_end']);
            $now = new \DateTime();
            $daysLeft = max(0, (int)$now->diff($end)->days);
        }

        return $this->json($response, [
            'status' => $est['license_status'],
            'days_left' => $daysLeft,
            'expires_at' => $est['license_end'],
            'student_count' => $studentCount,
            'simulation_count' => $simCount,
            'trial_limits' => [
                'max_students' => Settings::get('LICENSE_TRIAL_STUDENTS'),
                'max_simulations' => Settings::get('LICENSE_TRIAL_SIMULATIONS'),
            ],
            'price' => Settings::get('LICENSE_PRICE'),
        ]);
    }
}
