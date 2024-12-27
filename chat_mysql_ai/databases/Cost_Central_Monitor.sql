-- CREATE DATABASE Cost_Central_Monitor;
-- USE Cost_Central_Monitor;

-- 1. Providers Table
CREATE TABLE tbl_providers (
    provider_id INT AUTO_INCREMENT PRIMARY KEY,
    provider_name VARCHAR(100) NOT NULL,
    contact_info VARCHAR(255),
    website VARCHAR(255),
    provider_type ENUM('Cloud', 'SaaS', 'Hardware', 'Software', 'Service') NOT NULL,
    account_manager_name VARCHAR(100),
    account_manager_email VARCHAR(100),
    contract_start_date DATE NOT NULL,
    contract_end_date DATE NOT NULL,
    payment_terms VARCHAR(50) NOT NULL,
    status ENUM('Active', 'Inactive', 'Suspended') DEFAULT 'Active',
    CONSTRAINT chk_contract_dates CHECK (contract_end_date > contract_start_date),
    CONSTRAINT chk_email_format CHECK (account_manager_email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$')
);

-- 2. Projects Table
CREATE TABLE tbl_projects (
    project_id INT AUTO_INCREMENT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    project_manager VARCHAR(100) NOT NULL,
    department VARCHAR(100) NOT NULL,
    priority ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    status ENUM('Planning', 'In Progress', 'On Hold', 'Completed', 'Cancelled') DEFAULT 'Planning',
    budget_allocated DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    client_name VARCHAR(100),
    CONSTRAINT chk_end_date CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT chk_budget CHECK (budget_allocated >= 0)
);

-- 3. Resources Table
CREATE TABLE tbl_resources (
    resource_id INT AUTO_INCREMENT PRIMARY KEY,
    resource_name VARCHAR(100) NOT NULL,
    fk_provider_id INT NOT NULL,
    resource_type VARCHAR(50) NOT NULL,
    configuration TEXT,
    subscription_type ENUM('Monthly', 'Yearly', 'One-time', 'Pay-as-you-go') NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    recommended_capacity INT NOT NULL DEFAULT 1,
    efficiency_rating DECIMAL(3, 2) NOT NULL,
    FOREIGN KEY (fk_provider_id) REFERENCES tbl_providers(provider_id) ON DELETE RESTRICT,
    CONSTRAINT chk_efficiency_rating CHECK (efficiency_rating BETWEEN 0.00 AND 1.00),
    CONSTRAINT chk_unit_price CHECK (unit_price >= 0),
    CONSTRAINT chk_recommended_capacity CHECK (recommended_capacity > 0)
);

-- 4. Costs Table
CREATE TABLE tbl_costs (
    cost_id INT AUTO_INCREMENT PRIMARY KEY,
    fk_project_id INT NOT NULL,
    fk_resource_id INT NOT NULL,
    cost_amount DECIMAL(15, 2) NOT NULL,
    cost_date DATE NOT NULL,
    cost_type ENUM('Operational', 'Subscription', 'Licensing', 'Infrastructure', 'Maintenance') NOT NULL,
    billing_cycle ENUM('Monthly', 'Quarterly', 'Annually') NOT NULL,
    payment_method ENUM('Credit Card', 'Bank Transfer', 'Invoice', 'Direct Debit') NOT NULL,
    invoice_number VARCHAR(50) UNIQUE,
    notes TEXT,
    FOREIGN KEY (fk_project_id) REFERENCES tbl_projects(project_id) ON DELETE CASCADE,
    FOREIGN KEY (fk_resource_id) REFERENCES tbl_resources(resource_id) ON DELETE RESTRICT,
    CONSTRAINT chk_cost_amount CHECK (cost_amount > 0)
);

-- 5. Cost Alerts Table
CREATE TABLE tbl_cost_alerts (
    alert_id INT AUTO_INCREMENT PRIMARY KEY,
    fk_project_id INT,
    fk_resource_id INT,
    alert_type ENUM('Budget Exceed', 'Unusual Spending', 'Subscription Expiry', 'Resource Underutilization') NOT NULL,
    threshold_amount DECIMAL(15, 2),
    current_amount DECIMAL(15, 2),
    alert_date DATETIME NOT NULL,
    status ENUM('Active', 'Resolved', 'Ignored') DEFAULT 'Active',
    notification_sent BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (fk_project_id) REFERENCES tbl_projects(project_id) ON DELETE CASCADE,
    FOREIGN KEY (fk_resource_id) REFERENCES tbl_resources(resource_id) ON DELETE CASCADE,
    CONSTRAINT chk_threshold_amount CHECK (threshold_amount > 0),
    CONSTRAINT chk_current_amount CHECK (current_amount >= 0)
);

-- 6. Resource Utilization Table
CREATE TABLE tbl_resource_utilization (
    utilization_id INT AUTO_INCREMENT PRIMARY KEY,
    fk_resource_id INT NOT NULL,
    fk_project_id INT NOT NULL,
    record_date DATE NOT NULL,
    cpu_utilization DECIMAL(5, 2) NOT NULL,
    memory_utilization DECIMAL(5, 2) NOT NULL,
    storage_utilization DECIMAL(5, 2) NOT NULL,
    network_traffic DECIMAL(15, 2) NOT NULL,
    active_users INT NOT NULL DEFAULT 0,
    performance_score DECIMAL(4, 2) NOT NULL,
    FOREIGN KEY (fk_resource_id) REFERENCES tbl_resources(resource_id) ON DELETE CASCADE,
    FOREIGN KEY (fk_project_id) REFERENCES tbl_projects(project_id) ON DELETE CASCADE,
    CONSTRAINT chk_utilization CHECK (
        cpu_utilization BETWEEN 0 AND 100 AND 
        memory_utilization BETWEEN 0 AND 100 AND 
        storage_utilization BETWEEN 0 AND 100 AND 
        performance_score BETWEEN 0 AND 10
    )
);

-- 7. Users Table
CREATE TABLE tbl_users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    role ENUM('Admin', 'Manager', 'Viewer', 'Read-Only') DEFAULT 'Viewer',
    last_login DATETIME,
    is_active BOOLEAN DEFAULT TRUE,
    CONSTRAINT chk_users_email_format CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$')
);

