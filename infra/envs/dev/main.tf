module "security_group" {
  source = "../../modules/security_group"

  username          = var.username
  environment       = var.environment
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  ssh_allowed_cidrs = var.ssh_allowed_cidrs
  restrict_egress   = var.restrict_egress
}
