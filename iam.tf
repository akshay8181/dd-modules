resource "aws_iam_role" "databricks_cross_account_role" {
  name = "databricks-cross-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws-us-gov:iam::414351767826:role/unity-catalog-prod-UCMasterRole-<ID>"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "0000"   # <-- Replace with real external ID later
          }
        }
      }
    ]
  })
}
