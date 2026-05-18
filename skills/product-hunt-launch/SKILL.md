---
name: product-hunt-launch
description: "Product Hunt launch optimization — complete guide based on official PH documentation. Covers 30-day prep timeline, submission fields, gallery strategy, taglines, maker comments, timing, hunter myths, marketing rules, and launch day tactics. Use for: product launches, startup launches, side project launches, Product Hunt optimization. For general launch strategy (PR, press), see launch-marketing."
allowed-tools: Bash(infsh *)
---

# Product Hunt Launch

Complete Product Hunt launch guide based on official PH documentation (2024-2025).

## Quick Start (Image Generation)

> Requires inference.sh CLI (`infsh`). [Install instructions](https://raw.githubusercontent.com/inference-sh/skills/refs/heads/main/cli-install.md)

```bash
infsh login

# Generate gallery hero image (1270x760)
infsh app run falai/flux-dev-lora --input '{
  "prompt": "clean product showcase, modern SaaS dashboard interface on laptop screen, floating UI elements around it, soft gradient background from blue to purple, professional marketing hero shot, minimal clean design",
  "width": 1248,
  "height": 832
}'
```

## Who Product Hunt Is For

Product Hunt community = early adopters, makers, tech people, entrepreneurs, investors. Anyone can use it. No company/brand accounts allowed — person-to-person community only. Real people, not logos.

**Account requirement**: Must exist for at least 1 week before you can submit a product. Join 3+ months before launch to build presence.

## Is Product Hunt Right for You?

**Time investment**: Successful launches typically require **50-120 hours** of preparation. Some hit #1 with less, but odds improve significantly with prep. PH CEO Rajiv Ayyangar: "Founders often launch too late. Most founders I know recommend launching early and often. Product Hunt is a powerful signal on what the market wants."

**Consider alternatives if**: You need sustained signups (paid ads may be more efficient) or your product requires gated access (PH users are early adopters who want to dive in immediately).

**B2B tip**: You MUST have a smooth, self-serve onboarding flow. Delayed access = lost users.

## Why Launch on Product Hunt

- Reach highly-engaged product lovers and early adopters
- Get feedback that improves products / validate product-market fit
- Collect social proof (reviews, testimonials)
- Find customers searching for new products
- Attract investors and press (VCs use PH to scout)
- Hire talent / find co-founders
- **SEO**: High-authority backlink from producthunt.com — valuable long-tail effect, especially for new startups
- Distribution — not primarily customer acquisition

## What Makes a Good Fit

Product Hunt guidelines — your product should be:
- **New** (or have substantive updates since last launch)
- **A product** (not blog posts, lists, or plain text documents)
- **Usable** (or with trustworthy timeline — no closed betas where community can't participate)
- **Trustworthy maker** (no spam, no paid upvotes)
- **High-quality and interesting** to the community
- **Unique value** (info products must offer expertise not findable via Google)
- **Innovative and useful** (mass consumption products need demonstrated uniqueness)

## Hunters: Do You Need One?

**No. Self-hunt your product.**

Official PH stats:
- **79%** of featured posts were self-hunted by makers
- **60%** of #1 Product of the Day winners were self-hunted

Hunter = anyone who submits a product. It can be you, a co-maker, or an enthusiastic user. The "famous hunter" era is over — PH opened hunting to everyone. Big hunters **no longer trigger follower notifications** when they hunt a product, so the visibility boost is gone.

A well-known hunter can still help with valuable feedback in comments, but it's not worth delaying your launch for.

**Never pay a hunter** — against PH guidelines, results in product removal and permanent ban.

## Setting Goals

Product of the Day is NOT the only measure of success. Set measurable goals tied to your company objectives:

- Leaderboard position (any position, not just #1)
- Comments and feedback quality
- New followers / community members
- Website traffic and product signups
- Social media buzz
- Investor interest
- Brand recognition and reach
- Networking and partnerships
- Just shipping — launching is a milestone

### Realistic Expectations

| Outcome | Upvotes | Placement |
|---------|---------|-----------|
| Poor | 50-100 | -- |
| Average | 200-400 | Top 10 |
| Good | 500-800 | Top 5 |
| Great | 800+ | Product of the Day |

### Signup Benchmarks

| Type | Signups | Notes |
|------|---------|-------|
| B2B SaaS | 50-300 | Requires self-serve onboarding |
| B2C productivity | 500-1,500 | Broader target market |
| Wide-appeal B2C | up to 3,000+ | Newsletters, productivity tools |

Real examples: Twinr (PotD) got 1,000 signups on launch day, then 150/day ongoing. Air saw 5x web traffic, 8x account creation, 10x workspace creation, best organic sales leads day ever.

## 30-Day Preparation Plan

| Phase | Days | Actions |
|-------|------|---------|
| **Teaser** | 30-21 | Build "notify me" page; self-hunt (79% of featured do); engage in PH community; get network to **create PH accounts now** (algorithm values seasoned accounts — new accounts on launch day get votes removed) |
| **Supporters** | 20-11 | Build list of 200+ (makers, industry contacts, followers, users); target users within your ICP on PH; engage makers who recently launched (better response rates than those who posted years ago) |
| **Assets** | 10-3 | Finalize tagline (<=60 chars), gallery images (1270x760), video, maker comment, up to 3 launch tags; build awareness on X/LinkedIn |
| **Launch** | 2-1 | Clear calendar for 16+ hours; PH runs midnight-midnight Pacific; assign team roles for comment responses |

**Critical**: If supporters create brand-new PH accounts on launch day to upvote, those votes will likely be **removed by the algorithm**. Get them signed up 30 days before.

## Submission Content Checklist

All fields you'll encounter when submitting. Work is auto-saved as draft.

### Required Fields

| Field | Spec | Best Practice |
|-------|------|---------------|
| **URL** | Direct link to product page | No shortened links (bit.ly), no UTM tracking links |
| **Product name** | Product name only | No descriptions or emojis (unless legit part of name) |
| **Tagline** | Max 60 chars | Short description, no gimmicks or superlatives |
| **Description** | Max 500 chars | Concise value proposition and features |
| **Launch tags** | Up to 3 | Choose tags strongly related to your launch |
| **Thumbnail** | Square, 240x240 recommended | Under 3MB. GIFs allowed but don't autoplay (animate on hover) |
| **Gallery images** | Min 2 required, 1270x760 recommended | Multiple images, can reorder via drag-and-drop |
| **Makers** | Tag all team members | They need PH accounts created before launch |
| **Pricing** | Free / Paid / Paid with free tier | Select accurate option |

### Optional Fields

| Field | Spec | Notes |
|-------|------|-------|
| **Links** | App Store, Google Play, Amazon, etc. | Additional download/purchase links |
| **X handle** | Product's handle (not personal) | Helps community find you |
| **Video** | YouTube links only (not private), 3-5 min | 53% of PotD include video. A simple Loom walkthrough is often best. Avoid links that go live at launch time |
| **Interactive demo** | Arcade, Storylane, Hexus, Supademo, Layerpath, ScreenSpace | Free for PH launches — shows UI in action |
| **Shoutouts** | Max 3 | Tools that helped build your product |
| **Promo code** | Offer, code, expiration date (all required) | Special deal for PH community |
| **First comment** | Your maker pitch | 70% of PotD/W/M winners had a maker first comment |

**Scheduling**: Up to 1 month in advance. Use this time to tease, drive traffic, collect followers.

## Tagline (60 chars)

Must communicate what it does AND why someone should care. No period at end. Include an action verb if possible.

PH CEO Rajiv Ayyangar: "A common failure mode is trying to make a tagline seem grander but losing clarity (e.g. 'An AI platform to turbocharge...'). Make sure it's both compelling and clear."

### Formulas

| Formula | Example |
|---------|---------|
| [Action] for [audience] | "AI writing assistant for developers" |
| [Result] without [pain] | "Beautiful docs without the design skills" |
| [Tool] that [benefit] | "Analytics that explain themselves" |
| [Adjective] [category] | "Instant customer feedback surveys" |
| The [category] for [niche] | "The Figma for data visualization" |

### Examples

```
BAD: "The most ameozing app in the app store" (superlative, gimmicky)
BAD: "We help you manage projects better." (vague, has period)
BAD: "AI-powered machine learning project management SaaS" (buzzword soup)

GOOD: "Ship docs in minutes, not days" (31 chars)
GOOD: "AI turns your data into stories" (32 chars)
GOOD: "The open-source Calendly alternative" (37 chars)
GOOD: "Make Chrome faster and use 10x less memory"
GOOD: "Find the best SEO tools for the job"
GOOD: "Launch your own swag store in 3 easy steps"
```

## Gallery Images

### Strategy by Position

| Position | Content | Goal |
|----------|---------|------|
| **1 (Hero)** | Product in action, core value visible | Stop the scroll — shows in feed, email digest, social shares |
| **2** | Key feature demonstration | Show the "aha moment" |
| **3** | Before/after or problem/solution | Show the transformation |
| **4** | Social proof or metrics | Build credibility |
| **5** | Technical differentiator or integrations | For evaluators |

### Specs

- Recommended: **1270 x 760 px**
- Minimum: 2 required, recommend 3+
- GIF thumbnails: must have good first frame (no autoplay), under 3MB
- Less than a third of PotD products used animated GIF thumbnails
- **Embed captions within images** so audience knows exactly what each screenshot shows
- PH CEO Rajiv Ayyangar: "Show the UI. The PH community wants to know what your product looks like!"

### Generating Gallery Images

```bash
# Image 1: Hero product shot (1270x760)
infsh app run falai/flux-dev-lora --input '{
  "prompt": "modern SaaS product showcase, clean dashboard interface floating above gradient background, UI showing analytics charts and metrics, professional product marketing style, soft shadows, blue and white color scheme, wide format",
  "width": 1248,
  "height": 832
}'

# Image 2: Feature demo
infsh app run falai/flux-dev-lora --input '{
  "prompt": "product feature showcase, split screen showing drag-and-drop interface on left and generated output on right, clean UI design, modern SaaS aesthetic, subtle grid background, professional marketing",
  "width": 1248,
  "height": 832
}'

# Image 3: Before/after
infsh app run infsh/stitch-images --input '{
  "images": ["before-state.png", "after-state.png"],
  "direction": "horizontal"
}'
```

## First Comment

70% of PotD/Week/Month winners included a maker first comment. Add it during submission — don't wait until live.

### Structure

```
Hey Product Hunt!

[1 sentence: what it is]

[2-3 sentences: origin story — what pain points motivated you to build this]

[1-2 sentences: how it works / what makes it unique vs competitors]

[1 sentence: how to get started + promo code if available]

Would love to hear your thoughts — happy to answer any questions!
```

The maker comment is where you reel the audience in with your origin story. PH users love free trials — end with a clear CTA and discount code if you have one.

### Tips

- **Be humble and helpful** — marketing-speak doesn't resonate
- Use simple language, highlight who the product is for
- Show you know your target users; present use cases
- Images, videos, GIFs, emojis welcome (emojis sparingly)
- If possible, use your own product in replies (like Loom responding with Loom links)
- Co-makers can add their own comments once live
- **Ask for feedback, NOT upvotes**

## Timing

### Best Day

There is no golden-ticket day, but your goals should determine your day:

| Day | Traffic | Competition | Best for |
|-----|---------|-------------|----------|
| **Mon, Fri** | Good | Lower | Higher rank, brand awareness, credibility (#1 badge) |
| **Tue-Thu** | Highest | Fiercest | Maximum traffic, OK with lower rank |
| **Sat-Sun** | Lower | Lowest | Best chance at #1 spot; 15% more "Visit" clicks |

**Mon/Fri** is the sweet spot most agencies recommend for clients prioritizing brand visibility and #1 badge. Once ranked #1, few people check what day it was.

**Warning**: Your launch date is locked once the page goes live at 12:01 AM. No changing your mind.

If your product is gaining traction on X — ride those tailwinds NOW. You can always relaunch later.

### Best Time

- **Default**: Schedule for **12:01 AM PST** — gives full 24 hours on homepage (midnight-to-midnight Pacific cycle)
- **If coordinating with press**: Match your embargo time (e.g., Friday 8am PT if article drops then)
- **If non-US audience**: Consider launching earlier in the day for European/Asian time zones
- **If team needs to be online**: Pick a time when your team can celebrate and respond together

Schedule up to 1 month in advance.

## How the Leaderboard Works

Homepage changes throughout the day based on:
- **Upvote velocity and timing** — not just count. A sudden spike raises flags
- **Comments and discussions** — shows genuine community interest
- **Upvoter quality** — users with high "karma" scores carry more weight. Notable upvotes are highlighted in your dashboard
- **Time since submission**
- **Product quality** — innovative, well-crafted products

All upvotes are equal in weight, but **engagement from seasoned PH accounts matters more than from new ones**.

### Algorithm Pitfalls

- **Launch parties**: Simultaneous votes from the same location trigger spam filters → shadow ban
- **New account flood**: Supporters creating accounts on launch day get votes removed
- **Competitor sabotage**: Competitors can deploy bots/new accounts to trigger deranking. If you see comments from users with red balloon icons (new users), report them as spam
- **Upvoting rings**: PH actively cracks down on communities that band together to cross-upvote

## Promoting Your Launch

### Pre-Launch (Weeks Before)

1. **Join PH community early** — respond to Discussions, give feedback on other launches, make real connections (minimum 1 week, ideally 3+ months)
2. **Build an audience** — #buildinginpublic on social media, share progress, ask for help on features
3. **Host an AMA** on Product Hunt Discussions
4. **Get team involved** — designers, engineers, PMs engaging in community
5. **Invite your community** to join PH so they're ready on launch day
6. **Update your PH profile** — About section, website, social links polished
7. **Prepare landing page** — focused on key values with single CTA. Can be PH-specific with special discount
8. **Tease your scheduled launch** to collect followers before the day

### Launch Day

- **Share on social media** — personal accounts, not just brand
- **Use Launch Day dashboard** — tracks position, upvotes, comments, reviews
- **Add badges & embeds** to your website (drives traffic to launch page)
- **Email newsletters** — one of your strongest tools
- **LinkedIn** — update description + post
- **In-app notifications** — banners for existing users
- **Communities where you've been active** — not cold outreach to new communities

### How NOT to Market (PH Rules)

- **Never ask for upvotes** — ask for feedback, comments, opinions instead. Against PH policies, may result in product removal
- **No contests rewarding upvotes** — giveaways tied to upvotes will get product unfeatured
- **No spam** — don't send hundreds of identical tweets/DMs or scrape email lists for unsolicited messages
- **No paid hunters or promoters** — results in permanent ban

## Newsletter (Daily Digest)

500K+ readers. Delivered every weekday. Includes previous day's **top 10 most upvoted products**. Also has an editorial section highlighting trends and curated collections — you can get featured even if not top 10. Best way to get in: have a successful launch with great content (especially a thoughtful first comment).

## Launch Page vs Product Page

- **Launch Page**: Your launch milestone — drives awareness and traffic during launch
- **Product Page**: Single source of truth as your product grows over time
- **Claim your Product Page** immediately after launch ("Claim this page" or "Request access to manage this page")

## Launch Day Playbook

### Before Launch (1-2 weeks)

- [ ] Gallery images finalized (min 2, recommend 5)
- [ ] Thumbnail (240x240, square)
- [ ] Tagline tested with 5+ people (do they understand what it does?)
- [ ] Maker comment drafted and proofread
- [ ] Landing page with PH badge ready
- [ ] Early supporter list ready (people who want to check it out)
- [ ] Social media announcement posts drafted
- [ ] Video prepared (optional but 53% of PotD include one)
- [ ] Interactive demo built (optional — free tools available)
- [ ] Promo code ready (optional but effective)
- [ ] Team members have PH accounts
- [ ] Launch scheduled on PH

### Launch Day Timeline (Time Zone Strategy)

The algorithm favors **steady engagement throughout the day**, not a single spike. Plan 3 major outreach waves:

| Time (PT) | Action |
|-----------|--------|
| **12:01 AM** | Product goes live, first comment posted. Wave 1: announce to APAC/EU contacts |
| 12:15 AM | Share on personal social media |
| **7:00 AM** | Wave 2: US East Coast wakes up — email blast, LinkedIn, in-app banner |
| 9:00 AM | Share in communities where you've been active |
| 12:00 PM | Mid-day check — reply to all comments |
| **2:00 PM** | Wave 3: afternoon momentum push — email remaining segments, social reshare |
| 6:00 PM | Evening engagement — reply to remaining comments |
| 11:59 PM | Day ends — results are final |

**Email drips**: If you have a sizable list, segment by time zone and schedule up to 10 blasts throughout the day.

**Live embed**: Add a live upvote embed on your website — shows real-time engagement and creates excitement (PH CEO tip). Keep the badge up afterward.

### Engagement Rules

- **Reply to every comment** — creates conversation, shows investment
- **2-3 team members on standby**, batch responses in 2-hour intervals to stay sane
- **Ask questions back** — builds deeper threads
- **Be genuine** — no canned responses
- **Never ask for upvotes** — against PH terms, risk of removal
- **Use your product in replies** if possible (e.g., Loom links, collaborative boards)

### Reviews Drive Conversion

Reviews are the **Amazon reviews section for SaaS**. Quality reviews dramatically increase click-through from your PH page to your website. One-liner reviews don't drive decisions. Get your power users to write detailed reviews about what they love. High comment count also increases click-through from the PH homepage to your launch page.

## Post-Launch

| When | Action |
|------|--------|
| Day 1-3 | Reply to all remaining comments, thank supporters |
| Day 1 | Claim your Product Page |
| Week 1 | Publish "lessons learned" blog post / X thread |
| Week 2 | Follow up with interested users from comments |
| Month 1 | Check eligibility for "Product of the Week/Month" |

## Common Myths (Debunked by PH)

| Myth | Reality |
|------|---------|
| Maker upvotes count more | **False.** All upvotes are equal |
| You need lots of followers to succeed | **False.** PH works to ensure authentic engagement |
| Only worth it if you become #1 | **False.** Many successful products never hit #1 |
| PH penalizes direct product links | **False.** PH encourages linking directly to your product |
| You need a famous hunter | **False.** 79% of featured posts were self-hunted |
| Tue-Thu is the only good time | **False.** Weekend launches get 15% more "Visit" clicks |

## Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| No maker comment | Looks abandoned | Post during submission (70% of winners have one) |
| Asking for upvotes | Against TOS, can get unfeatured/banned | Ask for feedback and comments |
| Generic gallery images | Doesn't show the product | Show real UI, real features, min 2 images |
| Not replying to comments | Low engagement signal | Reply to every single comment |
| Buzzword tagline | Nobody knows what you do | Clear, specific, benefit-focused, <=60 chars |
| Paying for hunters/promoters | Permanent ban risk | Self-hunt (79% of featured posts do) |
| Priming community only on launch day | No momentum built | Start 3+ months before, build presence |
| Not preparing website/content | Lost traffic from launch | Landing page, badge, clear CTA ready |
| Only measuring PotD | Missing real value | Set measurable goals tied to company objectives |
| Launching too late in the day | Less time on homepage | 12:01 AM PST for full 24 hours |
| Using shortened/UTM links | Rejected by PH | Direct product URL only |
| Company brand account | Not allowed | Use personal accounts only |

## Research for Preparation

```bash
# Study similar product launches
infsh app run tavily/search-assistant --input '{
  "query": "Product Hunt top launches analytics tools best practices"
}'

# Competitive landscape
infsh app run exa/search --input '{
  "query": "Product Hunt analytics dashboard tools launched 2024 2025"
}'
```

## References

- [Official PH Launch Guide](https://www.producthunt.com/launch) — submission fields, timing, marketing rules, myths debunked
- [Lenny's Newsletter: How to hit #1 on Product Hunt](https://www.lennysnewsletter.com/p/how-to-hit-1-on-product-hunt) — Leo Bosuener (60+ #1 launches) + Rajiv Ayyangar (PH CEO) tips on algorithm, day-of-week strategy, time zones, signup benchmarks, reviews

## Related Skills

- **launch-marketing**: General launch strategy (PR, press, GTM campaigns)
- **copywriting**: Landing page and website copy
- **positioning-messaging**: Value proposition and positioning
- **social-writer**: Social media posts for launch promotion
- **community-building**: Building pre-launch community presence
- **brand-storytelling**: Crafting your maker story for first comment

Follow output preferences from USER.md (language, format, platform constraints).
