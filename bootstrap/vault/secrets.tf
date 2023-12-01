#----------------------------------------------------------
# Enable secrets engines
#----------------------------------------------------------

# Enable K/V v2 secrets engine at 'kv-v2'
resource "vault_mount" "kv-v2" {
  path = "kv-v2"
  type = "kv-v2"
}

# Enable Transit secrets engine at 'transit'
resource "vault_mount" "transit" {
  path = "transit"
  type = "transit"
}

