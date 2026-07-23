<?php
/**
 * SimuRH — Configuration
 */

error_reporting(E_ALL);
ini_set('display_errors', 0);
ini_set('log_errors', 1);

// Chemins
define('BASE_PATH', __DIR__);
define('DB_PATH', BASE_PATH . '/db/simurh.db');
define('UPLOADS_PATH', BASE_PATH . '/uploads');
define('ALLOWED_ORIGINS', '*');

// Licence (prix en FCFA)
define('LICENSE_PRICE', 150000);        // 150 000 FCFA/an
define('LICENSE_TRIAL_STUDENTS', 1);    // 1 étudiant max en essai
define('LICENSE_TRIAL_SIMULATIONS', 1); // 1 simulation max en essai
define('LICENSE_DURATION_DAYS', 365);

// CinetPay (sandbox par défaut)
define('CINETPAY_API_KEY', '');
define('CINETPAY_SITE_ID', '');
define('CINETPAY_SANDBOX', true);

// Headers CORS
header('Access-Control-Allow-Origin: ' . ALLOWED_ORIGINS);
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

/**
 * Retourne une réponse JSON
 */
function json_response($data, int $code = 200): void {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit;
}

function error_response(string $message, int $code = 400): void {
    json_response(['error' => $message], $code);
}

/**
 * Connexion SQLite (singleton)
 */
function get_db(): PDO {
    static $db = null;
    if ($db === null) {
        $dir = dirname(DB_PATH);
        if (!is_dir($dir)) mkdir($dir, 0755, true);
        
        $db = new PDO('sqlite:' . DB_PATH);
        $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
        $db->exec('PRAGMA journal_mode=WAL');
        $db->exec('PRAGMA foreign_keys=ON');
    }
    return $db;
}

/**
 * Récupère l'utilisateur connecté via le token
 */
function get_auth_user(): ?array {
    $token = null;
    
    $headers = getallheaders();
    $auth = $headers['Authorization'] ?? $headers['authorization'] ?? '';
    
    if (str_starts_with($auth, 'Bearer ')) {
        $token = substr($auth, 7);
    }
    
    if (!$token) {
        // Fallback: GET/POST param
        $token = $_REQUEST['token'] ?? null;
    }
    
    if (!$token) return null;
    
    $db = get_db();
    $stmt = $db->prepare('SELECT * FROM users WHERE api_token = ?');
    $stmt->execute([$token]);
    return $stmt->fetch() ?: null;
}

/**
 * Vérifie que l'utilisateur est connecté et a le bon rôle
 */
function require_auth(string $role = null): array {
    $user = get_auth_user();
    if (!$user) {
        error_response('Non authentifié', 401);
    }
    if ($role && $user['role'] !== $role) {
        error_response('Accès refusé : rôle ' . $role . ' requis', 403);
    }
    return $user;
}

/**
 * Génère un token aléatoire
 */
function generate_token(): string {
    return bin2hex(random_bytes(32));
}

/**
 * Génère un code unique pour une simulation
 */
function generate_simulation_code(): string {
    $year = date('Y');
    $letters = substr(str_shuffle('ABCDEFGHJKLMNPQRSTUVWXYZ'), 0, 3);
    $nums = str_pad((string)random_int(1, 999), 3, '0', STR_PAD_LEFT);
    return "RH-{$year}-{$letters}{$nums}";
}

/**
 * Nettoie une entrée utilisateur
 */
function clean_input(string $data): string {
    return htmlspecialchars(strip_tags(trim($data)), ENT_QUOTES, 'UTF-8');
}

/**
 * Valide les champs requis
 */
function require_fields(array $data, array $fields): void {
    foreach ($fields as $field) {
        if (!isset($data[$field]) || (is_string($data[$field]) && trim($data[$field]) === '')) {
            error_response("Le champ '{$field}' est requis");
        }
    }
}

/**
 * Upload de fichier
 */
function handle_upload(array $file, string $subdir = 'general'): string {
    $upload_dir = UPLOADS_PATH . '/' . $subdir;
    if (!is_dir($upload_dir)) mkdir($upload_dir, 0755, true);
    
    $ext = pathinfo($file['name'], PATHINFO_EXTENSION);
    $safe_name = bin2hex(random_bytes(16)) . '.' . $ext;
    $dest = $upload_dir . '/' . $safe_name;
    
    if (!move_uploaded_file($file['tmp_name'], $dest)) {
        error_response("Erreur lors de l'upload du fichier", 500);
    }
    
    return $subdir . '/' . $safe_name;
}
