#!/bin/bash
set -e

# Name of the large file to remove from history
LARGE_FILE="1)Preprocessing/individual_data.csv"

# Check for git-filter-repo
if ! command -v git-filter-repo &> /dev/null; then
    echo "git-filter-repo not found. Installing..."
    pip install git-filter-repo || {
        echo "Please install git-filter-repo manually: https://github.com/newren/git-filter-repo";
        exit 1;
    }
fi

echo "Removing $LARGE_FILE from git history..."
git filter-repo --force --path "$LARGE_FILE" --invert-paths

echo "Re-adding $LARGE_FILE with Git LFS..."
git lfs track "$LARGE_FILE"
git add .gitattributes "$LARGE_FILE"
git commit -m "Re-add $LARGE_FILE with Git LFS after history cleanup"

echo "Force-pushing cleaned history to origin/main..."
git push -u origin main --force

echo "Done! The large file is now tracked with Git LFS and your history is clean." 