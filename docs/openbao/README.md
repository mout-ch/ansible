# OpenBao

Secrets store of mout.ch, a 3-node raft cluster on the Ceph VMs (blotzheim).
Migrated from Vault 1.5.5 in October 2026.

- Nodes: `ceph-1/2/3.blotzheim.infra.mout.ch` (`192.168.14.10/11/12:8200`, no TLS)
- Public endpoint: `https://vault.infra.mout.ch` (nginx, Let's Encrypt)
- Storage: raft in `/opt/openbao/raft`, Shamir seal (3 of 5 keys)
- Config: `openbao_*` in [group_vars/all.yaml](../../group_vars/all.yaml), play `openbao` in [playbooks/main.yaml](../../playbooks/main.yaml)
- Clients: Ansible (plain HTTP API calls), vault-secrets-operator on compute-2 and theater-1

Upgrading to a new version: see [upgrade.md](upgrade.md).

## Setup

```bash
export VAULT_ADDR=https://vault.infra.mout.ch
export VAULT_TOKEN=<admin token>
```

Check both are set, an empty one makes `curl -s` print nothing:

```bash
echo "ADDR=$VAULT_ADDR TOKEN=${VAULT_TOKEN:+set}"
```

## Cluster state

Raft peers, all must be `voter: true`:

```bash
curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/storage/raft/configuration" | jq '.data.config.servers[] | {node_id, voter, leader}'
```

Current leader:

```bash
curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/storage/raft/configuration" | jq -r '.data.config.servers[] | select(.leader) | .node_id'
```

Autopilot, expect `healthy: true` and `failure_tolerance: 1`:

```bash
curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/storage/raft/autopilot/state" | jq '{healthy, failure_tolerance, leader, servers: [.servers[] | {id, status, healthy}]}'
```

Per node (version, seal state, HA mode, raft index):

```bash
for n in 1 2 3; do ssh ceph-$n.blotzheim.infra.mout.ch 'echo "== $(hostname -s)"; bao status -address=http://127.0.0.1:8200 | grep -E "Version|Sealed|HA Mode|Raft Applied"'; done
```

Mounts and auth methods:

```bash
curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/mounts" | jq -r '.data | to_entries[] | "\(.key) \(.value.type)"'
curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/auth"   | jq -r '.data | to_entries[] | "\(.key) \(.value.type)"'
```

## Unseal a node

Always on the node itself: the public endpoint picks the backend, so it may hit
another node.

```bash
ssh ceph-<n>.blotzheim.infra.mout.ch
bao operator unseal -address=http://127.0.0.1:8200   # x3, one key each
```

## Snapshot

Take it on the **active** node over SSH. Through the public endpoint a standby
answers with a redirect and `curl -s` writes an empty file.

```bash
LEADER=$(curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/storage/raft/configuration" | jq -r '.data.config.servers[] | select(.leader) | .node_id')
printf 'X-Vault-Token: %s\n' "$VAULT_TOKEN" | ssh $LEADER.blotzheim.infra.mout.ch 'curl -sf -H @- http://127.0.0.1:8200/v1/sys/storage/raft/snapshot' > openbao-$(date +%F).snap
```

Check it: a few hundred KB, and `tar` lists `meta.json`, `state.bin`, `SHA256SUMS`:

```bash
ls -la openbao-$(date +%F).snap && tar tzf openbao-$(date +%F).snap
```

`*.snap` is git-ignored. Keep snapshots outside the repo and outside the cluster.

## vault-secrets-operator token

Ansible injects a periodic orphan token (role `vault-secrets-operator`, period
24h, no max TTL) that the operator renews every 12h. To recreate it:

```bash
poetry run ansible-playbook playbooks/main.yaml --tags vault-operator
```

Check the token works from a cluster (expect `200`):

```bash
ssh compute-2.blotzheim.infra.mout.ch 'T=$(k3s kubectl -n vault-operator get secret vault-secrets-operator -o jsonpath="{.data.VAULT_TOKEN}" | base64 -d); curl -s -o /dev/null -w "%{http_code}\n" -H "X-Vault-Token: $T" http://192.168.14.10:8200/v1/auth/token/lookup-self'
```

## Known log noise

While a node restarts or waits for unseal, these are expected and stop once it
is unsealed:

- On the other nodes: `failed to appendEntries`, `failed to heartbeat` (`connection refused`, `EOF`), one `tls: internal error`
- On the node itself: `waiting for unseal keys to be supplied`, `transport shutdown`, `Raft RPC layer closed`
