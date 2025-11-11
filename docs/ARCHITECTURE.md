# 🏗️ Arhitectura Detaliata - Voting App

> **Pentru cei care vor sa inteleaga deep internals ale aplicatiei**

## 📊 Flux Complet

```
┌──────────────────────────────────────────────────────────────────┐
│                        USER (Browser)                            │
└──────────────────────────────────────────────────────────────────┘
                              │
                              ↓ HTTP Request
                              │
        ┌─────────────────────────────────────────┐
        │       FRONTEND (HTML/CSS/JS)            │
        │                                         │
        │  1. User click "Vote Dogs"             │
        │  2. JavaScript fetch() API              │
        │  3. POST /vote {vote: "dogs"}           │
        └─────────────────────────────────────────┘
                              │
                              ↓ JSON over HTTP
                              │
        ┌─────────────────────────────────────────┐
        │     BACKEND (FastAPI - Python)          │
        │                                         │
        │  1. Receive POST /vote                  │
        │  2. Validate input                      │
        │  3. Database insert()                   │
        │  4. Return JSON response                │
        └─────────────────────────────────────────┘
                              │
                              ↓ SQL Query
                              │
        ┌─────────────────────────────────────────┐
        │      DATABASE (MySQL)                   │
        │                                         │
        │  VOTES table:                           │
        │  - id (auto increment)                  │
        │  - vote (string: 'dogs' or 'cats')     │
        │  - timestamp (when voted)               │
        │  - count (aggregated)                   │
        └─────────────────────────────────────────┘
                              │
                              ↓ Return data
                              │
        ┌─────────────────────────────────────────┐
        │     BACKEND (FastAPI)                   │
        │                                         │
        │  GET /results                           │
        │  Return: {dogs: 42, cats: 35}          │
        └─────────────────────────────────────────┘
                              │
                              ↓ JSON over HTTP
                              │
        ┌─────────────────────────────────────────┐
        │     FRONTEND (JavaScript)               │
        │                                         │
        │  1. fetch() GET /results                │
        │  2. Parse JSON                          │
        │  3. Update UI (charts/counts)           │
        │  4. setInterval() - refresh every 1s   │
        └─────────────────────────────────────────┘
                              │
                              ↓ DOM Update
                              │
┌──────────────────────────────────────────────────────────────────┐
│                        USER (Browser)                            │
│                    "Dogs: 42, Cats: 35"                          │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📁 Structura Fisierelor

### Backend (`src/backend/`)

```
src/backend/
├── main.py                  # 🎯 FastAPI Application entry point
├── database.py              # 🗄️ MySQL connection & queries
├── models.py                # 📋 Data models (Pydantic)
├── config.py                # ⚙️ Configuration management
├── requirements.txt         # 📦 Python dependencies
├── tests/
│   └── test_api.py         # ✅ Unit tests
└── migrations/              # 🔄 Database migrations
```

### Frontend (`src/frontend/`)

```
src/frontend/
├── index.html               # 🎨 HTML structure
├── style.css                # 🎨 Styling
├── script.js                # 🔧 JavaScript logic
└── nginx.conf               # ⚙️ Nginx config (for Docker/K8s)
```

---

## 🔧 Backend Deep Dive

### `main.py` - FastAPI Application

```python
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# CORS: Allow frontend to make requests
app.add_middleware(CORSMiddleware, ...)

@app.post("/vote")
async def vote(vote: VoteRequest):
    """
    Endpoint pentru vot
    - Validate input (dogs sau cats)
    - Insert in database
    - Return success response
    """
    
@app.get("/results")
async def get_results():
    """
    Endpoint pentru rezultate
    - Query database
    - Aggregate counts
    - Return {dogs: X, cats: Y}
    """
```

### `database.py` - MySQL Connection

```python
import mysql.connector

class DatabaseConnection:
    def __init__(self, config):
        """
        Setup MySQL connection pool
        - Reuse connections
        - Auto-reconnect
        """
        
    def insert_vote(self, vote: str):
        """Insert vot in database"""
        
    def get_results(self) -> dict:
        """Get current vote counts"""
```

### `config.py` - Auto-Detection

```python
import os

DEPLOYMENT_MODE = os.getenv("DEPLOYMENT_MODE", "local")

