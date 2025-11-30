module "iam_read_only_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-read-only-policy"

  name        = "${var.interviewee_code}-read-only"
  path        = "/"
  description = "read-only policies for interviewee"

  allowed_services = [ "ec2", "ssm" ]
}
