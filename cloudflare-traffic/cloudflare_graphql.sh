#!/bin/bash

query='{ "query":
 "query ListFirewallEvents($zoneTag: string, $filter: FirewallEventsAdaptiveFilter_InputObject) {
 viewer {
 zones(filter: { zoneTag: $zoneTag }) {
 firewallEventsAdaptive(
 filter: $filter
 limit: 10000
 orderBy: [datetime_DESC]
 ) {
 action
 clientIP
 }
 }
 }
 }",
 "variables": {
 "zoneTag": "'$CF_ZONE_ID'",
 "filter": {
 "datetime_geq": "2024-07-09T00:00:00Z",
 "datetime_leq": "2024-07-09T12:00:00Z",
 "action": "managed_challenge"
 }
 }
}'

response=$(echo $query | tr -d '\n' | curl \
-X POST \
-H "Content-Type: application/json" \
-H "X-Auth-Email: $CF_EMAIL" \
-H "X-Auth-key: $CF_GLOBAL_API_KEY" \
-s \
-d @- \
https://api.cloudflare.com/client/v4/graphql/)

ip_addresses=$(echo $response | jq -r '.data.viewer.zones[].firewallEventsAdaptive[].clientIP' | sort -u)

echo "$ip_addresses" | awk '{print $0}' > ip_addresses.txt