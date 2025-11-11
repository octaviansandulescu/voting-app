#!/bin/bash

echo "🧹 CLEANING UP PROJECT STRUCTURE"
echo "================================="

# 1. Create directory structure
echo "📁 Creating folders..."
mkdir -p scripts/testing
mkdir -p scripts/deployment
mkdir -p scripts/monitoring
mkdir -p infrastructure/kubernetes
mkdir -p .github/workflows

# 2. Move existing test scripts
echo "📝 Organizing test scripts..."
for file in test-*.sh; do
    if [ -f "$file" ]; then
        mv "$file" "scripts/testing/" 2>/dev/null
        echo "  ✓ Moved: $file"
    fi
done

# 3. Move Kubernetes configuration
echo "📝 Organizing Kubernetes files..."
if [ -d "3-KUBERNETES/k8s" ]; then
    mkdir -p infrastructure/kubernetes
    cp -r 3-KUBERNETES/k8s/* infrastructure/kubernetes/ 2>/dev/null
    echo "  ✓ Copied K8s manifests to infrastructure/kubernetes/"
fi

# 4. List files that should be moved to docs/archive or removed
echo ""
echo "📦 Files to review/clean:"
ls -la *.md *.txt 2>/dev/null | grep -E "DEPLOYMENT|PHASE|FINAL|STATUS|COMPLETE|QUICK|GUIDE|LEARNING|READY" | awk '{print "  • " $9}'

echo ""
echo "✅ Project structure organization complete!"
