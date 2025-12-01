# Is the user an infra deployer or just non-infra related user? If the former one, I will remove some policies

module "iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "${var.interviewee_code}-iam-access"
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "iam:AddRoleToInstanceProfile",
              #"iam:AttachRolePolicy", # Otherwise user can add wider policy for himself, security concern
              #"iam:CreateInstanceProfile",
              #"iam:CreateRole",
              #"iam:DeleteInstanceProfile",
              #"iam:DeleteRole",
              #"iam:DetachRolePolicy",
              "iam:GetInstanceProfile",
              "iam:GetRole",
              "iam:ListAttachedRolePolicies",
              "iam:ListInstanceProfilesForRole",
              "iam:ListRolePolicies",
              "iam:PassRole",
              #"iam:RemoveRoleFromInstanceProfile"
          ],
          "Resource": [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.interviewee_code}-news_host", # consider to change news_host to *_host for future scale
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/${var.interviewee_code}-news_host"
          ]
      }
  ]
}
EOF
}
