# Setup our aws provider
variable "region" {
  default = "eu-west-1"
}
provider "aws" {
  region = "${var.region}"
}

terraform {
  backend "s3" {
    #region = "eu-west-1"  # follow line 6 to use region parameter instead of a hardcoded one
# --- UPDATED CODE START ---
    # Reference the variable here instead of hardcoding the region
    region = var.region
# --- UPDATED CODE END ---
    key = "base/terraform.tfstate"
  }
}
