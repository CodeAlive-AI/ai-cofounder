---
name: grafana-monitoring
description: Grafana Cloud monitoring — dashboards, alerts, Loki logs, Prometheus metrics, Tempo traces, incidents, Sift error investigation. Use for infrastructure and application observability. Triggers on "check logs", "show logs", "look at logs", "read logs", "view logs", "investigate errors", "query metrics", "analyze traces", "check latency", "find slow requests", "error rate", "why is API slow", "production errors", "job failures", "LLM costs", "check alerts", "firing alerts", "create incident", "oncall", "error patterns", "indexing status", "repository indexing", "is repo indexed", "indexing progress", "indexing errors", "indexer". ANY request about logs goes through this skill (Loki). For repository indexing status — query indexer logs. For product analytics use posthog-analytics instead.
user-invocable: true
---

# Grafana Monitoring

Access to [YOUR_PRODUCT]'s Grafana Cloud instance for infrastructure monitoring, alerting, and observability.

**Instance:** https://<your-stack>.grafana.net

## Tool

Call the native MCP tool `grafana__<tool-name>` directly (server=grafana, tool=<tool-name>). Parameters go in a JSON object — examples below use shorthand key=value.

## Datasources

| Pillar | Name | UID | Type |
|--------|------|-----|------|
| **Logs** | grafanacloud-[your-product]-logs | `grafanacloud-logs` | Loki |
| **Metrics** | grafanacloud-[your-product]-prom | `grafanacloud-prom` | Prometheus |
| **Traces** | grafanacloud-[your-product]-traces | `grafanacloud-traces` | Tempo |

## Services

| Service | Description |
|---------|-------------|
| `web-server` | Main API server (.NET) |
| `jobs-heavy` | Heavy background jobs (.NET) |
| `jobs-light` | Lightweight background jobs (.NET) |
| `indexer` | Primary indexing pipeline |
| `ai-server` | AI agent coordination (Python) |

## Key Tools

### Logs (Loki)

See [references/loki-logql.md](references/loki-logql.md) for complete LogQL guide.

```bash
# Errors from web server
grafana__query_loki_logs datasourceUid="grafanacloud-logs" logQL='{service_name="web-server", level=~"ERROR|Error|Fatal"}'

# Search for exception
grafana__query_loki_logs datasourceUid="grafanacloud-logs" logQL='{service_name="web-server"} |= "NullReferenceException"'

# Job failures
grafana__query_loki_logs datasourceUid="grafanacloud-logs" logQL='{service_name=~"jobs-heavy|jobs-light"} |= "failed"'

# Check log volume before querying
grafana__query_loki_stats datasourceUid="grafanacloud-logs" logQL='{service_name="web-server"}'

# Discover labels
grafana__list_loki_label_names datasourceUid="grafanacloud-logs"
grafana__list_loki_label_values datasourceUid="grafanacloud-logs" labelName="service_name"

# Auto-detected log patterns
grafana__query_loki_patterns datasourceUid="grafanacloud-logs"
```

### Metrics (Prometheus)

See [references/prometheus-metrics.md](references/prometheus-metrics.md) for available metrics and PromQL patterns.

```bash
# HTTP request latency (p95)
grafana__query_prometheus datasourceUid="grafanacloud-prom" expr='histogram_quantile(0.95, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="web-server"}[1h])))' startRfc3339="now-1h" endRfc3339="now" stepSeconds=300

# Error rate percentage
grafana__query_prometheus datasourceUid="grafanacloud-prom" expr='100 * sum(rate(http_server_request_duration_seconds_count{http_response_status_code=~"5.."}[5m])) / sum(rate(http_server_request_duration_seconds_count[5m]))' startRfc3339="now-1h" endRfc3339="now" stepSeconds=60

# Chat latency by search mode
grafana__query_prometheus datasourceUid="grafanacloud-prom" expr='sum by (search_mode) (rate(gen_ai_client_operation_duration_seconds_sum[1h]))' startRfc3339="now-1h" endRfc3339="now" stepSeconds=300

# Discover metrics
grafana__list_prometheus_metric_names datasourceUid="grafanacloud-prom"
grafana__list_prometheus_metric_metadata datasourceUid="grafanacloud-prom"
grafana__list_prometheus_label_names datasourceUid="grafanacloud-prom"
```

**Aggregated metrics note**: Grafana Cloud aggregates high-cardinality metrics. Always use aggregation functions (`sum`, `rate`, `histogram_quantile`), never query raw series.

### Traces (Tempo)

See [references/tempo-traceql.md](references/tempo-traceql.md) for TraceQL syntax and trace analysis.

