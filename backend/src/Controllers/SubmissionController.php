<?php

namespace SimuRH\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use SimuRH\Database;
use SimuRH\Helpers;

class SubmissionController
{
    use Helpers;

    public function list(Request $request, Response $response): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $params = $request->getQueryParams();
        $simId = (int)($params['simulation'] ?? 0);

        if (!$simId) {
            return $this->error($response, 'Paramètre simulation requis');
        }

        if ($user['role'] === 'student') {
            $stmt = $db->prepare('
                SELECT sub.*, g.name as group_name, e.total_score, e.comments, e.scores
                FROM submissions sub
                JOIN `groups` g ON sub.group_id = g.id
                LEFT JOIN evaluations e ON e.submission_id = sub.id
                JOIN group_members gm ON gm.group_id = g.id
                WHERE sub.simulation_id = ? AND gm.user_id = ?
            ');
            $stmt->execute([$simId, $user['id']]);
        } else {
            $stmt = $db->prepare('
                SELECT sub.*, g.name as group_name, u.name as leader_name,
                       e.total_score, e.comments, e.scores, e.evaluated_at
                FROM submissions sub
                JOIN `groups` g ON sub.group_id = g.id
                LEFT JOIN users u ON g.leader_id = u.id
                LEFT JOIN evaluations e ON e.submission_id = sub.id
                WHERE sub.simulation_id = ?
                ORDER BY g.name
            ');
            $stmt->execute([$simId]);
        }

        return $this->json($response, $stmt->fetchAll());
    }

    public function create(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $user = $this->requireAuth($request, $response, 'student');
            $this->requireFields($input, ['simulation_id', 'content']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $simId = (int)$input['simulation_id'];
        $content = $input['content'];

        $stmt = $db->prepare('
            SELECT g.id as group_id FROM `groups` g
            JOIN group_members gm ON gm.group_id = g.id
            WHERE g.simulation_id = ? AND g.leader_id = ? AND gm.user_id = ?
        ');
        $stmt->execute([$simId, $user['id'], $user['id']]);
        $group = $stmt->fetch();

        if (!$group) {
            return $this->error($response, 'Vous devez être chef de file pour soumettre le travail');
        }

        $groupId = $group['group_id'];

        $stmt = $db->prepare('SELECT id FROM submissions WHERE group_id = ? AND simulation_id = ?');
        $stmt->execute([$groupId, $simId]);
        $existing = $stmt->fetch();

        $filePath = null;

        if (!empty($_FILES['file'])) {
            try {
                $filePath = $this->handleUpload($_FILES['file'], 'submissions/' . $simId);
            } catch (\RuntimeException $e) {
                return $this->error($response, $e->getMessage(), $e->getCode() ?: 500);
            }
        } elseif (!empty($input['file_path'])) {
            $filePath = $input['file_path'];
        }

        if ($existing) {
            $sql = 'UPDATE submissions SET content = ?, submitted_at = CURRENT_TIMESTAMP, synced_at = CURRENT_TIMESTAMP';
            $params = [$content];

            if ($filePath) {
                $sql .= ', file_path = ?';
                $params[] = $filePath;
            }

            $sql .= ' WHERE id = ?';
            $params[] = $existing['id'];
            $db->prepare($sql)->execute($params);

            return $this->json($response, ['success' => true, 'updated' => true, 'id' => $existing['id']]);
        } else {
            $stmt = $db->prepare('INSERT INTO submissions (group_id, simulation_id, content, file_path, submitted_at) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)');
            $stmt->execute([$groupId, $simId, $content, $filePath]);

            return $this->json($response, ['success' => true, 'id' => (int)$db->lastInsertId()], 201);
        }
    }
}
