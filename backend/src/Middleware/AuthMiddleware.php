<?php

namespace SimuRH\Middleware;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Server\MiddlewareInterface;
use Psr\Http\Server\RequestHandlerInterface as RequestHandler;
use SimuRH\Database;

class AuthMiddleware implements MiddlewareInterface
{
    public function process(Request $request, RequestHandler $handler): Response
    {
        $authHeader = $request->getHeaderLine('Authorization');
        $token = '';

        if (str_starts_with($authHeader, 'Bearer ')) {
            $token = substr($authHeader, 7);
        }

        if ($token) {
            $db = Database::getInstance();
            $stmt = $db->prepare('SELECT * FROM users WHERE api_token = ?');
            $stmt->execute([$token]);
            $user = $stmt->fetch();

            if ($user) {
                $request = $request->withAttribute('user', $user);
            }
        }

        return $handler->handle($request);
    }
}
