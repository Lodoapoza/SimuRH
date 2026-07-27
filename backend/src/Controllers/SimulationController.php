<?php

namespace SimuRH\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use SimuRH\Database;
use SimuRH\Helpers;
use SimuRH\Settings;

class SimulationController
{
    use Helpers;

    public function list(Request $request, Response $response): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response, 'professor');
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('
            SELECT s.*,
                   (SELECT COUNT(*) FROM `groups` WHERE simulation_id = s.id) as group_count,
                   (SELECT COUNT(*) FROM submissions WHERE simulation_id = s.id) as submission_count
            FROM simulations s
            WHERE s.professor_id = ?
            ORDER BY s.created_at DESC
        ');
        $stmt->execute([$user['id']]);

        return $this->json($response, $stmt->fetchAll());
    }

    public function get(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();

        try {
            $this->requireAuth($request, $response);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('
            SELECT s.*, u.name as professor_name,
                   (SELECT COUNT(*) FROM `groups` WHERE simulation_id = s.id) as group_count,
                   (SELECT COUNT(*) FROM submissions WHERE simulation_id = s.id) as submission_count
            FROM simulations s
            JOIN users u ON s.professor_id = u.id
            WHERE s.id = ?
        ');
        $stmt->execute([$args['id']]);
        $sim = $stmt->fetch();

        if (!$sim) {
            return $this->error($response, 'Simulation introuvable', 404);
        }

        $stmt = $db->prepare('SELECT id, original_name, file_type, file_size FROM simulation_files WHERE simulation_id = ?');
        $stmt->execute([$args['id']]);
        $sim['files'] = $stmt->fetchAll();

        $sim['objectives'] = json_decode($sim['objectives'] ?: '[]', true);
        $sim['grading_criteria'] = json_decode($sim['grading_criteria'] ?: '[]', true);

        return $this->json($response, $sim);
    }

    public function create(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $user = $this->requireAuth($request, $response, 'professor');
            $this->requireFields($input, ['title', 'context']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $stmt = $db->prepare('SELECT license_status FROM establishments WHERE id = ?');
        $stmt->execute([$user['establishment_id']]);
        $est = $stmt->fetch();

        if ($est['license_status'] === 'trial') {
            $stmt = $db->prepare('SELECT COUNT(*) as cnt FROM simulations WHERE professor_id = ?');
            $stmt->execute([$user['id']]);
            $count = (int)$stmt->fetch()['cnt'];
            if ($count >= Settings::get('LICENSE_TRIAL_SIMULATIONS')) {
                return $this->error($response, 'Version d\'essai limitée à ' . Settings::get('LICENSE_TRIAL_SIMULATIONS') . ' simulation. Souscrivez à la licence complète.');
            }
        }

        $code = $this->generateSimulationCode();

        $stmt = $db->prepare('
            INSERT INTO simulations (professor_id, establishment_id, code, title, context, objectives, duration_days, max_groups, grading_criteria)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ');
        $stmt->execute([
            $user['id'],
            $user['establishment_id'],
            $code,
            $this->cleanInput($input['title']),
            $input['context'],
            json_encode($input['objectives'] ?? [], JSON_UNESCAPED_UNICODE),
            (int)($input['duration_days'] ?? 14),
            (int)($input['max_groups'] ?? 10),
            json_encode($input['grading_criteria'] ?? [
                ['name' => 'Pertinence de l\'analyse', 'max_score' => 10, 'coefficient' => 2],
                ['name' => 'Qualité de la rédaction', 'max_score' => 10, 'coefficient' => 1],
                ['name' => 'Respect des consignes', 'max_score' => 5, 'coefficient' => 1],
                ['name' => 'Présentation', 'max_score' => 5, 'coefficient' => 1],
            ], JSON_UNESCAPED_UNICODE),
        ]);

        return $this->json($response, [
            'id' => (int)$db->lastInsertId(),
            'code' => $code,
            'title' => $this->cleanInput($input['title']),
        ], 201);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $user = $this->requireAuth($request, $response, 'professor');
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('SELECT * FROM simulations WHERE id = ? AND professor_id = ?');
        $stmt->execute([$args['id'], $user['id']]);
        if (!$stmt->fetch()) {
            return $this->error($response, 'Simulation introuvable ou accès refusé', 404);
        }

        $updates = [];
        $params = [];
        foreach (['title', 'context', 'objectives', 'duration_days', 'max_groups', 'grading_criteria'] as $field) {
            if (isset($input[$field])) {
                $updates[] = "$field = ?";
                $params[] = is_array($input[$field]) ? json_encode($input[$field], JSON_UNESCAPED_UNICODE) : $input[$field];
            }
        }

        if (empty($updates)) {
            return $this->error($response, 'Aucun champ à mettre à jour');
        }

        $params[] = $args['id'];
        $sql = 'UPDATE simulations SET ' . implode(', ', $updates) . ' WHERE id = ?';
        $db->prepare($sql)->execute($params);

        return $this->json($response, ['success' => true]);
    }

    public function delete(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response, 'professor');
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('SELECT * FROM simulations WHERE id = ? AND professor_id = ?');
        $stmt->execute([$args['id'], $user['id']]);
        if (!$stmt->fetch()) {
            return $this->error($response, 'Simulation introuvable ou accès refusé', 404);
        }

        $db->prepare('DELETE FROM simulations WHERE id = ?')->execute([$args['id']]);

        return $this->json($response, ['success' => true, 'deleted' => true]);
    }

    public function launch(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response, 'professor');
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('SELECT * FROM simulations WHERE id = ? AND professor_id = ?');
        $stmt->execute([$args['id'], $user['id']]);
        if (!$stmt->fetch()) {
            return $this->error($response, 'Simulation introuvable', 404);
        }

        $db->prepare('UPDATE simulations SET status = "active" WHERE id = ?')->execute([$args['id']]);

        return $this->json($response, ['success' => true, 'message' => 'Simulation lancée']);
    }

    public function join(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response, 'student');
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('
            SELECT s.*, u.name as professor_name, e.name as establishment_name
            FROM simulations s
            JOIN users u ON s.professor_id = u.id
            JOIN establishments e ON s.establishment_id = e.id
            WHERE s.code = ? AND s.status = "active"
        ');
        $stmt->execute([$args['code']]);
        $sim = $stmt->fetch();

        if (!$sim) {
            return $this->error($response, 'Code invalide ou simulation inactive', 404);
        }

        $stmt = $db->prepare('SELECT license_status FROM establishments WHERE id = ?');
        $stmt->execute([$sim['establishment_id']]);
        $est = $stmt->fetch();

        if ($est['license_status'] === 'trial') {
            $stmt = $db->prepare('
                SELECT COUNT(DISTINCT gm.user_id) as cnt
                FROM group_members gm
                JOIN `groups` g ON gm.group_id = g.id
                WHERE g.simulation_id = ?
            ');
            $stmt->execute([$sim['id']]);
            $count = (int)$stmt->fetch()['cnt'];

            if ($count >= Settings::get('LICENSE_TRIAL_STUDENTS')) {
                return $this->error($response, 'Version d\'essai limitée à ' . Settings::get('LICENSE_TRIAL_STUDENTS') . ' étudiant. L\'établissement doit souscrire à la licence complète.');
            }
        }

        return $this->json($response, $sim);
    }

    public function uploadFiles(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response, 'professor');
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        if (empty($_FILES['file'])) {
            return $this->error($response, 'Aucun fichier fourni');
        }

        $file = $_FILES['file'];
        try {
            $path = $this->handleUpload($file, 'simulations/' . $args['id']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 500);
        }

        $stmt = $db->prepare('INSERT INTO simulation_files (simulation_id, filename, original_name, file_type, file_size) VALUES (?, ?, ?, ?, ?)');
        $stmt->execute([$args['id'], $path, $file['name'], $file['type'], $file['size']]);

        return $this->json($response, [
            'id' => (int)$db->lastInsertId(),
            'filename' => $file['name'],
            'path' => $path,
        ], 201);
    }

    public function listFiles(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();
        $stmt = $db->prepare('SELECT id, original_name, file_type, file_size, uploaded_at FROM simulation_files WHERE simulation_id = ?');
        $stmt->execute([$args['id']]);

        return $this->json($response, $stmt->fetchAll());
    }
}
