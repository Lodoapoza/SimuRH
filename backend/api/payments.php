<?php
/**
 * SimuRH — Paiement CinetPay
 * 
 * Intégration des paiements mobile (Orange Money, MTN, Moov, etc.)
 * via l'API CinetPay.
 */

// === Configuration CinetPay (sandbox par défaut — à modifier dans config.php) ===
defined('CINETPAY_API_KEY') or define('CINETPAY_API_KEY', 'YOUR_API_KEY_HERE');
defined('CINETPAY_SITE_ID') or define('CINETPAY_SITE_ID', 'YOUR_SITE_ID_HERE');
defined('CINETPAY_SECRET_KEY') or define('CINETPAY_SECRET_KEY', 'YOUR_SECRET_KEY_HERE');
define('CINETPAY_API_URL', 'https://api-checkout.cinetpay.com/v2/payment');

/**
 * Routeur pour /api/payments/
 * Utilise $segments défini par le routeur principal
 */
$action = $segments[1] ?? '';

switch ($action) {
    case 'init':
        handlePaymentInit();
        break;
    case 'notify':
        handlePaymentNotify();
        break;
    case 'status':
        handlePaymentStatus();
        break;
    default:
        error_response('Action paiement inconnue', 404);
}

/**
 * Étape 1 : Initialiser un paiement
 * POST /api/payments/init
 * Body : { establishment_id, phone }
 */
function handlePaymentInit() {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        error_response('Méthode non autorisée', 405);
    }

    $input = json_decode(file_get_contents('php://input'), true);
    $establishmentId = $input['establishment_id'] ?? '';
    $phone = $input['phone'] ?? '';

    if (!$establishmentId || !$phone) {
        error_response('establishment_id et phone requis', 400);
    }

    try {
        global $pdo;

        // Vérifier que l'établissement existe
        $stmt = $pdo->prepare("SELECT id, name FROM establishments WHERE id = ?");
        $stmt->execute([$establishmentId]);
        $establishment = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$establishment) {
            error_response('Établissement introuvable', 404);
        }

        // Vérifier qu'il n'y a pas déjà une licence active
        $stmt = $pdo->prepare("SELECT id, status FROM licenses WHERE establishment_id = ? AND status = 'active'");
        $stmt->execute([$establishmentId]);
        if ($stmt->fetch()) {
            json_response(['status' => 'already_active', 'message' => 'Cet établissement a déjà une licence active']);
            return;
        }

        // Créer la transaction
        $transactionId = 'SIMURH_' . date('YmdHis') . '_' . substr(bin2hex(random_bytes(3)), 0, 6);
        $amount = LICENSE_PRICE;
        $currency = 'XOF';

        $stmt = $pdo->prepare("
            INSERT INTO payment_transactions (transaction_id, establishment_id, amount, currency, phone, status, created_at)
            VALUES (?, ?, ?, ?, ?, 'pending', NOW())
        ");
        $stmt->execute([$transactionId, $establishmentId, $amount, $currency, $phone]);

        // Appeler l'API CinetPay pour obtenir l'URL de paiement
        $paymentUrl = callCinetPayApi($transactionId, $amount, $currency, $phone, $establishment['name']);

        json_response([
            'success' => true,
            'transaction_id' => $transactionId,
            'payment_url' => $paymentUrl,
            'amount' => $amount,
            'currency' => $currency,
        ]);

    } catch (Exception $e) {
        error_response('Erreur paiement : ' . $e->getMessage(), 500);
    }
}

/**
 * Appelle l'API CinetPay pour générer un lien de paiement
 */
function callCinetPayApi($transactionId, $amount, $currency, $phone, $establishmentName) {
    $baseUrl = getApiBaseUrl();
    $notifyUrl = $baseUrl . '/payments/notify';
    $returnUrl = $baseUrl . '/payments/status/' . $transactionId;

    $postData = [
        'apikey' => CINETPAY_API_KEY,
        'site_id' => CINETPAY_SITE_ID,
        'transaction_id' => $transactionId,
        'amount' => $amount,
        'currency' => $currency,
        'description' => 'Licence SimuRH - ' . $establishmentName . ' (1 an)',
        'notify_url' => $notifyUrl,
        'return_url' => $returnUrl,
        'channels' => 'ALL',
        'customer_phone_number' => $phone,
        'customer_name' => $establishmentName,
        'lang' => 'fr',
    ];

    $ch = curl_init(CINETPAY_API_URL);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($postData),
        CURLOPT_HTTPHEADER => ['Content-Type: application/json', 'Accept: application/json'],
        CURLOPT_TIMEOUT => 30,
    ]);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);

    if ($error) {
        throw new Exception('Erreur réseau CinetPay : ' . $error);
    }

    $result = json_decode($response, true);

    if ($httpCode === 201 && isset($result['data']['payment_url'])) {
        return $result['data']['payment_url'];
    } elseif (isset($result['message'])) {
        throw new Exception($result['message']);
    } else {
        throw new Exception('Réponse CinetPay invalide (HTTP ' . $httpCode . ')');
    }
}

