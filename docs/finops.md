# FinOps — Cost Management & Governance

## Overview

Cost awareness is a core platform engineering discipline. This document covers the cost strategy, actual spend, and governance controls implemented for this project.

The goal was to build a production-grade, cross-cloud platform at effectively zero cost — and to implement the same cost governance controls you would find in a real enterprise environment.

---

## Actual Cost

### AWS (Month to date)
| Service | Cost |
|---|---|
| Amazon CloudFront | $0.00 |
| Amazon S3 | $0.00 |
| Amazon DynamoDB | $0.00 |
| AWS Key Management Service | $0.00 |
| **Total** | **$0.00** |

### Azure (Month to date, cloud-portfolio-rg)
| Service | Cost |
|---|---|
| Azure Functions | ~$0.00 |
| Azure Storage Account | ~£0.01 |
| **Total** | **~£0.01** |

**Total cross-cloud monthly cost: effectively £0.01**

This confirms the architecture was designed cost-efficiently from the start — using serverless and managed services that have generous free tiers, with no idle compute running 24/7.

---

## Why It Costs Almost Nothing

| Service | Free Tier | Usage |
|---|---|---|
| AWS S3 | 5GB storage, 20k requests/month | Single HTML file, minimal requests |
| AWS CloudFront | 1TB transfer, 10M requests/month | Portfolio traffic levels |
| Azure Functions | 1M executions/month (always free) | A few hundred calls |
| Azure Table Storage | Pay per GB | Kilobytes of data |
| GitHub Actions | 2000 mins/month | A few minutes per deploy |
| Grafana Cloud | 10k metrics, 50GB logs (always free) | Well within limits |

The architecture deliberately avoids:
- Always-on virtual machines (EC2, Azure VMs)
- Managed databases with minimum charges (RDS, Azure SQL)
- NAT Gateways (significant hidden cost in VPC setups)
- Data transfer charges between regions

---

## Cost Governance

### AWS Budget Alert
A $5 monthly budget is configured in AWS Budgets with:
- **80% alert** ($4) — email notification sent
- **100% action** ($5) — automated kill switch triggered

### AWS Kill Switch
At 100% threshold ($5), AWS Budgets automatically applies the `DenyCloudPortfolioResources` IAM policy via the `AWSBudgetsActionRole`, which denies all access to:
- `s3:*` — blocks site delivery
- `cloudfront:*` — blocks CDN
- `dynamodb:*` — blocks Terraform state

This effectively shuts down the portfolio infrastructure without any manual intervention. Once triggered, the policy must be manually removed to restore access — a deliberate friction point to prevent runaway spend.

### Why the AWS Kill Switch Covers Azure Too
Because the portfolio site is served from CloudFront (AWS), blocking S3 and CloudFront means the browser never loads the page. Since the Azure Functions are only called by JavaScript in the browser, they receive zero traffic when the site is inaccessible. Azure spend stops naturally without needing a separate kill switch.

### Azure Budget Alert
A separate $5 budget is configured in Azure Cost Management covering the full Azure subscription. An alert is sent at 80% spend. This acts as an early warning for any unexpected Azure charges across all projects.

---

## Cost Projections

| Traffic Level | Estimated Monthly Cost |
|---|---|
| Portfolio (current) | ~£0.01 |
| 10,000 visitors/month | ~£0.05 |
| 100,000 visitors/month | ~£0.50 |
| 1,000,000 visitors/month | ~£5.00 |

The architecture scales linearly and cost-efficiently. CloudFront and Azure Functions both scale automatically with no infrastructure changes required.

---

## Future Cost Considerations

**Custom domain (~£10/year)**
Adding a custom domain requires a Route53 hosted zone ($0.50/month) plus domain registration (~£10/year). This is the only planned cost increase.

**Grafana Cloud free tier limits**
Grafana Cloud free tier supports 10,000 active metric series and 14-day retention. At current traffic levels this will never be exceeded. If the project were to scale significantly, a paid Grafana tier or self-hosted Grafana on a small VM would be the next consideration.

**Azure Key Vault (future security improvement)**
Moving secrets to Azure Key Vault would add a small cost (~$0.03/10,000 operations) — negligible at portfolio scale but worth noting.

---

## Lessons Learned

**Design for cost from day one.** Choosing serverless (Azure Functions consumption plan, CloudFront) over always-on compute eliminated the largest potential cost driver before writing a single line of infrastructure code.

**Free tiers are genuinely sufficient for portfolio projects.** AWS and Azure both offer permanent free tiers for the services used here — not just 12-month trials. The misconception that cloud is expensive comes from over-provisioning, not the platforms themselves.

**Automated governance matters more than manual monitoring.** Setting up the kill switch took 15 minutes and means cost overruns are impossible without manual intervention. Checking bills manually is not governance — automation is.

**The $0.00 bill is proof of good architecture.** In a real platform engineering role, cost efficiency is a deliverable, not an afterthought. This project demonstrates that production-grade infrastructure doesn't require significant spend.
