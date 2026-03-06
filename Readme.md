# AIRMAN Skynet Ops Audit Service

This is a minimal backend service built for the AIRMAN Cloud Ops Intern Technical Assessment. It ingests and stores operational/audit events for the Skynet ecosystem.

## Architecture Overview
This service is designed with strict cost-awareness for a pilot workload (5,000 - 20,000 requests/day). 
* **Compute:** AWS ECS Fargate (Serverless, scales to zero if needed)
* **Storage:** Amazon DynamoDB (On-Demand pricing to avoid idle DB costs)
* **Observability:** Amazon CloudWatch Logs (7-day retention)
* **Networking:** Public subnet deployment to entirely avoid NAT Gateway hourly costs.

## Local Development Setup
1. Install dependencies:
   ```bash
   npm install
   ```
2. Create a `.env` file based on the provided example:
   ```bash
   cp .env.example .env
   ```
3. Run the service locally (defaults to an in-memory store for local testing):
   ```bash
   node index.js
   ```

## Running via Docker
1. Build the image:
   ```bash
   docker build -t skynet-ops-audit-service .
   ```
2. Run the container:
   ```bash
   docker run -p 3000:3000 -e METRICS_DEMO_ENABLED=true -e PORT=3000 skynet-ops-audit-service
   ```

## Cloud Deployment (Terraform)
1. Navigate to the `infrastructure` directory:
   ```bash
   cd infrastructure
   ```
2. Initialize and apply the Terraform configuration:
   ```bash
   terraform init
   terraform apply
   ```

## ⚠️ Teardown / Cleanup
To prevent ongoing cloud costs, destroy all AWS resources when testing is complete:
```bash
cd infrastructure
terraform destroy -auto-approve
```