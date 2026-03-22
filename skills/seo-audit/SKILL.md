---
name: seo-audit
description: Audit, review, or diagnose SEO issues on the site. Use for "SEO audit," "technical SEO," "why am I not ranking," "SEO issues," "on-page SEO," "meta tags review," "SEO health check," "my traffic dropped," "lost rankings," "page speed," "core web vitals," "crawl errors," "indexing issues." For building pages at scale, see programmatic-seo. For content planning, see content-strategy.
metadata:
  version: 1.1.0
---
## Company Context

Before helping, read `MEMORY.md` for: current wedge, ICP, competitors, PMF stage, system constraint.
Apply all frameworks to the user's specific company and stage (read from MEMORY.md).
Follow output preferences from USER.md (language, format, platform constraints).

# SEO Audit

You are an expert in search engine optimization. Your goal is to identify SEO issues and provide actionable recommendations to improve organic search performance.

## Initial Assessment

Before auditing, understand:

1. **Site Context**
   - What type of site? (SaaS, e-commerce, blog, docs)
   - What's the primary business goal for SEO?
   - What keywords/topics are priorities?

2. **Current State**
   - Any known issues or concerns?
   - Current organic traffic level?
   - Recent changes or migrations?

3. **Scope**
   - Full site audit or specific pages?
   - Technical + on-page, or one focus area?
   - Access to Search Console / analytics?

---

## Audit Framework

### Schema Markup Detection Limitation

**`web_fetch` and `curl` cannot reliably detect structured data / schema markup.**

Many CMS plugins inject JSON-LD via client-side JavaScript — it won't appear in static HTML or `web_fetch` output.

**To accurately check for schema markup:**
1. **Browser tool** — render the page and run: `document.querySelectorAll('script[type="application/ld+json"]')`
2. **Google Rich Results Test** — https://search.google.com/test/rich-results

### Priority Order
1. **Crawlability & Indexation** (can Google find and index it?)
2. **Technical Foundations** (is the site fast and functional?)
3. **On-Page Optimization** (is content optimized?)
4. **Content Quality** (does it deserve to rank?)
5. **Authority & Links** (does it have credibility?)

---

## Technical SEO Audit

### Crawlability

**Robots.txt**
- Check for unintentional blocks
- Verify important pages allowed
- Check sitemap reference

**XML Sitemap**
- Exists and accessible
- Contains only canonical, indexable URLs
- Updated regularly

**Site Architecture**
- Important pages within 3 clicks of homepage
- Logical hierarchy
- Internal linking structure
- No orphan pages

### Performance

**Core Web Vitals**
- LCP < 2.5s
- INP < 200ms
- CLS < 0.1

**Page Speed**
- Check with web_fetch or browser tool
- Identify largest resources
- Image optimization (WebP/AVIF, lazy loading)
- CSS/JS minification

### Mobile
- Responsive design
- Touch-friendly elements
- No horizontal scrolling
- Readable without zooming

### Security
- HTTPS everywhere
- No mixed content
- Valid SSL certificate

---

## On-Page SEO Audit

### Title Tags
- Unique per page
- 50-60 characters
- Primary keyword included
- Compelling for click-through

### Meta Descriptions
- Unique per page
- 150-160 characters
- Include call-to-action
- Keyword present naturally

### Heading Structure
- One H1 per page (matches topic)
- Logical H2-H3 hierarchy
- Keywords in headings naturally
- No skipped heading levels

### URL Structure
- Short, descriptive
- Hyphens between words
- No parameters if avoidable
- Matches content hierarchy

### Internal Linking
- Descriptive anchor text
- Link to relevant pages
- Spread link equity to important pages
- Fix broken links

### Images
- Descriptive alt text
- Compressed file sizes
- Proper dimensions
- Lazy loading for below-fold

---

## Content Quality Audit

### Content Assessment
- Does it answer the search query fully?
- Is it more helpful than competing pages?
- Does it demonstrate expertise?
- Is it up to date?

### Content Issues
- Thin content (< 300 words with no depth)
- Duplicate content (internal or external)
- Keyword cannibalization (multiple pages targeting same keyword)
- Missing content for important topics

---

## Output Format

### Audit Report
```
Priority: Critical / High / Medium / Low
Issue: [What's wrong]
Impact: [Why it matters for SEO]
Fix: [How to fix it]
Effort: Quick fix / Medium / Major project
```

### Action Plan
Organize findings into:
1. **Quick wins** — high impact, low effort
2. **Strategic fixes** — high impact, higher effort
3. **Maintenance items** — lower priority improvements

**For AI search optimization guidance**: See [references/ai-writing-detection.md](references/ai-writing-detection.md)

---

## Site-Type Specific Notes

### SaaS Sites
- Documentation pages need SEO too
- Feature pages should target "[solution] for [use case]"
- Comparison pages: "[Product] vs [competitor]"
- Integration pages: "[Product] + [tool] integration"
- Use case pages: "[Product category] for [industry/team]"

---

## Generative Engine Optimization (GEO)

Traditional SEO gets you into Google results. GEO gets you cited by AI answer engines (Perplexity, ChatGPT, Google AI Overviews, Gemini). Users increasingly discover tools through AI search.

### Why GEO matters

Users ask AI questions about your category. If your content is structured for RAG retrieval, it gets cited. Free acquisition channel.

### GEO audit checklist

**Content structure for RAG citation:**
- Clear, factual statements that can be extracted as standalone answers
- Specific numbers and benchmarks (not "significantly faster" but "83% faster indexing")
- Direct answer to the query in the first paragraph, details below
- Avoid burying the answer in marketing fluff — AI extractors skip preamble

**E-E-A-T signals for AI engines:**
- Author bylines with credentials on blog/docs pages
- "Last updated" dates on all content pages
- Links to primary sources (GitHub repos, benchmarks, case studies)
- Technical depth that demonstrates first-hand experience

**Structured data for answer engines:**
- FAQ schema (JSON-LD) on feature and pricing pages — AI engines parse FAQ schema directly
- HowTo schema on integration/setup guides
- SoftwareApplication schema on the main product page
- Organization schema with founder and company details

**Content types that get cited by AI:**
- Comparison pages: "[Product] vs [Competitor]" — AI engines love structured comparisons
- "What is X" explainer pages — definition queries trigger RAG retrieval
- Integration guides: "How to use [Product] with [Tool]" — procedural queries
- Benchmark/data pages with specific numbers — AI cites sources with data

**Technical signals:**
- Fast page load (AI crawlers have timeouts; slow pages get skipped)
- Clean HTML with semantic tags (h1-h3 hierarchy, article, section)
- No JS-only content rendering — AI crawlers often don't execute JS
- Sitemap with lastmod dates — freshness signal for AI indexing

### GEO quick wins

1. Add FAQ schema to landing page and pricing page
2. Create "What is [Product]" / "What is [category]" explainer pages
3. Add comparison pages (vs top 3 competitors from MEMORY.md)
4. Ensure docs pages have clean H1 > H2 > H3 hierarchy
5. Add "Last updated" timestamps to all documentation pages
6. Make sure integration guides answer the query in the first sentence

---

## Related Skills

- **programmatic-seo**: For building SEO pages at scale
- **content-strategy**: For planning what content to create
- **copywriting**: For improving page copy
- **posthog-analytics**: For tracking organic traffic events
- **web-browser**: For rendering pages and checking JS-injected schema
- **humanizer**: For ensuring content doesn't read as AI-generated (AI engines may deprioritize obvious AI slop)
