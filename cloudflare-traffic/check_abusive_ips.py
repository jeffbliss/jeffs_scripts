import os
import requests

def check_ip(ip_address):
    # AbuseIPDB API endpoint
    url = "https://api.abuseipdb.com/api/v2/check"

    # Your AbuseIPDB API key
    api_key = os.environ.get("ABUSE_IP_API_KEY")

    # Set the parameters for the API request
    params = {
        "ipAddress": ip_address,
        "maxAgeInDays": 90
    }

    # Set the headers for the API request
    headers = {
        "Key": api_key,
        "Accept": "application/json"
    }

    try:
        # Send the API request
        response = requests.get(url, params=params, headers=headers)
        response.raise_for_status()

        # Parse the JSON response
        data = response.json()["data"]

        # Check if the IP address is abusive
        if data["abuseConfidenceScore"] > 0:
            return True
        else:
            return False

    except requests.exceptions.RequestException as e:
        print(f"An error occurred: {e}")
        return None

# Read the list of IP addresses from a file
with open("ip_addresses.txt", "r") as file:
    ip_addresses = file.read().splitlines()

# Read the existing non-abusive IP addresses from the file
with open("non_abusive_ips.txt", "r") as file:
    non_abusive_ips = file.read().splitlines()

# Read the existing abusive IP addresses from the file
with open("abusive_ips.txt", "r") as file:
    abusive_ips = file.read().splitlines()

# Open the files for appending the results
non_abusive_file = open("non_abusive_ips.txt", "a")
abusive_file = open("abusive_ips.txt", "a")

# Check each IP address and write the results to the respective files
for ip_address in ip_addresses:
    # Check if the IP address has already been classified as non-abusive
    if ip_address in non_abusive_ips:
        print(f"IP address {ip_address} is already classified as non-abusive. Skipping API request.")
        continue

    # Check if the IP address has already been classified as abusive
    if ip_address in abusive_ips:
        print(f"IP address {ip_address} is already classified as abusive. Skipping API request.")
        continue

    # If the IP address has not been classified, make the API request
    is_abusive = check_ip(ip_address)

    if is_abusive is True:
        abusive_file.write(ip_address + "\n")
    elif is_abusive is False:
        non_abusive_file.write(ip_address + "\n")
    else:
        print(f"Skipping IP address {ip_address} due to an error.")

# Close the files
non_abusive_file.close()
abusive_file.close()
