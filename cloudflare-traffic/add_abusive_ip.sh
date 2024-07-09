#!/bin/bash

while IFS= read -r line
do
  curl --request POST \
    --url "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/firewall/access_rules/rules" \
    --header 'Content-Type: application/json' \
    --header 'X-Auth-Email: '"$CF_EMAIL"'' \
    --header 'X-Auth-key: '"$CF_GLOBAL_API_KEY"'' \
    --data '{
      "configuration": {
        "target": "ip",
        "value": "'"$line"'"
      },
      "mode": "managed_challenge",
      "notes": "this ip is abusive according to abuseipdb July 2024"
    }'
done < "new_abuse.txt"
