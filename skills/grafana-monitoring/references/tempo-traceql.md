# Tempo TraceQL Reference

## Table of Contents
- [TraceQL Basics](#traceql-basics)
- [Span Attributes](#span-attributes)
- [Metrics Functions](#metrics-functions)
- [Common Patterns](#common-patterns)
- [MCP Tool Usage](#mcp-tool-usage)

## TraceQL Basics

### Span Selection

```traceql
{ <conditions> }
```

### Attribute Types

| Prefix | Description | Example |
|--------|-------------|---------|
| `span.` | Span attributes | `span.http.request.method` |
| `resource.` | Resource attributes | `resource.service.name` |
| `span:` | Intrinsic properties | `span:duration`, `span:status` |
| `event.` | Event attributes | `event.exception.message` |

### Operators

```traceql
=    # Equals
!=   # Not equals
=~   # Regex match
!~   # Regex not match
>    # Greater than
>=   # Greater or equal
<    # Less than
<=   # Less or equal
```

### Combining Conditions

```traceql
# AND (implicit)
{span.http.request.method = "POST" && span.http.response.status_code >= 400}

# OR
{span.http.request.method = "GET" || span.http.request.method = "POST"}
```

## Span Attributes

### Intrinsic Properties

| Property | Description |
|----------|-------------|
| `duration` | Span duration |
| `name` | Span name |
| `status` | Span status (ok, error, unset) |
| `statusMessage` | Status message |
| `kind` | Span kind (server, client, internal) |
| `span:duration` | Span duration (alternative) |
| `span:id` | Span ID |
| `span:kind` | Span kind |
| `span:name` | Span name |
| `span:parentID` | Parent span ID |
| `span:status` | Span status |
| `span:statusMessage` | Status message |
| `trace:duration` | Total trace duration |
| `trace:id` | Trace ID |
| `trace:rootName` | Root span name |
| `trace:rootService` | Root service name |
| `rootName` | Root span name (short) |
| `rootServiceName` | Root service name (short) |

### Resource Attributes

| Attribute | Description |
|-----------|-------------|
| `resource.service.name` | Service name (web-server, jobs-heavy, ai-server, etc.) |
| `resource.service.version` | Service version |
| `resource.service.instance.id` | Instance ID |
| `resource.deployment.environment` | Environment (production, staging) |
| `resource.host.name` | Host name |
| `resource.host.arch` | Host architecture |
| `resource.host.id` | Host ID |
| `resource.process.pid` | Process ID |
| `resource.process.owner` | Process owner |
| `resource.process.runtime.name` | Runtime name |
| `resource.process.runtime.version` | Runtime version |
| `resource.telemetry.sdk.language` | SDK language |
| `resource.telemetry.sdk.name` | SDK name |
| `resource.telemetry.sdk.version` | SDK version |
| `resource.telemetry.distro.name` | Distro name |
| `resource.telemetry.distro.version` | Distro version |

### HTTP Attributes

| Attribute | Description |
|-----------|-------------|
| `span.http.request.method` | HTTP method (GET, POST, etc.) |
| `span.http.response.status_code` | HTTP response status |
| `span.http.route` | API route |
| `span.url.path` | URL path |
| `span.url.full` | Full URL |
| `span.url.query` | URL query string |
| `span.url.scheme` | URL scheme (http, https) |
| `span.user_agent.original` | User agent |
| `span.server.address` | Server address |
| `span.server.port` | Server port |
| `span.network.protocol.version` | Protocol version |
| `span.network.transport` | Transport (tcp, udp) |

### Database Attributes

| Attribute | Description |
|-----------|-------------|
| `span.db.system.name` | Database type (mongodb, opensearch) |
| `span.db.operation.name` | Operation type |
| `span.db.collection.name` | Collection name |
| `span.db.namespace` | Database namespace |
| `span.db.connection_id` | Connection ID |
| `span.db.query.text` | Query text |

### GenAI/LLM Attributes

| Attribute | Description |
|-----------|-------------|
| `span.gen_ai.operation.name` | Operation name |
| `span.gen_ai.provider.name` | LLM provider (anthropic, openai) |
| `span.gen_ai.request.model` | Requested model |
| `span.gen_ai.response.model` | Response model |
| `span.gen_ai.request.max_tokens` | Max tokens requested |
| `span.gen_ai.usage.input_tokens` | Input token count |
| `span.gen_ai.usage.output_tokens` | Output token count |
| `span.gen_ai.usage.prompt_cost_usd` | Prompt cost (USD) |
| `span.gen_ai.usage.completion_cost_usd` | Completion cost (USD) |
| `span.gen_ai.usage.total_cost_usd` | Total cost (USD) |
| `span.llm.complexity` | Complexity level |
| `span.llm.purpose` | LLM purpose |
| `span.llm.response_type` | Response type |
| `span.llm.task_name` | Task name |
| `span.langfuse.session.id` | Langfuse session ID |
| `span.langfuse.trace.name` | Langfuse trace name |

### [YOUR_PRODUCT] Job Attributes

| Attribute | Description |
|-----------|-------------|
| `span.job.id` | Job ID |
| `span.job.name` | Job name |
| `span.job.type` | Job type |
| `span.job.status` | Job status |
| `span.job.duration_ms` | Job duration (ms) |
| `span.job.createdat` | Job creation time |
| `span.job.error` | Job error flag |
| `span.job.error.type` | Job error type |
| `span.job.owner.organisation_id` | Owner organization ID |
| `span.jobs.active.total` | Total active jobs |
| `span.jobs.active.processing` | Processing jobs |

### [YOUR_PRODUCT] Indexing Attributes

| Attribute | Description |
|-----------|-------------|
| `span.repository_id` | Repository ID |
| `span.repository_size_bytes` | Repository size |
| `span.commit_id` | Commit ID |
| `span.artifacts_count` | Artifacts count |
| `span.vectorized_artifacts_count` | Vectorized artifacts |
| `span.indexing_duration_ms` | Indexing duration |
| `span.processing_duration_ms` | Processing duration |
| `span.lsp_processed` | LSP processed count |
| `span.roslyn_processed` | Roslyn processed count |
| `span.removed_min_js_files` | Removed minified JS files |
| `span.removed_min_css_files` | Removed minified CSS files |

### [YOUR_PRODUCT] Search Attributes

| Attribute | Description | Values |
|-----------|-------------|--------|
| `span.search.mode` | Search mode | <your-mode-1>, <your-mode-2>, <your-mode-3>, <your-mode-4> |
| `span.session.id` | Session ID | UUID |
| `span.fingerprint_similarity` | Fingerprint similarity | Float |
| `span.result` | Result type | String |
| `span.skip_reason` | Skip reason | String |

### Repository Management Attributes

| Attribute | Description |
|-----------|-------------|
| `span.repos.candidates` | Candidate repos |
| `span.repos.errors` | Repo errors |
| `span.repos.reanimated` | Reanimated repos |
| `span.repos.stale` | Stale repos |
| `span.rewards.processed` | Rewards processed |

### Error Attributes

| Attribute | Description |
|-----------|-------------|
| `span.error` | Error flag |
| `span.error.type` | Error type |
| `span.error.retryable` | Retryable flag |
| `span.exception.message` | Exception message |
| `span.exception.type` | Exception type |
| `span.failure_reason` | Failure reason |
| `span.status` | Status |

### gRPC Attributes

| Attribute | Description |
|-----------|-------------|
| `span.rpc.system` | RPC system (grpc) |
| `span.rpc.service` | RPC service |
| `span.rpc.method` | RPC method |
| `span.rpc.grpc.status_code` | gRPC status code |

### Event Attributes

| Attribute | Description |
|-----------|-------------|
| `event.exception.message` | Exception message |
| `event.exception.type` | Exception type |
| `event.exception.stacktrace` | Stack trace |

### Organization Attributes

| Attribute | Description |
|-----------|-------------|
| `span.organization.id` | Organization ID |

## Metrics Functions

### rate()
Spans per second.

```traceql
{span:status = error} | rate()
{resource.service.name = "web-server"} | rate() by (span.http.route)
```

### count_over_time()
Count spans per interval.

```traceql
{span.search.mode != ""} | count_over_time() by (span.search.mode)
```

### avg_over_time()
Average of numeric values.

```traceql
{span.search.mode != ""} | avg_over_time(duration) by (span.search.mode)
{resource.service.name = "web-server"} | avg_over_time(span:duration)
```

### quantile_over_time()
Calculate percentiles.

```traceql
{resource.service.name = "web-server"} | quantile_over_time(duration, .50, .95, .99)
{span.search.mode != ""} | quantile_over_time(duration, .50, .95, .99) by (span.search.mode)
```

### sum_over_time()
Sum numeric values.

```traceql
{span.gen_ai.usage.input_tokens > 0} | sum_over_time(span.gen_ai.usage.input_tokens)
```

### min_over_time() / max_over_time()
Find extremes.

```traceql
{resource.service.name = "web-server"} | max_over_time(span:duration)
```

### histogram_over_time()
Duration distribution.

```traceql
{resource.service.name = "web-server"} | histogram_over_time(duration)
```

### Grouping with by()

```traceql
{span:status = error} | rate() by (resource.service.name)
{span.search.mode != ""} | avg_over_time(duration) by (span.search.mode)
```

### Limiting with topk() / bottomk()

```traceql
{} | avg_over_time(span:duration) by (span.http.route) | topk(10)
{span:status = error} | rate() by (resource.service.name) | topk(5)
```

## Common Patterns

### Find Slow Requests

```traceql
# Requests slower than 5 seconds
{span:duration > 5s}

# Slow requests by service
{span:duration > 5s && resource.service.name = "web-server"}

# Top 10 slowest endpoints
{resource.service.name = "web-server"} | avg_over_time(span:duration) by (span.http.route) | topk(10)
```

### Search Mode Analysis

```traceql
# Average duration by search mode
{span.search.mode != ""} | avg_over_time(duration) by (span.search.mode)

# Request count by search mode
{span.search.mode != ""} | count_over_time() by (span.search.mode)

# Percentiles by search mode
{span.search.mode != ""} | quantile_over_time(duration, .50, .95, .99) by (span.search.mode)

# Deep mode only
{span.search.mode = "Deep"} | avg_over_time(duration)

# Fast modes combined
{span.search.mode =~ "Fast.*"} | avg_over_time(duration) by (span.search.mode)
```

### Error Analysis

```traceql
# All error spans
{span:status = error}

# Error rate by service
{span:status = error} | rate() by (resource.service.name)

# Errors with HTTP 5xx
{span.http.response.status_code >= 500}

# Database errors
{span:status = error && span.db.system.name != ""}

# Errors by type
{span.error.type != ""} | count_over_time() by (span.error.type)
```

### LLM/GenAI Analysis

```traceql
# Token usage by model
{span.gen_ai.usage.input_tokens > 0} | sum_over_time(span.gen_ai.usage.input_tokens) by (span.gen_ai.request.model)

# LLM call duration by provider
{span.gen_ai.provider.name != ""} | avg_over_time(span:duration) by (span.gen_ai.provider.name)

# Cost by model
{span.gen_ai.usage.total_cost_usd > 0} | sum_over_time(span.gen_ai.usage.total_cost_usd) by (span.gen_ai.request.model)

# LLM calls by purpose
{span.llm.purpose != ""} | count_over_time() by (span.llm.purpose)

# LLM latency by complexity
{span.llm.complexity != ""} | avg_over_time(span:duration) by (span.llm.complexity)
```

### Job Analysis

```traceql
# Job duration by name
{span.job.name != ""} | avg_over_time(span:duration) by (span.job.name)

# Failed jobs
{span.job.error = "true"} | count_over_time() by (span.job.name)

# Job errors by type
{span.job.error.type != ""} | count_over_time() by (span.job.error.type)
```

### Service Dependencies

```traceql
# Calls between services
{resource.service.name = "web-server" && span:kind = "client"}

# Database calls
{span.db.system.name = "mongodb"} | avg_over_time(span:duration) by (span.db.operation.name)

# External HTTP calls
{span:kind = "client" && span.http.request.method != ""}

# gRPC calls
{span.rpc.system = "grpc"} | avg_over_time(span:duration) by (span.rpc.service, span.rpc.method)
```

### Indexing Pipeline Analysis

```traceql
# Indexing duration by repository
{span.indexing_duration_ms > 0} | avg_over_time(span.indexing_duration_ms) by (span.repository_id)

# Artifacts processed
{span.artifacts_count > 0} | sum_over_time(span.artifacts_count)

# Repository processing
{span.repository_size_bytes > 0} | avg_over_time(span.processing_duration_ms)
```

## MCP Tool Usage

### Get Attribute Names
```
mcp__grafana__tempo_get-attribute-names(
  datasourceUid: "grafanacloud-traces",
  scope: "span"  # or "resource", "event"
)
```

### Get Attribute Values
```
mcp__grafana__tempo_get-attribute-values(
  datasourceUid: "grafanacloud-traces",
  name: "span.search.mode"
)
```

### Search Traces
```
mcp__grafana__tempo_traceql-search(
  datasourceUid: "grafanacloud-traces",
  query: "{span:duration > 5s}",
  start: "2026-01-25T00:00:00Z",
  end: "2026-01-26T00:00:00Z"
)
```

### Instant Metrics Query
```
mcp__grafana__tempo_traceql-metrics-instant(
  datasourceUid: "grafanacloud-traces",
  query: "{span.search.mode != \"\"} | avg_over_time(duration) by (span.search.mode)"
)
```

### Range Metrics Query
```
mcp__grafana__tempo_traceql-metrics-range(
  datasourceUid: "grafanacloud-traces",
  query: "{span.search.mode != \"\"} | avg_over_time(duration) by (span.search.mode)",
  start: "2026-01-25T17:00:00Z",
  end: "2026-01-26T17:00:00Z"
)
```

### Get Trace by ID
```
mcp__grafana__tempo_get-trace(
  datasourceUid: "grafanacloud-traces",
  trace_id: "abc123..."
)
```

### Get TraceQL Documentation
```
mcp__grafana__tempo_docs-traceql(
  datasourceUid: "grafanacloud-traces",
  name: "metrics"  # or "basic", "aggregates", "structural"
)
```

### Time Range Limits

- **Metrics queries**: Maximum 25 hours
- **Trace search**: Depends on retention settings
- **Format**: RFC3339 required (`2026-01-26T12:00:00Z`)

### Tips

1. **Get attribute names first** before building queries
2. **Use metrics-instant** for single-point-in-time analysis
3. **Use metrics-range** for time series visualization
4. **Use trace search** to find specific traces, then get details with get-trace
5. **Filter by resource.service.name** for better performance
6. **Use span. prefix** for span attributes (e.g., `span.search.mode`)
