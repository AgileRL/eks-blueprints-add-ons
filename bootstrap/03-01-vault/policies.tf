# Create admin policy in the root namespace
resource "vault_policy" "admin_policy" {
  name   = "admins"
  policy = file("policies/admin.hcl")
}

resource "vault_policy" "internal_readers_policy" {
  name   = "internal-readers"
  policy = file("policies/internal-readers.hcl")
}

