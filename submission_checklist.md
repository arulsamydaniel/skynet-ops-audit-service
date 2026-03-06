# AIRMAN Skynet Cloud Ops Intern Assessment Submission Checklist

## 1) Candidate & Submission Info
* **Name:** Daniel Arulsamy
* **Email:** arulsamydaniel@gmail.com
* **Chosen Cloud Platform:** AWS
* **Assessment Level Submitted:** Level 1 only
* **Level 2 Option Chosen (if any):** N/A
* **GitHub Repo Link:** https://github.com/arulsamydaniel/skynet-ops-audit-service.git
* **Demo Video Link (optional but recommended):** * **Submission Date (UTC):** 2026-03-06

## 2) What I Implemented (Summary)
### Level 1
* [x] Mini service (`/health`, `/events`, `/events`)
* [x] Dockerized service
* [x] Cloud deployment (real or IaC-backed deploy plan)
* [x] Infrastructure as Code
* [x] Cost optimization report
* [x] Observability setup (or documented implementation)
* [x] Security/secrets approach
* [x] Ops runbook
* [x] README with setup + teardown

## 3) Repository Structure
### Service Code
* Service path: `./`
* Main entry file: `index.js`
* Local run command: `node index.js`

### Docker
* Dockerfile path: `./Dockerfile`
* `.dockerignore` path: `./.dockerignore`

### Infrastructure as Code
* IaC tool used: Terraform
* IaC root path: `./infrastructure/`
* Environment config files (`*.tfvars` etc.): Variables defined directly in `variables.tf`

### Docs
* README path: `./README.md`
* Cost report path: `./cost_optimization_report.md`
* Runbook path: `./ops_runbook.md`
* Observability notes/dashboard path: Included in README / Cost Report
* Security/secrets notes path: Included in README / Cost Report

## 4) Local Run Instructions (quick copy)
### Prerequisites
* [x] Docker installed
* [x] Language runtime installed (Node.js 18+)
* [x] Terraform installed
* [x] Cloud CLI installed (AWS CLI)

### Local Setup
```bash
npm install
cp .env.example .env
```
### Run Service Locally
```bash
node index.js
# OR via Docker:
docker build -t skynet-ops-audit-service .
docker run -p 3000:3000 -e METRICS_DEMO_ENABLED=true -e PORT=3000 skynet-ops-audit-service
```
### Test Endpoints Locally
```bash
curl http://localhost:3000/health
curl "http://localhost:3000/metrics-demo?mode=slow"
```

## 5) API Endpoint Checklist (Functional Validation)
* **Health**
  * [x] `GET /health` works
* **Events**
  * [x] `POST /events` stores an event
  * [x] `GET /events` returns events
  * [x] validation rejects bad payloads (400)
* **Optional**
  * [x] `GET /metrics-demo` implemented
  * [x] route can simulate latency/errors for observability testing

## 6) Cloud Deployment Summary
* **Deployment Type:** Real cloud deployment
* **Compute:** AWS ECS Fargate (0.25 vCPU, 512MB RAM)
* **Storage/DB:** Amazon DynamoDB (On-Demand)
* **Networking/Ingress:** VPC Public Subnet with Auto-assigned Public IP (No NAT Gateway)
* **Logging/Monitoring:** Amazon CloudWatch (7-day retention)
* **Secrets:** Environment variables passed via ECS Task Definition, no secrets in codebase
* **Budgeting/Alerts:** Documented in cost report
* **Container Registry:** Amazon ECR
* **IAM / Service Account:** Least-privilege Task Role scoped strictly to the DynamoDB table ARN

**Why I chose this architecture:**
* Serverless components (Fargate, DynamoDB On-Demand) entirely eliminate paying for idle compute time.
* Assigning a Public IP to the task avoids the guaranteed ~$32/month fixed cost of a NAT Gateway, keeping the pilot well within the $25-$75 budget constraint.

## 7) Cost Optimization Report (Mandatory)
* [x] Monthly estimate included
* [x] Assumptions documented
* [x] Component-wise cost breakdown included
* Common Cost Traps I accounted for:
  1. Idle compute instances (Used Serverless Fargate)
  2. Overprovisioned managed DBs (Used DynamoDB On-Demand)
  3. NAT gateway/egress costs (Used Public IP assignment)
  4. Snapshots and unattached disks (Used ephemeral container storage)
  5. Static IPs / load balancers left running (Skipped ALB for this minimal pilot)
  6. Excessive logging/trace volume (7-day CloudWatch retention)
  7. Cross-region traffic (Confined to a single region)
  8. Container registry storage accumulation (Mutable tags used to overwrite old images)

## 8) Observability & Monitoring (Mandatory)
* [x] Structured logs implemented
* [x] Log level configurable
* [x] Sample logs included (Visible in CloudWatch)
* [x] Request latency metric / Health signal monitoring (`/health` and `/metrics-demo` created for testing)

## 9) Security / Secrets / IAM (Mandatory)
* [x] No secrets committed to repo
* [x] `.env.example` included
* [x] Service permissions listed
* [x] Least-privilege approach explained

## 10) Ops Runbook (Mandatory)
* Runbook file path: `./ops_runbook.md`
* Covered scenarios:
  * [x] Service down / health checks failing
  * [x] Latency spike
  * [x] Sudden cost spike
  * [x] DB/storage issue
  * [x] Bad deployment / rollback
  * [x] Accidental public exposure / misconfiguration

## 11) IaC Validation / Reproducibility
* [x] `terraform init` works
* [x] `terraform validate` works
* [x] `terraform plan` works
* [x] Variables documented
* [x] Outputs documented
* [x] Destroy/cleanup steps documented

## 12) Known Limitations / Trade-offs (Mandatory)
1. **Single Availability Zone/Region:** To optimize costs for the pilot, this does not have enterprise-grade Multi-AZ high availability.
2. **No Load Balancer:** To avoid the ~$16-$22/mo ALB cost, tasks are accessed directly via their ephemeral public IPs. In a production environment, an ALB would be required.
3. **Database Scans:** The `GET /events` route uses a DynamoDB Scan operation for simplicity in this minimal ops service. In a full production environment, this should be converted to a Query with a Global Secondary Index (GSI) for performance.

## 13) AI Tool Usage Disclosure (Mandatory)
* **AI tools used:** Gemini
* **What I used AI for:** Assistance in architecting the cost-optimized AWS infrastructure (Fargate/DynamoDB), generating the Terraform boilerplate, and structuring the operational documentation.
* **What I manually verified / tested:** I manually wrote the application code execution flows, locally tested the Docker container, manually verified AWS CLI credentials, and executed all Terraform provisioning and curl tests against the live AWS endpoints to ensure the architecture functioned as intended.