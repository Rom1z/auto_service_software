-- ============================================
-- База данных для автосервиса
-- Пароли хранятся в открытом виде для простоты
-- ============================================

-- Создание базы данных
CREATE DATABASE IF NOT EXISTS autoservice 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

USE autoservice;

-- Пользователи системы (пароль хранится открыто)
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,          -- пароль открытым текстом
    full_name VARCHAR(100),
    role ENUM('admin','manager','mechanic','accountant') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Клиенты
CREATE TABLE IF NOT EXISTS clients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type ENUM('individual','legal') NOT NULL,
    full_name_or_company VARCHAR(200) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT,
    inn VARCHAR(12) NULL,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Автомобили
CREATE TABLE IF NOT EXISTS vehicles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    plate_number VARCHAR(20),
    vin VARCHAR(17),
    brand VARCHAR(50),
    model VARCHAR(50),
    year INT,
    mileage INT,
    engine_type VARCHAR(30),
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Сотрудники
CREATE TABLE IF NOT EXISTS employees (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NULL,
    full_name VARCHAR(100) NOT NULL,
    position VARCHAR(50),
    phone VARCHAR(20),
    hire_date DATE,
    hourly_rate DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Каталог услуг
CREATE TABLE IF NOT EXISTS services_catalog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    standard_hours DECIMAL(5,2) NOT NULL DEFAULT 1.00,
    price_per_hour DECIMAL(10,2) NOT NULL DEFAULT 0,
    category VARCHAR(50)
) ENGINE=InnoDB;

-- Каталог запчастей
CREATE TABLE IF NOT EXISTS parts_catalog (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    article VARCHAR(50),
    manufacturer VARCHAR(100),
    unit VARCHAR(20) DEFAULT 'шт.',
    purchase_price DECIMAL(10,2) DEFAULT 0,
    retail_price DECIMAL(10,2) NOT NULL DEFAULT 0,
    stock_quantity INT DEFAULT 0,
    min_stock INT DEFAULT 0
) ENGINE=InnoDB;

-- Поставщики
CREATE TABLE IF NOT EXISTS suppliers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    contact_info TEXT
) ENGINE=InnoDB;

-- Приходные накладные
CREATE TABLE IF NOT EXISTS purchase_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    supplier_id INT,
    order_date DATE NOT NULL,
    total_cost DECIMAL(12,2) DEFAULT 0,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Позиции приходных накладных
CREATE TABLE IF NOT EXISTS purchase_order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    purchase_order_id INT NOT NULL,
    part_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_cost DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (part_id) REFERENCES parts_catalog(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Заказ-наряды
CREATE TABLE IF NOT EXISTS repair_orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    description TEXT,
    mechanic_id INT,
    status ENUM('new','in_progress','completed','closed','cancelled') DEFAULT 'new',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    started_at DATETIME,
    completed_at DATETIME,
    total_labor DECIMAL(10,2) DEFAULT 0,
    total_parts DECIMAL(10,2) DEFAULT 0,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    final_total DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (client_id) REFERENCES clients(id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(id),
    FOREIGN KEY (mechanic_id) REFERENCES employees(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Услуги в заказ-наряде
CREATE TABLE IF NOT EXISTS order_services (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    service_id INT,
    custom_name VARCHAR(200),
    hours DECIMAL(5,2) NOT NULL,
    rate DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) GENERATED ALWAYS AS (hours * rate) STORED,
    FOREIGN KEY (order_id) REFERENCES repair_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES services_catalog(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- Запчасти в заказ-наряде
CREATE TABLE IF NOT EXISTS order_parts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    part_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total DECIMAL(10,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
    FOREIGN KEY (order_id) REFERENCES repair_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (part_id) REFERENCES parts_catalog(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Счета
CREATE TABLE IF NOT EXISTS invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    client_id INT NOT NULL,
    invoice_number VARCHAR(30) UNIQUE,
    issue_date DATE NOT NULL,
    due_date DATE,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('unpaid','partially_paid','paid','cancelled') DEFAULT 'unpaid',
    FOREIGN KEY (order_id) REFERENCES repair_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients(id)
) ENGINE=InnoDB;

-- Оплаты
CREATE TABLE IF NOT EXISTS payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    method ENUM('cash','card','transfer') DEFAULT 'cash',
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Журнал аудита
CREATE TABLE IF NOT EXISTS audit_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(50),
    table_name VARCHAR(50),
    record_id INT,
    old_data TEXT,
    new_data TEXT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================
-- Начальные данные
-- ============================================

-- Тестовые пользователи (пароли открытым текстом)
INSERT INTO users (username, password, full_name, role, is_active) VALUES
('admin', 'admin', 'Администратор Системы', 'admin', TRUE),
('manager', 'manager', 'Петров Петр Петрович', 'manager', TRUE),
('mechanic', 'mechanic', 'Иванов Иван Иванович', 'mechanic', TRUE),
('accountant', 'accountant', 'Сидорова Анна Сергеевна', 'accountant', TRUE);

-- Тестовый механик (сотрудник)
INSERT INTO employees (full_name, position, phone, hire_date, hourly_rate) VALUES
('Иванов Иван Иванович', 'механик', '+7-999-123-45-67', '2023-01-15', 500);

-- Тестовые услуги
INSERT INTO services_catalog (name, description, standard_hours, price_per_hour, category) VALUES
('Замена масла ДВС', 'Замена моторного масла и масляного фильтра', 0.5, 1500, 'ТО'),
('Диагностика ходовой', 'Проверка подвески на вибростенде', 1.0, 2000, 'Диагностика'),
('Замена тормозных колодок (перед)', 'Замена передних тормозных колодок', 1.2, 1800, 'Тормозная система'),
('Шиномонтаж (1 колесо)', 'Снятие/установка, балансировка', 0.5, 800, 'Шиномонтаж'),
('Компьютерная диагностика', 'Считывание и анализ ошибок ЭБУ', 0.5, 2500, 'Диагностика');

-- Тестовые запчасти
INSERT INTO parts_catalog (name, article, manufacturer, unit, purchase_price, retail_price, stock_quantity, min_stock) VALUES
('Масло моторное 5W-40 (1л)', 'OIL5W40-1', 'Shell', 'л', 500, 800, 50, 10),
('Масляный фильтр', 'OF-1234', 'Mann', 'шт.', 300, 500, 30, 5),
('Тормозные колодки передние', 'BP-5678', 'Brembo', 'компл.', 1500, 2500, 15, 3),
('Свеча зажигания', 'SP-9012', 'NGK', 'шт.', 200, 350, 80, 20),
('Фильтр воздушный', 'AF-3456', 'Mann', 'шт.', 400, 650, 25, 5);

-- Проверка
SELECT 'База данных успешно создана!' AS status;
SELECT * FROM users;