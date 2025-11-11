# 📚 Documentation Index - Ghid Complet

> **Navigheaza documentatia dupa caz de uz**

---

## 🚀 FIRST TIME? START HERE

| Pentru... | Citeste | Timp |
|-----------|---------|------|
| Sa intelegi conceptele | [docs/CONCEPTS.md](docs/CONCEPTS.md) | 30 min |
| Sa intelegi arhitectura | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | 30 min |
| Rapid start (nu toata teoria) | [GETTING_STARTED.md](GETTING_STARTED.md) | 5 min |

---

## 🎯 CHOOSE YOUR MODE

### MOD 1: LOCAL (Fara Docker)
**Ideal pentru:** Development, Learning, Quick testing

| Ce vrei? | Citeste | Timp |
|----------|---------|------|
| Tutorial complet pas-cu-pas | [docs/01-LOCAL/README.md](docs/01-LOCAL/README.md) | 45 min |
| Debugging local | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | 15 min |
| Setup checklist | [TESTING_GUIDE.md](TESTING_GUIDE.md#-checklist-mod-1-local) | 10 min |

**Quick Start:**
```bash
cd 1-LOCAL
source .env.local
python -m uvicorn src.backend.main:app --reload
```

---

### MOD 2: DOCKER (Containerization)
**Ideal pentru:** Consistency, Testing, Staging

| Ce vrei? | Citeste | Timp |
|----------|---------|------|
| Tutorial complet pas-cu-pas | [docs/02-DOCKER/README.md](docs/02-DOCKER/README.md) | 45 min |
| Docker concepts | [docs/CONCEPTS.md#pillaru-2-containerization](docs/CONCEPTS.md) | 20 min |
| Setup checklist | [TESTING_GUIDE.md](TESTING_GUIDE.md#-checklist-mod-2-docker) | 15 min |

**Quick Start:**
```bash
cd 2-DOCKER
docker-compose up -d
curl http://localhost/health
```

---

### MOD 3: KUBERNETES (Cloud)
**Ideal pentru:** Production, Scaling, High availability

| Ce vrei? | Citeste | Timp |
|----------|---------|------|
| Tutorial complet pas-cu-pas | [docs/03-KUBERNETES/README.md](docs/03-KUBERNETES/README.md) | 60 min |
| GCP + Terraform concepts | [docs/CONCEPTS.md#pillaru-3-orchestration](docs/CONCEPTS.md) | 30 min |
| Troubleshooting | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | 20 min |
| Setup checklist | [TESTING_GUIDE.md](TESTING_GUIDE.md#-checklist-mod-3-kubernetes) | 20 min |

**Quick Start:**
```bash
cd 3-KUBERNETES/terraform
terraform init
terraform apply
```

---

## 🐛 DEBUGGING & TROUBLESHOOTING

| Problem | Citeste |
|---------|---------|
| Orice nu lucreaza | [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| MOD 1 specific | [docs/TROUBLESHOOTING.md#mod-1-local](docs/TROUBLESHOOTING.md) |
| MOD 2 specific | [docs/02-DOCKER/README.md#troubleshooting-mod-2](docs/02-DOCKER/README.md) |
| MOD 3 specific | [docs/03-KUBERNETES/README.md#troubleshooting-mod-3](docs/03-KUBERNETES/README.md) |
| Database errors | [docs/TROUBLESHOOTING.md#database](docs/TROUBLESHOOTING.md) |
| Network errors | [docs/TROUBLESHOOTING.md#networking](docs/TROUBLESHOOTING.md) |

---

## ✅ TESTING & VERIFICATION

| Ce faci? | Citeste |
|----------|---------|
| Trebuie sa testez inainte GitHub | [TESTING_GUIDE.md](TESTING_GUIDE.md) |
| Local mode testing | [TESTING_GUIDE.md#-checklist-mod-1-local](TESTING_GUIDE.md) |
| Docker testing | [TESTING_GUIDE.md#-checklist-mod-2-docker](TESTING_GUIDE.md) |
| Kubernetes testing | [TESTING_GUIDE.md#-checklist-mod-3-kubernetes](TESTING_GUIDE.md) |
| Security check | [TESTING_GUIDE.md#-security-verification](TESTING_GUIDE.md) |

---

## 📋 PROJECT INFORMATION

| Informatia | Locatia |
|-----------|---------|
| Project overview | [README.md](README.md) |
| Current status | [PROJECT_STATUS.md](PROJECT_STATUS.md) |
| Getting started quick | [GETTING_STARTED.md](GETTING_STARTED.md) |

---

## 📁 FOLDER STRUCTURE

```
voting-app/
├── 1-LOCAL/                    # MOD 1: Local setup
│   ├── README.md              # (Legacy, use docs/01-LOCAL/README.md)
│   └── .env.local.example     # Configuration template
│
├── 2-DOCKER/                   # MOD 2: Docker setup
│   ├── .env.docker.example    # Configuration template
│   ├── docker-compose.yml     # (To be created)
│   ├── Dockerfile.backend     # (To be created)
│   └── Dockerfile.frontend    # (To be created)
│
├── 3-KUBERNETES/              # MOD 3: Kubernetes setup
│   ├── .env.kubernetes.example # Configuration template
│   ├── terraform/             # (To be created)
│   └── k8s/                   # (To be created)
│
├── docs/
│   ├── CONCEPTS.md            # DevOPS theory
│   ├── ARCHITECTURE.md        # Technical details
│   ├── TROUBLESHOOTING.md     # Problem solving
│   ├── 01-LOCAL/README.md     # MOD 1 tutorial
│   ├── 02-DOCKER/README.md    # MOD 2 tutorial
│   └── 03-KUBERNETES/README.md # MOD 3 tutorial
│
├── src/
│   ├── backend/               # FastAPI application
│   │   ├── main.py
│   │   ├── database.py
│   │   ├── config.py
│   │   └── requirements.txt
│   └── frontend/              # Web UI
│       ├── index.html
│       ├── script.js
│       └── style.css
│
├── TESTING_GUIDE.md           # Testing checklist
├── DOCUMENTATION_INDEX.md     # This file
└── README.md                  # Project overview
```

---

## 🎓 LEARNING PATH

### For Beginners

1. **Read:** [docs/CONCEPTS.md](docs/CONCEPTS.md) - Understand DevOPS
2. **Setup:** [docs/01-LOCAL/README.md](docs/01-LOCAL/README.md) - Run locally
3. **Learn:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) - How it works
4. **Test:** [TESTING_GUIDE.md#mod-1](TESTING_GUIDE.md) - Verify works

### For Intermediate

1. **Setup:** [docs/02-DOCKER/README.md](docs/02-DOCKER/README.md) - Docker
2. **Test:** [TESTING_GUIDE.md#mod-2](TESTING_GUIDE.md) - Verify Docker
3. **Learn:** [docs/CONCEPTS.md#pillaru-2](docs/CONCEPTS.md) - Docker concepts
4. **Troubleshoot:** [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) - Fix issues

### For Advanced

1. **Setup:** [docs/03-KUBERNETES/README.md](docs/03-KUBERNETES/README.md) - Kubernetes
2. **Infra:** Study terraform/ configs
3. **Test:** [TESTING_GUIDE.md#mod-3](TESTING_GUIDE.md) - Verify Kubernetes
4. **Scale:** Modify replica counts, autoscaling, etc.

---

## 📞 NEED HELP?

1. **Check:** [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. **Search:** Use Ctrl+F for keywords
3. **Mode-specific:** Go to the MOD tutorial
4. **Still stuck:** Check logs with:
   - MOD 1: `tail -f /tmp/voting-app.log`
   - MOD 2: `docker-compose logs backend`
   - MOD 3: `kubectl logs -n voting-app -l app=backend`

---

## 🔒 SECURITY

| Aspect | Verificare |
|--------|-----------|
| Nici o secret pe GitHub | [.gitignore](.gitignore) |
| Credentiale in .env files | 1-LOCAL/.env.local.example |
| Database passwords | 2-DOCKER/.env.docker.example |
| Cloud credentials | 3-KUBERNETES/.env.kubernetes.example |

✅ IMPORTANT: `.env` files sunt in `.gitignore` - NU le uplocada pe GitHub!

---

## 📝 NOTES

**In Romana, fara diacritice:**
- ă → a
- ț → t  
- ș → s
- ž → z
- î → i
- â → a

Toata documentatia este scrisa fara diacritice pentru compatibilitate maxima.

---

## 🚀 NEXT STEPS

1. **Citeste** [GETTING_STARTED.md](GETTING_STARTED.md) (5 min)
2. **Alege MOD-ul** tau (LOCAL, DOCKER, KUBERNETES)
3. **Urmareste tutorial** din docs/XX-YYY/README.md
4. **Testeaza** cu TESTING_GUIDE.md
5. **Raportul GitHub** cand e ready!

---

**Created:** 2024
**Language:** Romanian (no diacritics)
**Project:** Voting App - Educational DevOPS
