module "ec2_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "${var.interviewee_code}-ec2-access"
  path        = "/"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Effect": "Allow",
          "Action": [
              "ec2:AssociateRouteTable",
              "ec2:AttachInternetGateway",
              "ec2:AuthorizeSecurityGroupEgress",
              "ec2:AuthorizeSecurityGroupIngress",
              "ec2:CreateInternetGateway",
              "ec2:CreateRoute",
              "ec2:CreateRouteTable",
              "ec2:CreateSecurityGroup",
              "ec2:CreateSubnet",
              "ec2:CreateTags",
              "ec2:CreateVpc",
              "ec2:DeleteInternetGateway",
              "ec2:DeleteKeyPair",
              "ec2:DeleteRouteTable",
              "ec2:DeleteSecurityGroup",
              "ec2:DeleteSubnet",
              "ec2:DeleteVpc",
              "ec2:DescribeAccountAttributes",
              "ec2:DescribeNetworkAcls",
              "ec2:DescribeNetworkInterfaces",
              "ec2:DescribeSecurityGroups",
              "ec2:DescribeVpcAttribute",
              "ec2:DescribeVpcs",
              "ec2:DetachInternetGateway",
              "ec2:DisassociateRouteTable",
              "ec2:ImportKeyPair",
              "ec2:ModifyInstanceAttribute",
              "ec2:RevokeSecurityGroupEgress",
              "ec2:RevokeSecurityGroupIngress",
              "ec2:RunInstances",
              "ec2:StartInstances",
              "ec2:StopInstances",            
              "ec2:TerminateInstances"
          ],
          "Resource": [
              "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:vpc/*",
              "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:subnet/*",
              "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:internet-gateway/*",
              "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:route-table/*",
              "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:security-group/*",
              "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:key-pair/${var.interviewee_code}-news",
              "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:network-interface/*",
              "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:placement-group/",
              "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:volume/*",
              "arn:aws:ec2:*::image/*",
              "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
          ]
      }
  ]
}
EOF
}
