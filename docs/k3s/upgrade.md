# k3s upgrade

Plan to bring the three clusters from v1.28.1 to v1.36, written in October 2026.
Kubernetes only supports upgrading the control plane one minor at a time, so
it's 9 hops per cluster, with the components below bumped in between.

## Current state (2026-10-27)

| | compute-2 + gate-1.ovh | theater-1 | hv-1.hirsingue |
|---|---|---|---|
| k3s | v1.28.1+k3s1 (agent gate-1.ovh v1.28.6+k3s2) | v1.28.1+k3s1 | v1.28.1+k3s1 |
| version var | `group_vars/k3s.yaml` (+ `host_vars/gate-1.ovh`) | `host_vars/theater-1` | `host_vars/hv-1` |
| Cilium | 1.15.1 | 1.16.1 | 1.16.19 |
| Traefik (bundled) | 2.9.10 | 2.9.10 | 2.9.10 |
| ArgoCD | 3.0.6 (chart 8.1.1, `host_vars/compute-2`) | managed from compute-2 | none yet |
| cert-manager (k8s repo) | 1.18.1 | 1.18.0 | none |
| ceph-csi (k8s repo) | **3.5.1** (repo says 3.14.0, never synced) | none | none |
| datastore | sqlite, 454M | sqlite, 30M | sqlite, 15M |
| local-path data | 3.7G in `/var/lib/rancher/k3s/storage` | 11G in `/var/lib/volumes/k3s-local-path` | `/var/lib/volumes/backup/k3s-local-path` |

