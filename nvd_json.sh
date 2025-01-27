#!/bin/bash

################################################################################
# NVD JSON Data Update Script with Historical and Incremental Updates
#
# Purpose:
#   - Retrieve and maintain a local repository of NVD CVE data using REST API v2.0.
#   - Fetch historical CVE data from 1999 onward on the first run.
#   - Efficiently fetch only modified CVEs using `modStartDate` and `modEndDate` 
#     for subsequent runs.
#   - Ensure compliance with API restrictions, including the 120-day date range limit.
#
# Features:
#   - Dynamically fetches historical data year by year and quarter by quarter 
#     using `pubStartDate` and `pubEndDate` for initial setup.
#   - Tracks the last successful update to fetch only incremental CVEs in later runs.
#   - Handles paginated responses to fetch all CVE data within each range.
#   - Saves quarterly data into JSON files and supports merging for comprehensive analysis.
#   - Includes historical coverage starting from the first official CVE (CVE-1999-0001).
#
# Why Merge Incrementally:
#   - Loading all JSON files into memory at once can cause resource exhaustion.
#   - Incremental merging processes files in smaller chunks, reducing memory usage 
#     and ensuring efficient handling of large datasets.
#
# Requirements:
#   - `curl` for HTTP requests.
#   - `jq` for JSON processing.
#   -  8 GB RAM, 40 GB free local storage (Ubuntu)
#
# Usage:
#   1. Replace `YOUR_API_KEY` with your valid NVD API key.
#   2. Run the script: `./nvd_json.sh`.
#   3. Optionally, schedule the script using cron for periodic updates.
#
# Example Cron Job:
#   0 2 * * * /path/to/nvd_json.sh >> /path/to/nvd_update.log 2>&1
#
# API References:
#   - API Developers Getting Started:  https://nvd.nist.gov/developers/start-here
#   - API Documentation: https://nvd.nist.gov/developers/vulnerabilities
#   - API Endpoint: https://services.nvd.nist.gov/rest/json/cves/2.0
#
# Author: Orlando Stevenson
# Date: 01.26.2025
# Version: 1.0
################################################################################

# Variables
DATA_DIR="$HOME/nvd_data"                           # Directory for storing CVE data
API_URL="https://services.nvd.nist.gov/rest/json/cves/2.0"  # NVD API endpoint
API_KEY="Replace with your valid API key"	    # Replace with your valid API key
RESULTS_PER_PAGE=1000                               # Number of results per page
MASTER_FILE="$DATA_DIR/local_nvd_data.json"         # Merged JSON file for all CVE data
META_FILE="$DATA_DIR/last_update.meta"              # File to track last update timestamp
OLDEST_DATE="1999-01-01T00:00:00.000Z"              # Oldest CVE date (CVE-1999-0001)

# Ensure data directory exists
mkdir -p "$DATA_DIR"

################################################################################
# Function: fetch_quarterly_data
# Purpose:
#   Fetch CVEs for a given quarter using `pubStartDate` and `pubEndDate`.
################################################################################
fetch_quarterly_data() {
    local pub_start_date=$1
    local pub_end_date=$2
    local year=$3
    local quarter=$4
    local start_index=0
    local quarterly_file="$DATA_DIR/nvdcve-${year}-Q${quarter}.json"

    echo "Fetching CVE data published from $pub_start_date to $pub_end_date..."

    # Paginated requests for the published data
    while :; do
        response=$(curl -s -H "apiKey:$API_KEY" -G "$API_URL" \
            --data-urlencode "resultsPerPage=$RESULTS_PER_PAGE" \
            --data-urlencode "startIndex=$start_index" \
            --data-urlencode "pubStartDate=$pub_start_date" \
            --data-urlencode "pubEndDate=$pub_end_date")

        # Check for valid response
        if [[ -z "$response" || $(echo "$response" | jq '.vulnerabilities | length') -eq 0 ]]; then
            echo "No CVE data found for this range."
            break
        fi

        # Save the data into the quarterly JSON file
        echo "$response" | jq '.vulnerabilities' >> "$quarterly_file"

        # Parse total results and handle pagination
        total_results=$(echo "$response" | jq '.totalResults')
        start_index=$((start_index + RESULTS_PER_PAGE))

        # Break if all results are fetched
        if [[ $start_index -ge $total_results ]]; then
            break
        fi

        # Ensure rate limit compliance with up to 50 requests every 30 seconds when using API key - at least sleep 0.6.
	# NIST recommends users "sleep" their scripts for six seconds between requests.  
        sleep 6

    done
}

################################################################################
# Function: merge_cve_data
# Purpose:
#   Incrementally merge all JSON files into a single file.
################################################################################
merge_cve_data() {
    echo "Merging all CVE data into a single file in chunks..."
    local json_files=("$DATA_DIR"/nvdcve-*.json)
    local temp_master="$MASTER_FILE.tmp"

    # Initialize the master file
    > "$MASTER_FILE"

    # Merge files incrementally
    for file in "${json_files[@]}"; do
        echo "Merging $file..."
        jq -s 'reduce .[] as $item ([]; . + $item)' "$MASTER_FILE" "$file" > "$temp_master"
        mv "$temp_master" "$MASTER_FILE"
    done

    echo "Merged data saved to $MASTER_FILE."
}

################################################################################
# Main Function
################################################################################
main() {
    echo "Starting NVD incremental update process using REST API v2.0..."

    if [[ -f "$META_FILE" ]]; then
        mod_start_date=$(cat "$META_FILE")
        mod_end_date=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
        fetch_incremental_updates "$mod_start_date" "$mod_end_date"
        echo "$mod_end_date" > "$META_FILE"
    else
        for year in $(seq 1999 $(date +"%Y")); do
            fetch_quarterly_data "${year}-01-01T00:00:00.000Z" "${year}-03-31T23:59:59.999Z" "$year" "Q1"
            fetch_quarterly_data "${year}-04-01T00:00:00.000Z" "${year}-06-30T23:59:59.999Z" "$year" "Q2"
            fetch_quarterly_data "${year}-07-01T00:00:00.000Z" "${year}-09-30T23:59:59.999Z" "$year" "Q3"
            fetch_quarterly_data "${year}-10-01T00:00:00.000Z" "${year}-12-31T23:59:59.999Z" "$year" "Q4"
        done
        mod_end_date=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
        echo "$mod_end_date" > "$META_FILE"
    fi

    merge_cve_data
    echo "NVD update process completed successfully."
}

main

