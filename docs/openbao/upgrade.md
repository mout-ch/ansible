# Upgrade OpenBao

Rolling upgrade, one node at a time: standbys first, then step down the leader
and upgrade it last. A restarted node comes back sealed, and two sealed nodes
means no raft quorum, so never work on two nodes at once.

Setup and checks used below: see [README.md](README.md).

## 1. Prepare

Read the release notes of every version between the current one and the target,
look for breaking changes on raft, Shamir seal, listeners, kv, pki, userpass and
approle:

- https://github.com/openbao/openbao/blob/main/CHANGELOG.md
- https://openbao.org/docs/release-notes/

Check the version is in the APT repository:

```bash
curl -s https://pkgs.openbao.org/deb/dists/stable/main/binary-amd64/Packages | awk 'BEGIN{RS=""} /Package: openbao\n/' | grep '^Version' | sort -V | tail -5
```

Check the cluster is healthy (all voters, autopilot healthy) and take a snapshot
on the leader (see README).

## 2. Bump the version

In [group_vars/all.yaml](../../group_vars/all.yaml):

```yaml
openbao_version: "<new version>"
```

Commit it. Never lower it afterwards: the role installs whatever is set there.

## 3. Upgrade the standbys

Find the leader, then run this for each of the two other nodes, one after the
other:

```bash
poetry run ansible-playbook playbooks/main.yaml --tags openbao --limit ceph-<n>.blotzheim.infra.mout.ch
```

When the play reaches `Wait for the node to be unsealed`, unseal the node (see
README). The play continues once it is unsealed, or fails after 15 minutes.

Check before moving on: `Version` is the new one, `Sealed false`, `HA Mode
standby`, same raft index as the others.

## 4. Step down the leader

```bash
curl -s -X PUT -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/step-down" -w "%{http_code}\n"   # 204
curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/sys/storage/raft/configuration" | jq -r '.data.config.servers[] | select(.leader) | .node_id'
```

The new leader must be one of the nodes already upgraded. The API may refuse
requests for a few seconds during the election, retry if needed.

## 5. Upgrade the former leader

Same command as step 3, with its name in `--limit`, then unseal it.

## 6. Check

- All nodes on the new version, unsealed, same raft index, all voters
- Autopilot healthy
- Operator token still works from compute-2 and theater-1
- `curl -s https://vault.infra.mout.ch/v1/sys/health?standbyok=true` shows the new version
- Fresh snapshot on the leader

## Rollback

A newer version may migrate data in a way an older one can't read: don't just
reinstall the old package on an upgraded node. Restore the snapshot taken in
step 1 on a cluster running the old version:

```bash
bao operator raft snapshot restore -force <file>.snap
```
