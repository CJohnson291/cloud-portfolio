# Cloud CV Project — Write-up

## What It Was

A serverless resume API built on Azure Functions, extended with a real-time monitoring pipeline using Application Insights, Azure Monitor, and Terraform.

Every time someone hit the `/api/getresume` endpoint, Azure logged the request, evaluated a KQL alert rule on a schedule, and fired an email notification via an Action Group.

**Stack:** Azure Functions · Application Insights · Azure Monitor · KQL · Action Groups · Terraform

---

## Architecture

```
User
  ↓
Azure Function App (/api/getresume)
  ↓ logs
Application Insights
  ↓ KQL scheduled query
Azure Monitor Alert Rule
  ↓
Action Group (Email notification)
```

---

## The Terraform Drift Incident

### What Happened

During troubleshooting, a resource group needed to be destroyed and recreated in a different region. The new resource group was created manually in the Azure portal before Terraform had destroyed the old one.

This caused **Terraform drift** — the real state of Azure no longer matched what Terraform had in its state file. Specifically:

- The old resource group refused to delete (Azure blocked destruction due to dependent resources)
- The new resource group existed in Azure but was unknown to Terraform — no output, no state entry
- Terraform was now out of sync with reality on both sides

### What Drift Actually Means

Drift occurs when infrastructure changes outside of Terraform — in this case by manually creating a resource in the portal. Terraform's state file is its source of truth. When reality diverges from that file, Terraform either tries to destroy things that shouldn't be destroyed or fails to manage things it doesn't know exist.

This is exactly why infrastructure changes should always go through IaC rather than the portal — even when it feels faster to click.

### How It Was Resolved

**Step 1 — Remove ghost resources from state**

The old resource group was stuck. Rather than force-deleting it and risking data loss, the resource was removed from Terraform state so Terraform would stop trying to manage it:

```bash
terraform state rm azurerm_resource_group.monitoring
```

**Step 2 — Import the existing resource group**

The new resource group already existed in Azure but Terraform didn't know about it. The `terraform import` command was used to bring it into state:

```bash
terraform import azurerm_resource_group.monitoring \
  /subscriptions/<subscription-id>/resourceGroups/rg-resume-monitoring
```

After this, Terraform recognised the existing resource and could manage it going forward without recreating it.

**Step 3 — Verify alignment**

```bash
terraform plan
```

A clean plan with no unexpected changes confirmed that Terraform state and Azure reality were back in sync.

---

## Other Lessons Learned

**KQL query targeting** — the alert wasn't firing initially because the KQL query was running against Resource Graph instead of Application Insights Logs. Switching to `contains` instead of `endswith` and verifying the Function App was actually logging requests resolved it.

**Validating monitoring pipelines layer by layer** — monitoring pipelines fail silently. The lesson was to validate each layer independently: confirm logs exist, confirm the query matches, confirm the alert evaluates, confirm the action group fires. Assuming the whole pipeline works end-to-end without checking each step is how alerts get missed in production.

**Portal vs IaC discipline** — the drift was self-inflicted by using the portal as a shortcut. The fix reinforced why all infrastructure changes should go through Terraform, even during debugging.

---

## What I'd Do Differently

- Never create or modify resources in the portal when Terraform is managing them
- Use `terraform plan -out=tfplan` before any destructive operation to review exactly what will be destroyed
- Add resource locks to critical resource groups to prevent accidental deletion
- Structure Terraform modules so monitoring resources are separated from application resources — easier to destroy and recreate independently

---

## Project Status

Decommissioned. The infrastructure no longer exists but the code and documentation are preserved in the repository.

The monitoring pipeline was validated end-to-end before decommission — logs flowing, KQL query firing, alert triggering, email received.
