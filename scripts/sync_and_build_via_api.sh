#!/usr/bin/env sh
set -eu

: "${GITHUB_TOKEN:?Set GITHUB_TOKEN in environment}"
: "${GH_OWNER:?Set GH_OWNER in environment}"
: "${GH_REPO_PRIVATE:?Set GH_REPO_PRIVATE in environment}"
: "${GH_REPO_PUBLIC:?Set GH_REPO_PUBLIC in environment}"
: "${SUPABASE_PAT:?Set SUPABASE_PAT in environment}"
: "${SUPABASE_PROJECT_REF:?Set SUPABASE_PROJECT_REF in environment}"

REPO_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$REPO_DIR"

BRANCH="$(git branch --show-current)"
if [ "$BRANCH" != "main" ]; then
  echo "Current branch is '$BRANCH', expected 'main'"
  exit 1
fi

echo "Applying Supabase schema to project: $SUPABASE_PROJECT_REF"
SUPABASE_PAT="$SUPABASE_PAT" SUPABASE_PROJECT_REF="$SUPABASE_PROJECT_REF" sh scripts/apply_schema.sh

echo "Pushing main to private repo"
git push "https://x-access-token:${GITHUB_TOKEN}@github.com/${GH_OWNER}/${GH_REPO_PRIVATE}.git" main:main

echo "Pushing main to public repo"
git push "https://x-access-token:${GITHUB_TOKEN}@github.com/${GH_OWNER}/${GH_REPO_PUBLIC}.git" main:main

dispatch_workflow() {
  repo="$1"
  curl -sS -X POST \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${GH_OWNER}/${repo}/actions/workflows/build-apk.yml/dispatches" \
    -d '{"ref":"main"}' >/dev/null
}

echo "Dispatching build-apk.yml in private repo"
dispatch_workflow "$GH_REPO_PRIVATE"

echo "Dispatching build-apk.yml in public repo"
dispatch_workflow "$GH_REPO_PUBLIC"

echo "Done: schema applied, code pushed, workflows dispatched."
