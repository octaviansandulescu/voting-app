# Phase 2.1: Local Setup Guide

**Estimated Time**: 20 minutes | **Difficulty**: Beginner | **Prerequisites**: TESTING_FUNDAMENTALS.md, SECURITY.md

## Overview

In this guide, you'll deploy the voting app on your local machine without containers. This is the simplest way to understand how the application works and serves as the foundation for Docker and Kubernetes deployments.

**What you'll learn**:
- ✅ How to run the application locally
- ✅ How to run the test suite
- ✅ How to debug issues
- ✅ How environment detection works
- ✅ How to connect to a local MySQL database

## Prerequisites

Before starting, ensure you have:

```bash
# Required
python3 --version          # Should be 3.11 or higher
mysql --version            # MySQL client installed
pip3 --version             # Package manager

# Verify they're in PATH
which python3
which mysql
which pip3
```

**System Requirements**:
- RAM: 2 GB minimum
- Disk: 500 MB free
- Network: localhost access only
- MySQL: Running on localhost:3306

## Step 1: Set Up Local MySQL Database

### 1.1 Start MySQL Service

**On Linux**:
```bash
# Start MySQL
sudo systemctl start mysql

# Verify it's running
sudo systemctl status mysql

# Should show: Active (running)
```

**On macOS**:
```bash
# With Homebrew
brew services start mysql

# Verify
brew services list | grep mysql
```

**On Windows**:
```bash
# If installed via MySQL installer, start via Services
# Or use: net start MySQL80 (replace 80 with your version)
```

### 1.2 Create Database and User

```bash
# Connect to MySQL
mysql -u root -p

# Enter your root password
```

Then run these SQL commands:

```sql
-- Create database
CREATE DATABASE voting_app_local CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Create user
CREATE USER 'voting_user'@'localhost' IDENTIFIED BY 'voting_password_local';

-- Grant permissions
GRANT ALL PRIVILEGES ON voting_app_local.* TO 'voting_user'@'localhost';

-- Apply changes
FLUSH PRIVILEGES;

-- Verify
SHOW DATABASES;
EXIT;
```

### 1.3 Create Tables

```bash
# Navigate to project root
cd /home/octavian/sandbox/voting-app

# Connect and import schema
mysql -u voting_user -p voting_app_local < src/backend/schema.sql
```

**If schema.sql doesn't exist**, create it:

```bash
cat > src/backend/schema.sql << 'EOF'
CREATE TABLE IF NOT EXISTS votes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vote VARCHAR(10) NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT
);

CREATE INDEX idx_timestamp ON votes(timestamp);
CREATE INDEX idx_vote ON votes(vote);

-- Initial count: 0 votes for each option
EOF
```

Then import:
```bash
mysql -u voting_user -p voting_app_local < src/backend/schema.sql
```

### 1.4 Verify Database Connection

```bash
# Test the connection
mysql -u voting_user -p voting_app_local -e "SELECT * FROM votes;"

# Should return: empty result (no votes yet)
```

## Step 2: Configure Environment

### 2.1 Create .env File

Create `.env` in the project root:

```bash
cat > .env << 'EOF'
# Local Environment Configuration
DEPLOYMENT_MODE=local
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_USER=voting_user
DATABASE_PASSWORD=voting_password_local
DATABASE_NAME=voting_app_local
FLASK_ENV=development
DEBUG=True
EOF
```

### 2.2 Verify .env is Ignored

Check your `.gitignore`:

```bash
cat .gitignore
```

Should include:
```
.env
.env.local
*.pyc
__pycache__/
*.db
```

**Remember**: Never commit `.env` to GitHub! ⚠️

See `docs/guides/SECURITY.md` for more details.

## Step 3: Install Python Dependencies

### 3.1 Create Virtual Environment

```bash
# Navigate to backend
cd src/backend

# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate  # On Linux/macOS
# OR
venv\Scripts\activate     # On Windows (CMD)
source venv/Scripts/activate  # On Windows (PowerShell)

# Verify activation (should see "venv" in prompt)
which python3
```

### 3.2 Install Dependencies

```bash
# Ensure pip is up to date
pip3 install --upgrade pip

# Install requirements
pip3 install -r requirements.txt

# Verify installations
pip3 list
```

**Expected packages** (minimal set):
```
fastapi==0.104.1
uvicorn==0.24.0
mysql-connector-python==8.2.0
pytest==7.4.3
python-dotenv==1.0.0
```

### 3.3 Verify Installation

```bash
# Test imports
python3 -c "import fastapi; print(fastapi.__version__)"
python3 -c "import mysql.connector; print('MySQL connector OK')"
python3 -c "import pytest; print(pytest.__version__)"
```

## Step 4: Run Tests Locally

