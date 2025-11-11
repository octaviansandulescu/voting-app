"""
⚙️ Configuration Management - Auto-Detection Environment

Concept DevOPS: Configuration should NOT be in code.
Instead, use environment variables și context detection.

Suporta 3 moduri:
1. LOCAL - Direct pe mașina ta
2. DOCKER - în Docker containers
3. KUBERNETES - pe GCP Kubernetes
"""

import os
from dotenv import load_dotenv

# ============================================================================
# Detect Deployment Mode
# ============================================================================

DEPLOYMENT_MODE = os.getenv("DEPLOYMENT_MODE", "local").lower()

print(f"[CONFIG] Detected Mode: {DEPLOYMENT_MODE}")

# ============================================================================
# Load .env based on mode
# ============================================================================

if DEPLOYMENT_MODE == "local":
    # Load from 1-LOCAL/.env.local (only if file exists)
    env_file = "1-LOCAL/.env.local"
    if os.path.exists(env_file):
        load_dotenv(env_file)
        print(f"[CONFIG] Loaded environment from {env_file}")
    else:
        print(f"[CONFIG] No {env_file} found - using environment variables")

elif DEPLOYMENT_MODE == "docker":
    # Load from 2-DOCKER/.env.docker (only if file exists)
    # In Docker, this may not exist - environment vars are set in docker-compose.yml
    env_file = "2-DOCKER/.env.docker"
    if os.path.exists(env_file):
        load_dotenv(env_file)
        print(f"[CONFIG] Loaded environment from {env_file}")
    else:
        print(f"[CONFIG] No {env_file} found - using docker-compose environment variables")

elif DEPLOYMENT_MODE == "kubernetes":
    # K8s: Secrets are injected as environment variables
    print("[CONFIG] Running in Kubernetes - Using injected secrets")

# ============================================================================
# Database Configuration
# ============================================================================

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", 3306))
DB_USER = os.getenv("DB_USER", "voting_user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "voting_app")

# Build Database URL
DATABASE_URL = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

print(f"[CONFIG] Database: {DB_HOST}:{DB_PORT}/{DB_NAME}")

# ============================================================================
# Frontend Configuration
# ============================================================================

FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:3000")
BACKEND_PORT = int(os.getenv("BACKEND_PORT", 8000))

# ============================================================================
# Application Configuration
# ============================================================================

DEBUG = os.getenv("DEBUG", "False").lower() == "true"

print(f"[CONFIG] Frontend URL: {FRONTEND_URL}")
print(f"[CONFIG] Backend Port: {BACKEND_PORT}")
print(f"[CONFIG] Debug: {DEBUG}")
