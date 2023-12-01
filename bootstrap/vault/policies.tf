# Create admin policy in the root namespace
resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("policies/admin.hcl")
}


resource "vault_policy" "kv2_readers_policy" {
  name   = "kv2-readers"
  policy = file("policies/kv-v2-readers.hcl")
}
