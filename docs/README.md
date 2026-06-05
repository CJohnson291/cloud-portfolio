# Cloud Portfolio Platform

A production-grade, cross-cloud portfolio platform demonstrating infrastructure engineering across AWS and Azure. Every resource is provisioned via Terraform, every deployment is automated via GitHub Actions, and the entire stack is observable via Grafana Cloud.

**Live site:** https://d3rqh12vcebb1z.cloudfront.net  
**Grafana dashboard:** https://peacefullily1526.grafana.net/public-dashboards/6efb2484ef524c059b3cceb033354293  
**GitHub:** https://github.com/CJohnson291

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Browser                             │
└──────────────────────────┬──────────────────────────────────┘
                           │
                ┌──────────▼──────────┐
                │   CloudFront (CDN)   │  HTTPS, edge caching,
                │   AWS / eu-west-2    │  security headers
                └──────────┬──────────┘
                           │
                ┌──────────▼──────────┐
                │     S3 Bucket        │  Static site hosting
                │   AWS / eu-west-2    │  Private, encrypted
                └─────────────────────┘

index.html (JavaScript)
        │
        ├──────────────────────────────────────────────────────┐
        │                                                      │
┌───────▼────────────┐                             ┌──────────▼──────────┐
│  /visitor_count    │                             │      /health         │
│  Azure Function    │                             │   Azure Function     │
│  Python 3.11       │                             │   Python 3.11        │
└───────┬────────────┘                             └──────────┬──────────┘
        │                                                     │
        └──────────────────┬──────────────────────────────────┘
                           │
                ┌──────────▼──────────┐
                │   Table Storage      │  Visitor count
                │   Azure / West EU    │  persistence
                └─────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     Grafana Cloud                           │
│   CloudWatch (AWS) ◄────────────────► Azure Monitor        │
│             Cross-cloud observability dashboard             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                          │
│   Push to site/ ──► Deploy to S3 + CloudFront invalidation  │
│   Push to api/  ──► Deploy to Azure Function App            │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                       Terraform                             │
│   S3 backend + DynamoDB locking for remote state            │
│   Manages all AWS and Azure resources                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Static hosting | AWS S3 |
| CDN | AWS CloudFront |
| API compute | Azure Functions (Python 3.11, Consumption plan) |
| Data persistence | Azure Table Storage |
| IaC | Terraform |
| Remote state | S3 + DynamoDB locking |
| CI/CD | GitHub Actions |
| Observability | Grafana Cloud (CloudWatch + Azure Monitor) |
| Security | CloudFront Response Headers Policy |

---

## Repository Structure

```
cloud-portfolio/
├── infra/                  # Terraform configuration
│   ├── main.tf             # Providers, backend configuration
│   ├── s3.tf               # S3 bucket + security settings
│   ├── cloudfront.tf       # CloudFront distribution + security headers
│   ├── azure.tf            # Azure resource group, storage, function app
│   └── outputs.tf          # Output values
├── site/                   # Static portfolio site
│   ├── index.html          # Single page application
│   └── badges/             # Certification badge images
├── api/                    # Azure Function code
│   ├── visitor_count/      # POST/GET visitor counter
│   ├── health/             # GET infrastructure health check
│   ├── system_check/       # GET system diagnostics
│   ├── host.json           # Function App configuration
│   └── requirements.txt    # Python dependencies
├── docs/                   # Architecture and technical documentation
│   ├── security-headers.md # CloudFront security headers implementation
│   └── cloud-cv-writeup.md # Cloud CV project write-up and lessons learned
└── .github/
    └── workflows/
        ├── deploy-aws.yml  # AWS deployment pipeline
        └── deploy-azure.yml # Azure deployment pipeline
```

---

## Design Decisions

### Why cross-cloud?
This project intentionally spans AWS and Azure rather than staying within a single provider. The reasoning is twofold — to build upon an existing Azure skill set while developing AWS proficiency, and to reflect real enterprise environments where multi-cloud is inherited rather than chosen. Managing provider boundaries in a single Terraform codebase is a skill that most single-cloud portfolio projects don't demonstrate.

### Why Terraform?
Terraform is the industry standard for infrastructure as code and is provider-agnostic — the same tooling manages both AWS and Azure resources in this project. This is a deliberate choice over provider-specific tools like AWS CloudFormation or Azure Bicep, which would have required two separate IaC systems to manage one project.

### Why Python for the Azure Functions?
Python was chosen over Node.js based on prior experience with Azure Functions runtime issues using Node.js. Python 3.11 is the recommended runtime for Azure Functions and has excellent support for the `azure-data-tables` SDK used for Table Storage access.

### Why a static site?
A static HTML/CSS/JS site with no framework was deliberately chosen. The deployment pipeline and infrastructure are the demonstration — not the frontend technology. A clean, dependency-free site is easier to version control, faster to deploy, and more appropriate for an infrastructure-focused portfolio.

---

## API Endpoints

All endpoints are hosted at `https://cloud-portfolio-api-cj.azurewebsites.net`

