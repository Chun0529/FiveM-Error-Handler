CREATE TABLE IF NOT EXISTS `player_businesses` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `business_id` VARCHAR(50) NOT NULL,
    `business_type` VARCHAR(50) NOT NULL,
    `owner_citizenid` VARCHAR(50) DEFAULT NULL,
    `balance` INT NOT NULL DEFAULT 0,
    `purchased_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `business_id` (`business_id`),
    KEY `owner_citizenid` (`owner_citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `business_stock` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `business_id` VARCHAR(50) NOT NULL,
    `item` VARCHAR(50) NOT NULL,
    `quantity` INT NOT NULL DEFAULT 0,
    `price` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `business_item` (`business_id`, `item`),
    KEY `business_id` (`business_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `business_employees` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `business_id` VARCHAR(50) NOT NULL,
    `citizenid` VARCHAR(50) NOT NULL,
    `role` ENUM('employee', 'manager') NOT NULL DEFAULT 'employee',
    `clocked_in` TINYINT(1) NOT NULL DEFAULT 0,
    `hired_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `business_employee` (`business_id`, `citizenid`),
    KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `business_transactions` (
    `id` INT NOT NULL AUTO_INCREMENT,
    `business_id` VARCHAR(50) NOT NULL,
    `type` VARCHAR(30) NOT NULL,
    `amount` INT NOT NULL DEFAULT 0,
    `description` VARCHAR(255) DEFAULT NULL,
    `citizenid` VARCHAR(50) DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `business_id` (`business_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
