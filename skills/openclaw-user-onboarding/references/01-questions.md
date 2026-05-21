# Onboarding questions — variants and rationale

The five-question prompt is sent in **one** message. Three language variants below; pick by `$USER_LANGUAGE`.

## Why five, in this order

We're not trying to capture everything — we want a profile that's *useful from message one*. Anything past five fields turns this into a survey, which is the failure mode we're trying to avoid (Sales 101: every additional form field cuts completion ~15%).

| # | Field | Why it's worth asking on day one |
|---|---|---|
| 1 | **Identity** (name, role, company) | Without this, the bot's first response is "Здравствуйте! Чем могу помочь?" — generic. With it, the bot can say "Родион, у тебя сегодня встреча с..." — specific. Single highest-ROI field. |
| 2 | **Focus** (this week / next two weeks) | Lets the bot bias its suggestions toward what actually matters now, instead of toward whatever the user's latest message happens to mention. Tactical horizon, not strategic — annual goals belong in MEMORY.md, not USER.md. |
| 3 | **Style** | The bot defaults to formal Russian with no emoji. ~40% of CEOs/founders want informal `ты` and zero hedging. Asking saves a week of "не пиши так, пиши вот так" corrections. |
| 4 | **Tools** | Future skills (calendar, email, slack) hook into specific providers. Knowing "Google Calendar + Gmail + Slack" upfront lets the bot propose "хочешь поставлю в календарь?" instead of asking "какой у тебя календарь?". |
| 5 | **Anti-patterns** | The single most underused field. Most users have 1-2 specific things that drive them up the wall ("не пиши после 22:00", "не предлагай прежде, чем я спросил"). Capturing them costs 10 seconds and saves a year of friction. |

What we deliberately do NOT ask:
- Age, gender, location → irrelevant; if relevant, comes up organically
- Long-term goals → belongs in MEMORY.md (human-curated stratagic state), not USER.md (preferences)
- Industry → derivable from company name; asking is noise
- "How did you hear about us?" → not a product survey

## Russian (default)

```
Последний шаг — расскажи коротко о себе, чтобы я был полезным с первого сообщения в Telegram. Заполни в любом формате (можно по пунктам, можно одним абзацем, можно пропустить пункт — напиши «пропусти»).

1. Как тебя называть и чем ты занимаешься?
   Имя, роль, компания/проект, стадия (если применимо).

2. Что важно на ближайшие 1-2 недели?
   1-3 главных задачи или цели.

3. Стиль общения.
   Язык по умолчанию (русский/английский/смешанно), эмодзи (да/нет), на «ты» или на «вы», как реагировать когда я ошибаюсь — прямо или мягко.

4. Чем пользуешься?
   Почта (gmail, yandex, ...), календарь, мессенджеры, код-агент — что в твоей повседневке.

5. Чего НЕ нужно от меня?
   Что раздражает, что не делай (например: «не пиши после 23:00», «без маркетингового жаргона», «не предлагай решения, пока я не попросил»).

Если что-то неудобно отвечать сейчас — пиши «пропусти» по этому пункту, поправим потом.
```

## English

```
Last step — tell me a bit about yourself so I'm useful from message one in Telegram. Any format works (bullets, one paragraph, skip fields by writing "skip").

1. What should I call you, and what do you do?
   Name, role, company/project, stage (if applicable).

2. What matters in the next 1-2 weeks?
   1-3 main tasks or goals.

3. Communication style.
   Default language, emoji (yes/no), level of formality, and whether you want me to push back directly or softly when I think you're wrong.

4. What tools do you live in?
   Email (gmail, outlook, ...), calendar, messengers, code agent — your daily kit.

5. What do you NOT want from me?
   Pet peeves and anti-patterns (e.g. "don't message after 11pm", "no marketing fluff", "don't suggest solutions before I ask").

Skip any field that's awkward right now — we'll come back to it.
```

## Kazakh

```
Соңғы қадам — Telegram-да бірінші хабарламадан бастап пайдалы болуым үшін өзің туралы қысқаша айтып бер. Кез келген пішімде толтыруға болады (тізіммен, бір абзацпен, керек болмаса «өткіз» деп жазып өтуге болады).

1. Сені қалай шақыруға болады және немен айналысасың?
   Аты-жөнің, рөлі, компания/жоба, кезеңі (керек болса).

2. Алдағы 1-2 аптада не маңызды?
   1-3 басты міндет немесе мақсат.

3. Қарым-қатынас стилі.
   Әдепкі тіл, эмодзи (иә/жоқ), ресмиліктің деңгейі, қателескенімде тура немесе жұмсақ айту керек пе.

4. Қандай құралдарды күнделікті қолданасың?
   Электрондық пошта, күнтізбе, мессенджерлер, код-агент.

5. Менен НЕ керек емес?
   Ашуландыратын дүние, болмауы керек әрекеттер (мысалы: «түнгі 23:00-ден кейін жазба», «маркетинг сөзін қолданба», «сұрағанша шешім ұсынба»).

Қазір ыңғайсыз болса — «өткіз» деп жаз, кейін қайта оралармыз.
```

## After the user answers

The reply is free-form. Don't regex — use the LLM to extract slots into the table below:

| Slot | Type | Default if user skipped or didn't mention |
|---|---|---|
| `user.name` | string | "пользователь" |
| `user.role` | string | "(не указано)" |
| `user.company` | string | "(не указано)" |
| `user.stage` | string | "(не указано)" |
| `focus.items` | list of strings | ["(не указано)"] |
| `style.language` | string (`ru` / `en` / `kk` / `mixed`) | `$USER_LANGUAGE` |
| `style.emoji` | bool | `false` |
| `style.formality` | string (`ты` / `вы` / `casual` / `formal`) | `ты` for ru, `casual` for en |
| `style.feedback` | string (`direct` / `soft`) | `direct` |
| `tools.email` | string or list | "(не указано)" |
| `tools.calendar` | string | "(не указано)" |
| `tools.messengers` | list | "(не указано)" |
| `tools.code_agent` | string | "(не указано)" |
| `tools.other` | list | [] |
| `anti_patterns` | list of strings | [] |

If `anti_patterns` is empty, do NOT write the section in USER.md at all — empty bullet lists look like the user forgot. If the user explicitly said "ничего" / "nothing", write "(пользователь не указал явных антипаттернов)" — that's informative.

If `focus.items` is `["(не указано)"]`, write the field as "(не указано — пользователь предпочёл не отвечать сейчас)". On a re-run, the skill can re-ask just this one.
