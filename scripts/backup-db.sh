#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}AdCP Database Backup${NC}"
echo "===================================="
echo ""

# Load environment variables
if [ ! -f .env ]; then
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

source .env

# Check if required variables are set
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$CLOUD_SQL_INSTANCE_NAME" ]; then
    echo -e "${RED}Error: Required environment variables are not set${NC}"
    exit 1
fi

# Set backup filename with timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="adcp_backup_${TIMESTAMP}.sql"
BACKUP_DIR="./backups"

# Create backup directory if not exists
mkdir -p $BACKUP_DIR

echo -e "${YELLOW}Creating database backup...${NC}"
echo "Project: $GCP_PROJECT_ID"
echo "Instance: $CLOUD_SQL_INSTANCE_NAME"
echo "Database: $CLOUD_SQL_DATABASE_NAME"
echo "Output: $BACKUP_DIR/$BACKUP_FILE"
echo ""

# Export database
gcloud sql export sql $CLOUD_SQL_INSTANCE_NAME \
    gs://${GCP_PROJECT_ID}-adcp-backups/${BACKUP_FILE} \
    --database=$CLOUD_SQL_DATABASE_NAME \
    --project=$GCP_PROJECT_ID \
    2>/dev/null || {
        echo -e "${YELLOW}Cloud Storage bucket not found. Creating...${NC}"
        gsutil mb -p $GCP_PROJECT_ID -l $GCP_REGION gs://${GCP_PROJECT_ID}-adcp-backups
        gcloud sql export sql $CLOUD_SQL_INSTANCE_NAME \
            gs://${GCP_PROJECT_ID}-adcp-backups/${BACKUP_FILE} \
            --database=$CLOUD_SQL_DATABASE_NAME \
            --project=$GCP_PROJECT_ID
    }

# Download backup locally
echo -e "${YELLOW}Downloading backup file...${NC}"
gsutil cp gs://${GCP_PROJECT_ID}-adcp-backups/${BACKUP_FILE} $BACKUP_DIR/

echo ""
echo -e "${GREEN}===================================="
echo -e "Backup completed successfully!${NC}"
echo -e "${GREEN}===================================="
echo ""
echo "Backup file: $BACKUP_DIR/$BACKUP_FILE"
echo "Cloud Storage: gs://${GCP_PROJECT_ID}-adcp-backups/${BACKUP_FILE}"
echo ""

# Clean up old backups (keep last 7 days)
echo -e "${YELLOW}Cleaning up old backups (keeping last 7 days)...${NC}"
find $BACKUP_DIR -name "adcp_backup_*.sql" -mtime +7 -delete
gsutil ls gs://${GCP_PROJECT_ID}-adcp-backups/ | \
    grep "adcp_backup_" | \
    head -n -7 | \
    xargs -r gsutil rm

echo -e "${GREEN}✓ Old backups cleaned up${NC}"
echo ""