| Endpoint | Method | Description |
|---|---|---|
| `/api/visitor_count` | POST | Increments and returns total visitor count from Table Storage |
| `/api/health` | GET | Returns health status of all infrastructure components |
| `/api/system_check` | GET | Returns runtime diagnostics — region, uptime, Python version |

### Example responses

**`/api/health`**
```json
{
  "status": "healthy",
  "checks": {
    "api": true,
    "storage": true,
    "cloudfront": true,
    "pipeline": true
  }
}
```

**`/api/visitor_count`**
```json
{
  "count": 42
}
```

**`/api/system_check`**
```json
{
  "status": "operational",
  "region": "westeurope",
  "runtime": "Python 3.11.13",
  "uptime_minutes": 12.5,
  "function_app": "cloud-portfolio-api-cj",
  "storage_account": "cloudportfoliostcj",
  "timestamp": 1780405499
}
```

---

## Infrastructure

### AWS Resources
| Resource | Name | Purpose |
|---|---|---|
| S3 Bucket | `cloud-portfolio-site-cj` | Static site hosting |
| CloudFront Distribution | `E34NNLRYASC8XS` | CDN, HTTPS, security headers |
| S3 Bucket (state) | `cloud-portfolio-tfstate-cj` | Terraform remote state |
| DynamoDB Table | `cloud-portfolio-tfstate-lock` | Terraform state locking |

### Azure Resources
| Resource | Name | Purpose |
|---|---|---|
| Resource Group | `cloud-portfolio-rg` | Logical container |
| Storage Account | `cloudportfoliostcj` | Function App storage + Table Storage |
| Storage Table | `visitorcounts` | Visitor count persistence |
| Service Plan | `cloud-portfolio-plan` | Consumption plan (Y1) |
| Function App | `cloud-portfolio-api-cj` | Python API |

---

## Security

### CloudFront Security Headers
All HTTP responses include the following security headers, managed via a Terraform Response Headers Policy:

| Header | Value | Purpose |
|---|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | Enforce HTTPS for 1 year |
| `X-Frame-Options` | `DENY` | Prevent clickjacking |
| `X-XSS-Protection` | `1; mode=block` | Block XSS attacks |
| `X-Content-Type-Options` | `nosniff` | Prevent MIME sniffing |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Control referrer leakage |

Verify with:
```bash
curl -I https://d3rqh12vcebb1z.cloudfront.net
```

### CORS
The Azure Function API only accepts requests from the CloudFront domain. All other origins are blocked at the Function App level.

### Secrets Management
All credentials are stored as GitHub repository secrets and never committed to version control. The `.gitignore` excludes `.tfvars`, `.env`, and credential files from day one.

---

## CI/CD Pipelines

### AWS Deployment (`deploy-aws.yml`)
Triggered on push to `main` when files in `site/` change:
1. Configure AWS credentials from GitHub secrets
2. Sync `site/` to S3 bucket
3. Invalidate CloudFront cache (`/*`)

### Azure Deployment (`deploy-azure.yml`)
Triggered on push to `main` when files in `api/` change:
1. Login to Azure using service principal credentials
2. Setup Python 3.11
3. Install dependencies
4. Deploy to Azure Function App with remote build

---

## Observability

Grafana Cloud provides unified observability across both clouds:

- **AWS CloudWatch** → CloudFront request metrics
- **Azure Monitor** → Function App invocations and execution units

**Live dashboard:** https://peacefullily1526.grafana.net/public-dashboards/6efb2484ef524c059b3cceb033354293

---

## Known Improvements & Future Work

| Improvement | Priority | Notes |
|---|---|---|
| Custom domain | Medium | Route53 + ACM certificate, ~£10/year |
| Azure Key Vault | High | Move storage connection string out of app settings |
| AWS IAM least privilege | High | Scope GitHub Actions IAM user to minimum required permissions |
| Content Security Policy | Medium | Define strict CSP for fonts and API calls |
| Azure Function authentication | Medium | Add function keys or Azure AD authentication |
| Terraform CI/CD pipeline | Medium | Automate `terraform plan/apply` via GitHub Actions |
| Cost kill switch | High | AWS Budget Actions + Azure Cost Management alerts to auto-shutdown resources at threshold |

---

## Local Development

### Prerequisites
- Terraform >= 1.12
- AWS CLI >= 2.0 (configured with `aws configure`)
- Azure CLI >= 2.80 (authenticated with `az login`)
- Python 3.11

### Deploy infrastructure
```bash
cd infra
terraform init
terraform plan
terraform apply
```

### Deploy site manually
```bash
aws s3 sync site/ s3://cloud-portfolio-site-cj --delete
aws cloudfront create-invalidation --distribution-id E34NNLRYASC8XS --paths "/*"
```

### Deploy API manually
```bash
cd api
zip -r ../api.zip .
cd ..
az functionapp deployment source config-zip \
  --resource-group cloud-portfolio-rg \
  --name cloud-portfolio-api-cj \
  --src api.zip \
  --build-remote true
```

---

## Author

**Chris Johnson**  
Cloud & Platform Engineer  
[GitHub](https://github.com/CJohnson291) · [LinkedIn](https://www.linkedin.com/in/chris-johnson-63b538264)
