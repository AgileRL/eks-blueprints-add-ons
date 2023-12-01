#------------------------------------------------------------------------------
# The best practice is to use remote state file and encrypt it since your
# state files may contains sensitive data (secrets).
#------------------------------------------------------------------------------
# terraform {
#       backend "s3" {
#             bucket = "remote-terraform-state-dev"
#             encrypt = true
#             key = "terraform.tfstate"
#             region = "us-east-1"
#       }


################################################################################
# Setup AWS IAM policies for auto unseal
################################################################################
locals {
  name   = var.cluster_name

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/AgileRL/terraform-aws-eks-blueprints"
  }
}

module "vault_auto_unseal_kms" {
  source  = "terraform-aws-modules/kms/aws"

  description             = "vault auto unseal key"
  key_usage               = "ENCRYPT_DECRYPT"
  # deletion_window_in_days = var.kms_key_deletion_window_in_days
  # enable_key_rotation     = var.enable_kms_key_rotation

  # Policy
  enable_default_policy     = true
  # key_owners                = var.kms_key_owners
  # key_administrators        = module.eks.kms.key_administrators
  # key_users                 = [aws_iam_role.this.arn]
  # key_service_users         = var.kms_key_service_users
  # source_policy_documents   = var.kms_key_source_policy_documents
  # override_policy_documents = var.kms_key_override_policy_documents

  # Aliases
  # aliases = var.kms_key_aliases
  computed_aliases = {
    # Computed since users can pass in computed values for cluster name such as random provider resources
    cluster = { name = "eks/${var.cluster_name}-vault-unseal" }
  }

  tags = local.tags
}

data "aws_eks_node_groups" "this" {
  cluster_name    = var.cluster_name
}

data "aws_eks_node_group" "example" {
  for_each = data.aws_eks_node_groups.this.names

  cluster_name    = var.cluster_name
  node_group_name = each.value
}

data "aws_iam_roles" "this" {
  name_regex = ".*eks-node-group-.*"
}

resource "aws_iam_policy" "vault-kms-unseal" {
  name_prefix = "${var.cluster_name}-vault-kms-unseal"
  description = "Allow vault to auto unseal using AWS KMS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey",
        ]
        Effect    = "Allow"
        Resource = [module.vault_auto_unseal_kms.key_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vault-kms-unseal-policy-attach" {
  for_each = data.aws_iam_roles.this.names
  role       = each.value
  policy_arn = "${aws_iam_policy.vault-kms-unseal.arn}"
}

# Use Vault provider
provider "vault" {
  # It is strongly recommended to configure this provider through the
  # environment variables:
  #    - VAULT_ADDR
  #    - VAULT_TOKEN
  #    - VAULT_CACERT
  #    - VAULT_CAPATH
  #    - etc.  

  # after we configure the ingress, but we still need VAULT_TOKEN
  address = "https://vault.agilerl.rlops.ai"

}
