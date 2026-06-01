output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = "https://${aws_cloudfront_distribution.portfolio.domain_name}"
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.portfolio.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.portfolio.id
}

output "azure_function_url" {
  description = "Azure Function App URL"
  value       = "https://${azurerm_linux_function_app.portfolio.default_hostname}"
}

output "azure_resource_group" {
  description = "Azure Resource Group name"
  value       = azurerm_resource_group.portfolio.name
}

output "azure_storage_account" {
  description = "Azure Storage Account name"
  value       = azurerm_storage_account.portfolio.name
}