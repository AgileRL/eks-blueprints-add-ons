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

    default_role = "gmail"
}
