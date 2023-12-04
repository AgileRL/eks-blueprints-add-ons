locals {
  name   = var.cluster_name

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/AgileRL/terraform-aws-eks-blueprints"
  }

}

module "s3_backups_bucket" {
  source = "./modules/s3_backups"

  cluster_name = local.name
  bucket_name = "${local.name}-backups"

  tags = local.tags
}

