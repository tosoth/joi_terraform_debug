module "ssm_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "${var.interviewee_code}-ssm-access"
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "ssm:DeleteParameter",
              "ssm:GetParameter",
              "ssm:GetParameters",
              "ssm:ListTagsForResource",
              "ssm:PutParameter"
          ],
          "Resource": [
              "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.interviewee_code}/base/ecr",
              "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.interviewee_code}/base/vpc_id",
              "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.interviewee_code}/base/subnet/a/id",
              "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/${var.interviewee_code}/base/subnet/b/id"
          ]
      }
  ]
}
EOF
}
