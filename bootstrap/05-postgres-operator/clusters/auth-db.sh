#!/bin/bash

cat << EOT | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: auth-db-tls
  namespace: cert-manager
spec:
  commonName: "*.auth-system"
  dnsNames: 
  - "*.auth-system"
  - "*.auth-system.svc"
  - "*.auth-system.svc.cluster"
  - "*.auth-system.svc.cluster.local"
  ipAddresses:
  - 127.0.0.1
  issuerRef:
    group: cert-manager.io
    kind: ClusterIssuer
    name: selfsigned-cluster-issuer
  privateKey:
    algorithm: ECDSA
    size: 256
  secretName: auth-db-tls
EOT


until $(kubectl -n cert-manager get secrets auth-db-tls 1>/dev/null 2>&1); do
  echo "Waiting for auth-db-tls"
  sleep 5
done

# enable pull based replication
kubectl -n cert-manager annotate secret auth-db-tls "replicator.v1.mittwald.de/replication-allowed"="true"
kubectl -n cert-manager annotate secret auth-db-tls "replicator.v1.mittwald.de/replication-allowed-namespaces"="auth-system"

kubectl -n gitlab get secrets auth-db-tls 1>/dev/null 2>&1
if [[ $? -ne 0 ]]; then

cat << EOT | kubectl apply -f -
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: auth-db
  namespace: auth-system
  annotations:
   "acid.zalan.do/controller": "pgopr-postgres-operator"
spec:
  dockerImage: ghcr.io/zalando/spilo-15:3.0-p1
  teamId: "agrl-core"
  numberOfInstances: 2
  users:  # Application/Robot users
    keycloak:
    - superuser
    - createdb
  enableMasterLoadBalancer: false
  enableReplicaLoadBalancer: false
  enableConnectionPooler: true # enable/disable connection pooler deployment
  enableReplicaConnectionPooler: false # set to enable connectionPooler for replica service
  enableMasterPoolerLoadBalancer: false
  enableReplicaPoolerLoadBalancer: false
  databases:
    keycloak: keycloak
  postgresql:
    version: "15"
    parameters:  # Expert section
      shared_buffers: "32MB"
      max_connections: "10"
      log_statement: "all"
#  env:
#  - name: wal_s3_bucket
#    value: my-custom-bucket

  volume:
    size: 1Gi
    storageClass: gp3

  enableShmVolume: true
  spiloRunAsUser: 101
  spiloRunAsGroup: 103
  spiloFSGroup: 103
  resources:
    requests:
      cpu: 10m
      memory: 100Mi
    limits:
      cpu: 500m
      memory: 500Mi
  patroni:
    failsafe_mode: false
    initdb:
      encoding: "UTF8"
      locale: "en_US.UTF-8"
      data-checksums: "true"
#    pg_hba:
#      - hostssl all all 0.0.0.0/0 md5
#      - host    all all 0.0.0.0/0 md5
#    slots:
#      permanent_physical_1:
#        type: physical
#      permanent_logical_1:
#        type: logical
#        database: foo
#        plugin: pgoutput
    ttl: 30
    loop_wait: 10
    retry_timeout: 128 # default only 10, change to 128, it seems it takes more than 30 seconds to change labels
    synchronous_mode: false
    synchronous_mode_strict: false
    synchronous_node_count: 1
    maximum_lag_on_failover: 33554432

# restore a Postgres DB with point-in-time-recovery
# with a non-empty timestamp, clone from an S3 bucket using the latest backup before the timestamp
# with an empty/absent timestamp, clone from an existing alive cluster using pg_basebackup
#  clone:
#    uid: "efd12e58-5786-11e8-b5a7-06148230260c"
#    cluster: "acid-minimal-cluster"
#    timestamp: "2017-12-19T12:40:33+01:00"  # timezone required (offset relative to UTC, see RFC 3339 section 5.6)
#    s3_wal_path: "s3://custom/path/to/bucket"

# run periodic backups with k8s cron jobs
#  enableLogicalBackup: true
#  logicalBackupSchedule: "30 00 * * *"

#  maintenanceWindows:
#  - 01:00-06:00  #UTC
#  - Sat:00:00-04:00

# overwrite custom properties for connection pooler deployments
#  connectionPooler:
#    numberOfInstances: 1
#    mode: "transaction"
#    schema: "pooler"
#    user: "pooler"
#    maxDBConnections: 60
#    resources:
#      requests:
#        cpu: 300m
#        memory: 100Mi
#      limits:
#        cpu: "1"
#        memory: 100Mi

  initContainers:
  - name: date
    image: busybox
    command: [ "/bin/date" ]

# Custom TLS certificate. Disabled unless tls.secretName has a value.
  tls:
    secretName: ""  # should correspond to a Kubernetes Secret resource to load
    certificateFile: "tls.crt"
    privateKeyFile: "tls.key"
    caFile: ""  # optionally configure Postgres with a CA certificate
    caSecretName: "" # optionally the ca.crt can come from this secret instead.
# file names can be also defined with absolute path, and will no longer be relative
# to the "/tls/" path where the secret is being mounted by default, and "/tlsca/"
# where the caSecret is mounted by default.
# When TLS is enabled, also set spiloFSGroup parameter above to the relevant value.
# if unknown, set it to 103 which is the usual value in the default spilo images.
# In Openshift, there is no need to set spiloFSGroup/spilo_fsgroup.

# Add node affinity support by allowing postgres pods to schedule only on nodes that
# have label: "postgres-operator:enabled" set.
#  nodeAffinity:
#    requiredDuringSchedulingIgnoredDuringExecution:
#      nodeSelectorTerms:
#        - matchExpressions:
#            - key: postgres-operator
#              operator: In
#              values:
#                - enabled

# Enables change data capture streams for defined database tables
#  streams:
#  - applicationId: test-app
#    database: foo
#    tables:
#      data.state_pending_outbox:
#        eventType: test-app.status-pending
#      data.state_approved_outbox:
#        eventType: test-app.status-approved
#      data.orders_outbox:
#        eventType: test-app.order-completed
#        idColumn: o_id
#        payloadColumn: o_payload
#    # Optional. Filter ignores events before a certain txnId and lsn. Can be used to skip bad events
#    filter:
#      data.orders_outbox: "[?(@.source.txId > 500 && @.source.lsn > 123456)]"
#    batchSize: 1000
EOT

fi
