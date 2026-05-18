# Loki LogQL Reference

## Table of Contents
- [Label Selectors](#label-selectors)
- [Line Filters](#line-filters)
- [Parsers](#parsers)
- [Label Filters](#label-filters)
- [Log Levels](#log-levels)
- [Common Patterns](#common-patterns)
- [MCP Tool Usage](#mcp-tool-usage)

## Label Selectors

```logql
{label="value"}           # Exact match
{label=~"regex.*"}        # Regex match
{label!="value"}          # Not equal
{label!~"regex.*"}        # Not regex match
```

### Available Labels

| Label | Values | Description |
|-------|--------|-------------|
| `service_name` | web-server, jobs-heavy, jobs-light, indexer, ai-server | Service identifier |
| `job` | Same as service_name | Prometheus job label |
| `level` | ERROR, Error, Fatal, WARN, Warning, INFO, Information, Debug | Log level |
| `environment` | Production | Deployment environment |
| `instance` | varies | Service instance identifier |
| `organizationId` | varies | Tenant/organization ID |

## Line Filters

```logql
|= "text"      # Line contains text (case-sensitive)
!= "text"      # Line does not contain text
|~ "regex"     # Line matches regex
!~ "regex"     # Line does not match regex
```

### Filter Chaining

```logql
{service_name="web-server"}
  |= "error"
  != "health check"
  |~ "user|auth"
```

## Parsers

### JSON Parser
```logql
{service_name="ai-server"} | json
{service_name="ai-server"} | json | status >= 500
{service_name="ai-server"} | json | level="error"
```

### Logfmt Parser
```logql
{job="web-server"} | logfmt | duration > 1s
```

### Pattern Parser
```logql
{job="web-server"} | pattern "<_> <level> <_> <message>"
```

### Regex Parser
```logql
{job="web-server"} | regexp "(?P<ip>\\d+\\.\\d+\\.\\d+\\.\\d+)"
```

## Label Filters

After parsing, filter on extracted labels:

```logql
| label == "value"
| label != "value"
| label =~ "regex"
| label > 100
| label >= 100
| label < 100
| label <= 100
```

## Log Levels

[YOUR_PRODUCT] services use different log level formats:

| .NET Services | Python Services |
|---------------|-----------------|
| ERROR, Fatal | ERROR |
| Warning | WARN |
| Information | INFO |
| Debug | DEBUG |

### Match All Error Levels
```logql
{service_name="web-server", level=~"ERROR|Error|Fatal"}
```

### Match All Warning and Above
```logql
{service_name="web-server", level=~"ERROR|Error|Fatal|WARN|Warning"}
```

## Common Patterns

### Errors by Service
```logql
# Web Server errors
{service_name="web-server", level=~"ERROR|Error|Fatal"}

# Jobs Engine errors (heavy + lightweight)
{service_name=~"jobs-heavy|jobs-light", level=~"ERROR|Error|Fatal"}

# Symbols Collector errors
{service_name="indexer", level=~"ERROR|Error|Fatal"}

# Agents Server errors
{service_name="ai-server", level=~"ERROR|Error"}
```

### Exception Search
```logql
# Specific exception type
{service_name="web-server"} |= "NullReferenceException"

# Any exception
{service_name="web-server"} |= "Exception"

# Stack trace
{service_name="web-server"} |= "at " |= "Exception"
```

### Job Processing
```logql
# Failed jobs
{service_name=~"jobs-heavy|jobs-light"} |= "failed"

# Specific job type
{service_name=~"jobs-heavy|jobs-light"} |= "YourPrimaryJob"

# Job completion
{service_name=~"jobs-heavy|jobs-light"} |= "completed"
```

### Tenant-Specific
```logql
# Logs for specific organization
{service_name="web-server", organizationId="<org-id>"}

# Tenant access errors
{service_name="web-server"} |= "WrongTenantAccessException"
```

### Authentication
```logql
# Auth errors
{service_name="web-server"} |= "auth" |~ "error|fail"

# JWT issues
{service_name="web-server"} |= "JWT" |= "expired"
```

### Metrics Queries (Count/Rate)
```logql
# Count errors by service in last hour
sum by (service_name) (count_over_time({level=~"ERROR|Error|Fatal"}[1h]))

# Error rate per minute
rate({level=~"ERROR|Error|Fatal"}[1m])

# Bytes processed
sum(bytes_over_time({service_name="web-server"}[1h]))

# Top 5 services by error count
topk(5, sum by (service_name) (count_over_time({level=~"ERROR|Error|Fatal"}[1h])))

# Error percentage (errors / total logs)
sum(rate({service_name="web-server", level=~"ERROR|Error|Fatal"}[5m]))
/
sum(rate({service_name="web-server"}[5m])) * 100
```

### Unwrap (Extract Numeric Fields)
```logql
# P95 of a numeric field parsed from logs
quantile_over_time(0.95, {service_name="ai-server"} | json | unwrap response_time [5m])

# Average of a numeric field
avg_over_time({service_name="ai-server"} | json | unwrap duration [5m])
```

### Line Format (Reformat Output)
```logql
# Reformat log lines for readability
{service_name="web-server"} | json | line_format "{{.level}} [{{.RequestPath}}] {{.StatusCode}} {{.ElapsedMs}}ms"

# Extract just the message
{service_name=~"jobs-heavy|jobs-light"} | json | line_format "{{.Message}}"
```

## MCP Tool Usage

### List Available Labels
```
mcp__grafana__list_loki_label_names(datasourceUid: "grafanacloud-logs")
```

### Get Label Values
```
mcp__grafana__list_loki_label_values(
  datasourceUid: "grafanacloud-logs",
  labelName: "service_name"
)
```

### Check Stream Statistics (Before Large Queries)
```
mcp__grafana__query_loki_stats(
  datasourceUid: "grafanacloud-logs",
  logql: '{service_name="web-server", level=~"ERROR|Error"}'
)
```

### Query Logs
```
mcp__grafana__query_loki_logs(
  datasourceUid: "grafanacloud-logs",
  logql: '{service_name="web-server", level=~"ERROR|Error"}',
  limit: 50,
  direction: "backward",  # newest first
  startRfc3339: "2026-01-25T00:00:00Z",
  endRfc3339: "2026-01-26T00:00:00Z"
)
```

### Best Practices

1. **Always check stats first** before running large queries
2. **Use specific time ranges** to limit data volume
3. **Start with narrow filters** and expand if needed
4. **Use limit parameter** (default 10, max 100)
5. **Filter by service_name first** for better performance
