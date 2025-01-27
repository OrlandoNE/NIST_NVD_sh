# NIST_NVD_sh
NIST NVD JSON Data Update Script with Historical and Incremental Update - REST API v2.0
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
