<?php

namespace SimuRH;

use Psr\Http\Message\ResponseInterface as Response;

trait Helpers
{
    protected function json(Response $response, mixed $data, int $code = 200): Response
    {
        $response->getBody()->write(json_encode($data, JSON_UNESCAPED_UNICODE));
        return $response->withHeader('Content-Type', 'application/json')->withStatus($code);
    }

    protected function error(Response $response, string $message, int $code = 400): Response
    {
        return $this->json($response, ['error' => $message], $code);
    }

    protected function requireFields(array $data, array $fields): void
    {
        foreach ($fields as $field) {
            if (!isset($data[$field]) || (is_string($data[$field]) && trim($data[$field]) === '')) {
                throw new \RuntimeException("Le champ '{$field}' est requis");
            }
        }
    }

    protected function cleanInput(string $data): string
    {
        return htmlspecialchars(strip_tags(trim($data)), ENT_QUOTES, 'UTF-8');
    }

    protected function generateToken(): string
    {
        return bin2hex(random_bytes(32));
    }

    protected function generateSimulationCode(): string
    {
        $year = date('Y');
        $letters = substr(str_shuffle('ABCDEFGHJKLMNPQRSTUVWXYZ'), 0, 3);
        $nums = str_pad((string)random_int(1, 999), 3, '0', STR_PAD_LEFT);
        return "RH-{$year}-{$letters}{$nums}";
    }

    protected function handleUpload(array $file, string $subdir = 'general'): string
    {
        $uploadDir = Settings::get('UPLOADS_PATH') . '/' . $subdir;
        if (!is_dir($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
        $safeName = bin2hex(random_bytes(16)) . '.' . $ext;
        $dest = $uploadDir . '/' . $safeName;

        if (!move_uploaded_file($file['tmp_name'], $dest)) {
            throw new \RuntimeException("Erreur lors de l'upload du fichier", 500);
        }

        return $subdir . '/' . $safeName;
    }

    protected function getAuthUser(\Psr\Http\Message\ServerRequestInterface $request): ?array
    {
        return $request->getAttribute('user');
    }

    protected function requireAuth(\Psr\Http\Message\ServerRequestInterface $request, Response $response, ?string $role = null): ?array
    {
        $user = $this->getAuthUser($request);
        if (!$user) {
            throw new \RuntimeException('Non authentifié', 401);
        }
        if ($role && $user['role'] !== $role) {
            throw new \RuntimeException("Accès refusé : rôle {$role} requis", 403);
        }
        return $user;
    }
}
