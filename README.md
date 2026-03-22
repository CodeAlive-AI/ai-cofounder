# AI Cofounder

![AI Cofounder Banner](banner.png)

**Your AI Chief of Staff for startup operations.** 48 skills that turn any AI agent into an augmented CEO: strategic reviews, hypothesis tracking, GTM playbooks, founder sales, and more.

Built for founders who wear too many hats.

## Who is this for

**Technical founders** — honestly, this is a must-have. You're good at building product but probably underinvesting in strategy, sales, and marketing. These 48 skills fill that gap: structured frameworks for everything from weekly CEO reviews to cold email outreach, without needing to hire a Chief of Staff or a sales coach. If you catch yourself hiding in code instead of talking to customers, this system will call you out.

**CEOs and business leaders** — a structured operating system for the hard decisions. Hypothesis tracking with WIP limits. Decision playbooks for pivots and hiring. Self-deception audits that flag when you're confusing activity with progress. A constraint-first approach that keeps you focused on what actually matters. Works whether you're pre-PMF or scaling.

**Marketers** — 24 GTM skills covering positioning, content strategy, SEO, cold email, social writing, growth loops, and launch playbooks. Each skill has frameworks from practitioners like April Dunford and Jen Abel. Use them as a second brain for marketing decisions, whether you're a one-person team or running a department.

**Anyone building with AI agents** — the skills are portable. Install them into Claude Code, Claude Cowork, Cursor, Codex, OpenClaw, or any of 40+ agents that support the skills format. They work standalone or as an integrated system. Claude Cowork users get these skills automatically (same `~/.claude/skills/` directory, no extra setup).

## Install

### Any agent (Claude Code, Claude Cowork, Cursor, Codex, etc.)

Install all skills at once:

```bash
npx skills add CodeAlive-AI/ai-cofounder -g
```

Or install individual skills:

```bash
npx skills add CodeAlive-AI/ai-cofounder@hypothesis-tracker -g
npx skills add CodeAlive-AI/ai-cofounder@decision-playbook -g
npx skills add CodeAlive-AI/ai-cofounder@founder-sales -g
```

> **No terminal?** Just tell your agent: *"Install skills from CodeAlive-AI/ai-cofounder following the README"* — it will handle the rest.

### OpenClaw (full autonomous CEO OS)

