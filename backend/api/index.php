<?php
/**
 * SimuRH — Routeur API
 * 
 * Toutes les requêtes passent par ici.
 * Dispache vers le bon gestionnaire selon l'URL.
 */

require_once __DIR__ . '/../config.php';

$request = $_SERVER['REQUEST_URI'];
$method  = $_SERVER['REQUEST_METHOD'];

// Nettoyer l'URI (enlever le préfixe /api/ et les query strings)
$path = parse_url($request, PHP_URL_PATH);
$path = preg_replace('#^.*/api/#', '', $path);
$path = trim($path, '/');
$segments = $path ? explode('/', $path) : [];

// Premier segment = ressource
$resource = $segments[0] ?? '';
$id       = $segments[1] ?? null;
$action   = $segments[2] ?? null;

// Router
switch ($resource) {
    case 'auth':
        require __DIR__ . '/auth.php';
        break;
    case 'establishments':
        require __DIR__ . '/establishments.php';
        break;
    case 'simulations':
        require __DIR__ . '/simulations.php';
        break;
    case 'groups':
        require __DIR__ . '/groups.php';
        break;
    case 'submissions':
        require __DIR__ . '/submissions.php';
        break;
    case 'evaluations':
        require __DIR__ . '/evaluations.php';
        break;
    case 'resources':
        require __DIR__ . '/resources.php';
        break;
    case 'license':
        require __DIR__ . '/license.php';
        break;
    case 'files':
        require __DIR__ . '/files.php';
        break;
    case 'payments':
        require __DIR__ . '/payments.php';
        break;
    case 'health':
        json_response(['status' => 'ok', 'time' => date('c')]);
        break;
    default:
        error_response('Endpoint non trouvé', 404);
}
