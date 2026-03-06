# Cost Optimization Report: Skynet Ops Audit Service

## Cost Estimate Summary
[cite_start]This architecture was explicitly designed to operate safely within the $25-$75/month pilot budget [cite: 292-294]. [cite_start]By utilizing a serverless approach, the estimated monthly cost for the pilot workload (5k-20k requests/day) is well under the budget [cite: 205-207].

| Component | Service | Estimated Cost / Month |
| :--- | :--- | :--- |
| **Compute** | AWS ECS Fargate (0.25 vCPU, 512MB RAM) | ~$8.00 |
| **Database** | AWS DynamoDB (On-Demand / PAY_PER_REQUEST) | < $1.00 |
| **Storage** | AWS ECR (1 image, ~50MB) | < $0.50 |
| **Logging** | CloudWatch Logs (7-day retention) | < $1.00 |
| **Networking** | VPC (Public Subnet, No NAT Gateway) | $0.00 |
| **Total** | | **~$10.50 / month** |

## Cost Controls Implemented
* [cite_start]**Non-prod shutdown / scale-to-zero strategy:** Fargate desired count can easily be scaled to 0 outside of testing hours [cite: 275-276, 452].
* [cite_start]**Log retention policy:** CloudWatch log groups are explicitly limited to 7 days to prevent infinite storage accumulation [cite: 284-286, 451].
* [cite_start]**Teardown (destroy) instructions:** Full `terraform destroy` commands are documented in the README[cite: 454].
* [cite_start]**Tags / labels for cost tracking:** Terraform automatically tags resources with `Environment` and `Service` labels[cite: 450].

## Common Cost Traps Accounted For
1. **Idle compute instances:** Avoided by using serverless Fargate instead of always-on EC2 instances.
2. **Overprovisioned managed DBs:** Avoided by using DynamoDB On-Demand rather than a fixed RDS instance.
3. **Excessive logging/trace volume:** Avoided by configuring the app to only log essential structured data and capping CloudWatch retention.
4. [cite_start]**NAT gateway/egress costs:** Avoided by assigning a public IP to the Fargate task in a public subnet, entirely bypassing the NAT Gateway base charge[cite: 306].
5. [cite_start]**Snapshots and unattached disks:** Fargate uses ephemeral storage, eliminating orphaned EBS volume costs[cite: 307].
6. [cite_start]**Static IPs / load balancers left running:** Using ephemeral AWS public IPs instead of Elastic IPs or costly ALBs for this basic pilot[cite: 307].
7. [cite_start]**Cross-region traffic:** Everything is contained within a single region (`us-east-1`) [cite: 310-311].
8. [cite_start]**Container registry storage accumulation:** Enabled ECR image scanning and mutable tags so old images can be overwritten or cleaned up[cite: 312].