if DEPLOYMENT_MODE == "local":
    DB_HOST = "localhost"
elif DEPLOYMENT_MODE == "docker":
    DB_HOST = "db"  # Docker service name
elif DEPLOYMENT_MODE == "kubernetes":
    DB_HOST = "cloudsql-proxy"  # K8s service
```

---

## 🎨 Frontend Deep Dive

### `index.html` - Structure

```html
<!DOCTYPE html>
<html>
<head>
    <title>Voting App</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <h1>Vote: Dogs vs Cats</h1>
        
        <!-- Vote buttons -->
        <button onclick="vote('dogs')">🐕 Dogs</button>
        <button onclick="vote('cats')">🐱 Cats</button>
        
        <!-- Results display -->
        <div class="results">
            <div>Dogs: <span id="dogs-count">0</span></div>
            <div>Cats: <span id="cats-count">0</span></div>
        </div>
    </div>
    
    <script src="script.js"></script>
</body>
</html>
```

### `script.js` - Logic

```javascript
// Auto-detect API endpoint based on environment
const API_URL = window.location.hostname === 'localhost'
    ? 'http://localhost:8000'
    : `http://${window.location.hostname}`;

async function vote(choice) {
    /**
     * 1. User click vote button
     * 2. fetch POST /vote
     * 3. Refresh results
     */
}

async function getResults() {
    /**
     * 1. fetch GET /results
     * 2. Update UI
     */
}

// Refresh results every 1 second
setInterval(getResults, 1000);
```

---

## 🗄️ Database Schema

### VOTES Table

```sql
CREATE TABLE votes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    vote VARCHAR(10) NOT NULL,        -- 'dogs' or 'cats'
    timestamp DATETIME DEFAULT NOW(), -- When voted
    ip_address VARCHAR(45),           -- For analytics
    user_agent VARCHAR(500)           -- Browser info
);

CREATE INDEX idx_vote ON votes(vote);
```

### Aggregation Query

```sql
SELECT 
    vote,
    COUNT(*) as count
FROM votes
GROUP BY vote;

-- Output:
-- | dogs | 42  |
-- | cats | 35  |
```

---

## 🔄 3 Moduri de Deployment

### MOD 1: LOCAL

```
┌─────────────────────────────────┐
│   Your Machine                  │
│                                 │
│  Python Process                 │
│  │                              │
│  ├─ Frontend (http.server:3000) │
│  ├─ Backend (FastAPI:8000)      │
│  └─ MySQL (localhost:3306)      │
│                                 │
└─────────────────────────────────┘
```

**Conectare directa, rapid, usor debugging**

### MOD 2: DOCKER

```
┌──────────────────────────────────┐
│   Your Machine (Docker Desktop)  │
│                                  │
│  ┌──────────────────────────┐   │
│  │  Frontend Container      │   │
│  │  Nginx:80 → :3000        │   │
│  └──────────────────────────┘   │
│                                  │
│  ┌──────────────────────────┐   │
│  │  Backend Container       │   │
│  │  FastAPI:8000            │   │
│  └──────────────────────────┘   │
│                                  │
│  ┌──────────────────────────┐   │
│  │  MySQL Container         │   │
│  │  MySQL:3306              │   │
│  └──────────────────────────┘   │
│                                  │
│  Docker Volume (persistent)      │
│                                  │
└──────────────────────────────────┘
```

**Simulare production, consistent environment**

### MOD 3: KUBERNETES + GCP

```
┌─────────────────────────────────────────────────┐
│              GOOGLE CLOUD PLATFORM              │
│                                                 │
│  ┌────────────────────────────────────────┐   │
│  │  GKE CLUSTER (Kubernetes)              │   │
│  │                                        │   │
│  │  ┌────────────────────────────────┐   │   │
│  │  │  Frontend Pods (Nginx)         │   │   │
│  │  │  - 2 replicas                  │   │   │
│  │  │  - LoadBalancer exposed        │   │   │
│  │  └────────────────────────────────┘   │   │
│  │                                        │   │
│  │  ┌────────────────────────────────┐   │   │
│  │  │  Backend Pods (FastAPI)        │   │   │
│  │  │  - 2 replicas                  │   │   │
│  │  │  - Auto-restart if crash       │   │   │
│  │  └────────────────────────────────┘   │   │
│  │                                        │   │
│  └────────────────────────────────────────┘   │
│                                                 │
│  ┌────────────────────────────────────────┐   │
│  │  CLOUD SQL (MySQL)                     │   │
│  │  - Private IP (VPC)                    │   │
│  │  - Cloud SQL Proxy                     │   │
│  │  - Automatic backups                   │   │
│  └────────────────────────────────────────┘   │
│                                                 │
└─────────────────────────────────────────────────┘
```

**Production-grade, scalable, reliable**

---

## 🔐 Security Measures

### 1. **Input Validation**
```python
vote = request.vote.lower()
if vote not in ['dogs', 'cats']:
    raise HTTPException(status_code=400, detail="Invalid vote")
