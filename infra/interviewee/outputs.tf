output "user_name" {
  value = module.iam_user.iam_user_name
}

output "user_password" {
  # GOOD TO MARK THESE SENSITIVE INFO TO TRUE, NO ISSUE
  sensitive = true
  value = module.iam_user.iam_user_login_profile_password
}

output "access_key_id" {
  # GOOD TO MARK THESE SENSITIVE INFO TO TRUE, NO ISSUE
  sensitive = true
  value = module.iam_user.iam_access_key_id
}

output "secret_access_key" {
  # GOOD TO MARK THESE SENSITIVE INFO TO TRUE, NO ISSUE
  sensitive = true
  value = module.iam_user.iam_access_key_secret
}

output "console_url" {
  value = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
}
