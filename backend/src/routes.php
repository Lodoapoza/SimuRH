<?php

use Slim\Routing\RouteCollectorProxy;
use SimuRH\Controllers\AuthController;
use SimuRH\Controllers\EstablishmentController;
use SimuRH\Controllers\SimulationController;
use SimuRH\Controllers\GroupController;
use SimuRH\Controllers\SubmissionController;
use SimuRH\Controllers\EvaluationController;
use SimuRH\Controllers\FileController;
use SimuRH\Controllers\ResourceController;
use SimuRH\Controllers\PaymentController;
use SimuRH\Controllers\LicenseController;
use SimuRH\Middleware\AuthMiddleware;

return function (Slim\App $app) {
    $app->get('/api/health', function ($request, $response) {
        $payload = ['status' => 'ok', 'version' => '1.0.0', 'timestamp' => date('c')];
        $response->getBody()->write(json_encode($payload));
        return $response->withHeader('Content-Type', 'application/json');
    });

    // Auth (no middleware)
    $app->post('/api/auth/login', [AuthController::class, 'login']);
    $app->post('/api/auth/register', [AuthController::class, 'register']);
    $app->get('/api/auth/me', [AuthController::class, 'me'])->add(AuthMiddleware::class);

    // Payment webhook (no auth — called by CinetPay)
    $app->post('/api/payments/notify', [PaymentController::class, 'notify']);

    // Protected routes
    $app->group('/api', function (RouteCollectorProxy $group) {
        // Establishments
        $group->get('/establishments/status', [EstablishmentController::class, 'status']);
        $group->get('/establishments', [EstablishmentController::class, 'list']);
        $group->get('/establishments/{id}', [EstablishmentController::class, 'get']);
        $group->post('/establishments', [EstablishmentController::class, 'create']);

        // Simulations
        $group->get('/simulations/join/{code}', [SimulationController::class, 'join']);
        $group->get('/simulations', [SimulationController::class, 'list']);
        $group->get('/simulations/{id}', [SimulationController::class, 'get']);
        $group->post('/simulations', [SimulationController::class, 'create']);
        $group->put('/simulations/{id}', [SimulationController::class, 'update']);
        $group->delete('/simulations/{id}', [SimulationController::class, 'delete']);
        $group->post('/simulations/{id}/launch', [SimulationController::class, 'launch']);
        $group->post('/simulations/{id}/files', [SimulationController::class, 'uploadFiles']);
        $group->get('/simulations/{id}/files', [SimulationController::class, 'listFiles']);

        // Groups
        $group->get('/groups', [GroupController::class, 'list']);
        $group->post('/groups/join', [GroupController::class, 'join']);
        $group->post('/groups', [GroupController::class, 'create']);
        $group->put('/groups/{id}', [GroupController::class, 'update']);
        $group->delete('/groups/{id}', [GroupController::class, 'delete']);
        $group->post('/groups/{id}/members', [GroupController::class, 'addMember']);
        $group->delete('/groups/{id}/members/{userId}', [GroupController::class, 'removeMember']);

        // Submissions
        $group->get('/submissions', [SubmissionController::class, 'list']);
        $group->post('/submissions', [SubmissionController::class, 'create']);

        // Evaluations
        $group->get('/evaluations', [EvaluationController::class, 'list']);
        $group->post('/evaluations', [EvaluationController::class, 'create']);
        $group->get('/rankings', [EvaluationController::class, 'rankings']);

        // Files
        $group->post('/files/upload', [FileController::class, 'upload']);
        $group->get('/files/{id}', [FileController::class, 'download']);

        // Resources
        $group->get('/resources', [ResourceController::class, 'list']);
        $group->post('/resources', [ResourceController::class, 'create']);
        $group->delete('/resources/{id}', [ResourceController::class, 'delete']);

        // Payments
        $group->post('/payments', [PaymentController::class, 'create']);
        $group->get('/payments/{id}/status', [PaymentController::class, 'checkStatus']);

        // License
        $group->post('/license/validate', [LicenseController::class, 'validate']);
        $group->get('/license/status', [LicenseController::class, 'status']);
    })->add(AuthMiddleware::class);
};