```bash
# Find slow requests (>10s)
grafana__tempo_traceql-search datasourceUid="grafanacloud-traces" query='{span:duration > 10s}'

# Average duration by search mode
grafana__tempo_traceql-metrics-instant datasourceUid="grafanacloud-traces" query='{span.search.mode != ""} | avg_over_time(duration) by (span.search.mode)'

# Error traces by service
grafana__tempo_traceql-metrics-range datasourceUid="grafanacloud-traces" query='{span:status = error} | rate() by (resource.service.name)'

# Get specific trace
grafana__tempo_get-trace traceId="abc123"

# Discover trace attributes
grafana__tempo_get-attribute-names datasourceUid="grafanacloud-traces"
grafana__tempo_get-attribute-values datasourceUid="grafanacloud-traces" attributeName="service.name"
```

### Dashboards

See [references/dashboards.md](references/dashboards.md) for full dashboard list and deeplink generation.

```bash
# Search dashboards
grafana__search_dashboards query="[YOUR_PRODUCT]"

# Get dashboard summary
grafana__get_dashboard_summary uid="cdiz9piuoa3gge"

# Get panel queries
grafana__get_dashboard_panel_queries dashboardUid="cdiz9piuoa3gge"

# Generate deeplink
grafana__generate_deeplink resourceType="dashboard" dashboardUid="cdiz9piuoa3gge"
```

Key dashboards:
- **Agents GenAI Observability** (`cdiz9piuoa3gge`) — LLM operations, tokens, costs
- **Hangfire Jobs Monitoring** (`sc5pdf5`) — Background job health
- **[YOUR_PRODUCT] Web Server Test** (`040cee27-2c68-47e4-8e73-e69975e8cc4f`) — API performance

### Alerts
```bash
# Check firing alerts
grafana__list_alert_groups

# List all alert rules
grafana__list_alert_rules

# Get specific alert rule
grafana__get_alert_rule_by_uid uid="abc"

# Get specific alert group
grafana__get_alert_group groupId="abc"
```

### Incidents
```bash
# List incidents
grafana__list_incidents

# Get incident details
grafana__get_incident incidentId="abc"

# Create incident
grafana__create_incident title="API latency spike" severity="minor"

# Add investigation notes
grafana__add_activity_to_incident incidentId="abc" body="Root cause: connection pool exhaustion"
```

### Error Investigation (Sift)

Automated error pattern detection — use before manual log trawling.

```bash
# Auto-detect error patterns
grafana__find_error_pattern_logs datasourceUid="grafanacloud-logs"

# Find slow requests
grafana__find_slow_requests datasourceUid="grafanacloud-logs"

# List/get sift investigations
grafana__list_sift_investigations
grafana__get_sift_analysis analysisId="abc"
```

### Annotations
```bash
# Mark deployment on dashboards
grafana__create_annotation text="Deployed v2.1" dashboardUID="cdiz9piuoa3gge"

# Search annotations (correlate events)
grafana__get_annotations
```

### OnCall
```bash
# Who is on call now
grafana__get_current_oncall_users

# List schedules
grafana__list_oncall_schedules
```

### Datasources
```bash
# List all datasources (discover UIDs)
grafana__list_datasources
```

## Investigation Workflows

### "Why is the API slow?"
1. `query_prometheus` — HTTP latency p95
2. `tempo_traceql-search` — find slow traces (>5s)
3. `query_loki_logs` — check logs around slow request timestamps

### "Are there errors in production?"
1. `find_error_pattern_logs` — auto-detect error patterns (Sift)
2. `query_loki_logs` — error logs by service
3. `tempo_traceql-search` — error traces
4. `list_alert_groups` — check firing alerts

### "How is search performance?"
1. `tempo_traceql-metrics-instant` — avg duration by search mode
2. `query_prometheus` — LLM operation latency by search mode
3. `query_loki_logs` — specific search errors

### "What is the indexing status of a repository?"
1. `query_loki_logs` — `{service_name="indexer"}` — recent activity
2. `query_loki_logs` — `{service_name="indexer"} |= "<repo-name>"` — filter by repo
3. `query_loki_logs` — `{service_name="indexer"} |= "error"` — check for indexing errors
4. `query_prometheus` — indexer metrics (if available)

### General investigation flow
1. `list_datasources` — get datasource UIDs (if unsure)
2. `find_error_pattern_logs` / `find_slow_requests` — Sift auto-detection
3. `query_loki_logs` — search for errors
4. `query_prometheus` — check related metrics
5. `tempo_traceql-search` — trace analysis
6. `search_dashboards` — find relevant dashboards
7. `create_incident` — if critical

## Time Ranges
- **Prometheus**: Use relative (`now-1h`, `now-24h`) or RFC3339
- **Tempo**: RFC3339 format, max 25h for metrics queries
- **Always verify current date** before time-sensitive queries

## Output Format

Present results concisely for Telegram:
- Status indicators for alerts/incidents
- Key metric values with time context
- Log excerpts (max 5 lines, most relevant)
- Link to dashboard when available

## Related Skills
- posthog-analytics — product analytics (user behavior, funnels)
- metrics-briefing — CEO-level metric interpretation
