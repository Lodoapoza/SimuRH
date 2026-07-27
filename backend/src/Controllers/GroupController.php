<?php

namespace SimuRH\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use SimuRH\Database;
use SimuRH\Helpers;

class GroupController
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

        $stmt = $db->prepare('
            SELECT g.*, u.name as leader_name
            FROM `groups` g
            LEFT JOIN users u ON g.leader_id = u.id
            WHERE g.simulation_id = ?
            ORDER BY g.name
        ');
        $stmt->execute([$simId]);
        $groups = $stmt->fetchAll();

        foreach ($groups as &$group) {
            $stmt = $db->prepare('
                SELECT u.id, u.name, u.email,
                       CASE WHEN g.leader_id = u.id THEN 1 ELSE 0 END as is_leader
                FROM group_members gm
                JOIN users u ON gm.user_id = u.id
                JOIN `groups` g ON gm.group_id = g.id
                WHERE gm.group_id = ?
            ');
            $stmt->execute([$group['id']]);
            $group['members'] = $stmt->fetchAll();

            $stmt = $db->prepare('SELECT id, submitted_at FROM submissions WHERE group_id = ?');
            $stmt->execute([$group['id']]);
            $sub = $stmt->fetch();
            $group['has_submission'] = !empty($sub);
            $group['submitted_at'] = $sub['submitted_at'] ?? null;
        }

        return $this->json($response, $groups);
    }

    public function create(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $user = $this->requireAuth($request, $response, 'student');
            $this->requireFields($input, ['simulation_id', 'name']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $simId = (int)$input['simulation_id'];
        $name = $this->cleanInput($input['name']);

        $stmt = $db->prepare('SELECT id, status FROM simulations WHERE id = ?');
        $stmt->execute([$simId]);
        $sim = $stmt->fetch();
        if (!$sim) return $this->error($response, 'Simulation introuvable', 404);
        if ($sim['status'] !== 'active') return $this->error($response, 'La simulation n\'est pas active');

        $stmt = $db->prepare('
            SELECT 1 FROM group_members gm
            JOIN `groups` g ON gm.group_id = g.id
            WHERE gm.user_id = ? AND g.simulation_id = ?
        ');
        $stmt->execute([$user['id'], $simId]);
        if ($stmt->fetch()) return $this->error($response, 'Vous êtes déjà dans un groupe pour cette simulation');

        $stmt = $db->prepare('SELECT COUNT(*) as cnt FROM `groups` WHERE simulation_id = ?');
        $stmt->execute([$simId]);
        $count = (int)$stmt->fetch()['cnt'];

        $stmt = $db->prepare('SELECT max_groups FROM simulations WHERE id = ?');
        $stmt->execute([$simId]);
        $max = (int)$stmt->fetch()['max_groups'];
        if ($count >= $max) return $this->error($response, 'Nombre maximum de groupes atteint');

        $db->beginTransaction();
        try {
            $stmt = $db->prepare('INSERT INTO `groups` (simulation_id, name, leader_id) VALUES (?, ?, ?)');
            $stmt->execute([$simId, $name, $user['id']]);
            $groupId = (int)$db->lastInsertId();

            $stmt = $db->prepare('INSERT INTO group_members (group_id, user_id) VALUES (?, ?)');
            $stmt->execute([$groupId, $user['id']]);

            $db->commit();

            return $this->json($response, [
                'id' => $groupId,
                'name' => $name,
                'leader_id' => (int)$user['id'],
                'member_count' => 1,
            ], 201);
        } catch (\Exception $e) {
            $db->rollBack();
            return $this->error($response, 'Erreur lors de la création du groupe', 500);
        }
    }

    public function join(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $user = $this->requireAuth($request, $response, 'student');
            $this->requireFields($input, ['group_id']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $groupId = (int)$input['group_id'];

        $stmt = $db->prepare('SELECT g.*, s.status FROM `groups` g JOIN simulations s ON g.simulation_id = s.id WHERE g.id = ?');
        $stmt->execute([$groupId]);
        $group = $stmt->fetch();
        if (!$group) return $this->error($response, 'Groupe introuvable', 404);
        if ($group['status'] !== 'active') return $this->error($response, 'La simulation n\'est plus active');

        $stmt = $db->prepare('
            SELECT 1 FROM group_members gm
            JOIN `groups` g ON gm.group_id = g.id
            WHERE gm.user_id = ? AND g.simulation_id = ?
        ');
        $stmt->execute([$user['id'], $group['simulation_id']]);
        if ($stmt->fetch()) return $this->error($response, 'Vous êtes déjà dans un groupe pour cette simulation');

        $stmt = $db->prepare('INSERT INTO group_members (group_id, user_id) VALUES (?, ?)');
        $stmt->execute([$groupId, $user['id']]);

        return $this->json($response, ['success' => true, 'group_id' => $groupId], 201);
    }

    public function update(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $user = $this->requireAuth($request, $response, 'student');
            $this->requireFields($input, ['user_id']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $newLeaderId = (int)$input['user_id'];

        $stmt = $db->prepare('SELECT * FROM `groups` WHERE id = ? AND leader_id = ?');
        $stmt->execute([$args['id'], $user['id']]);
        if (!$stmt->fetch()) {
            return $this->error($response, 'Seul le chef de file peut transférer le rôle', 403);
        }

        $stmt = $db->prepare('SELECT 1 FROM group_members WHERE group_id = ? AND user_id = ?');
        $stmt->execute([$args['id'], $newLeaderId]);
        if (!$stmt->fetch()) {
            return $this->error($response, 'Cet utilisateur n\'est pas membre du groupe');
        }

        $stmt = $db->prepare('UPDATE `groups` SET leader_id = ? WHERE id = ?');
        $stmt->execute([$newLeaderId, $args['id']]);

        return $this->json($response, ['success' => true, 'new_leader_id' => $newLeaderId]);
    }

    public function addMember(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $user = $this->requireAuth($request, $response);
            $this->requireFields($input, ['user_id']);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
        }

        $groupId = (int)$args['id'];
        $memberId = (int)$input['user_id'];

        $stmt = $db->prepare('SELECT * FROM `groups` WHERE id = ?');
        $stmt->execute([$groupId]);
        $group = $stmt->fetch();
        if (!$group) return $this->error($response, 'Groupe introuvable', 404);

        if ($user['id'] !== $group['leader_id']) {
            return $this->error($response, 'Seul le chef de file peut ajouter un membre', 403);
        }

        $stmt = $db->prepare('INSERT IGNORE INTO group_members (group_id, user_id) VALUES (?, ?)');
        $stmt->execute([$groupId, $memberId]);

        return $this->json($response, ['success' => true], 201);
    }

    public function removeMember(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $groupId = (int)$args['id'];
        $memberId = (int)$args['userId'];

        $stmt = $db->prepare('SELECT * FROM `groups` WHERE id = ?');
        $stmt->execute([$groupId]);
        $group = $stmt->fetch();
        if (!$group) return $this->error($response, 'Groupe introuvable', 404);

        if ($user['id'] !== $group['leader_id'] && $user['id'] !== $memberId) {
            return $this->error($response, 'Seul le chef de file peut retirer un membre', 403);
        }

        if ($memberId === $group['leader_id']) {
            $stmt = $db->prepare('SELECT user_id FROM group_members WHERE group_id = ? AND user_id != ? LIMIT 1');
            $stmt->execute([$groupId, $memberId]);
            $next = $stmt->fetch();
            if ($next) {
                $db->prepare('UPDATE `groups` SET leader_id = ? WHERE id = ?')->execute([$next['user_id'], $groupId]);
            } else {
                $db->prepare('DELETE FROM `groups` WHERE id = ?')->execute([$groupId]);
                return $this->json($response, ['success' => true, 'group_deleted' => true]);
            }
        }

        $db->prepare('DELETE FROM group_members WHERE group_id = ? AND user_id = ?')->execute([$groupId, $memberId]);

        return $this->json($response, ['success' => true]);
    }

    public function delete(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('SELECT * FROM `groups` WHERE id = ? AND leader_id = ?');
        $stmt->execute([$args['id'], $user['id']]);
        if (!$stmt->fetch()) {
            return $this->error($response, 'Seul le chef peut supprimer le groupe', 403);
        }

        $db->prepare('DELETE FROM `groups` WHERE id = ?')->execute([$args['id']]);

        return $this->json($response, ['success' => true, 'deleted' => true]);
    }
}