Before running the application, let's verify everything works with tests!

### 4.1 Run Unit Tests

```bash
# From src/backend directory (with venv activated)
pytest tests/ -v

# Or run specific test file
pytest tests/test_api.py -v
```

**Expected Output**:
```
tests/test_api.py::test_health_endpoint PASSED
tests/test_api.py::test_vote_submission PASSED
tests/test_api.py::test_results_endpoint PASSED

===== 3 passed in 0.42s =====
```

### 4.2 Run with Coverage

```bash
# Install coverage plugin
pip3 install pytest-cov

# Run with coverage
pytest tests/ --cov=. --cov-report=html

# View report
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

### 4.3 Test Database Connection

```bash
# Create test to verify DB connectivity
pytest tests/test_database.py -v -s

# Should show database connected message
```

## Step 5: Start the Backend API

### 5.1 Start Development Server

```bash
# From src/backend directory (with venv activated)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# Output should show:
# Uvicorn running on http://127.0.0.1:8000
# Application startup complete
```

**What `--reload` does**: Automatically restarts server when code changes (great for development!)

### 5.2 Test the API Endpoints

**In another terminal**:

```bash
# Health check
curl -X GET http://localhost:8000/health
# Returns: {"status": "healthy", "mode": "local"}

# Get results
curl -X GET http://localhost:8000/results
# Returns: {"dogs": 0, "cats": 0}

# Submit a vote
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"vote": "dogs"}'
# Returns: {"message": "Vote recorded", "total_votes": 1}

# Get updated results
curl -X GET http://localhost:8000/results
# Returns: {"dogs": 1, "cats": 0}
```

### 5.3 Check Logs

The server logs should show:
```
INFO:     Application startup complete
INFO:     GET /health HTTP/1.1" 200
INFO:     POST /vote HTTP/1.1" 200
```

## Step 6: Set Up Frontend

### 6.1 Configure Frontend Environment Detection

Frontend automatically detects "local" mode. Edit `src/frontend/script.js`:

```javascript
// Should have this logic:
const API_URL = (() => {
    if (window.location.hostname === 'localhost' || 
        window.location.hostname === '127.0.0.1') {
        return 'http://localhost:8000';
    }
    return window.location.origin + '/api';
})();
```

### 6.2 Serve Frontend Locally

**Option A: Using Python's built-in server**

```bash
cd src/frontend
python3 -m http.server 3000

# Open browser: http://localhost:3000
```

**Option B: Using Live Server (VS Code extension)**

1. Install "Live Server" extension in VS Code
2. Right-click `index.html` → "Open with Live Server"
3. Automatically opens at `http://127.0.0.1:5500`

**Option C: Using Node.js http-server**

```bash
npm install -g http-server
cd src/frontend
http-server -p 3000 -o
```

### 6.3 Test Frontend

1. Open browser to frontend URL
2. Click "Vote for Dogs" button
3. See vote count increase
4. Refresh page - vote persists in database ✅
5. Click "Vote for Cats"
6. See results update in real-time

## Step 7: Troubleshooting

### Issue: "Connection refused" when connecting to database

```bash
# Check MySQL is running
sudo systemctl status mysql

# If not running, start it
sudo systemctl start mysql

# Verify on correct port
mysql -u voting_user -p voting_app_local -h localhost
```

### Issue: "ModuleNotFoundError: No module named 'fastapi'"

```bash
# Virtual environment not activated!
source src/backend/venv/bin/activate

# Or reinstall dependencies
pip3 install -r src/backend/requirements.txt
```

### Issue: "Access denied for user 'voting_user'"

```bash
# Database password mismatch
# Check .env file has correct password

# Reset password if needed
mysql -u root -p
ALTER USER 'voting_user'@'localhost' IDENTIFIED BY 'voting_password_local';
FLUSH PRIVILEGES;
```

### Issue: "Port 8000 already in use"

```bash
# Find what's using port 8000
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or use different port
uvicorn main:app --host 0.0.0.0 --port 8001
```

### Issue: Frontend can't reach backend API

```bash
# Check CORS headers in main.py
# Should have:
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],  # Local dev only!
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# Test API directly
curl -X GET http://localhost:8000/health
```

## Step 8: Run Complete Test Suite

### 8.1 Unit Tests
```bash
cd src/backend
pytest tests/test_api.py -v
```

### 8.2 Integration Tests
```bash
# Tests that interact with real database
pytest tests/test_database.py -v
```

### 8.3 End-to-End Tests
```bash
# Start backend first: uvicorn main:app --host 0.0.0.0 --port 8000
# In another terminal:
pytest tests/test_e2e.py -v
```

