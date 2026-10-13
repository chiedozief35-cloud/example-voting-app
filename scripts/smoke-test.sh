#!/usr/bin/env bash
set -euo pipefail

VOTE_URL="http://localhost:8080"
RESULT_URL="http://localhost:8081"
VOTER_ID="capstone-ci-test"

db_query() {
  printf '%s\n' "$1" |
    docker compose exec -T db sh -c \
      'exec psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -At -v ON_ERROR_STOP=1'
}

cleanup() {
  db_query "DELETE FROM votes WHERE id = '$VOTER_ID';" \
    >/dev/null 2>&1 || true
}

wait_for_vote() {
  local expected="$1"
  local actual

  for attempt in {1..60}; do
    actual="$(db_query \
      "SELECT vote FROM votes WHERE id = '$VOTER_ID';" \
      2>/dev/null || true)"

    if [[ "$actual" == "$expected" ]]; then
      printf 'PASS: database contains vote %s\n' "$expected"
      return 0
    fi

    sleep 1
  done

  printf 'FAIL: expected vote %s within 60 seconds\n' "$expected" >&2
  return 1
}

printf '%s\n' "Checking the voting and results pages..."
curl -fsS "$VOTE_URL/" >/dev/null
curl -fsS "$RESULT_URL/" >/dev/null

printf '%s\n' "Waiting for the worker to create the votes table..."
table_ready=false

for attempt in {1..60}; do
  table="$(db_query "SELECT to_regclass('public.votes');" \
    2>/dev/null || true)"

  if [[ "$table" == "votes" ]]; then
    table_ready=true
    break
  fi

  sleep 1
done

if [[ "$table_ready" != true ]]; then
  printf '%s\n' "FAIL: votes table was not created" >&2
  exit 1
fi

trap cleanup EXIT
db_query "DELETE FROM votes WHERE id = '$VOTER_ID';" >/dev/null

printf '%s\n' "Submitting vote a..."
curl -fsS -b "voter_id=$VOTER_ID" \
  --data "vote=a" "$VOTE_URL/" >/dev/null
wait_for_vote a

printf '%s\n' "Changing the same voter to b..."
curl -fsS -b "voter_id=$VOTER_ID" \
  --data "vote=b" "$VOTE_URL/" >/dev/null
wait_for_vote b

count="$(db_query "SELECT COUNT(*) FROM votes WHERE id = '$VOTER_ID';")"

if [[ "$count" != "1" ]]; then
  printf 'FAIL: expected one voter record, found %s\n' "$count" >&2
  exit 1
fi

printf '%s\n' "PASS: changing a vote preserves one voter record"
printf '%s\n' "All smoke tests passed."
