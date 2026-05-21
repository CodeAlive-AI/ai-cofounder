# Quota check and KZ pricing math

Run these before `scripts/provision.sh` to make sure the run won't fail halfway.

## 1. What the workshop needs

For N participants on the default `install-openclaw-to-yc` VM shape (2 vCPU, 4 GB RAM, 30 GB SSD, 1 public IP):

| Resource | Per participant | For N = 25 (with 10% headroom) |
|---|---|---|
| vCPU (compute) | 2 | 55 |
| RAM GB (compute) | 4 | 110 |
| Public IPv4 (vpc) | 1 | 28 |
| SSD GB (compute) | 30 | 825 |
| Folders (resource-manager) | 1 | 25 |
| Service accounts (iam) | 1 | 25 |

## 2. Check the active limits

```bash
# Compute service quotas
yc quota list --service-id compute --format json \
  | jq '.[] | {name: .resource_id, limit, usage}'

# Same for vpc + resource-manager + iam
for svc in vpc resource-manager iam; do
  echo "=== $svc ==="
  yc quota list --service-id "$svc" --format json \
    | jq '.[] | {name: .resource_id, limit, usage}'
done
```

Defaults on a brand-new YC KZ cloud (as of 2026-05): compute `total-core-count` ≈ 12 vCPU, `total-disk-size` ≈ 100 GB, `total-instance-count` ≈ 8. **All three are too small for a 25-person workshop.**

## 3. Request a bump

Console:
```
https://kz.console.yandex.cloud/quotas?service=compute
```

CLI (preferred, no GUI):
```bash
# Compute vCPU
yc quota request submit \
  --service-id compute \
  --resource-id total-core-count \
  --limit 60 \
  --reason "OpenClaw workshop: 25 VMs (2 vCPU each) + headroom"

# Compute RAM
yc quota request submit \
  --service-id compute \
  --resource-id total-memory-size \
  --limit 120 \
  --reason "OpenClaw workshop"

# Compute disks
yc quota request submit \
  --service-id compute \
  --resource-id total-disk-size \
  --limit 1000 \
  --reason "OpenClaw workshop"

# Public IPv4
yc quota request submit \
  --service-id vpc \
  --resource-id external-static-address-count \
  --limit 30 \
  --reason "OpenClaw workshop"
```

Approval is usually within an hour for reasonable amounts, but can take up to 24 hours for first-time accounts. **Submit at least 48 hours before the workshop.**

## 4. Verify after approval

```bash
yc quota list --service-id compute --format json \
  | jq '.[] | select(.resource_id == "total-core-count") | {limit, usage}'
```

`limit` must be at least the value you requested.

## 5. Cost estimate (KZ)

Yandex Cloud Kazakhstan pricing for the workshop shape:

| Item | Hourly | 4-hour workshop | 25 participants |
|---|---|---|---|
| 2 vCPU (100% guaranteed, standard-v3) | ~2.5 ₸ | ~10 ₸ | ~250 ₸ |
| 4 GB RAM | ~1.5 ₸ | ~6 ₸ | ~150 ₸ |
| 30 GB SSD network disk | ~0.3 ₸ | ~1.2 ₸ | ~30 ₸ |
| Ephemeral public IPv4 | free | free | free |
| **Total** | **~4.3 ₸** | **~17 ₸/participant** | **~430 ₸** |

≈ **$1 total** for a 4-hour workshop. The 24 000 ₸ trial grant on a fresh KZ account covers this ~55x over.

If you forget to run `cleanup.sh` and the VMs run for a full day before participants stop them: ~3 000 ₸ / day for 25 VMs. Still inside the grant. Set a calendar reminder anyway.

## 6. After-workshop billing check

```bash
# Sum spent in the last day across all workshop folders
for fid in $(jq -r '.participants[].folder_id' "$BUNDLES/manifest.json"); do
  yc billing usage list --folder-id "$fid" --format json
done | jq -s 'map(.[].cost | tonumber) | add'
```

Yandex Cloud's billing API has a ~24-hour lag, so the exact spend isn't visible until the day after the workshop.
