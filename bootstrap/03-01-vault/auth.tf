# Setting google_workspace and get the oidc_client_id/secrets: https://developer.hashicorp.com/vault/tutorials/auth-methods/google-workspace-oauth
resource "vault_jwt_auth_backend" "google_workspace" {
    description = "OIDC backend with Google Workspace"
    path = "oidc"
    type = "oidc"

    oidc_discovery_url  = "https://accounts.google.com"
    oidc_client_id      = var.gws_oidc_client_id
    oidc_client_secret  = var.gws_oidc_client_secret
    tune {
      listing_visibility = "unauth"
      default_lease_ttl  = "768h"
      max_lease_ttl      = "768h"
      token_type         = "default-service"
    }

    default_role = "developer"
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

resource "vault_kubernetes_auth_backend_config" "kube_config" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = data.aws_eks_cluster.this.endpoint
  # kubernetes_ca_cert     = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  # token_reviewer_jwt     = "ZXhhbXBsZQo="
  # issuer                 = "api"
  # disable_iss_validation = "true"
}
