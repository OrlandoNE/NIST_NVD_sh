# NVD JSON Data Update Script with Historical and Incremental Updates

## Overview
This script automates the process of retrieving and maintaining a local repository of National Vulnerability Database (NVD) CVE data using the NVD REST API v2.0. It supports historical data retrieval from 1999 onward and efficiently updates the local dataset with only modified CVEs in subsequent runs. The script ensures compliance with API restrictions, such as the 120-day date range limit, while offering features to handle large datasets with optimal resource usage.

## Features
- **Historical Data Fetching**: Dynamically fetches CVE data year by year and quarter by quarter using `pubStartDate` and `pubEndDate` during the initial setup.
- **Incremental Updates**: Tracks the last successful update date and fetches only modified CVEs using `modStartDate` and `modEndDate` in subsequent runs.
- **Paginated Response Handling**: Automatically handles API pagination to retrieve all CVE data within a given range.
- **Data Storage**: Saves data quarterly in JSON files for modular and efficient analysis.
- **Merging Support**: Supports merging incremental updates for comprehensive data management.
- **Full Historical Coverage**: Includes all CVEs starting from CVE-1999-0001.

## Why Incremental Merging?
- **Efficiency**: Loading all JSON files into memory at once can cause resource exhaustion. Incremental merging processes smaller chunks of data, reducing memory usage and improving performance.
- **Scalability**: Ensures the script can handle large datasets without overwhelming system resources.

## Requirements
- **Software**:
  - `curl`: For HTTP requests.
  - `jq`: For JSON processing.
- **System**:
  - Minimum 8 GB RAM.
  - 40 GB free local storage.
  - Tested on Ubuntu.

## Usage
1. Replace `YOUR_API_KEY` with your valid NVD API key.
2. Make the script executable:  
   ```bash
   chmod +x nvd_json.sh
