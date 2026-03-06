# Ops Runbook: Skynet Ops Audit Service

## 1. Service down / health checks failing
* [cite_start]**Symptoms:** `GET /health` times out or returns 502/503[cite: 499].
* **Actions:** 1. Check ECS Cluster Tasks via AWS Console or CLI (`aws ecs list-tasks`). Ensure `desired_count` is 1 and the task is `RUNNING`.
  2. If the task is crash-looping (`PENDING` -> `STOPPED`), inspect CloudWatch logs for startup errors (e.g., missing environment variables).
  3. Validate IAM task execution roles have permissions to pull the ECR image.

## 2. Latency spike
* [cite_start]**Symptoms:** API response times exceed typical SLAs (< 500ms for POST)[cite: 266, 500].
* **Actions:**
  1. Check DynamoDB metrics for throttling. (Though On-Demand scales automatically, an aggressive sudden burst might cause brief throttling).
  2. Review application logs for slow operations or check if `METRICS_DEMO_ENABLED` is set to `true` and the `?mode=slow` endpoint is being hit.
  3. If compute-bound, update the Terraform task definition to 0.5 vCPU and re-apply.

## 3. Sudden cost spike
* [cite_start]**Symptoms:** AWS Billing Alerts trigger unexpectedly[cite: 501].
* **Actions:**
  1. Check AWS Cost Explorer.
  2. If the spike is in CloudWatch, verify the 7-day retention policy is active and check application logs for excessive error spam.
  3. If the spike is in DynamoDB, check for an unexpected surge in traffic or a runaway script hitting the `GET /events` endpoint without limits.

## 4. DB/storage issue
* [cite_start]**Symptoms:** `POST /events` returns 500 errors; logs show `AccessDeniedException` or AWS SDK timeouts[cite: 502].
* **Actions:**
  1. Verify the IAM Task Role (`DynamoDBAccessPolicy`) still has `dynamodb:PutItem` permissions for the specific table ARN.
  2. Verify the `DYNAMODB_TABLE_NAME` environment variable matches the live AWS resource name exactly.

## 5. Bad deployment / rollback
* [cite_start]**Symptoms:** New container version causes immediate crashes[cite: 503].
* **Actions:**
  1. Revert the code change locally.
  2. Build and push the previous known-good Docker image to ECR.
  3. Force a new deployment in ECS: `aws ecs update-service --cluster skynet-ops-audit-service-cluster --service skynet-ops-audit-service-service --force-new-deployment`.

## 6. Accidental public exposure / misconfiguration
* [cite_start]**Symptoms:** Unauthorized traffic detected hitting the endpoint[cite: 504].
* **Actions:**
  1. Go to EC2 Security Groups and locate `${service_name}-sg`.
  2. Immediately remove the `0.0.0.0/0` ingress rule.
  3. Update Terraform (`ecs.tf`) to restrict ingress to a specific trusted IP range.