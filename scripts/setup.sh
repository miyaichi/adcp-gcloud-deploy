#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}AdCP Google Cloud Deployment Setup${NC}"
echo "========================================="
echo ""

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${RED}Please edit .env file with your actual values before continuing.${NC}"
    exit 1
fi

# Load environment variables
source .env

# Check if required variables are set
if [ -z "$GCP_PROJECT_ID" ] || [ "$GCP_PROJECT_ID" = "your-gcp-project-id" ]; then
    echo -e "${RED}Error: GCP_PROJECT_ID is not set in .env file${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Environment variables loaded${NC}"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: Google Cloud SDK is not installed${NC}"
    echo "Please install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo -e "${GREEN}✓ Google Cloud SDK is installed${NC}"

# Set GCP project
echo -e "${YELLOW}Setting GCP project to $GCP_PROJECT_ID...${NC}"
gcloud config set project $GCP_PROJECT_ID

# Enable required APIs
echo -e "${YELLOW}Enabling required Google Cloud APIs...${NC}"
gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    sqladmin.googleapis.com \
    compute.googleapis.com \
    secretmanager.googleapis.com \
    containerregistry.googleapis.com

echo -e "${GREEN}✓ APIs enabled${NC}"

# Check if service account key file exists
if [ -n "$GCP_SA_KEY" ] && [ "$GCP_SA_KEY" != "your-service-account-key-in-json-format" ]; then
    echo "$GCP_SA_KEY" > ${HOME}/gcp-key.json
    gcloud auth activate-service-account --key-file=${HOME}/gcp-key.json
    echo -e "${GREEN}✓ Service account authenticated${NC}"
fi

# Create Cloud SQL instance (if not exists)
echo -e "${YELLOW}Checking Cloud SQL instance...${NC}"
if ! gcloud sql instances describe $CLOUD_SQL_INSTANCE_NAME --project=$GCP_PROJECT_ID &> /dev/null; then
    echo -e "${YELLOW}Creating Cloud SQL instance (this may take several minutes)...${NC}"
    gcloud sql instances create $CLOUD_SQL_INSTANCE_NAME \
        --database-version=POSTGRES_15 \
        --tier=db-f1-micro \
        --region=$GCP_REGION \
        --root-password=$CLOUD_SQL_PASSWORD \
        --backup \
        --backup-start-time=03:00
    
    echo -e "${GREEN}✓ Cloud SQL instance created${NC}"
else
    echo -e "${GREEN}✓ Cloud SQL instance already exists${NC}"
fi

# Create database
echo -e "${YELLOW}Creating database...${NC}"
gcloud sql databases create $CLOUD_SQL_DATABASE_NAME \
    --instance=$CLOUD_SQL_INSTANCE_NAME \
    2>/dev/null || echo -e "${GREEN}✓ Database already exists${NC}"

# Create database user
echo -e "${YELLOW}Creating database user...${NC}"
gcloud sql users create $CLOUD_SQL_USER \
    --instance=$CLOUD_SQL_INSTANCE_NAME \
    --password=$CLOUD_SQL_PASSWORD \
    2>/dev/null || echo -e "${GREEN}✓ User already exists${NC}"

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Test locally: docker-compose up"
echo "2. Deploy to Cloud Run: git push origin main"
echo "3. Check GitHub Actions for deployment status"
echo ""
