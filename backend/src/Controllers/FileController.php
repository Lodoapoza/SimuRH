<?php

namespace SimuRH\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use SimuRH\Database;
use SimuRH\Helpers;
use SimuRH\Settings;

class FileController
{
    use Helpers;

    public function upload(Request $request, Response $response): Response
    {
        return $this->error($response, 'Use POST /api/simulations/{id}/files to upload simulation files', 400);
    }

    public function download(Request $request, Response $response, array $args): Response
    {
        $db = Database::getInstance();

        try {
            $this->requireAuth($request, $response);
        } catch (\RuntimeException $e) {
            return $this->error($response, $e->getMessage(), $e->getCode() ?: 401);
        }

        $stmt = $db->prepare('SELECT * FROM simulation_files WHERE id = ?');
        $stmt->execute([$args['id']]);
        $file = $stmt->fetch();

        if (!$file) {
            $stmt = $db->prepare('SELECT file_path as filename, file_type FROM resources WHERE id = ?');
            $stmt->execute([$args['id']]);
            $file = $stmt->fetch();
            if ($file) {
                $file['original_name'] = basename($file['filename']);
            }
        }

        if (!$file) {
            return $this->error($response, 'Fichier introuvable', 404);
        }

        $filepath = Settings::get('UPLOADS_PATH') . '/' . $file['filename'];
        if (!file_exists($filepath)) {
            return $this->error($response, 'Fichier non trouvé sur le serveur', 404);
        }

        $mime = $file['file_type'] ?: mime_content_type($filepath) ?: 'application/octet-stream';
        $name = $file['original_name'] ?? basename($filepath);

        $fh = fopen($filepath, 'rb');
        $stream = new \Slim\Psr7\Stream($fh);

        return $response
            ->withBody($stream)
            ->withHeader('Content-Type', $mime)
            ->withHeader('Content-Disposition', 'attachment; filename="' . $name . '"')
            ->withHeader('Content-Length', (string)filesize($filepath));
    }
}
