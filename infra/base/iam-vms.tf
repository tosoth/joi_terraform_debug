data "aws_iam_policy_document" "instance-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "news_host" {
  name               = "${var.prefix}-news_host"
  assume_role_policy = "${data.aws_iam_policy_document.instance-assume-role-policy.json}"
}

#resource "aws_iam_role_policy_attachment" "ecr_read_attach" {
#  role       = "${aws_iam_role.news_host.name}"
#  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"  # !!! this is too wild
#}
# changed code start here
# 1. Define a custom IAM policy document for ECR read-only access
data "aws_iam_policy_document" "ecr_read_only" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    # Restrict permissions to all ECR resources in the current account/region
    resources = ["*"]
  }
}

# 2. Create the custom IAM Policy
resource "aws_iam_policy" "ecr_read_only_policy" {
  name   = "${var.prefix}-ecr-read-only"
  policy = data.aws_iam_policy_document.ecr_read_only.json
}

# 3. Attach the new, restricted policy (REPLACE the old attachment)
resource "aws_iam_role_policy_attachment" "ecr_read_attach" {
  role       = aws_iam_role.news_host.name
  # Change the policy ARN to reference the new custom policy
  policy_arn = aws_iam_policy.ecr_read_only_policy.arn
}

#changed code end here

resource "aws_iam_instance_profile" "news_host" {
  name = "${var.prefix}-news_host"
  role = "${aws_iam_role.news_host.name}"
}
