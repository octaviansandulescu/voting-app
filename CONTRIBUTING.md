# 🤝 Contributing to Voting App

Thank you for considering contributing to this project! This is a **learning-focused project** designed to help junior developers understand DevOps practices.

---

## 🎯 Types of Contributions

We welcome:

### 📝 Documentation
- Improve existing guides
- Add missing explanations
- Fix typos or unclear instructions
- Translate to other languages
- Add diagrams/screenshots

### 🐛 Bug Fixes
- Fix deployment issues
- Correct code errors
- Improve error handling
- Update outdated dependencies

### ✨ Features
- Add new voting options
- Improve UI/UX
- Add monitoring capabilities
- Enhance security
- Add testing coverage

### 📚 Educational Content
- Create new tutorials
- Add video walkthroughs
- Write blog posts
- Create example projects
- Add exercises for learners

---

## 🚀 Getting Started

### 1. Fork the Repository

Click the "Fork" button at the top right of the [repository page](https://github.com/octaviansandulescu/voting-app).

---

### 2. Clone Your Fork

```bash
git clone https://github.com/YOUR_USERNAME/voting-app.git
cd voting-app
```

---

### 3. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

**Branch naming conventions:**
- `feature/add-postgresql-support` - New features
- `fix/database-connection-error` - Bug fixes
- `docs/improve-quickstart-guide` - Documentation
- `test/add-backend-tests` - Tests

---

### 4. Make Your Changes

**Before coding:**
- Read [QUICKSTART.md](QUICKSTART.md) to understand the project
- Check [FAQ.md](FAQ.md) for common questions
- Review [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for known issues

**While coding:**
- Follow existing code style
- Add comments for complex logic
- Test your changes locally
- Update documentation if needed

---

### 5. Test Your Changes

**For code changes:**
```bash
# Test locally with Docker Compose
docker-compose up -d
docker-compose ps  # All services should be "Up"

# Test backend
curl http://localhost:8000/results

# Run tests (if available)
cd src/backend
pytest tests/
```

**For documentation changes:**
- Read through your changes
- Check for typos and formatting
- Verify all links work
- Test code examples

---

### 6. Commit Your Changes

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git add .
git commit -m "feat: add PostgreSQL as alternative database"
git commit -m "fix: correct Cloud SQL connection timeout"
git commit -m "docs: improve troubleshooting guide for beginners"
git commit -m "test: add integration tests for voting API"
```

**Commit message format:**
```
<type>: <description>

[optional body]
[optional footer]
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Code style (formatting, no logic change)
- `refactor:` - Code restructuring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

**Example:**
```
feat: add Redis caching for vote counts

- Implement Redis connection in backend
- Cache results for 60 seconds
- Update docker-compose with Redis service
- Add Redis health check

Closes #42
```

---

### 7. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

---

### 8. Create Pull Request

1. Go to your fork on GitHub
2. Click "Pull Request" button
3. Select your branch
4. Fill in the PR template:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation
- [ ] Tests

## Testing
How did you test this?

## Checklist
- [ ] Code follows project style
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] No secrets in code
```

---

## 📋 Coding Standards

### Python (Backend)

Follow [PEP 8](https://pep8.org/):

```python
# Good
def get_vote_count(vote_type: str) -> int:
    """Get total votes for a specific type."""
    return db.query(Vote).filter(Vote.type == vote_type).count()

# Bad
def GetVoteCount(VoteType):
    return db.query(Vote).filter(Vote.type==VoteType).count()
```

**Tools:**
```bash
# Format code
black src/backend/

# Check style
flake8 src/backend/

# Type checking
mypy src/backend/
```

---

### JavaScript (Frontend)

Follow standard JavaScript conventions:

```javascript
// Good
function submitVote(voteType) {
    return fetch('/api/vote', {
        method: 'POST',
        body: JSON.stringify({ vote: voteType })
    });
}

// Bad
function Submit_Vote(VoteType) {
    return fetch('/api/vote',{method:'POST',body:JSON.stringify({vote:VoteType})})
}
```

**Tools:**
```bash
# Format code
prettier --write src/frontend/

# Check style
eslint src/frontend/
```

---

### Terraform

Follow [Terraform style guide](https://www.terraform.io/docs/language/syntax/style.html):

```hcl
# Good
resource "google_container_cluster" "voting_cluster" {
  name     = "voting-app-cluster"
  location = var.region
  
  remove_default_node_pool = true
  initial_node_count       = 1
}

# Bad
resource "google_container_cluster" "voting_cluster" {
name="voting-app-cluster"
location=var.region
remove_default_node_pool=true
initial_node_count=1}
```

**Tools:**
```bash
# Format code
terraform fmt

# Validate
terraform validate
```

---

### Bash Scripts

Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html):

```bash
# Good
#!/bin/bash
set -e  # Exit on error

function deploy_application() {
    local namespace="$1"
    kubectl apply -f manifests/ -n "$namespace"
}

# Bad
#!/bin/bash
function deploy_application {
kubectl apply -f manifests/ -n $1
}
```

---

## 🧪 Testing Requirements

### For New Features

**Must include:**
- Unit tests
- Integration tests (if applicable)
- Manual testing steps in PR description

**Example:**
```python
# tests/test_voting.py
def test_vote_submission():
    """Test that votes are recorded correctly."""
    response = client.post("/vote", json={"vote": "dogs"})
    assert response.status_code == 200
    assert response.json()["success"] is True
```

---

### For Bug Fixes

**Must include:**
- Test that reproduces the bug
- Test that verifies the fix

**Example:**
```python
def test_vote_with_empty_string():
    """Bug #42: Empty vote should return 400."""
    response = client.post("/vote", json={"vote": ""})
    assert response.status_code == 400
```

---

## 📚 Documentation Requirements

### For New Features

Update:
- `README.md` - If user-facing feature
- `docs/` - Detailed guide if complex
- `FAQ.md` - If frequently asked about
- `TROUBLESHOOTING.md` - If prone to errors

---

### For Bug Fixes

Update:
- `TROUBLESHOOTING.md` - Add error and solution
- `CHANGELOG.md` - Record the fix

---

## 🔒 Security Guidelines

**NEVER commit:**
- ❌ Passwords, API keys, tokens
- ❌ `.env` files with real credentials
- ❌ Service account JSON keys
- ❌ SSL certificates/private keys

**Always:**
- ✅ Use `.env.example` with dummy values
- ✅ Use environment variables
- ✅ Add sensitive files to `.gitignore`
- ✅ Review changes before committing

**If you accidentally commit secrets:**
1. Revoke/rotate credentials immediately
2. Remove from Git history: `git filter-repo` or BFG
3. Force push after cleanup

---

## 🎨 UI/UX Guidelines

**For frontend changes:**
- Keep design simple and intuitive
- Ensure mobile responsiveness
- Test in multiple browsers (Chrome, Firefox, Safari)
- Maintain accessibility (ARIA labels, keyboard navigation)
- Use existing color scheme

---

## 📦 Dependency Management

### Adding New Dependencies

**Python:**
```bash
# Add to requirements.txt with version pinning
echo "redis==5.0.0" >> src/backend/requirements.txt
```

**JavaScript:**
```bash
# Use package.json
npm install --save redis
```

**Explain why:** In PR description, explain why the dependency is needed.

---

### Updating Dependencies

**Check compatibility:**
```bash
# Python
pip-compile --upgrade

# JavaScript
npm outdated
```

**Test thoroughly** after updating dependencies.

---

## 🏷️ Pull Request Guidelines

### Good PR Example

**Title:** `feat: add Redis caching for vote counts`

**Description:**
```markdown
## Description
Adds Redis caching to improve performance for frequently accessed vote counts.

## Motivation
Current implementation queries database on every request. With high traffic, 
this causes slow response times (>2s). Redis caching reduces to <100ms.

## Changes
- Added Redis service to docker-compose.yml
- Implemented caching in backend/main.py
- Added cache invalidation on new votes
- Updated documentation

## Testing
- Tested locally with 1000 concurrent requests
- Response time improved from 2.1s to 0.09s
- Cache invalidates correctly after voting

## Screenshots
[Before/After performance graphs]

## Checklist
- [x] Tests pass locally
- [x] Documentation updated
- [x] No secrets committed
- [x] Follows code style
```

---

### Bad PR Example (Don't do this)

**Title:** `Update`

**Description:**
```markdown
Fixed stuff
```

**Problems:**
- ❌ Vague title
- ❌ No description of changes
- ❌ No testing information
- ❌ No checklist

---

## 🚫 What We WON'T Accept

- Incomplete features without tests
- Breaking changes without migration guide
- Uncommented complex code
- Commits with secrets
- PRs with unrelated changes mixed together
- Changes without documentation updates

---

## ⏱️ Review Process

1. **Automated checks run** (if CI/CD configured)
2. **Maintainer reviews within 1-7 days**
3. **Feedback provided** if changes needed
4. **You address feedback** and push updates
5. **Approved and merged** once ready

**Be patient!** Maintainers review in spare time.

---

## 🎓 Learning Resources

**New to contributing?**
- [First Contributions Guide](https://github.com/firstcontributions/first-contributions)
- [How to Write Good Commit Messages](https://chris.beams.io/posts/git-commit/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)

**New to testing?**
- [pytest Documentation](https://docs.pytest.org/)
- [Testing Python Applications](https://realpython.com/pytest-python-testing/)

---

## 💬 Communication

**Questions?**
- Open a [Discussion](https://github.com/octaviansandulescu/voting-app/discussions)
- Ask in PR comments
- Check [FAQ.md](FAQ.md)

**Found a bug?**
- Open an [Issue](https://github.com/octaviansandulescu/voting-app/issues)
- Include reproduction steps
- Attach screenshots/logs

---

## 📜 Code of Conduct

**Be respectful:**
- Use welcoming language
- Respect differing viewpoints
- Accept constructive criticism
- Focus on what's best for the community

**Not tolerated:**
- Harassment or discrimination
- Trolling or insulting comments
- Public or private harassment
- Publishing others' private information

**Violations:** Report to maintainers privately.

---

## 🙏 Recognition

Contributors are recognized in:
- `CONTRIBUTORS.md` file
- GitHub contributors page
- Release notes

---

## 📝 License

By contributing, you agree that your contributions will be licensed under the same license as the project (see [LICENSE](LICENSE)).

---

## 🎉 Thank You!

Every contribution helps make this project better for learners worldwide. Whether it's fixing a typo or adding a major feature, your effort is appreciated!

**Happy contributing! 🚀**
