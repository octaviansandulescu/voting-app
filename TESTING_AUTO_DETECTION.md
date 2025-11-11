# ✅ Script.js Auto-Detection Implementation - Test Plan

## 🔄 Schimbare Aplicată

**File**: `src/frontend/script.js`

**Caracteristică**: Auto-detectare mediu (Local vs Kubernetes/GCP)

```javascript
function getApiBaseUrl() {
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
        return 'http://localhost:8000';  // Local docker-compose
    } else {
        return `${window.location.protocol}//${window.location.host}/api`;  // K8s/GCP
    }
}
```

---

## 📋 Plan de Testare

### Test 1: LOCAL - Docker Compose

**Setup:**
```bash
cd /home/octavian/sandbox/voting-app
docker-compose down  # Clean up
docker-compose up --build -d
sleep 30
```

**Verificări:**
```bash
# 1. Container status
docker ps --filter "label=com.docker.compose.project=voting-app"

# 2. Frontend accessibility
curl http://localhost/
# Ar trebui să returneze HTML cu script.js care folosește http://localhost:8000

# 3. Backend API test
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"choice": "dog"}'

curl http://localhost:8000/results
# Ar trebui să returneze: {"dogs": 1, "cats": 0}

# 4. Frontend via nginx proxy test
curl http://localhost/api/results
# Ar trebui să returneze JSON prin nginx proxy

# 5. Browser test (manual)
# Visit: http://localhost
# Open DevTools Console (F12)
# Ar trebui să vadă: "API_BASE_URL = http://localhost:8000"
# Click "Vote for Dogs"
# Ar trebui să vadă results update
```

**Rezultat așteptat**: ✅ Se votează și se actualizează, `script.js` detectează localhost și folosește port 8000

---

### Test 2: KUBERNETES/GCP - Deployed Version

**Setup:**
```bash
cd /home/octavian/sandbox/voting-app
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/legacy_credentials/octavian.sandulescu@gmail.com/adc.json
```

**Verificări:**
```bash
# 1. Get frontend external IP
FRONTEND_IP=$(kubectl get svc frontend -n voting-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend URL: http://$FRONTEND_IP"

# 2. Test via external IP
curl http://$FRONTEND_IP/
# Ar trebui să returneze HTML cu script.js care detectează non-localhost

# 3. Test API endpoint
curl http://$FRONTEND_IP/api/results
# Ar trebui să returneze JSON prin nginx proxy

# 4. Browser test (manual)
# Visit: http://<EXTERNAL-IP>
# Open DevTools Console (F12)
# Ar trebui să vadă: "API_BASE_URL = http://<EXTERNAL-IP>/api"
# Click "Vote for Dogs"
# Ar trebui să vadă results update din Cloud SQL
```

**Rezultat așteptat**: ✅ Se votează și se actualizează, `script.js` detectează non-localhost și folosește `/api` proxy

---

## 📊 Comparison Table

| Mediu | Hostname | API URL detectat | Backend endpoint | Proxy |
|-------|----------|-----------------|-----------------|-------|
| Local Docker | localhost | http://localhost:8000 | Direct | ❌ Nu |
| Local Docker | 127.0.0.1 | http://127.0.0.1:8000 | Direct | ❌ Nu |
| GCP Kubernetes | 35.x.x.x | http://35.x.x.x/api | Via nginx | ✅ Da |
| GCP Kubernetes | custom-domain.com | http://custom-domain.com/api | Via nginx | ✅ Da |

---

## 🎯 Ce verifică aceasta

✅ **Fără breaking changes** - Codul local funcționează exact ca înainte
✅ **Transparență** - Script.js se adaptează automat
✅ **Production-ready** - Funcționează pe GCP cu LoadBalancer/Ingress
✅ **Maintenance** - Un singur script.js pentru ambele medii

---

## 🔍 Debugging

Dacă apare eroare, deschide DevTools (F12) și cauta în Console:
```javascript
// Verifica ce URL e detectat
console.log('API_BASE_URL:', API_BASE_URL);
console.log('Hostname:', window.location.hostname);
console.log('Full URL:', window.location);
```

---

## ✅ Checklist Test

- [ ] **Local test**: docker-compose up - votează și se actualizează pe http://localhost
- [ ] **Local test**: DevTools console arată API_BASE_URL = http://localhost:8000
- [ ] **GCP test**: kubectl apply manifests și pods pornesc
- [ ] **GCP test**: Frontend URL accesibil pe LoadBalancer IP
- [ ] **GCP test**: DevTools console arată API_BASE_URL = http://<IP>/api
- [ ] **GCP test**: Votează și se actualizează din Cloud SQL
- [ ] **Logs**: Backend logs arată POST /vote și GET /results

---

## 📝 Note

Dacă Cloud SQL are probleme de conectare:
```bash
# Check backend logs
kubectl logs -f deployment/backend -n voting-app

# Check database secreturi
kubectl get secrets -n voting-app -o yaml

# Test direct din pod
kubectl exec -it <backend-pod> -n voting-app -- python -c "from database import SessionLocal; db = SessionLocal(); print('DB OK')"
```

