# 🏠 MOD 1: LOCAL SETUP (Fara Docker)

> **Timp estimat: 20 minute**
> 
> Rulezi aplicatia **direct pe masina ta**, fara Docker.

## 📖 Cand Folosesti Acest Mod

- ✅ **Dezvoltare rapida** - Schimba cod, refresh browser, vezi imediat
- ✅ **Debugging** - Usor sa debuguezi cu print() si breakpoints
- ✅ **Primeiro contact** - Intelege mai bine cum merge aplicatia
- ✅ **Fara Docker** - Nu trebuie sa instalezi Docker
- ✅ **Rapid** - Nu astepta build time

---

## 🔧 Cerinte

Verifica ca ai instalat:

```bash
python --version         # Trebuie 3.11 sau mai nou
pip --version           # Package manager Python
mysql --version         # MySQL server
```

**Nu le ai?** Jump la instalare mai jos ↓

---

## 📝 STEP 1: Instaleaza MySQL (Baza de Date)

MySQL stocheaza voturile si rezultatele.

### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y mysql-server mysql-client

# Pornire
sudo systemctl start mysql
sudo systemctl status mysql
```

### macOS (cu Homebrew):
```bash
brew install mysql

# Pornire
brew services start mysql
```

### Windows:
Descarca installer de pe [mysql.com](https://dev.mysql.com/downloads/mysql/)

---

## ⚙️ STEP 2: Setup MySQL Database

Creeaza database si user:

```bash
# Conectare la MySQL
mysql -u root -p
# Introdu password (default: vacid pe instalare)

# In MySQL prompt, ruleaza:
CREATE DATABASE voting_app_local;
CREATE USER 'voting_user_local'@'localhost' IDENTIFIED BY 'secure_password_local';
GRANT ALL PRIVILEGES ON voting_app_local.* TO 'voting_user_local'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

Verifica conexiune:
```bash
mysql -u voting_user_local -p voting_app_local -e "SELECT 1"
# Introdu parola: secure_password_local
# Output: 1 = succes!
```

---

## 🐍 STEP 3: Setup Python Virtual Environment

Virtual environment = "cutie" izolata cu dependentele Python.

```bash
cd /path/to/voting-app

# Creeaza venv
python3.11 -m venv venv

# Activeaza
source venv/bin/activate      # macOS/Linux
# SAU
venv\Scripts\activate         # Windows

# Verifica activare - prompt ar trebui sa arate: (venv) user@machine
```

---

## 📦 STEP 4: Instaleaza Dependente Python

```bash
cd src/backend

# Instaleaza libraries din requirements.txt
pip install -r requirements.txt

# Verifica
pip list | grep -i fastapi   # Ar trebui sa apara FastAPI
```

---

## ⚙️ STEP 5: Configureaza Environment

Creeaza `.env.local` cu datele MySQL:

```bash
cp 1-LOCAL/.env.local.example 1-LOCAL/.env.local
```

Editeaza `1-LOCAL/.env.local`:

```bash
# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=voting_user_local
DB_PASSWORD=secure_password_local        # Parola din STEP 2
DB_NAME=voting_app_local

# Environment
DEPLOYMENT_MODE=local
BACKEND_PORT=8000
FRONTEND_PORT=3000
```

---

## 🚀 STEP 6: Ruleaza Backend (FastAPI)

Terminal 1:

```bash
cd src/backend

# Seteaza environment
export DEPLOYMENT_MODE=local
export FLASK_ENV=development    # (optional pentru debugging)

# Pornire server
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Output ar trebui sa arate:

```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Application startup complete
```

✅ Backend e live!

---

## 🎨 STEP 7: Ruleaza Frontend

Terminal 2 (nou terminal, NU pe acelasi!):

```bash
cd src/frontend

# Pornire simple HTTP server (Python built-in)
python -m http.server 3000

# Output:
# Serving HTTP on 0.0.0.0 port 3000 ...
```

SAU, daca ai Node.js:

```bash
npx http-server -p 3000 -c-1
```

---

## ✅ STEP 8: Testeaza Aplicatia

1. Deschide browser: **http://localhost:3000**
2. Ar trebui sa vezi UI-ul de vot (Dogs vs Cats)
3. Click pe "Dogs" sau "Cats"
4. Rezultatele ar trebui sa se actualizeze in timp real

🎉 **Felicitari! Aplicatia merge local!**

---

## 🔍 Debugging

### Backend nu merge?

```bash
# Verifica conexiune MySQL
mysql -u voting_user_local -p voting_app_local

# Verifica port 8000
lsof -i :8000    # macOS/Linux
netstat -ano | findstr :8000  # Windows

# Verifica logs
# Flask va afisa erorile in terminal
```

### Frontend nu merge?

```bash
# Verifica port 3000
lsof -i :3000

# Verifica console browser (F12 → Console tab)
# Ar trebui sa arate URL-urile API calls
```

### Erori MySQL?

```bash
# Conectare
mysql -u voting_user_local -p voting_app_local

# Verifica tabele
SHOW TABLES;

# Verifica date
SELECT * FROM votes;
```

---

## 📝 Fisierele Importante

| Fisier | Ce Face |
|--------|----------|
| `src/backend/main.py` | FastAPI server |
| `src/backend/database.py` | MySQL connection |
| `src/frontend/index.html` | UI |
| `src/frontend/script.js` | JavaScript (API calls) |
| `1-LOCAL/.env.local` | Configuratie (NU commit!) |

---

## 🛑 Oprire

Pentru a opri aplicatia:

```bash
# Backend terminal: CTRL+C
# Frontend terminal: CTRL+C
```

---

## 📋 Checklist

- [ ] MySQL instalat si ruleaza
- [ ] Database `voting_app_local` creat
- [ ] User `voting_user_local` creat
- [ ] Python venv creat si activat
- [ ] Dependencies instalate
- [ ] `.env.local` configurat
- [ ] Backend ruleaza pe 8000
- [ ] Frontend ruleaza pe 3000
- [ ] Aplicatia merge pe http://localhost:3000
- [ ] Poti vota si vezi rezultate

---

## 📚 Urmatorul Pas

Gata cu LOCAL? Mergi la:
- **[MOD 2: DOCKER](../02-DOCKER/README.md)** - Containerizare
- **[MOD 3: KUBERNETES](../03-KUBERNETES/README.md)** - Production GCP

---

**Ai probleme? Verifica [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)**
