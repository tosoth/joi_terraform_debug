output "user_name" {
  value = module.iam_user.iam_user_name
}

output "user_password" {
  sensitive = true
  value = module.iam_user.iam_user_login_profile_password
}

output "access_key_id" {
  sensitive = true
  value = module.iam_user.iam_access_key_id
}

output "secret_access_key" {
  sensitive = true
  value = module.iam_user.iam_access_key_secret
}

output "console_url" {
  value = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
}
