<?php

namespace SimuRH;

class Settings
{
    private static array $config = [];
    private static bool $loaded = false;

    public static function load(): void
    {
        if (self::$loaded) return;
        self::$config = [
            'DB_HOST' => $_ENV['DB_HOST'] ?? 'localhost',
            'DB_PORT' => $_ENV['DB_PORT'] ?? '3306',
            'DB_NAME' => $_ENV['DB_NAME'] ?? 'simurh',
            'DB_USER' => $_ENV['DB_USER'] ?? 'root',
            'DB_PASS' => $_ENV['DB_PASS'] ?? '',
            'UPLOADS_PATH' => $_ENV['UPLOADS_PATH'] ?? dirname(__DIR__) . '/uploads',
            'LICENSE_PRICE' => (int)($_ENV['LICENSE_PRICE'] ?? 150000),
            'LICENSE_TRIAL_STUDENTS' => (int)($_ENV['LICENSE_TRIAL_STUDENTS'] ?? 1),
            'LICENSE_TRIAL_SIMULATIONS' => (int)($_ENV['LICENSE_TRIAL_SIMULATIONS'] ?? 1),
            'LICENSE_DURATION_DAYS' => (int)($_ENV['LICENSE_DURATION_DAYS'] ?? 365),
            'CINETPAY_API_KEY' => $_ENV['CINETPAY_API_KEY'] ?? '',
            'CINETPAY_SITE_ID' => $_ENV['CINETPAY_SITE_ID'] ?? '',
            'CINETPAY_SECRET_KEY' => $_ENV['CINETPAY_SECRET_KEY'] ?? '',
            'CINETPAY_SANDBOX' => (bool)($_ENV['CINETPAY_SANDBOX'] ?? true),
        ];
        self::$loaded = true;
    }

    public static function get(string $key): mixed
    {
        self::load();
        return self::$config[$key] ?? null;
    }
}