-- 8. User Project Access Table
CREATE TABLE tbl_user_project_access (
    access_id INT AUTO_INCREMENT PRIMARY KEY,
    fk_user_id INT NOT NULL,
    fk_project_id INT NOT NULL,
    access_level ENUM('Read', 'Write', 'Admin') DEFAULT 'Read',
    FOREIGN KEY (fk_user_id) REFERENCES tbl_users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (fk_project_id) REFERENCES tbl_projects(project_id) ON DELETE CASCADE,
    UNIQUE(fk_user_id, fk_project_id)
);

-- Comprehensive Indexes for Performance Optimization
-- Providers Indexes
CREATE INDEX idx_provider_type ON tbl_providers (provider_type, status);
CREATE INDEX idx_provider_name ON tbl_providers (provider_name);

-- Projects Indexes
CREATE INDEX idx_project_priority ON tbl_projects (priority, status);
CREATE INDEX idx_project_department ON tbl_projects (department);
CREATE INDEX idx_project_manager ON tbl_projects (project_manager);

-- Resources Indexes
CREATE INDEX idx_resource_provider ON tbl_resources (fk_provider_id);
CREATE INDEX idx_resource_type ON tbl_resources (resource_type);
CREATE INDEX idx_resource_subscription ON tbl_resources (subscription_type, unit_price);

-- Costs Indexes
CREATE INDEX idx_cost_project ON tbl_costs (fk_project_id);
CREATE INDEX idx_cost_resource ON tbl_costs (fk_resource_id);
CREATE INDEX idx_cost_date ON tbl_costs (cost_date);
CREATE INDEX idx_cost_type ON tbl_costs (cost_type);

-- Cost Alerts Indexes
CREATE INDEX idx_alert_project ON tbl_cost_alerts (fk_project_id);
CREATE INDEX idx_alert_resource ON tbl_cost_alerts (fk_resource_id);
CREATE INDEX idx_alert_type ON tbl_cost_alerts (alert_type, status);

-- Resource Utilization Indexes
CREATE INDEX idx_utilization_resource ON tbl_resource_utilization (fk_resource_id);
CREATE INDEX idx_utilization_project ON tbl_resource_utilization (fk_project_id);
CREATE INDEX idx_utilization_date ON tbl_resource_utilization (record_date);

-- Users Indexes
CREATE INDEX idx_user_email ON tbl_users (email);
CREATE INDEX idx_user_role ON tbl_users (role);

-- User Project Access Indexes
CREATE INDEX idx_user_access_project ON tbl_user_project_access (fk_project_id);
CREATE INDEX idx_user_access_user ON tbl_user_project_access (fk_user_id);


