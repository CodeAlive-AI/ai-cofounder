# USER.md template

The rendered file is plain Markdown. OpenClaw reads it on every fresh session as bootstrap context — keep it under ~3 KB so the context budget isn't blown.

## Template

```markdown
# About the user

## Identity
- **Name**: {{user.name}}
- **Role**: {{user.role}}
- **Company / project**: {{user.company}}{{#if user.stage}} (stage: {{user.stage}}){{/if}}

## Focus right now (next 1-2 weeks)
{{#each focus.items}}
- {{this}}
{{/each}}

## Communication style
- Default language: **{{style.language}}**
- Emoji: {{#if style.emoji}}use sparingly when the user uses them first{{else}}don't use{{/if}}
- Formality: {{style.formality}}
- When the user is wrong or making a questionable call: respond {{style.feedback}}

## Tools the user lives in
- Email: {{tools.email}}
- Calendar: {{tools.calendar}}
- Messengers: {{tools.messengers}}
- Code agent: {{tools.code_agent}}
{{#each tools.other}}
- {{this}}
{{/each}}

{{#if anti_patterns}}
## Anti-patterns (do NOT do these)
{{#each anti_patterns}}
- {{this}}
{{/each}}
{{/if}}

---
Last updated by `openclaw-user-onboarding` skill on {{timestamp}}.
```

The `{{...}}` mustache-style placeholders are just a visual aid for this document — the actual rendering happens in the agent's head, not via a template engine. Don't worry about whitespace fiddliness; the resulting Markdown is human-readable and that's enough.

## Worked example

Input from the user (free-form reply to the five questions):

> 1. Родион Мостовой, CEO CodeAlive, YC W26, seed-stage SaaS для разработчиков
> 2. Закрыть 3 enterprise пилота, нанять Head of Sales, запустить v3 Skills CLI
> 3. Русский по умолчанию, английский для технических вопросов. Без эмодзи. На ты. Прямо когда я ошибаюсь — не виляй.
> 4. Gmail (rodion@codealive.ai), Google Calendar, Telegram + Slack, Claude Code как код-агент
> 5. Не пиши после 23:00 если не пожар. Без маркетингового жаргона. Не предлагай решения пока я не попросил — сначала уточняй.

Rendered USER.md:

```markdown
# About the user

## Identity
- **Name**: Родион Мостовой
- **Role**: CEO
- **Company / project**: CodeAlive (stage: YC W26, seed-stage)
- **Product**: SaaS для разработчиков (AI-агенты для инженерных команд)

## Focus right now (next 1-2 weeks)
- Закрыть 3 enterprise пилота
- Нанять Head of Sales
- Запустить v3 Skills CLI

## Communication style
- Default language: **русский**; английский для технических вопросов
- Emoji: don't use
- Formality: на ты
- When I'm wrong or making a questionable call: respond directly — don't hedge

## Tools the user lives in
- Email: Gmail (rodion@codealive.ai)
- Calendar: Google Calendar
- Messengers: Telegram + Slack
- Code agent: Claude Code

## Anti-patterns (do NOT do these)
- Не пиши после 23:00 если не пожар
- Без маркетингового жаргона
- Не предлагай решения пока я не попросил — сначала уточняй

---
Last updated by `openclaw-user-onboarding` skill on 2026-05-21.
```

## Style notes for rendering

- Use the user's exact wording where it's tight and clear. Paraphrase only when the user wrote a wall of text or used contradictory wording.
- Keep bullets short (one line each). If the user's answer was a paragraph, break it into bullets.
- Keep section headers fixed (Identity, Focus, Communication style, Tools, Anti-patterns). The bot's other skills may look for these by name.
- "Anti-patterns" section is **omitted** if the user genuinely had none — empty bullets look like a mistake. If the user said "nothing", write "(пользователь не указал явных антипаттернов)" instead.
- Always include the footer with timestamp.

## What to NOT write into USER.md

These are tempting fields that don't belong here — they live elsewhere:

| Tempting addition | Where it actually goes |
|---|---|
| The company's long-term mission | `MEMORY.md` (strategic context, human-curated) |
| OKRs, quarterly goals | `MEMORY.md` |
| Daily logs, "what we did today" | `memory/YYYY-MM-DD.md` (agent-owned) |
| Notes about the user's mood / energy | nowhere — bot infers from each message |
| Phone number, full address, bank info | nowhere — out of scope |
| Family info, hobbies | only if the user explicitly mentioned and it's relevant to the bot's job |

The rule of thumb: **USER.md = preferences and stable identity. Anything that changes week-to-week goes in MEMORY.md (if strategic) or `memory/*.md` (if operational).**
