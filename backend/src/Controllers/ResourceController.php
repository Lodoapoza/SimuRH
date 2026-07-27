<?php

namespace SimuRH\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use SimuRH\Database;
use SimuRH\Helpers;

class ResourceController
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
        $estId = (int)($params['establishment'] ?? $user['establishment_id']);

        $stmt = $db->prepare('
            SELECT r.*, u.name as professor_name
            FROM resources r
            JOIN users u ON r.professor_id = u.id
            WHERE r.establishment_id = ?
            ORDER BY r.uploaded_at DESC
        ');
        $stmt->execute([$estId]);

        return $this->json($response, $stmt->fetchAll());
    }

    public function create(Request $request, Response $response): Response
    {
        $db = Database::getInstance();
        $input = $request->getParsedBody() ?: [];

        try {
            $user = $this->requireAuth($request, $response, 'professor');
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        if (!empty($_FILES['file'])) {
            try {
                $this->requireFields($input, ['title']);
            } catch (\RuntimeException $e) {
                return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
            }

            try {
                $path = $this->handleUpload($_FILES['file'], 'resources/' . $user['establishment_id']);
            } catch (\RuntimeException $e) {
                return $this->error($response, $e->getMessage(), $e->getCode() ?: 500);
            }
            $fileType = $_FILES['file']['type'];

            $stmt = $db->prepare('INSERT INTO resources (professor_id, establishment_id, title, description, file_path, file_type) VALUES (?, ?, ?, ?, ?, ?)');
            $stmt->execute([
                $user['id'],
                $user['establishment_id'],
                $this->cleanInput($input['title']),
                $this->cleanInput($input['description'] ?? ''),
                $path,
                $fileType,
            ]);

            return $this->json($response, [
                'id' => (int)$db->lastInsertId(),
                'title' => $this->cleanInput($input['title']),
            ], 201);
        } else {
            try {
                $this->requireFields($input, ['title', 'file_path']);
            } catch (\RuntimeException $e) {
                return $this->error($response, $e->getMessage(), $e->getCode() ?: 400);
            }

            $stmt = $db->prepare('INSERT INTO resources (professor_id, establishment_id, title, description, file_path, file_type) VALUES (?, ?, ?, ?, ?, ?)');
            $stmt->execute([
                $user['id'],
                $user['establishment_id'],
                $this->cleanInput($input['title']),
                $this->cleanInput($input['description'] ?? ''),
                $input['file_path'],
                $input['file_type'] ?? '',
            ]);

            return $this->json($response, ['id' => (int)$db->lastInsertId()], 201);
        }
    }

    public function delete(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();

        try {
            $user = $this->requireAuth($request, $response, 'professor');
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('SELECT * FROM resources WHERE id = ? AND professor_id = ?');
        $stmt->execute([$args['id'], $user['id']]);
        if (!$stmt->fetch()) {
            return $this->error($response, 'Ressource introuvable ou accès refusé', 404);
        }

        $db->prepare('DELETE FROM resources WHERE id = ?')->execute([$args['id']]);

        return $this->json($response, ['success' => true, 'deleted' => true]);
    }
}
