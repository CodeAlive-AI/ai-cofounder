---
name: person-lookup
description: "Look up a person's background: work history, education, social profiles, contact info. Use when asked 'who is [person]?' or need to research someone before a meeting. For finding their email specifically, see find-email-by-name. For enriching a lead with full contact data, see lead-enrichment."
user-invocable: true
---

## [YOUR_PRODUCT] Context

Before helping, check `MEMORY.md` for current contacts and relationships.
Output in Russian (names, titles, company names in original).
For chat platforms: bio-style summary, not raw data dump.

# Person Lookup

Find detailed background on a person: work history, education, social profiles, contact info.

## Usage

### Search by Name + Company (Nyne)

```bash
orth run nyne /person/search -d '{"query": "FULL_NAME COMPANY"}'
```

NOTE: Nyne searches are **async**. The POST returns a `request_id`. Poll with:

```bash
orth run nyne /person/search -q request_id=REQUEST_ID
```

Retry every 3-5 seconds until status is complete. Usually takes 5-15 seconds.

### Search Tips

- Include company name: `"Dario Amodei Anthropic"`
- Include title for common names: `"John Smith CTO Acme"`
- Use LinkedIn URL if available for exact match

## Response Fields

- Full name and current title
- Current employer and role
- Work history (previous companies, roles, dates)
- Education (schools, degrees)
- Location
- Social profiles (LinkedIn, Twitter)
- Skills and expertise

## Output Format

```
**[Name]** — [Current Title] @ [Current Company]

Background:
- Previously: [role] @ [company] ([years])
- Education: [school], [degree]
- Location: [city]

Profiles: [LinkedIn], [Twitter]
```

If researching before a meeting, add:
```
Meeting prep notes:
- [relevant background detail]
- [shared connection or interest]
- [topic to discuss]
```

## Error Handling

- **Async timeout** — if no result after 30 seconds, report partial data
- **Multiple results** — add company or title to narrow down
- **No results** — try alternate name spelling, or use Fiber people-search as fallback:

```bash
orth run fiber /v1/people-search -d '{"searchParams": {"full_name": "FULL_NAME", "company_names": ["COMPANY"]}}'
```

## Related Skills

- **meeting-prep** — pre-meeting briefings combining person + company + pipeline context
- **find-email-by-name** — find their email address
- **lead-enrichment** — full contact enrichment (email + phone + company)
- **company-intel** — research their company
- **exa-people-research** — web-based person research via Exa
- **sales-qualification** — qualify them as a lead
