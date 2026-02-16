terraform {
  required_version = ">= 1.5.0"

  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.40"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key

  # Optional: use if you're in EU site
  # api_url = "https://api.datadoghq.eu/"
}
