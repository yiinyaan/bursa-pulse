#!/bin/bash
# Bursa Pulse Daily Pipeline
# Runs every weekday at 6PM MYT after Bursa Malaysia market close

set -e

LOG_FILE="/home/user/bruin/bursa-pulse/orchestration/pipeline.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] Starting Bursa Pulse pipeline..." >> $LOG_FILE

# Activate dbt environment
source /home/user/bruin/bursa-pulse/dbt-env/bin/activate

# Run dbt transformations
echo "[$TIMESTAMP] Running dbt models..." >> $LOG_FILE
dbt run --project-dir /home/user/bruin/bursa-pulse/dbt/bursa_pulse --profiles-dir /home/user/.dbt >> $LOG_FILE 2>&1

# Run dbt tests
echo "[$TIMESTAMP] Running dbt tests..." >> $LOG_FILE
dbt test --project-dir /home/user/bruin/bursa-pulse/dbt/bursa_pulse --profiles-dir /home/user/.dbt >> $LOG_FILE 2>&1

echo "[$TIMESTAMP] Pipeline completed successfully." >> $LOG_FILE
