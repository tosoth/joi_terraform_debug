
module "iam_user" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-user"
  version = "5.33.1"

  name          = "interview-${var.interviewee_code}"
  force_destroy = true

  policy_arns = [
    module.dynamodb_policy.arn,
    module.ec2_policy.arn,
    module.ecr_policy.arn,
    module.iam_policy.arn,
    module.iam_read_only_policy.arn,
    module.manual_policy.arn,
    module.s3_policy.arn,
    module.ssm_policy.arn,
  ]

  password_reset_required = false
}
