#!/usr/bin/env sh
set -eu

: "${SUPABASE_PAT:?Set SUPABASE_PAT=sbp_xxx}"
: "${SUPABASE_PROJECT_REF:?Set SUPABASE_PROJECT_REF=yourref}"

python3 - "$SUPABASE_PROJECT_REF" "$SUPABASE_PAT" <<'PY'
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
