-- SimuRH — Mise à jour du schéma (v2)
-- Ajout de la table payment_transactions pour CinetPay

CREATE TABLE IF NOT EXISTS payment_transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transaction_id TEXT UNIQUE NOT NULL,
    establishment_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,
    currency TEXT DEFAULT 'XOF',
    phone TEXT,
    status TEXT DEFAULT 'pending',
    payment_data TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (establishment_id) REFERENCES establishments(id)
);

-- Index pour recherche rapide
CREATE INDEX IF NOT EXISTS idx_payment_transaction_id ON payment_transactions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_establishment ON payment_transactions(establishment_id);
