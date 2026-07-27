<?php

namespace SimuRH\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use SimuRH\Database;
use SimuRH\Helpers;

class EvaluationController
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

        $params = $request->getQueryParams();
        $simId = (int)($params['simulation'] ?? 0);

        $stmt = $db->prepare('
            SELECT
                e.id,
                e.total_score,
                e.scores,
                e.comments,
                e.evaluated_at,
                g.name as group_name,
                sub.id as submission_id
            FROM evaluations e
            JOIN submissions sub ON e.submission_id = sub.id
            JOIN `groups` g ON sub.group_id = g.id
            WHERE sub.simulation_id = ?
            ORDER BY e.total_score DESC
        ');
        $stmt->execute([$simId]);

        return $this->json($response, $stmt->fetchAll());
    }

    public function create(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $user = $this->requireAuth($request, $response, 'professor');
            $this->requireFields($input, ['submission_id', 'scores']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $submissionId = (int)$input['submission_id'];
        $scores = $input['scores'];
        $comments = $input['comments'] ?? '';

        $stmt = $db->prepare('
            SELECT sub.*, s.professor_id
            FROM submissions sub
            JOIN simulations s ON sub.simulation_id = s.id
            WHERE sub.id = ?
        ');
        $stmt->execute([$submissionId]);
        $sub = $stmt->fetch();

        if (!$sub) return $this->error($response, 'Rendu introuvable', 404);
        if ($sub['professor_id'] != $user['id']) return $this->error($response, 'Ce rendu ne vous appartient pas', 403);

        $totalScore = 0;
        if (is_array($scores)) {
            foreach ($scores as $value) {
                $totalScore += (float)$value;
            }
        }

        $stmt = $db->prepare('SELECT id FROM evaluations WHERE submission_id = ?');
        $stmt->execute([$submissionId]);
        $existing = $stmt->fetch();

        if ($existing) {
            $stmt = $db->prepare('UPDATE evaluations SET scores = ?, total_score = ?, comments = ?, evaluated_at = CURRENT_TIMESTAMP WHERE id = ?');
            $stmt->execute([json_encode($scores, JSON_UNESCAPED_UNICODE), $totalScore, $comments, $existing['id']]);
        } else {
            $stmt = $db->prepare('INSERT INTO evaluations (submission_id, professor_id, scores, total_score, comments) VALUES (?, ?, ?, ?, ?)');
            $stmt->execute([$submissionId, $user['id'], json_encode($scores, JSON_UNESCAPED_UNICODE), $totalScore, $comments]);
        }

        return $this->json($response, [
            'success' => true,
            'total_score' => $totalScore,
            'comments' => $comments,
        ]);
    }

    public function rankings(Request $request, Response $response): Response
    {
        $db = Database::getInstance();

        try {
            $this->requireAuth($request, $response);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $params = $request->getQueryParams();
        $simId = (int)($params['simulation'] ?? 0);

        if (!$simId) {
            return $this->error($response, 'Paramètre simulation requis');
        }

        $stmt = $db->prepare('
            SELECT
                g.name as group_name,
                e.total_score,
                e.comments,
                e.evaluated_at,
                COUNT(gm.user_id) as member_count
            FROM `groups` g
            JOIN evaluations e ON e.submission_id = (
                SELECT id FROM submissions WHERE group_id = g.id LIMIT 1
            )
            LEFT JOIN group_members gm ON gm.group_id = g.id
            WHERE g.simulation_id = ?
            GROUP BY g.id
            ORDER BY e.total_score DESC
        ');
        $stmt->execute([$simId]);
        $results = $stmt->fetchAll();

        $rank = 0;
        $prevScore = null;
        foreach ($results as &$row) {
            if ($row['total_score'] !== $prevScore) {
                $rank++;
                $prevScore = $row['total_score'];
            }
            $row['rank'] = $rank;
        }

        return $this->json($response, $results);
    }
}
