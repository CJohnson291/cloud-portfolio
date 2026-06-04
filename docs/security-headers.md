# CloudFront Security Response Headers

## Overview

Security response headers are implemented via an AWS CloudFront Response Headers Policy, managed entirely by Terraform. These headers are injected into every HTTP response served by the CloudFront distribution, enforcing browser-level security controls without any application code changes.

The policy is defined in `infra/cloudfront.tf` and applied to the default cache behaviour of the distribution.

---

## Headers Implemented

### `Strict-Transport-Security` (HSTS)
```
strict-transport-security: max-age=31536000; includeSubDomains
```
Forces browsers to only connect to the site over HTTPS, never HTTP. The `max-age=31536000` caches this rule in the browser for one year. Even if a user manually types `http://` the browser automatically upgrades to `https://`. The `includeSubDomains` directive extends this rule to all subdomains.

**Protects against:** Protocol downgrade attacks, SSL stripping.

---

### `X-Frame-Options`
```
x-frame-options: DENY
```
Prevents the site from being loaded inside an iframe on any other website. A value of `DENY` means no site — including the same origin — can embed this page in a frame.

**Protects against:** Clickjacking attacks, where a malicious site embeds a page invisibly and tricks users into clicking UI elements they cannot see.

---

### `X-XSS-Protection`
```
x-xss-protection: 1; mode=block
```
Activates the browser's built-in cross-site scripting (XSS) filter. If a reflected XSS attack is detected, `mode=block` instructs the browser to block the page from rendering entirely rather than attempting to sanitise the malicious content.

**Protects against:** Reflected cross-site scripting attacks.

---

### `X-Content-Type-Options`
```
x-content-type-options: nosniff
```
Prevents browsers from MIME-sniffing — guessing the content type of a response and overriding the declared `Content-Type` header. Forces the browser to respect the server's declared content type.

**Protects against:** MIME type confusion attacks where a browser might execute a file as JavaScript or HTML when it should not.

---

### `Referrer-Policy`
```
referrer-policy: strict-origin-when-cross-origin
```
Controls what information is included in the `Referer` header when navigating between pages. With this policy, only the origin (e.g. `https://d3rqh12vcebb1z.cloudfront.net`) is sent when crossing domains — not the full URL path. Nothing is sent when navigating from HTTPS to HTTP.

**Protects against:** Sensitive URL information leaking to third-party sites via the Referer header.

---

## Terraform Implementation

```hcl
resource "aws_cloudfront_response_headers_policy" "portfolio" {
  name = "cloud-portfolio-security-headers"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      override                   = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      frame_option = "DENY"
      override     = true
    }

    xss_protection {
      mode_block = true
      protection = true
      override   = true
    }

    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = true
    }
  }
}
```

The `override = true` setting on each header ensures CloudFront always injects the header, even if the origin (S3) sends a conflicting value.

---

## Verification

Headers can be verified with curl:

```bash
curl -I https://d3rqh12vcebb1z.cloudfront.net
```

Expected output includes:
```
x-xss-protection: 1; mode=block
x-frame-options: DENY
referrer-policy: strict-origin-when-cross-origin
x-content-type-options: nosniff
strict-transport-security: max-age=31536000; includeSubDomains
```

---

## Known Future Improvements

### Content Security Policy (CSP)
A CSP header would restrict which sources the browser can load scripts, styles, and other resources from. This was not implemented in the initial version due to the complexity of configuring it correctly with Google Fonts and the Azure Function API calls. A future improvement would define a strict CSP that explicitly whitelists:
- `fonts.googleapis.com` for font loading
- `cloud-portfolio-api-cj.azurewebsites.net` for API calls

### Azure Key Vault for Secrets
Currently the Azure Storage Account connection string is stored as a Function App application setting. A production improvement would move this to Azure Key Vault with the Function App granted access via a Managed Identity, eliminating the need for a static connection string entirely.

### AWS IAM Least Privilege
The AWS IAM user used for GitHub Actions deployment currently has broad S3 and CloudFront permissions. A future improvement would create a scoped IAM policy granting only the specific actions required:
- `s3:PutObject`, `s3:DeleteObject` on the specific bucket
- `cloudfront:CreateInvalidation` on the specific distribution

### Azure Function API Authentication
The Function App endpoints are currently anonymous — anyone who knows the URL can call them. A future improvement would add Function App authentication keys or Azure AD authentication to restrict API access.
