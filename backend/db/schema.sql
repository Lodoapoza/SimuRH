-- SimuRH — Schéma de la base MySQL

CREATE TABLE IF NOT EXISTS establishments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    city VARCHAR(255) DEFAULT '',
    country VARCHAR(255) DEFAULT 'Mali',
    license_status ENUM('trial','active','expired') DEFAULT 'trial',
    license_key VARCHAR(255),
    license_start DATE,
    license_end DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    establishment_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('professor','student') NOT NULL,
    api_token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (establishment_id) REFERENCES establishments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS simulations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    professor_id INT NOT NULL,
    establishment_id INT NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    context TEXT NOT NULL,
    objectives JSON DEFAULT NULL,
    duration_days INT DEFAULT 14,
    max_groups INT DEFAULT 10,
    grading_criteria JSON DEFAULT NULL,
    status ENUM('draft','active','closed') DEFAULT 'draft',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (professor_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (establishment_id) REFERENCES establishments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS simulation_files (
    id INT AUTO_INCREMENT PRIMARY KEY,
    simulation_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    original_name VARCHAR(255) NOT NULL,
    file_type VARCHAR(50) DEFAULT '',
    file_size INT DEFAULT 0,
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `groups` (
    id INT AUTO_INCREMENT PRIMARY KEY,
    simulation_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    leader_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE,
    FOREIGN KEY (leader_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS group_members (
    group_id INT NOT NULL,
    user_id INT NOT NULL,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (group_id, user_id),
    FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS submissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    group_id INT NOT NULL,
    simulation_id INT NOT NULL,
    content TEXT DEFAULT '',
    file_path VARCHAR(255),
    submitted_at TIMESTAMP NULL,
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (group_id) REFERENCES `groups`(id) ON DELETE CASCADE,
    FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS evaluations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    submission_id INT NOT NULL,
    professor_id INT NOT NULL,
    scores JSON DEFAULT NULL,
    total_score DECIMAL(5,2) DEFAULT 0,
    comments TEXT DEFAULT '',
    evaluated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (submission_id) REFERENCES submissions(id) ON DELETE CASCADE,
    FOREIGN KEY (professor_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS resources (
    id INT AUTO_INCREMENT PRIMARY KEY,
    professor_id INT NOT NULL,
    establishment_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    file_path VARCHAR(255) NOT NULL,
    file_type VARCHAR(50) DEFAULT '',
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (professor_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (establishment_id) REFERENCES establishments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    establishment_id INT NOT NULL,
    amount INT NOT NULL,
    payment_method VARCHAR(50) DEFAULT '',
    cinetpay_transaction_id VARCHAR(255),
    status ENUM('pending','completed','failed') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (establishment_id) REFERENCES establishments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
