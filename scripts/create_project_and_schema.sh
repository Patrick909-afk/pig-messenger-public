#!/usr/bin/env sh
set -eu

: "${SUPABASE_PAT:?Set SUPABASE_PAT=sbp_xxx}"
ORG_ID="${SUPABASE_ORG_ID:-dvirbqsgvlzircbvjall}"
PROJECT_NAME="${1:-pig-messenger}"
DB_PASS="${SUPABASE_DB_PASS:-PigMessenger_2026_supabase!}"
REGION="${SUPABASE_REGION:-us-east-1}"

create_payload=$(cat <<JSON
{"organization_id":"$ORG_ID","name":"$PROJECT_NAME","region":"$REGION","db_pass":"$DB_PASS"}
JSON
)

project_json=$(curl -sS -X POST https://api.supabase.com/v1/projects \
  -H "Authorization: Bearer $SUPABASE_PAT" \
  -H "Content-Type: application/json" \
  -d "$create_payload")

project_ref=$(echo "$project_json" | sed -n 's/.*"ref":"\([^"]*\)".*/\1/p')

if [ -z "$project_ref" ]; then
  echo "Failed to create project"
  echo "$project_json"
  exit 1
fi

echo "Created project ref: $project_ref"

python3 - "$project_ref" "$SUPABASE_PAT" <<'PY'
import json
import pathlib
import subprocess
import sys

project_ref = sys.argv[1]
pat = sys.argv[2]
sql = pathlib.Path('supabase/schema.sql').read_text()
payload = json.dumps({'query': sql})
cmd = [
    'curl', '-sS', '-X', 'POST',
    f'https://api.supabase.com/v1/projects/{project_ref}/database/query',
    '-H', f'Authorization: Bearer {pat}',
    '-H', 'Content-Type: application/json',
    '-d', payload,
]
res = subprocess.run(cmd, check=False, text=True, capture_output=True)
print(res.stdout)
if res.returncode != 0:
    print(res.stderr)
    raise SystemExit(res.returncode)
PY

curl -sS -H "Authorization: Bearer $SUPABASE_PAT" \
  "https://api.supabase.com/v1/projects/$project_ref/api-keys"

echo "Done."
