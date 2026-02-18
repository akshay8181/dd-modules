############################################
# DATADBRICKS CROSS ACCOUNT IAM ROLE
############################################

resource "aws_iam_role" "databricks_cross_account_role" {
  name = "databricks-cross-account-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws-us-gov:iam::414351767826:role/unity-catalog-prod-UCMasterRole-REPLACE_ME"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "0000"  # Replace with real external ID from Databricks
          }
        }
      }
    ]
  })
}

############################################
# MAIN DATADBRICKS POLICY
############################################

resource "aws_iam_policy" "databricks_policy" {
  name        = "databricks-unity-catalog-policy"
  description = "Full access policy for Databricks Unity Catalog"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      #################################################
      # S3 ACCESS
      #################################################
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.saturnsvcs_s3_bucket.arn,
          "${aws_s3_bucket.saturnsvcs_s3_bucket.arn}/*"
        ]
      },

      #################################################
      # KMS ACCESS (For encrypted bucket)
      #################################################
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.saturnsvcs_s3_kms_key.arn
      },

      #################################################
      # FILE EVENTS SETUP (SNS/SQS)
      #################################################
      {
        Sid    = "ManagedFileEventsSetupStatement"
        Effect = "Allow"
        Action = [
          "s3:GetBucketNotification",
          "s3:PutBucketNotification",
          "sns:ListSubscriptionsByTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:Publish",
          "sqs:CreateQueue",
          "sqs:DeleteQueue",
          "sqs:GetQueueAttributes",
          "sqs:SetQueueAttributes",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:PurgeQueue"
        ]
        Resource = "*"
      },

      #################################################
      # FILE EVENTS LIST PERMISSIONS
      #################################################
      {
        Sid    = "ManagedFileEventsListStatement"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "sqs:ListQueues",
          "sns:ListTopics"
        ]
        Resource = "*"
      }
    ]
  })
}

############################################
# ATTACH POLICY TO ROLE
############################################

resource "aws_iam_role_policy_attachment" "databricks_policy_attach" {
  role       = aws_iam_role.databricks_cross_account_role.name
  policy_arn = aws_iam_policy.databricks_policy.arn
}
