# Read permission on the kv2 secrets on '/internal'
path "/internal/*" {
    capabilities = ["read", "list"]
}