All nodes run cgroup v2 (required from 1.35). No deprecated Kubernetes API is
requested on any cluster (`apiserver_requested_deprecated_apis` only shows
Cilium's own `ciliumnodeconfigs/v2alpha1`), and the k8s repo has no removed API.

## Hops

"Before" = what must be done (and verified) before bumping k3s to that version.

| Hop | k3s | Traefik bundled | Before |
|---|---|---|---|
| 0 | v1.28.15+k3s1 | 2.11.10 | nothing. **After**: migrate `traefik.containo.us` objects to `traefik.io` (below) |
| 1 | v1.29.15+k3s1 | 2.11.20 | |
| 2 | v1.30.14+k3s2 | 2.11.24 | Cilium 1.16 on compute-2; ceph-csi plan decided (below) |
| 3 | v1.31.14+k3s1 | 2.11.24 | Cilium 1.17 everywhere |
| 4 | v1.32.13+k3s1 | **3.6.9** | no `traefik.containo.us` object left; `traefik-config` values checked against chart 39 |
| 5 | v1.33.13+k3s2 | 3.7.8 | Cilium 1.18; ArgoCD 3.1 (chart 9.0.x); ceph-csi 3.16 |
| 6 | v1.34.12+k3s1 | 3.7.13 | Cilium 1.19; cert-manager 1.19 |
| 7 | v1.35.9+k3s1 | 3.7.13 | ArgoCD 3.3 (via 3.2); ceph-csi 3.17.1+ |
| 8 | v1.36.5+k3s1 | 3.7.13 | Cilium 1.20; cert-manager 1.21 (via 1.20); ArgoCD 3.5 (via 3.4) |

Order for each hop: hv-1 first (no data yet, canary), then theater-1, then
compute-2 followed by gate-1.ovh (an agent may lag the server, never lead it).

Versions tested by upstream, which the "Before" column comes from:

- Cilium: 1.15 → k8s 1.26-1.29, 1.16 → 1.27-1.30, 1.17 → 1.29-1.32,
  1.18 → 1.30-1.33, 1.19 → 1.32-1.35, 1.20 → 1.33-1.36. One minor at a time.
- ArgoCD: 3.0 → 1.29-1.32, 3.1/3.2 → 1.31-1.34, 3.3/3.4 → 1.32-1.35, 3.5 → 1.33-1.36.
- cert-manager: 1.18 → 1.29-1.33, 1.19 → 1.31-1.35, 1.20 → 1.32-1.35, 1.21 → 1.33-1.36.
- ceph-csi: 3.14 → 1.30-1.32, 3.15 → 1.31-1.33, 3.16 → 1.32-1.34, 3.17.1/3.18 → 1.34-1.36.

Re-check these when you get to a hop, newer patch releases may exist.

## One hop

1. Bump the version var of the cluster (see the table above), commit.
2. Run the k3s play on the server:

   ```bash
   poetry run ansible-playbook playbooks/main.yaml --tags k3s --limit <server>
   ```

   The play backs up the datastore first, whenever the installed version
   differs from `k3s_release_version`
   ([playbooks/k3s-backup.yaml](../../playbooks/k3s-backup.yaml)), to
   `/var/lib/rancher/k3s/server/backup/<old version>-<date>/`. Then the role
   swaps the binary and restarts k3s; pods keep running during the restart.
3. On blotzheim, then the agent, always together with its server:

   ```bash
   poetry run ansible-playbook playbooks/main.yaml --tags k3s --limit compute-2.blotzheim.infra.mout.ch,gate-1.ovh.infra.mout.ch
   ```

   Never `--limit gate-1.ovh.infra.mout.ch` alone: with no control node among
   the play hosts, the role elects the first one as a server, and gate-1.ovh
   comes up as a new standalone cluster (happened on 2026-10-28).
4. Check (on the server):

   ```bash
   k3s kubectl get nodes -o wide
   k3s kubectl -n kube-system get jobs | grep helm-install    # all Complete
   k3s kubectl get pods -A | grep -vE 'Running|Completed'
   k3s kubectl get --raw /metrics | grep ^apiserver_requested_deprecated_apis
   curl -sI https://argocd.infra.mout.ch                       # blotzheim
   ```

   On blotzheim also check the ArgoCD apps (blotzheim and theater-1) are Healthy.
5. Delete old backups once the next hop went fine (compute-2 has ~22G free).

Component bumps (Cilium, ArgoCD) are separate runs of the same play, after
changing `cilium_version` / `argocd_chart_version` in `host_vars`. Read the
upstream upgrade notes of each minor first, values sometimes get renamed.

## Traefik: `traefik.containo.us` to `traefik.io`

Traefik v3 (k3s 1.32) no longer reads `traefik.containo.us`. Traefik 2.11
(from hop 0) reads both, so migrate between hop 0 and hop 4:

- k8s repo: change `apiVersion: traefik.containo.us/v1alpha1` to
  `traefik.io/v1alpha1` in
  `root/templates/traefik-https-redirection.yaml` (`kube-system/redirect-https`,
  used by most ingresses), `apps/firefly/templates/authentik-middleware.yaml`,
  `apps/traefik-middleware-theater-1/templates/redirect-https-middleware.yaml`.
  Same names, so `kube-system-redirect-https@kubernetescrd` keeps resolving.
- `goauthentik/ak-outpost-traefik-outpost` is created by authentik itself:
  check it gets recreated as `traefik.io` once the CRD exists.
- `kube-system/traefik-dashboard` comes from the k3s chart, it follows.

Check nothing is left before hop 4:

```bash
for r in $(k3s kubectl get crd -o name | grep traefik.containo.us | cut -d/ -f2); do k3s kubectl get $r -A --no-headers; done
```

## ceph-csi

compute-2 runs ceph-csi 3.5.1 (2022, images from the frozen `k8s.gcr.io`) with
7 RBD volumes on it. The `ceph-csi` app in the k8s repo already says 3.14.0
but was never synced (no auto-sync). It has to be upgraded along the way
(3.14 by 1.30, 3.16 by 1.33, 3.17.1+ by 1.35), in the k8s repo. Upstream only
documents upgrades from the previous release, so 3.5 → 3.14 needs its own plan.
Supported Ceph versions of recent ceph-csi also matter for Ceph Reef → Squid.

## Rollback

Only right after a hop, before workloads change anything:

```bash
systemctl stop k3s
cp /var/lib/rancher/k3s/server/backup/<dir>/state.db /var/lib/rancher/k3s/server/db/state.db
rm -f /var/lib/rancher/k3s/server/db/state.db-wal /var/lib/rancher/k3s/server/db/state.db-shm
tar -xzf /var/lib/rancher/k3s/server/backup/<dir>/server.tar.gz -C /var/lib/rancher/k3s/server
```

Then set the previous version back in the vars and run the k3s play.

## Don't

- Don't run `k3s-uninstall.sh` or `k3s_state=uninstalled` on compute-2 or
  theater-1: it deletes `/var/lib/rancher/k3s`, the datastore and on compute-2
  the local-path volumes.
- If the role has to drain a node named by fqdn, it fails (`kubectl drain hv-1`):
  pass `-e ansible_hostname=<fqdn>`.
- After changing the CNI (or reinstalling k3s), reboot the node before starting
  k3s again: leftover `OLD_CILIUM_*` iptables chains break masquerade.
