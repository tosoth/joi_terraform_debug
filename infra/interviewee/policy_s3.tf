module "s3_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "${var.interviewee_code}-s3-access"
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "s3:CreateBucket",
              "s3:DeleteBucket",
              "s3:DeleteBucketOwnershipControls",
              "s3:DeleteBucketPolicy",
              "s3:DeleteObject",
              "s3:DeleteObjectVersion",
              "s3:GetAccelerateConfiguration",
              "s3:GetBucketAcl",
              "s3:GetBucketCORS",
              "s3:GetBucketLocation",
              "s3:GetBucketLogging",
              "s3:GetBucketObjectLockConfiguration",
              "s3:GetBucketOwnershipControls",
              "s3:GetBucketPolicy",
              "s3:GetBucketPublicAccessBlock",
              "s3:GetBucketRequestPayment",
              "s3:GetBucketTagging",
              "s3:GetBucketVersioning",
              "s3:GetBucketWebsite",
              "s3:GetEncryptionConfiguration",
              "s3:GetLifecycleConfiguration",
              "s3:GetObject",
              "s3:GetReplicationConfiguration",
              "s3:ListBucket",
              "s3:ListBucketVersions",
              "s3:PutBucketAcl",
              "s3:PutBucketOwnershipControls",
              "s3:PutBucketPolicy",
              "s3:PutBucketPublicAccessBlock",
              "s3:PutBucketTagging",
              "s3:PutBucketVersioning",
              "s3:PutBucketWebsite",
              "s3:PutLifecycleConfiguration",
              "s3:PutObject"
          ],
          "Resource": [
              "arn:aws:s3:::${var.interviewee_code}-terraform-infra",
              "arn:aws:s3:::${var.interviewee_code}-terraform-infra/*",
              "arn:aws:s3:::${var.interviewee_code}-terraform-infra-static-pages",
              "arn:aws:s3:::${var.interviewee_code}-terraform-infra-static-pages/*"
          ]
      }
  ]
}
EOF
}
