#!/bin/bash
# Template: GitHub label setup script
# Customize REPO and area labels for each project, then run once.
#
# Usage: bash scripts/github/setup-labels.sh
#
# This is a TEMPLATE — copy to the target project's scripts/github/setup-labels.sh
# and customize the REPO variable and area labels section.

set -e

REPO="OWNER/REPO"  # <-- CUSTOMIZE THIS

echo "Setting up labels for $REPO..."
echo ""

# ============================================================
# AREA LABELS — Customize per project
# ============================================================
echo "=== Area Labels ==="

# Example area labels (uncomment and customize as needed):

# gh label create "rust" --repo $REPO --description "Rust backend work (crates/)" --color "dea584" --force 2>/dev/null || true
# gh label create "python" --repo $REPO --description "Python backend work" --color "3572A5" --force 2>/dev/null || true
# gh label create "go" --repo $REPO --description "Go backend work" --color "00ADD8" --force 2>/dev/null || true
# gh label create "java" --repo $REPO --description "Java backend work" --color "b07219" --force 2>/dev/null || true
# gh label create "frontend" --repo $REPO --description "Frontend work" --color "61DAFB" --force 2>/dev/null || true
# gh label create "api" --repo $REPO --description "REST API changes" --color "5319e7" --force 2>/dev/null || true
# gh label create "ui" --repo $REPO --description "UI/UX changes" --color "c5def5" --force 2>/dev/null || true
# gh label create "infra" --repo $REPO --description "Infrastructure/DevOps" --color "0e8a16" --force 2>/dev/null || true
# gh label create "mobile" --repo $REPO --description "Mobile native app (iOS/Android)" --color "006b75" --force 2>/dev/null || true
# gh label create "tooling" --repo $REPO --description "Tooling crate/package" --color "dea584" --force 2>/dev/null || true
# gh label create "cli" --repo $REPO --description "CLI tool" --color "1D76DB" --force 2>/dev/null || true

echo ""

# ============================================================
# TYPE LABELS — Standard (keep as-is)
# ============================================================
echo "=== Type Labels ==="

gh label create "bug" --repo $REPO --description "Something isn't working" --color "d73a4a" --force 2>/dev/null || true
gh label create "enhancement" --repo $REPO --description "New feature or request" --color "a2eeef" --force 2>/dev/null || true
gh label create "docs" --repo $REPO --description "Documentation improvements" --color "0075ca" --force 2>/dev/null || true
gh label create "refactor" --repo $REPO --description "Code restructuring" --color "fbca04" --force 2>/dev/null || true
gh label create "test" --repo $REPO --description "Test improvements" --color "bfd4f2" --force 2>/dev/null || true

echo ""

# ============================================================
# PRIORITY LABELS — Standard (keep as-is)
# ============================================================
echo "=== Priority Labels ==="

gh label create "priority: high" --repo $REPO --description "High priority" --color "b60205" --force 2>/dev/null || true
gh label create "priority: low" --repo $REPO --description "Low priority" --color "c2e0c6" --force 2>/dev/null || true

echo ""

# ============================================================
# STATUS LABELS — Standard (keep as-is)
# ============================================================
echo "=== Status Labels ==="

gh label create "blocked" --repo $REPO --description "Blocked by external dependency" --color "d93f0b" --force 2>/dev/null || true
gh label create "needs-design" --repo $REPO --description "Needs design work before implementation" --color "e99695" --force 2>/dev/null || true

echo ""
echo "=== Done ==="
