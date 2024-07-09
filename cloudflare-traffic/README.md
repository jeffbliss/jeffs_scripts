# Purpose

cloudflare_graphql.sh queries cloudflare and grabs ips and stores in ip_addresses.txt

check_abusive_ips.py checks if the ip is abusive according to https://www.abuseipdb.com/ - however it won't check if it finds the ip in either non_abusive_ips.txt or abusive_ips.txt

add_abusive_ip.sh adds the ip as abusive to cloudflare