# 🗳️ Voting App - DevOPS Learning Project

> **Un tutorial complet de DevOPS pentru junior developers**

## 👋 Bun venit!

Aceasta e o aplicație simplă care te va ghida prin **toți pașii DevOPS**:
1. 🏠 Mod LOCAL (fără Docker)
2. 🐳 Mod DOCKER (containerizare)
3. ☸️ Mod KUBERNETES (production pe GCP)

**Fiecare mod funcționează independent** - nu trebuie să faci pe toate dacă nu vrei!

---

## 🎯 Ce Vei Aprinde

- ✅ Docker & Containerizare
- ✅ Kubernetes & Orkestrare
- ✅ Terraform & Infrastructure as Code
- ✅ CI/CD & GitHub Actions
- ✅ Bune practici de securitate
- ✅ Deployment pe Google Cloud

---

## 📖 Learning Path

### **Începător? START AICI:**

1. **[📚 Citește CONCEPTS.md](docs/CONCEPTS.md)** (10 min)
   - Înțelege ce e DevOPS
   - Înțelege Docker, Kubernetes, Terraform, CI/CD

2. **[🏠 Rulează MOD 1: LOCAL](docs/01-LOCAL/README.md)** (20 min)
   - Instalează MySQL și Python
   - Rulează aplicația fără Docker
   - Înțelege cum merge

3. **[🐳 Rulează MOD 2: DOCKER](docs/02-DOCKER/README.md)** (15 min)
   - Containerizează aplicația
   - docker-compose up
   - Simuleaza production local

4. **[☸️ Rulează MOD 3: KUBERNETES](docs/03-KUBERNETES/README.md)** (30 min)
   - Deploy pe GCP
   - Terraform + Kubernetes
   - Aplicația LIVE pe internet!

### **Avansat? MERGI DIRECT LA MODUL PE CARE IL VREI**

---

## 🏗️ Arhitectura Aplicației

