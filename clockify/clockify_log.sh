#!/usr/bin/env bash
#
# clockify_log.sh - log a time entry in Clockify for today.
#
# Pick a project (favorites first, then alphabetical), pick a task,
# enter decimal hours and a description. The entry starts at 9:00am
# local time today, or right after your latest entry today, so entries
# stack up without overlapping; actual clock times don't matter.
#
# Requires: curl, jq, and CLOCKIFY_API_KEY set in the environment.
# (macOS: uses BSD date flags)

set -euo pipefail

API="https://api.clockify.me/api"
WORKSPACE_NAME="NEMAC's workspace"

# load CLOCKIFY_API_KEY from a .env next to this script, if present
script_dir=$(cd "$(dirname "$0")" && pwd)
if [[ -f "$script_dir/.env" ]]; then
  # shellcheck source=/dev/null
  source "$script_dir/.env"
fi

if [[ -z "${CLOCKIFY_API_KEY:-}" ]]; then
  echo "Error: CLOCKIFY_API_KEY is not set." >&2
  echo "Get a key at https://app.clockify.me/user/preferences#advanced" >&2
  exit 1
fi

# api METHOD PATH [JSON_BODY] -> prints response body, exits on HTTP error
api() {
  local method=$1 path=$2 body=${3:-}
  local response status payload
  response=$(curl -s -w $'\n%{http_code}' -X "$method" \
    -H "X-Api-Key: $CLOCKIFY_API_KEY" \
    -H "Content-Type: application/json" \
    ${body:+-d "$body"} \
    "$API$path")
  status=${response##*$'\n'}
  payload=${response%$'\n'*}
  if [[ $status != 2* ]]; then
    echo "Clockify API error ($status): $(echo "$payload" | jq -r '.message // .' 2>/dev/null)" >&2
    exit 1
  fi
  echo "$payload"
}

# ---- workspace ----
workspace_id=$(api GET /v1/workspaces | jq -r --arg name "$WORKSPACE_NAME" \
  '.[] | select(.name == $name) | .id')
if [[ -z $workspace_id ]]; then
  echo "Error: no workspace named \"$WORKSPACE_NAME\" found. Your workspaces:" >&2
  api GET /v1/workspaces | jq -r '.[].name' >&2
  exit 1
fi

# ---- pick a project (favorites first, then alphabetical) ----
# Uses the undocumented project-picker endpoint (what the Clockify web UI
# calls) because the official v1 API does not expose the favorite flag.
projects=$(api GET "/workspaces/$workspace_id/project-picker/projects?page=1&page-size=200&search=" |
  jq 'sort_by((if (.favorite // false) then 0 else 1 end), (.name | ascii_downcase))')

project_ids=()
project_names=()
i=1
while IFS=$'\t' read -r id name fav; do
  project_ids+=("$id")
  project_names+=("$name")
  star=" "
  [[ $fav == true ]] && star="★"
  printf "%3d) %s %s\n" "$i" "$star" "$name"
  i=$((i + 1))
done < <(echo "$projects" | jq -r '.[] | [.id, .name, (.favorite // false)] | @tsv')

if [[ ${#project_ids[@]} -eq 0 ]]; then
  echo "No projects found." >&2
  exit 1
fi

while true; do
  read -rp "Project number: " choice
  if [[ $choice =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#project_ids[@]})); then
    break
  fi
  echo "Enter a number between 1 and ${#project_ids[@]}."
done
project_id=${project_ids[$((choice - 1))]}
project_name=${project_names[$((choice - 1))]}

# ---- pick a task (alphabetical); skip if the project has none ----
tasks=$(api GET "/v1/workspaces/$workspace_id/projects/$project_id/tasks?is-active=true&page-size=200" |
  jq 'sort_by(.name | ascii_downcase)')

task_id=""
task_name="(none)"
if [[ $(echo "$tasks" | jq 'length') -gt 0 ]]; then
  task_ids=()
  task_names=()
  i=1
  while IFS=$'\t' read -r id name; do
    task_ids+=("$id")
    task_names+=("$name")
    printf "%3d) %s\n" "$i" "$name"
    i=$((i + 1))
  done < <(echo "$tasks" | jq -r '.[] | [.id, .name] | @tsv')

  while true; do
    read -rp "Task number: " choice
    if [[ $choice =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#task_ids[@]})); then
      break
    fi
    echo "Enter a number between 1 and ${#task_ids[@]}."
  done
  task_id=${task_ids[$((choice - 1))]}
  task_name=${task_names[$((choice - 1))]}
else
  echo "(no tasks on this project - logging to the project directly)"
fi

# ---- hours ----
while true; do
  read -rp "Hours (e.g. 1, 0.5, 2.25): " hours
  if [[ $hours =~ ^[0-9]*\.?[0-9]+$ ]] && awk -v h="$hours" 'BEGIN { exit !(h > 0) }'; then
    break
  fi
  echo "Enter a positive number of hours."
done

# ---- description ----
while true; do
  read -rp "Description: " description
  [[ -n $description ]] && break
  echo "Description is required."
done

# ---- create the entry: start at 9:00am local, or after today's latest entry ----
duration_secs=$(awk -v h="$hours" 'BEGIN { printf "%d", h * 3600 }')
start_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$(date +%Y-%m-%d) 09:00:00" +%s)

user_id=$(api GET /v1/user | jq -r '.id')
day_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "$(date +%Y-%m-%d) 00:00:00" +%s)
range_start=$(date -u -r "$day_epoch" +"%Y-%m-%dT%H:%M:%SZ")
range_end=$(date -u -r "$((day_epoch + 86400))" +"%Y-%m-%dT%H:%M:%SZ")

latest_end=$(api GET "/v1/workspaces/$workspace_id/user/$user_id/time-entries?start=$range_start&end=$range_end&page-size=200" |
  jq -r '[.[].timeInterval.end // empty] | max // empty')

if [[ -n $latest_end ]]; then
  # parse "2026-08-31T14:00:00Z" (strip any fractional seconds and the Z)
  t=${latest_end%%.*}
  t=${t%Z}
  latest_epoch=$(date -ju -f "%Y-%m-%dT%H:%M:%S" "$t" +%s)
  if ((latest_epoch > start_epoch)); then
    start_epoch=$latest_epoch
  fi
fi

end_epoch=$((start_epoch + duration_secs))
start=$(date -u -r "$start_epoch" +"%Y-%m-%dT%H:%M:%SZ")
end=$(date -u -r "$end_epoch" +"%Y-%m-%dT%H:%M:%SZ")

body=$(jq -n \
  --arg start "$start" --arg end "$end" \
  --arg pid "$project_id" --arg tid "$task_id" --arg desc "$description" \
  '{start: $start, end: $end, projectId: $pid, description: $desc}
   + (if $tid != "" then {taskId: $tid} else {} end)')

api POST "/v1/workspaces/$workspace_id/time-entries" "$body" > /dev/null

echo
echo "Logged: $hours hour(s) on \"$project_name\" / \"$task_name\""
echo "        $(date -r "$start_epoch" +"%I:%M %p") - $(date -r "$end_epoch" +"%I:%M %p") today"
echo "        $description"
