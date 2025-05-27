terraform {
  backend "s3" {
    bucket       = "xoak77-terraform-remote-state"
    key          = "terraform-module/rentzone/terrafomr.tfstate"
    region       = "us-east-1"
    profile      = "terraform-user"
    use_lockfile = "terraform-state-lock"
  }
}