```
┌──────────────────────────────────────────────────────────────┐
│                 VOTING APP ARCHITECTURE                      │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Frontend                          Backend                    │
│  ┌──────────────────┐          ┌──────────────────┐         │
│  │  HTML/CSS/JS     │          │  Python/FastAPI  │         │
│  │                  │          │                  │         │
│  │  - Vote UI       │←──HTTP──→│  - /vote         │         │
│  │  - Results real  │          │  - /results      │         │
│  │  - Auto-detect   │          │  - Validation    │         │
│  │    environment   │          │  - Logic         │         │
│  └──────────────────┘          └──────────────────┘         │
│                                         │                    │
│                                         │ SQL                │
│                                         ↓                    │
│                                  ┌──────────────┐           │
│                                  │    MySQL     │           │
│                                  │  - Votes     │           │
│                                  │  - Results   │           │
│                                  └──────────────┘           │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## 📁 Structura Proiectului

```
voting-app/
│
├── docs/                          # 📚 DOCUMENTAȚIE
│   ├── CONCEPTS.md               # Ce e DevOPS?
│   ├── ARCHITECTURE.md           # Arhitectură detaliată
│   ├── TROUBLESHOOTING.md        # Probleme & soluții
│   ├── 01-LOCAL/                 # Setup LOCAL
│   │   └── README.md
│   ├── 02-DOCKER/                # Setup DOCKER
│   │   └── README.md
│   └── 03-KUBERNETES/            # Setup KUBERNETES
│       └── README.md
│
├── src/                           # 💻 CODUL SURSĂ (IDENTIC pentru toate 3)
│   ├── backend/
│   │   ├── main.py              # FastAPI app
│   │   ├── database.py          # MySQL connection
│   │   ├── models.py            # Data models
│   │   ├── config.py            # Auto-detect environment
│   │   ├── requirements.txt
│   │   └── tests/
│   │       └── test_api.py
│   └── frontend/
│       ├── index.html           # Voting UI
│       ├── style.css
│       ├── script.js            # Auto-detect API
│       └── nginx.conf           # Nginx config
│
├── 1-LOCAL/                       # 🏠 MOD 1: SETUP LOCAL
│   ├── README.md
│   ├── .env.local.example
│   ├── install.sh               # MySQL + Python setup
│   ├── start.sh                 # Start backend + frontend
│   └── stop.sh                  # Stop all
│
├── 2-DOCKER/                      # 🐳 MOD 2: SETUP DOCKER
│   ├── README.md
│   ├── .env.docker.example
│   ├── docker-compose.yml       # 3 services
│   ├── Dockerfile.backend
│   ├── Dockerfile.frontend
│   └── .dockerignore
│
├── 3-KUBERNETES/                  # ☸️ MOD 3: SETUP GCP
│   ├── README.md
│   ├── terraform/
│   │   ├── main.tf              # GKE + Cloud SQL
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars.example
│   ├── k8s/
│   │   ├── 01-namespace.yaml
│   │   ├── 02-secrets.yaml
│   │   ├── 03-backend-deployment.yaml
│   │   ├── 04-frontend-deployment.yaml
│   │   └── 05-services.yaml
│   └── scripts/
│       ├── deploy.sh
│       ├── destroy.sh
│       └── status.sh
│
├── .github/workflows/             # 🤖 CI/CD
│   ├── ci-test.yml              # Test automat pe push
│   └── cd-deploy.yml            # Deploy automat pe main
│
└── .gitignore                     # 🔒 Secretele nu merge pe GitHub
```

---

## 🚀 Quick Start

### Option A: LOCAL (fără Docker)
```bash
cd 1-LOCAL
cp .env.local.example .env.local
# Editeaza .env.local cu datele MySQL
./install.sh
./start.sh
# Accesează http://localhost:3000
```

### Option B: DOCKER
```bash
cd 2-DOCKER
cp .env.docker.example .env.docker
docker-compose up
# Accesează http://localhost
```

### Option C: KUBERNETES + GCP
```bash
cd 3-KUBERNETES
cp terraform.tfvars.example terraform.tfvars
# Editeaza terraform.tfvars cu datele GCP
./scripts/deploy.sh
# Accesează http://<EXTERNAL-IP>
```

---

## 📋 Cerințe Minime

### MOD 1 (LOCAL)
- Python 3.11+
- MySQL 8.0
- Git

### MOD 2 (DOCKER)
- Docker Desktop
- Git

### MOD 3 (KUBERNETES)
- GCP Account (free tier ok)
- gcloud CLI
- kubectl
- Terraform
- Git

---

## 🔒 Securitate

**IMPORTANT: Nici o dată sensibilă pe GitHub!**

- `.env` files → `.gitignore` (nu se uploadează)
- `.example` templates → Pe GitHub (fără valori reale)
- GitHub Secrets → Pentru CI/CD
- Terraform secrets → `.gitignore`

---

## 📚 Documentație Completă

| Document | Descriere | Timp |
|----------|-----------|------|
| [CONCEPTS.md](docs/CONCEPTS.md) | Ce e DevOPS? | 10 min |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Arhitectură detaliată | 15 min |
| [01-LOCAL](docs/01-LOCAL/README.md) | Setup fără Docker | 20 min |
| [02-DOCKER](docs/02-DOCKER/README.md) | Setup cu Docker | 15 min |
| [03-KUBERNETES](docs/03-KUBERNETES/README.md) | Setup pe GCP | 30 min |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Probleme comune | ~5 min |

---

## ✅ Learning Checklist

Marchează cu ✅ pe măsură ce progresezi:

- [ ] Citit CONCEPTS.md
- [ ] Setup MOD 1 (LOCAL)
- [ ] Setup MOD 2 (DOCKER)
- [ ] Setup MOD 3 (KUBERNETES)
- [ ] Gata! 🎉

---

## 🆘 Probleme?

1. Verifică [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Citește logs cu atentie
3. Cauta în documentație

---

## 📄 Licență

MIT License - Vezi [LICENSE](LICENSE)

---

**Gata să înveți DevOPS? Start cu [CONCEPTS.md](docs/CONCEPTS.md)! →**
cd voting-app
```

2. Start the application:
```bash
docker-compose up --build
```

3. Access the application:
- Frontend: http://localhost
- Backend API: http://localhost:8000

## API Endpoints

### GET /results
Returns the current voting results.

Response:
```json
{
    "dogs": 10,
    "cats": 15
}
```

### POST /vote
Submit a vote.

Request body:
```json
{
    "choice": "dog"  // or "cat"
}
```

Response:
```json
{
    "message": "Vote recorded"
}
```

## Development

### Local Development with Docker Compose

```bash
docker-compose up --build
```

Access at http://localhost

### GCP Deployment

See [GCP Deployment Guide](docs/GCP_DEPLOYMENT.md) for detailed instructions.

Quick start:
```bash
chmod +x setup-gcp.sh
./setup-gcp.sh
chmod +x deploy.sh
./deploy.sh
```

## Testing

The project includes automated tests for the backend API. Run the tests with:

```bash
cd src/backend
python -m pytest tests/ --cov=.
```

## CI/CD

The project uses GitHub Actions for Continuous Integration, running:
- Python tests with coverage
- Frontend linting (if configured)

## Contributing

1. Fork the repository
2. Create a new branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