The skills work in any agent, but [OpenClaw](https://openclaw.ai) is where the full system comes alive. The agent lives in your Telegram, WhatsApp, or Discord. It sends you insights on its own, runs daily recaps, tracks hypotheses across sessions, and nudges you when you're drifting from the constraint. You don't open it. It just works in the background.

```bash
git clone https://github.com/CodeAlive-AI/ai-cofounder.git
cd ai-cofounder/openclaw
./install.sh
```

Then customize for your company — see [openclaw/CUSTOMIZATION.md](openclaw/CUSTOMIZATION.md). Full setup guide: [openclaw/README.md](openclaw/README.md).

## What is this?

48 skills organized into a CEO operating system. Each skill is a structured workflow with frameworks from 100+ product leaders. They work standalone, but together they form a system:

- **Weekly CEO reviews** with self-deception checks
- **Hypothesis tracking** with WIP limits and evidence tiers
- **Decision playbooks** for pivots, hiring, pricing, and more
- **Discovery debriefs** that extract structured learnings from customer conversations
- **GTM skills** covering positioning, sales, content, SEO, email, and launch
- **Proactive nudges** via heartbeat — insights, coaching, and daily recaps (OpenClaw only)

The system is opinionated. It follows a constraint-first approach (Theory of Constraints), uses evidence tiers to separate signal from noise, and checks for self-deception patterns that founders usually don't notice on their own.

## Repo structure

```
ai-cofounder/
├── skills/                  <- 48 portable skills (work in any agent)
│   ├── ceo-weekly-review/
│   ├── hypothesis-tracker/
│   ├── founder-sales/
│   └── ...
├── openclaw/                <- Full CEO OS for OpenClaw (Telegram/WhatsApp/Discord)
└── docs/                    <- Skill catalog, tool setup guides
```

## Skills (48 total)

| Category | Count | Examples |
|----------|:-----:|---------|
| **CEO Operating System** | 12 | Weekly reviews, hypothesis tracking, decision playbooks, strategic analysis, anti-pattern audits |
| **Go-To-Market** | 24 | Positioning, founder sales, cold email, SEO, content strategy, pricing, user onboarding |
| **Launch** | 2 | Product Hunt launch playbook + 30-day timeline |
| **Writing Quality** | 2 | AI pattern removal (humanizer), prompt engineering |
| **Tools** (optional) | 8 | PostHog analytics, Exa research, web browser |

<details>
<summary><strong>Full skill catalog (click to expand)</strong></summary>

### CEO Operating System (12 skills)

| Skill | What it does |
|-------|-------------|
| `ceo-weekly-review` | Weekly review: dashboard, 10 questions, self-deception check, next week focus |
| `hypothesis-tracker` | Add, update, rank, and kill hypotheses with WIP limits and evidence tiers |
| `decision-playbook` | 9 quick-reference frameworks: pivot, hire, double down, kill feature, etc. |
| `strategic-review` | Deep multi-phase analysis: premise challenge, alternatives, risk map, adversarial review |
| `business-investigation` | Root cause analysis for business problems (why no signups, why churn) |
| `discovery-debrief` | Structured debrief after customer conversations — extract learnings, update hypotheses |
| `metrics-briefing` | CEO-level metrics through 9-category framework |
| `anti-pattern-audit` | Monthly self-deception audit — 25 anti-patterns |
| `idea-generator` | Generate business, marketing, and content ideas tied to your wedge |
| `daily-recap` | End-of-day consolidation — summarize, promote durable facts to MEMORY.md |
| `structured-log` | Write structured entries to daily memory for better recall |
| `fpf-problem-solving` | First Principles Framework — rigorous decomposition for complex problems |

### Go-To-Market (24 skills)

| Skill | What it does |
|-------|-------------|
| `problem-definition` | Define and validate the problem you're solving |
| `positioning-messaging` | Craft positioning, value props, and taglines |
| `product-marketing-context` | Shared marketing context across skills |
| `competitive-analysis` | Analyze competitors and find differentiation |
| `conducting-user-interviews` | Plan and run effective customer interviews |
| `measuring-product-market-fit` | Measure PMF with frameworks beyond Sean Ellis |
| `writing-north-star-metrics` | Define your North Star metric |
| `pricing-strategy` | Design pricing tiers and packaging |
| `founder-sales` | Close first customers, build repeatable sales process |
| `sales-qualification` | Qualify leads before investing time |
| `enterprise-sales` | Navigate complex buying committees |
| `product-led-sales` | Convert self-serve users to enterprise |
| `content-strategy` | Plan what content to create and why |
| `copywriting` | Write landing pages and web copy |
| `social-writer` | Write LinkedIn and X posts that sound human |
| `cold-email` | Write cold emails that get replies |
| `email-sequence` | Design lifecycle and nurture email sequences |
| `seo-audit` | SEO and GEO (generative engine optimization) audit |
| `programmatic-seo` | Scale content with programmatic SEO |
| `designing-growth-loops` | Design viral and content growth loops |
| `user-onboarding` | Optimize user onboarding and activation |
| `brand-storytelling` | Craft company narrative and pitch story |
| `community-building` | Build and grow developer/user communities |
| `launch-marketing` | Plan and execute product launches |

### Launch (2 skills)

| Skill | What it does |
|-------|-------------|
| `product-hunt-launch` | Product Hunt launch specs and tactics |
| `ph-launch-timeline` | 30-day Product Hunt preparation plan |

### Writing Quality (2 skills)

| Skill | What it does |
|-------|-------------|
| `humanizer` | Remove AI-generated writing patterns |
| `prompt-engineering` | Universal prompt engineering techniques |

### Tools (8 skills, optional)

| Skill | What it does | Requires |
|-------|-------------|----------|
| `posthog-analytics` | Query PostHog data | PostHog + mcporter |
| `exa-company-research` | Research companies via Exa | Exa API + mcporter |
| `exa-people-research` | Research people and LinkedIn profiles | Exa API + mcporter |
| `exa-personal-site` | Find personal sites and blogs | Exa API + mcporter |
| `exa-x-search` | Search X/Twitter posts | Exa API + mcporter |
| `exa-code-search` | Search code repositories | Exa API + mcporter |
| `exa-lead-gen` | Deep search for lead generation | Exa API + mcporter |
| `web-browser` | Browse web pages via agent-browser | agent-browser CLI |

</details>

## Key concepts

### Evidence tiers

Not all signals are equal. The system uses 5 tiers to assess evidence quality:

1. **Tier 1**: Costly-to-fake behavioral (paid pilots, expansion, renewals)
2. **Tier 2**: Product evidence (session replays, drop-offs, support tickets)
3. **Tier 3**: Commercial evidence (win/loss, objections, stalled deals)
4. **Tier 4**: Market narrative (competitor moves, content performance)
5. **Tier 5**: Low-power (praise, vanity traffic, investor excitement)

### Hypothesis management

Hypotheses follow the format: *"For [ICP] who [trigger], if we [change], then [metric] will move from X to Y by [date], because [evidence]."*

WIP limits: max 3 active hypotheses, max 2 concurrent experiments. Relay race rule: if evidence is sufficient before the deadline — decide now.

### Self-deception checks

25 anti-patterns organized in 5 blocks: general founder mistakes, ex-engineer mistakes, metric interpretation, pre-PMF growth, and AI-era pitfalls. The agent flags these during weekly reviews and monthly audits.

## OpenClaw integration

The `openclaw/` directory has the full workspace setup:

- **SOUL.md** — AI Chief of Staff persona with constraint-first thinking
- **MEMORY.md** — Structured company context (wedge, ICP, stage, constraint)
- **HEARTBEAT.md** — Proactive nudge cadence (insights, coaching, daily recaps)
- **AGENTS.md** — Skill routing and disambiguation rules
- **Memory system** — Daily logs, weekly reviews, hypothesis tracker

See [openclaw/README.md](openclaw/README.md) for setup instructions.

## Works great with CodeAlive

[CodeAlive](https://codealive.ai) is an AI context platform for codebases. It lets agents instantly get answers about how anything works in a repository (architecture, dependencies, cross-service patterns) without reading thousands of files. If your startup builds software, the [codealive-context-engine](https://github.com/CodeAlive-AI/codealive-skills) skill gives the CEO OS direct access to your codebase for deeper technical context during strategic reviews and investigations.

## Docs

- [openclaw/README.md](openclaw/README.md) — OpenClaw setup and deployment
- [openclaw/CUSTOMIZATION.md](openclaw/CUSTOMIZATION.md) — Configure for your company
- [docs/skill-catalog.md](docs/skill-catalog.md) — Detailed skill descriptions
- [docs/adding-tools.md](docs/adding-tools.md) — Connect analytics, search, and browser tools

## What's inside

The CEO OS is built on five pillars:

1. **[Lenny Rachitsky's Podcast](https://www.lennyspodcast.com/)** — 14 GTM skills distilled from 100+ episodes with top product leaders. Frameworks for positioning (April Dunford), founder sales (Jen Abel), growth loops, PMF measurement, and more. Packaged by [RefoundAI/lenny-skills](https://github.com/RefoundAI/lenny-skills) (MIT).

2. **[Corey Haines' Marketing Skills](https://marketing-skills.com/)** — 8 skills for copywriting, cold email, SEO, content strategy, email sequences, and programmatic SEO. Practical frameworks from a SaaS marketer. Source: [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) (MIT).

3. **[Garry Tan's gstack](https://github.com/garrytan/gstack)** — Inspired the strategic review modes (EXPAND / SELECTIVE / HOLD / REDUCE) and structured decision-making patterns.

4. **[First Principles Framework (FPF)](https://github.com/ailev/FPF/blob/main/FPF-Spec.md)** by Anatoly Levenchuk — Transdisciplinary reasoning architecture for rigorous decomposition of complex problems. Used in `fpf-problem-solving` skill.

5. **CEO Bible** — A research document on the role of CEO in an early-stage startup, synthesized by GPT-5.4 Pro from 50+ sources (Goldratt's Theory of Constraints, Horowitz's Wartime CEO, Bezos's two-way doors, Jobs's subtraction, and others). Powers the CEO OS skills: weekly reviews, hypothesis tracking, anti-pattern audits, decision playbooks, and constraint-first thinking.

## License

This project is [MIT](LICENSE) licensed.

Skills included from third-party sources retain their original licenses:

| Source | Skills | License |
|--------|:------:|---------|
| [RefoundAI/lenny-skills](https://github.com/RefoundAI/lenny-skills) | 14 | MIT |
| [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | 8 | MIT |
| [blader/humanizer](https://github.com/blader/humanizer) | 1 | MIT |
| [inference-sh/skills](https://github.com/inference-sh/skills) | 1 | No license specified |
| [ailev/FPF](https://github.com/ailev/FPF) (spec only) | 1 | No license on spec; skill packaging is MIT |
| Original (this repo) | 23 | MIT |

See `SOURCE.md` in each skill folder for detailed provenance.

## Contributing

PRs with new skills and agent setups are welcome.

Before submitting, please check that your skill doesn't duplicate functionality already covered by an existing one — review the [skill catalog](docs/skill-catalog.md) and the descriptions in `skills/*/SKILL.md`. If there's overlap, consider extending the existing skill instead.

**What we're looking for:**
- New skills that fill gaps in the CEO OS (finance, hiring, fundraising, legal, etc.)
- Agent setups for other platforms (`agents/claude-code/`, `agents/codex/`, etc.)
- Improvements to existing skills — better frameworks, more examples, clearer instructions
- Bug fixes — broken cross-references, outdated advice, formatting issues
