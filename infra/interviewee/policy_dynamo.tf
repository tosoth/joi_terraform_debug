module "dynamodb_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "${var.interviewee_code}-dynamo-access"
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "dynamodb:CreateTable",
              "dynamodb:DeleteItem",
              "dynamodb:DeleteTable",
              "dynamodb:DescribeContinuousBackups",
              "dynamodb:DescribeTable",
              "dynamodb:DescribeTimeToLive",
              "dynamodb:GetItem",
              "dynamodb:ListTagsOfResource",
              "dynamodb:PutItem",
              "dynamodb:TagResource"
          ],
          "Resource": [
              "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.interviewee_code}-terraform-locks"
          ]
      }
  ]
}
EOF
}