### 8.4 Security Tests
```bash
# Tests for SQL injection, XSS, etc.
pytest tests/test_security.py -v
```

### 8.5 All Tests with Coverage
```bash
pytest tests/ \
  --cov=. \
  --cov-report=html \
  --cov-report=term-missing \
  -v
```

## Step 9: Development Workflow

### Recommended Development Process

1. **Start with tests** (TDD approach):
   ```bash
   # Write failing test first
   pytest tests/test_new_feature.py -v
   # Should fail (RED phase)
   
   # Write code to pass test
   # Edit src/backend/main.py
   
   # Run tests again
   pytest tests/test_new_feature.py -v
   # Should pass (GREEN phase)
   
   # Refactor if needed (keep tests passing)
   ```

2. **Run full test suite**:
   ```bash
   pytest tests/ -v --cov
   ```

3. **Start backend server** (with auto-reload):
   ```bash
   uvicorn main:app --reload
   ```

4. **Test in browser or with curl**:
   ```bash
   curl -X GET http://localhost:8000/results
   ```

5. **Check logs** for errors
6. **Iterate** on step 1

### Example: Adding a New Feature

Let's say you want to add a "statistics" endpoint:

```bash
# Step 1: Write test (TDD - RED phase)
cat > tests/test_statistics.py << 'EOF'
def test_statistics_endpoint():
    response = client.get("/statistics")
    assert response.status_code == 200
    assert "total_votes" in response.json()
    assert "percentage" in response.json()
EOF

# Step 2: Run test - it fails ❌
pytest tests/test_statistics.py -v

# Step 3: Write code to pass test (GREEN phase)
# Edit src/backend/main.py, add:
# @app.get("/statistics")
# def get_statistics():
#     return {"total_votes": 18, "percentage": {"dogs": 55.6, "cats": 44.4}}

# Step 4: Run test - it passes ✅
pytest tests/test_statistics.py -v

# Step 5: Run full test suite to ensure nothing broke
pytest tests/ -v

# Step 6: Test in browser/curl
curl -X GET http://localhost:8000/statistics
```

## Step 10: Database Inspection

### 10.1 View All Votes

```bash
mysql -u voting_user -p voting_app_local << 'EOF'
SELECT * FROM votes;
EOF
```

### 10.2 Get Vote Statistics

```bash
mysql -u voting_user -p voting_app_local << 'EOF'
SELECT 
    vote,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM votes), 1) as percentage
FROM votes
GROUP BY vote;
EOF
```

### 10.3 Clear All Votes

```bash
mysql -u voting_user -p voting_app_local << 'EOF'
DELETE FROM votes;
EOF
```

## Step 11: Stop Services

### Clean Shutdown

```bash
# Stop backend server (Ctrl+C in terminal)
# Stop frontend server (Ctrl+C in terminal)

# Stop MySQL
sudo systemctl stop mysql

# Deactivate virtual environment
deactivate
```

## Security Checklist - Local Development

Before moving to Docker, verify these security practices:

- ✅ `.env` file is in `.gitignore`
- ✅ Database password is strong (not shown in logs)
- ✅ API CORS allows localhost only (or localhost + specific hosts)
- ✅ No secrets in code or comments
- ✅ Tests pass without errors
- ✅ No hardcoded credentials in any files

Run this check:
```bash
# Search for common secrets
grep -r "password\|secret\|api_key\|token" src/backend/*.py | grep -v ".env"

# Should return nothing or only comments
```

## Testing Checklist - Local Development

- ✅ All unit tests pass (`pytest tests/ -v`)
- ✅ API endpoints respond correctly (`curl http://localhost:8000/...`)
- ✅ Database stores votes correctly
- ✅ Frontend displays results correctly
- ✅ Environment detection shows "local"
- ✅ No errors in logs

## Next Steps

Congratulations! You've successfully deployed locally! 🎉

**What you've learned**:
- How the application works at the code level
- How to run and debug tests
- How environment detection works
- How to connect to a real database

**Ready for next phase?**
- If issues, review TESTING_FUNDAMENTALS.md or SECURITY.md
- Ready to containerize? → Move to `docs/guides/DOCKER_SETUP.md`
- Want to go production? → Move to `docs/guides/KUBERNETES_SETUP.md`

## Resources

- **pytest Documentation**: https://docs.pytest.org/
- **FastAPI Documentation**: https://fastapi.tiangolo.com/
- **MySQL Documentation**: https://dev.mysql.com/doc/
- **Python Virtual Environments**: https://docs.python.org/3/tutorial/venv.html

---

**Questions?** Check `TROUBLESHOOTING.md` or review `TESTING_FUNDAMENTALS.md` for testing strategies.

**Ready for Docker?** Continue to `docs/guides/DOCKER_SETUP.md` →
