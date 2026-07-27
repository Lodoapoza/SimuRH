<?php

namespace SimuRH\Controllers;

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use SimuRH\Database;
use SimuRH\Helpers;
use SimuRH\Settings;

class PaymentController
{
    use Helpers;

    private const CINETPAY_API_URL = 'https://api-checkout.cinetpay.com/v2/payment';

    public function create(Request $request, Response $response): Response
    {
        $input = $request->getParsedBody() ?: [];
        $establishmentId = $input['establishment_id'] ?? '';
        $phone = $input['phone'] ?? '';

        if (!$establishmentId || !$phone) {
            return $this->error($response, 'establishment_id et phone requis', 400);
        }

        try {
            $db = Database::getInstance();

            $stmt = $db->prepare('SELECT id, name FROM establishments WHERE id = ?');
            $stmt->execute([$establishmentId]);
            $establishment = $stmt->fetch();

            if (!$establishment) {
                return $this->error($response, 'Établissement introuvable', 404);
            }

            $transactionId = 'SIMURH_' . date('YmdHis') . '_' . substr(bin2hex(random_bytes(3)), 0, 6);
            $amount = Settings::get('LICENSE_PRICE');
            $currency = 'XOF';

            $stmt = $db->prepare('INSERT INTO payments (establishment_id, amount, cinetpay_transaction_id, status) VALUES (?, ?, ?, ?)');
            $stmt->execute([$establishmentId, $amount, $transactionId, 'pending']);

            $paymentUrl = $this->callCinetPayApi($transactionId, $amount, $currency, $phone, $establishment['name']);

            return $this->json($response, [
                'success' => true,
                'transaction_id' => $transactionId,
                'payment_url' => $paymentUrl,
                'amount' => $amount,
                'currency' => $currency,
            ]);
        } catch (\RuntimeException $e) {
            return $this->error($response, 'Erreur paiement : ' . $e->getMessage(), 500);
        }
    }

    private function callCinetPayApi(string $transactionId, int $amount, string $currency, string $phone, string $establishmentName): string
    {
        $baseUrl = $this->getApiBaseUrl();
        $notifyUrl = $baseUrl . '/payments/notify';
        $returnUrl = $baseUrl . '/payments/status/' . $transactionId;

        $postData = [
            'apikey' => Settings::get('CINETPAY_API_KEY'),
            'site_id' => Settings::get('CINETPAY_SITE_ID'),
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

        $ch = curl_init(self::CINETPAY_API_URL);
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
            throw new \RuntimeException('Erreur réseau CinetPay : ' . $error);
        }

        $result = json_decode($response, true);

        if ($httpCode === 201 && isset($result['data']['payment_url'])) {
            return $result['data']['payment_url'];
        } elseif (isset($result['message'])) {
            throw new \RuntimeException($result['message']);
        } else {
            throw new \RuntimeException('Réponse CinetPay invalide (HTTP ' . $httpCode . ')');
        }
    }

    public function notify(Request $request, Response $response): Response
    {
        $body = $request->getParsedBody();
        $transactionId = $body['cpm_trans_id'] ?? ($_POST['cpm_trans_id'] ?? '');

        if (!$transactionId) {
            $response->getBody()->write('cpm_trans_id non fourni');
            return $response->withStatus(400);
        }

        try {
            $dataPost = implode('', $body ?? $_POST);
            $generatedToken = hash_hmac('SHA256', $dataPost, Settings::get('CINETPAY_SECRET_KEY'));
            $receivedToken = $request->getHeaderLine('X-Token') ?: ($_SERVER['HTTP_X_TOKEN'] ?? '');

            if (!hash_equals($receivedToken, $generatedToken)) {
                $response->getBody()->write('HMAC non conforme');
                return $response->withStatus(403);
            }

            $ch = curl_init();
            curl_setopt_array($ch, [
                CURLOPT_URL => 'https://api-checkout.cinetpay.com/v2/payment/check',
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_POST => true,
                CURLOPT_POSTFIELDS => json_encode([
                    'transaction_id' => $transactionId,
                    'site_id' => Settings::get('CINETPAY_SITE_ID'),
                    'apikey' => Settings::get('CINETPAY_API_KEY'),
                ]),
                CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
                CURLOPT_TIMEOUT => 30,
            ]);
            $apiResponse = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode !== 200) {
                $response->getBody()->write('Erreur vérification CinetPay');
                return $response->withStatus(502);
            }

            $paymentStatus = json_decode($apiResponse, true);
            $db = Database::getInstance();

            $isAccepted = ($paymentStatus['code'] === '00')
                || (isset($paymentStatus['data']['status']) && $paymentStatus['data']['status'] === 'ACCEPTED');

            if ($isAccepted) {
                $stmt = $db->prepare("SELECT id, establishment_id, amount FROM payments WHERE cinetpay_transaction_id = ? AND status = 'pending'");
                $stmt->execute([$transactionId]);
                $payment = $stmt->fetch();

                if ($payment) {
                    $stmt = $db->prepare('UPDATE payments SET status = ? WHERE id = ?');
                    $stmt->execute(['completed', $payment['id']]);

                    $start = date('Y-m-d');
                    $end = date('Y-m-d', strtotime('+' . Settings::get('LICENSE_DURATION_DAYS') . ' days'));
                    $key = strtoupper(bin2hex(random_bytes(16)));

                    $stmt = $db->prepare('UPDATE establishments SET license_status = ?, license_key = ?, license_start = ?, license_end = ? WHERE id = ?');
                    $stmt->execute(['active', $key, $start, $end, $payment['establishment_id']]);
                }
            } else {
                $stmt = $db->prepare("UPDATE payments SET status = ? WHERE cinetpay_transaction_id = ? AND status = 'pending'");
                $stmt->execute(['failed', $transactionId]);
            }

            $response->getBody()->write('OK');
            return $response;
        } catch (\Exception $e) {
            $response->getBody()->write('Erreur : ' . $e->getMessage());
            return $response->withStatus(500);
        }
    }

    public function checkStatus(Request $request, Response $response, array $args): Response
    {
        $transactionId = $args['id'] ?? '';

        if (!$transactionId) {
            return $this->error($response, 'transaction_id requis', 400);
        }

        try {
            $db = Database::getInstance();
            $stmt = $db->prepare('
                SELECT p.id as payment_id, p.cinetpay_transaction_id as transaction_id, p.status as payment_status,
                       p.amount, p.created_at,
                       e.license_status, e.license_end as expiry_date
                FROM payments p
                JOIN establishments e ON p.establishment_id = e.id
                WHERE p.cinetpay_transaction_id = ?
            ');
            $stmt->execute([$transactionId]);
            $result = $stmt->fetch();

            if (!$result) {
                return $this->error($response, 'Transaction introuvable', 404);
            }

            return $this->json($response, [
                'transaction_id' => $result['transaction_id'],
                'payment_status' => $result['payment_status'],
                'amount' => (int)$result['amount'],
                'created_at' => $result['created_at'],
                'license_status' => $result['license_status'],
                'expiry_date' => $result['expiry_date'],
            ]);
        } catch (\Exception $e) {
            return $this->error($response, 'Erreur : ' . $e->getMessage(), 500);
        }
    }

    private function getApiBaseUrl(): string
    {
        $protocol = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
        return $protocol . '://' . ($_SERVER['HTTP_HOST'] ?? 'cloud.glocal-innov.com') . '/simurh/api';
    }
}
