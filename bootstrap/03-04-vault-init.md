# Initial lise the vault storage

After the pods is up, init the vault

## check status

```shell
kubectl -n vault exec vault-0 -ti sh
vault status -address https://vault-0.vault-internal:8200 -ca-cert /vault/userconfig/vault-server-tls/ca.crt
```

## init the storage

```shell
kubectl -n vault exec vault-0 -ti sh

# run this inside vault-0
export VAULT_CLIENT_TIMEOUT=300s;  vault operator init -address https://vault-0.vault-internal:8200 -ca-cert /vault/userconfig/vault-server-tls/ca.crt
```

## record the initial keys

Copy the recovery keys to **data/vault.recovery-keys** and then run `vault-store-root-key.sh` and `vault-store-recovery-keys.sh`


## Reinit vault
j
```shell
kubectl -n vault scale --replicas=0 statefulset vault
kubectl -n vault delete pvc data-vault-0 data-vault-1 data-vault-2
kubectl -n vault scale --replicas=3 statefulset vault
```
