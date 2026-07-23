<?php
/**
 * SimuRH — Licences & Paiements
 * GET  /api/license/status                    → Statut licence
 * POST /api/license/purchase                   → Initier un paiement CinetPay
 * POST /api/license/cinetpay-webhook           → Webhook CinetPay (notification)
 */

$db = get_db();
$method = $_SERVER['REQUEST_METHOD'];

// GET /api/license/status
if ($method === 'GET' && $id === 'status') {
    $user = require_auth();
    
    $stmt = $db->prepare('SELECT * FROM establishments WHERE id = ?');
    $stmt->execute([$user['establishment_id']]);
    $est = $stmt->fetch();
    
    if (!$est) error_response('Établissement introuvable', 404);
    
    // Compter les étudiants et simulations
    $stmt = $db->prepare('SELECT COUNT(*) as cnt FROM users WHERE establishment_id = ? AND role = "student"');
    $stmt->execute([$user['establishment_id']]);
    $student_count = (int)$stmt->fetch()['cnt'];
    
    $stmt = $db->prepare('SELECT COUNT(*) as cnt FROM simulations WHERE establishment_id = ?');
    $stmt->execute([$user['establishment_id']]);
    $sim_count = (int)$stmt->fetch()['cnt'];
    
    // Jours restants
    $days_left = 0;
    if ($est['license_end']) {
        $end = new DateTime($est['license_end']);
        $now = new DateTime();
        $days_left = max(0, (int)$now->diff($end)->days);
    }
    
    json_response([
        'status' => $est['license_status'],
        'days_left' => $days_left,
        'expires_at' => $est['license_end'],
        'student_count' => $student_count,
        'simulation_count' => $sim_count,
        'trial_limits' => [
            'max_students' => LICENSE_TRIAL_STUDENTS,
            'max_simulations' => LICENSE_TRIAL_SIMULATIONS
        ],
        'price' => LICENSE_PRICE
    ]);
}

// POST /api/license/purchase (initie le paiement CinetPay)
elseif ($method === 'POST' && $id === 'purchase') {
    $user = require_auth();
    
    // Créer la transaction
    $stmt = $db->prepare('INSERT INTO payments (establishment_id, amount, payment_method, status) VALUES (?, ?, ?, "pending")');
    $stmt->execute([
        $user['establishment_id'],
        LICENSE_PRICE,
        $_POST['payment_method'] ?? 'orange_money'
    ]);
    $payment_id = $db->lastInsertId();
    
    // TODO: Intégration CinetPay
    // Actuellement, on active manuellement (à remplacer par l'API CinetPay)
    // Voir documentation : https://docs.cinetpay.com
    
    // Simulation : activation directe pour test
    $start = date('Y-m-d');
    $end = date('Y-m-d', strtotime('+' . LICENSE_DURATION_DAYS . ' days'));
    $key = strtoupper(bin2hex(random_bytes(16)));
    
    $stmt = $db->prepare('UPDATE establishments SET license_status = "active", license_key = ?, license_start = ?, license_end = ? WHERE id = ?');
    $stmt->execute([$key, $start, $end, $user['establishment_id']]);
    
    $stmt = $db->prepare('UPDATE payments SET status = "completed" WHERE id = ?');
    $stmt->execute([$payment_id]);
    
    json_response([
        'success' => true,
        'license_key' => $key,
        'valid_until' => $end,
        'message' => 'Licence activée avec succès'
    ]);
}

// POST /api/license/cinetpay-webhook
elseif ($method === 'POST' && $id === 'cinetpay-webhook') {
    // Webhook appelé par CinetPay après un paiement
    $input = json_decode(file_get_contents('php://input'), true) ?: [];
    
    $transaction_id = $input['transaction_id'] ?? '';
    $status = $input['status'] ?? '';
    $payment_id = $input['payment_id'] ?? 0;
    
    if ($status === 'success') {
        $stmt = $db->prepare('SELECT * FROM payments WHERE id = ?');
        $stmt->execute([$payment_id]);
        $payment = $stmt->fetch();
        
        if ($payment) {
            $start = date('Y-m-d');
            $end = date('Y-m-d', strtotime('+' . LICENSE_DURATION_DAYS . ' days'));
            $key = strtoupper(bin2hex(random_bytes(16)));
            
            $stmt = $db->prepare('UPDATE establishments SET license_status = "active", license_key = ?, license_start = ?, license_end = ? WHERE id = ?');
            $stmt->execute([$key, $start, $end, $payment['establishment_id']]);
            
            $stmt = $db->prepare('UPDATE payments SET status = "completed", cinetpay_transaction_id = ? WHERE id = ?');
            $stmt->execute([$transaction_id, $payment_id]);
        }
    }
    
    json_response(['success' => true]);
}

else {
    error_response('Méthode non autorisée', 405);
}