```

### 2. **SQL Injection Prevention**
```python
# ❌ GRESIT:
query = f"INSERT INTO votes VALUES ('{vote}')"

# ✅ CORECT:
cursor.execute("INSERT INTO votes (vote) VALUES (%s)", (vote,))
```

### 3. **CORS Protection**
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],  # Whitelist
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### 4. **Secrets Management**
- Parole in environment variables (`.env`)
- `.env` nu merge pe GitHub
- GitHub Secrets pentru CI/CD

---

## 📊 Performance Considerations

### Database Indexing
```sql
-- Fast vote counting
CREATE INDEX idx_vote ON votes(vote);

-- Fast filtering by time
CREATE INDEX idx_timestamp ON votes(timestamp);
```

### API Response Times
```
/vote:
  - Database insert: ~5ms
  - Network: ~10ms
  - Total: ~15ms ✅

/results:
  - Database query: ~2ms
  - JSON serialization: ~1ms
  - Network: ~10ms
  - Total: ~13ms ✅

Frontend refresh (1 second interval):
  - 100 votes/second = 1 query every 0.01s = OK ✅
```

### Caching (Optional)
```python
# Redis cache pentru /results
cache = Redis()

@app.get("/results")
async def get_results():
    cached = cache.get("results")
    if cached:
        return cached
    
    results = db.get_results()
    cache.set("results", results, ex=5)  # Cache 5 seconds
    return results
```

---

## 🧪 Testing Strategy

### Unit Tests
```python
# test_api.py
def test_vote_dogs():
    response = client.post("/vote", json={"vote": "dogs"})
    assert response.status_code == 200

def test_invalid_vote():
    response = client.post("/vote", json={"vote": "birds"})
    assert response.status_code == 400
```

### Integration Tests
```python
def test_full_flow():
    # Vote
    client.post("/vote", json={"vote": "dogs"})
    # Check results
    response = client.get("/results")
    assert response.json()["dogs"] > 0
```

---

## 📈 Monitoring & Logging

### Backend Logs
```python
import logging

logger = logging.getLogger(__name__)

@app.post("/vote")
async def vote(request):
    logger.info(f"Vote received: {request.vote}")
    try:
        db.insert_vote(request.vote)
    except Exception as e:
        logger.error(f"Database error: {str(e)}")
        raise
```

### Frontend Logs
```javascript
console.log("API Response:", data);
console.error("API Error:", error);
```

### Kubernetes Logs
```bash
kubectl logs -f deployment/backend -n voting-app
kubectl logs -f deployment/frontend -n voting-app
```

---

## 🚀 Scalability Path

```
Day 1: LOCAL (1 user)
  ↓
Day 2: DOCKER (10 users)
  ↓
Day 3: KUBERNETES (1000 users)
  ├─ 3 backend replicas
  ├─ 2 frontend replicas
  ├─ Cloud SQL automatic scaling
  └─ LoadBalancer distributes traffic
```

---

## 📚 Urmatorul Pas

- **[MOD 1: LOCAL](01-LOCAL/README.md)** - Ruleaza local
- **[MOD 2: DOCKER](02-DOCKER/README.md)** - Containerizare
- **[MOD 3: KUBERNETES](03-KUBERNETES/README.md)** - Production GCP

---

**Ai alte intrebari despre arhitectura? Verifica [TROUBLESHOOTING.md](TROUBLESHOOTING.md)**
