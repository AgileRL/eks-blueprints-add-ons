# Read permission on the k/v secrets
path "/kv-v2/*" {
    capabilities = ["read", "list"]
}

