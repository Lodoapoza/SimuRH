<?php

namespace SimuRH;

class Database
{
    private static ?\PDO $instance = null;

    public static function getInstance(): \PDO
    {
        if (self::$instance === null) {
            $host = Settings::get('DB_HOST');
            $port = Settings::get('DB_PORT');
            $name = Settings::get('DB_NAME');
            $user = Settings::get('DB_USER');
            $pass = Settings::get('DB_PASS');

            $dsn = "mysql:host={$host};port={$port};dbname={$name};charset=utf8mb4";
            self::$instance = new \PDO($dsn, $user, $pass, [
                \PDO::ATTR_ERRMODE => \PDO::ERRMODE_EXCEPTION,
                \PDO::ATTR_DEFAULT_FETCH_MODE => \PDO::FETCH_ASSOC,
                \PDO::ATTR_EMULATE_PREPARES => false,
            ]);
        }
        return self::$instance;
    }
}
