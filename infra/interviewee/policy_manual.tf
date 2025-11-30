module "manual_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "${var.interviewee_code}-manual_access"
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
            "ec2:Describe*"
          ],
          "Resource": [ "*" ]
      }
  ]
}
EOF
}
