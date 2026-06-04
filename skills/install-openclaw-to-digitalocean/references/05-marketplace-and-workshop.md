# Marketplace 1-click alternative & workshop mode

Two adjacent paths that are NOT the wizard's default, documented here so the agent can reach for them when the user asks.

## 1. The DigitalOcean Marketplace 1-Click OpenClaw image

DigitalOcean ships an official **OpenClaw 1-Click Droplet** in its Marketplace (catalog: https://docs.digitalocean.com/products/marketplace/catalog/openclaw/, listing: https://marketplace.digitalocean.com/apps/openclaw — originally launched as "Moltbot"). It provisions Ubuntu 24.04 with OpenClaw, Node, Docker, a non-root `openclaw` user, a generated gateway token, and a firewall, and runs a **setup wizard on first SSH login**.

### Why the automation wizard does NOT use it

The 1-Click image's first-boot **interactive wizard** (it prompts for provider + API key on first SSH login) is exactly what blocks unattended automation — our skill needs to inject everything via cloud-init and never touch an interactive prompt. So the skill uses the **plain `ubuntu-24-04-x64` base image + our own cloud-init**, which is fully scripted and gives us the hardening, ceo-ai-os workspace seeding, and locale handling the 1-Click image doesn't.

### When the 1-Click image is the better choice

For a **human doing a manual, UI-driven deploy** who wants the DO-blessed hardened base and is happy to run the interactive wizard themselves. Point them to the Marketplace page; it's a legitimate, security-reviewed starting point (DO published a hardening write-up: https://www.digitalocean.com/blog/technical-dive-openclaw-hardened-1-click-app). After it boots they SSH in, run the wizard, and can still drop the ceo-ai-os workspace on top with `git clone … && bash ceo-ai-os/openclaw/install.sh`.

### Creating the 1-Click image via doctl (if a human insists on it + CLI)

The Marketplace image isn't a simple slug like `ubuntu-24-04-x64`; resolve it first:

```bash
doctl compute image list --public --context openclaw | grep -i openclaw   # → numeric ID or vendor slug
doctl compute droplet create openclaw-bot \
  --image <openclaw-marketplace-id-or-slug> \
  --size s-2vcpu-4gb --region fra1 --ssh-keys <fp> \
  --context openclaw --wait
```

Then SSH in and run the on-box wizard. This is outside the autonomous flow — the skill's job ends if the user takes this path.

## 2. Workshop shared-token mode

The Yandex Cloud sibling skill has an elaborate "Plan B" — a per-participant `bundle-NN.json` carrying a service-account key + cloud-id + folder-id, because YC isolates participants into folders. **DigitalOcean needs none of that.** DO has a single global account scope, so a workshop organizer has two clean options, and in both cases the wizard's flow is **completely unchanged** — there is just one input, a DO API token, and it doesn't matter whose it is.

| Option | How the organizer sets it up | What the participant pastes | Isolation |
|---|---|---|---|
| **Shared scoped token** | Organizer generates one API token (or one per participant) at cloud.digitalocean.com/account/api/tokens, scoped to droplet/ssh_key/firewall write, short expiry, and DMs it. | That `dop_v1_…` token (instead of their own). | All participants' Droplets live in the organizer's one account — tag each with the participant name (`--tag-name workshop-userNN`) so cleanup is easy. |
| **Team invite** | Organizer creates a DigitalOcean **Team**, invites participants by email; each participant makes their own token within the team. | Their own team-scoped token. | DO Teams give per-member tokens but a shared billing account and shared resource namespace. |

Because the only difference from the default flow is "the token came from the organizer," there is **no separate code path** — Step 0c accepts whatever token works. The only thing worth doing differently in workshop mode:

```bash
# Tag every workshop Droplet + firewall so the organizer can bulk-clean afterwards
doctl compute droplet create "openclaw-${PARTICIPANT}" --tag-name "openclaw-workshop" ... 
# Organizer cleanup at the end of the workshop:
for ID in $(doctl compute droplet list --tag-name openclaw-workshop --format ID --no-header); do
  doctl compute droplet delete "$ID" --force
done
```

### What to tell a workshop participant using the organizer's token

> Этот сервер живёт в аккаунте организатора и будет удалён после воркшопа. Если хочешь оставить бота на постоянку — заведи свой аккаунт DigitalOcean, создай свой API-токен и запусти меня снова с ним: я переустановлю бота в твоём аккаунте.

There is no organizer-side companion skill to build (unlike YC's `prepare-yc-workshop`) — generating a DO token is a 30-second dashboard action, not a scripted SA-key + folder + bundle pipeline. If a workshop needs dozens of pre-made tokens, a short `doctl`-free shell loop against the DO API (`POST /v2/tokens` is not exposed — tokens are dashboard-only as of 2026) means the organizer creates them by hand or via a Team invite. Keep it simple.

## See also

- `01-prerequisites.md` — token creation, contexts, SSH-key upload (the default Plan).
- `install-openclaw-to-yc/references/05-workshop-key-mode.md` — the YC bundle-based equivalent, for contrast.