/**
 * Étape 2 : Webhook de notification CinetPay
 * POST /api/payments/notify
 */
function handlePaymentNotify() {
    if (!isset($_POST['cpm_trans_id'])) {
        http_response_code(400);
        echo "cpm_trans_id non fourni";
        return;
    }

    try {
        // Vérifier HMAC
        $dataPost = implode('', $_POST);
        $generatedToken = hash_hmac('SHA256', $dataPost, CINETPAY_SECRET_KEY);
        $receivedToken = $_SERVER['HTTP_X_TOKEN'] ?? '';

        if (!hash_equals($receivedToken, $generatedToken)) {
            http_response_code(403);
            echo "HMAC non conforme";
            return;
        }

        $transactionId = $_POST['cpm_trans_id'];

        // Vérifier le statut chez CinetPay
        $ch = curl_init();
        curl_setopt_array($ch, [
            CURLOPT_URL => 'https://api-checkout.cinetpay.com/v2/payment/check',
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode([
                'transaction_id' => $transactionId,
                'site_id' => CINETPAY_SITE_ID,
                'apikey' => CINETPAY_API_KEY
            ]),
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
            CURLOPT_TIMEOUT => 30,
        ]);
        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode !== 200) {
            http_response_code(502);
            echo "Erreur vérification CinetPay";
            return;
        }

        $paymentStatus = json_decode($response, true);
        global $pdo;

        $isAccepted = ($paymentStatus['code'] === '00')
            || (isset($paymentStatus['data']['status']) && $paymentStatus['data']['status'] === 'ACCEPTED');

        if ($isAccepted) {
            $stmt = $pdo->prepare("
                SELECT id, establishment_id, amount
                FROM payment_transactions
                WHERE transaction_id = ? AND status = 'pending'
            ");
            $stmt->execute([$transactionId]);
            $transaction = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($transaction) {
                $stmt = $pdo->prepare("
                    UPDATE payment_transactions
                    SET status = 'completed', payment_data = ?, updated_at = NOW()
                    WHERE id = ?
                ");
                $stmt->execute([json_encode($paymentStatus), $transaction['id']]);

                $stmt = $pdo->prepare("
                    INSERT INTO licenses (establishment_id, status, purchase_date, expiry_date, amount_paid, created_at, updated_at)
                    VALUES (?, 'active', NOW(), DATE_ADD(NOW(), INTERVAL 1 YEAR), ?, NOW(), NOW())
                    ON DUPLICATE KEY UPDATE
                        status = 'active',
                        purchase_date = NOW(),
                        expiry_date = DATE_ADD(NOW(), INTERVAL 1 YEAR),
                        amount_paid = VALUES(amount_paid),
                        updated_at = NOW()
                ");
                $stmt->execute([$transaction['establishment_id'], $transaction['amount']]);
            }
        } else {
            $stmt = $pdo->prepare("
                UPDATE payment_transactions
                SET status = 'failed', payment_data = ?, updated_at = NOW()
                WHERE transaction_id = ? AND status = 'pending'
            ");
            $stmt->execute([json_encode($paymentStatus), $transactionId]);
        }

        echo "OK";

    } catch (Exception $e) {
        http_response_code(500);
        echo "Erreur : " . $e->getMessage();
    }
}

/**
 * Étape 3 : Vérifier le statut d'un paiement
 * GET /api/payments/status/{transaction_id}
 */
function handlePaymentStatus() {
    global $id;
    $transactionId = $id ?? ($_GET['transaction_id'] ?? '');

    if (!$transactionId) {
        error_response('transaction_id requis', 400);
    }

    try {
        global $pdo;
        $stmt = $pdo->prepare("
            SELECT pt.transaction_id, pt.status, pt.amount, pt.currency, pt.created_at,
                   l.status as license_status, l.expiry_date
            FROM payment_transactions pt
            LEFT JOIN licenses l ON l.establishment_id = pt.establishment_id
            WHERE pt.transaction_id = ?
        ");
        $stmt->execute([$transactionId]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$result) {
            error_response('Transaction introuvable', 404);
        }

        json_response([
            'transaction_id' => $result['transaction_id'],
            'payment_status' => $result['status'],
            'amount' => (int)$result['amount'],
            'currency' => $result['currency'],
            'created_at' => $result['created_at'],
            'license_status' => $result['license_status'],
            'expiry_date' => $result['expiry_date'],
        ]);

    } catch (Exception $e) {
        error_response('Erreur : ' . $e->getMessage(), 500);
    }
}

/**
 * Retourne l'URL de base de l'API
 */
function getApiBaseUrl() {
    $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    return $protocol . '://' . ($_SERVER['HTTP_HOST'] ?? 'cloud.glocal-innov.com') . '/simurh/api';
}
