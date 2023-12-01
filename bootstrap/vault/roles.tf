resource "vault_jwt_auth_backend_role" "example" {
  backend         = vault_jwt_auth_backend.google_workspace.path
  role_name       = "gmail"
  token_policies  = ["kv2-readers"]

  bound_audiences       = [vault_jwt_auth_backend.google_workspace.oidc_client_id]
  user_claim            = "sub"
  role_type             = "oidc"
  allowed_redirect_uris = ["https://vault.agilerl.rlops.ai/ui/vault/auth/oidc/oidc/callback"]
}
