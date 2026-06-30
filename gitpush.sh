#!/bin/bash
set -e
cd "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")"

echo "Pushing to git"

if [ ! -d ".git" ]; then
    echo "Error: This directory is not a Git repository. Run 'git init' first."
    exit 1
fi

# --- Handle submodules first ---
if [ -f ".gitmodules" ]; then
    echo "Checking submodules for uncommitted changes..."

    # Warn about dirty submodules (uncommitted changes inside them)
    DIRTY_SUBMODULES=$(git submodule foreach --quiet 'git status --porcelain | grep -q . && echo "$name"' || true)
    if [ -n "$DIRTY_SUBMODULES" ]; then
        echo ""
        echo "Warning: the following submodules have uncommitted changes:"
        echo "$DIRTY_SUBMODULES"
        echo "These changes will NOT be included automatically."
        echo "cd into each submodule, commit, and push manually if needed."
        echo ""
    fi

    echo "Pushing any committed-but-unpushed submodule commits..."
    git submodule foreach --quiet '
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        if [ "$branch" != "HEAD" ] && [ -n "$branch" ]; then
            git push origin "$branch" 2>/dev/null || echo "  (nothing to push for $name or push failed)"
        else
            echo "  ($name is in detached HEAD state, skipping push)"
        fi
    ' || true
fi

# --- Handle main repo ---
if [ -z "$(git status --porcelain)" ]; then
    echo "No changes detected in main repo. Repository is already up to date!"
    exit 0
fi

echo "Staging files..."
git add .

DEFAULT_MSG="Auto-Update: $(date '+%Y-%m-%d %H:%M')"
echo ""
echo "Enter a commit message (or press Enter for '$DEFAULT_MSG'):"
read -r msg

if [ -z "$msg" ]; then
    AUTO_MSG="$DEFAULT_MSG"
else
    AUTO_MSG="$msg"
fi

echo ""
echo "Committing changes with message: '$AUTO_MSG'..."
git commit -m "$AUTO_MSG"

echo "Pushing to GitHub main branch (including referenced submodule commits)..."
git push --recurse-submodules=on-demand origin main

echo "Pushed to git successfully"