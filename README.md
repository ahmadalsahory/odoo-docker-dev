# Odoo 19.0 Enterprise - Docker Development Environment

This repository provides a standardized, containerized development environment for **Odoo 19.0 Enterprise** using Docker Compose and PostgreSQL 16.

---

## 📌 Architecture & Versions

* **Odoo Version:** `19.0 Enterprise` (Official Base Image: `odoo:19`)
* **Database:** `PostgreSQL 16` (`postgres:16`)
* **Orchestration:** `Docker Compose`
* **Python Runtime:** Python 3.12+ (Pre-packaged with dependencies, `wkhtmltopdf`, and system libraries inside the official image).

---

## 📁 Repository Structure

```text
odoo_enterprise_docker_test/
├── docker-compose.yml       # Docker services configuration (Odoo & Postgres)
├── odoo.conf                # Odoo configuration (addons_path, db connection, master password)
├── enterprise_addons/       # Odoo Enterprise addons directory (Excluded from Git)
├── custom_addons/           # Your custom Odoo modules and client developments
├── .agents/                 # AI Assistant skills & workflow customizations
├── .gitignore               # Excludes proprietary enterprise source & runtime data
└── README.md                # Project documentation
```

---

## 🚀 Quick Start Guide

### 1. Prerequisites
* [Docker Desktop](https://www.docker.com/products/docker-desktop/) or Docker Engine + Docker Compose installed.
* Valid Odoo Enterprise source code (obtained via your **Odoo Partner Portal** or Enterprise Subscription).

### 2. Prepare Enterprise Addons
Place your Odoo Enterprise modules inside the `enterprise_addons/` directory in the root of this project:
```bash
# Example structure:
enterprise_addons/
  ├── account_accountant/
  ├── web_enterprise/
  ├── documents/
  ├── helpdesk/
  └── ...
```

### 3. Start the Containers
Run Docker Compose in detached mode:
```bash
docker compose up -d
```

### 4. Access Odoo & Create Database
1. Open your browser and navigate to: **[http://localhost:8069](http://localhost:8069)**
2. In the database creation form, use the **Master Password**:
   ```text
   admin_secret_token_123
   ```
   *(Defined in `odoo.conf` under `admin_passwd`)*.
3. Complete the database name, admin email, and password.

---

## ⚙️ Configuration Details

### `odoo.conf`
The configuration file binds local addons paths inside the container:
```ini
[options]
admin_passwd = admin_secret_token_123
data_dir = /var/lib/odoo
db_host = db
db_port = 5432
db_user = odoo
db_password = odoo
addons_path = /mnt/enterprise-addons,/mnt/custom-addons
```

### Port Mapping
* **Web Interface:** `http://localhost:8069`
* **Longpolling / Chat:** `http://localhost:8072`
* **PostgreSQL (External Access):** `localhost:5433` (maps to internal `5432` to avoid local port conflicts).

---

## ⚖️ Licensing & Git Policy (OEEL Compliance)

> [!IMPORTANT]
> **Why is `enterprise_addons/` excluded from this repository?**
> * Odoo Enterprise code is protected by the **Odoo Enterprise Edition License (OEEL-1)**, a proprietary commercial license prohibiting public redistribution and hosting on public repositories.
> * As an **Odoo Partner / Subscriber**, enterprise code should be synced directly from the private `odoo/enterprise` repository or mounted locally, while maintaining only configuration files and custom modules (`custom_addons/`) in project version control.

---

## 🛠️ Useful Management Commands

* **View live Odoo logs:**
  ```bash
  docker compose logs -f odoo
  ```
* **Restart Odoo service:**
  ```bash
  docker compose restart odoo
  ```
* **Stop all containers:**
  ```bash
  docker compose stop
  ```
* **Start stopped containers:**
  ```bash
  docker compose start
  ```
* **Down and remove network (keeps volumes intact):**
  ```bash
  docker compose down
  ```
