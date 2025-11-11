# Local Testing Before GCP Deployment

It's recommended to test the application locally before deploying to GCP.

## Prerequisites
- Docker
- Docker Compose

## Running Locally

### 1. Start the Application
```bash
docker-compose up --build
```

This starts:
- Frontend on http://localhost
- Backend on http://localhost:8000
- MySQL on localhost:3306

### 2. Test the Application

#### Test Frontend
Open http://localhost in your browser and:
- [ ] Page loads without errors
- [ ] Two buttons visible (Dogs, Cats)
- [ ] Results display correctly
- [ ] Buttons are clickable

#### Test Backend API
```bash
# Test voting endpoint
curl -X POST http://localhost:8000/vote \
  -H "Content-Type: application/json" \
  -d '{"choice": "dog"}'

# Expected response:
# {"message":"Vote recorded"}

# Test results endpoint
curl http://localhost:8000/results

# Expected response:
# {"dogs":1,"cats":0}
```

### 3. Run Tests
```bash
cd src/backend
TESTING=true pytest tests/ -v
```

All tests should pass:
- [ ] `test_vote_endpoint` passes
- [ ] `test_invalid_vote` passes
- [ ] `test_get_results` passes

### 4. Test Database
```bash
# Connect to MySQL
docker-compose exec db mysql -uroot -ppassword

# Inside MySQL:
USE votingapp;
SELECT * FROM votes;
SELECT COUNT(*) FROM votes WHERE choice='dog';
```

## Cleanup Local Environment

```bash
# Stop containers
docker-compose down

# Remove volumes (resets database)
docker volume rm voting-app_mysql_data

# Clean up images (optional)
docker image rm voting-app-backend
docker image rm voting-app-frontend
```

## Common Local Issues

### Port already in use
```bash
# Check what's using port 80, 8000, 3306
lsof -i :80
lsof -i :8000
lsof -i :3306

# Kill the process or change ports in docker-compose.yml
```

### Database connection errors
```bash
# Check MySQL logs
docker-compose logs db

# Restart containers
docker-compose restart
```

### Frontend shows blank page
```bash
# Check frontend logs
docker-compose logs frontend

# Verify nginx is serving files
docker-compose exec frontend ls -la /usr/share/nginx/html
```

### Backend API not responding
```bash
# Check backend logs
docker-compose logs backend

# Test connectivity
docker-compose exec frontend curl http://backend:8000/results
```

## Performance Testing (Optional)

### Load testing with Apache Bench
```bash
# Install Apache Bench
# macOS: brew install httpd
# Ubuntu: sudo apt-get install apache2-utils

# Test 100 requests, 10 concurrent
ab -n 100 -c 10 http://localhost/

# Test voting endpoint
ab -n 100 -c 10 -p payload.json -T application/json http://localhost:8000/vote
```

### Database Performance
```bash
# Check slow queries
docker-compose exec db mysql -uroot -ppassword \
  -e "SET GLOBAL slow_query_log='ON'; SET GLOBAL long_query_time=0.1;"

# Monitor in real-time
docker-compose exec db mysql -uroot -ppassword -e "SHOW PROCESSLIST;"
```

## Data Validation

### Database Schema
```bash
docker-compose exec db mysql -uroot -ppassword -e \
  "DESCRIBE votingapp.votes;"

# Expected output:
# id       | int(11) | NO | PRI | NULL | auto_increment
# choice   | varchar(50) | NO | | NULL |
```

### Sample Data
```bash
# Add test data
docker-compose exec db mysql -uroot -ppassword << EOF
USE votingapp;
INSERT INTO votes (choice) VALUES ('dog'), ('dog'), ('cat'), ('dog');
SELECT choice, COUNT(*) as count FROM votes GROUP BY choice;
EOF
```

## Browser Developer Tools Testing

### Check Network Requests
1. Open DevTools (F12)
2. Go to Network tab
3. Click on Dogs/Cats button
4. Verify:
   - [ ] POST request to `/vote` returns 200
   - [ ] GET request to `/results` returns 200
   - [ ] Response JSON is valid

### Check Console
1. Open Console tab
2. No JavaScript errors should appear
3. No CORS errors

### Check Application
1. Application tab
2. Verify frontend files are loaded correctly
3. Check stored data (if applicable)

## Ready for GCP?

When all local tests pass:

1. Commit your changes
```bash
git add .
git commit -m "Application tested locally"
git push
```

2. Review GitHub Actions
```
Go to Actions tab in GitHub
Verify CI/CD pipeline passes
```

3. Run GCP setup
```bash
./validate.sh
./setup-gcp.sh
./deploy.sh
```

---

**Pro Tip**: Keep the local environment running in one terminal while developing. Use another terminal for testing.
