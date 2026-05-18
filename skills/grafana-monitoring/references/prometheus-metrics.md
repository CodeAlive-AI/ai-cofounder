# Prometheus Metrics Reference

## Table of Contents
- [Available Metrics](#available-metrics)
- [Key Labels](#key-labels)
- [PromQL Patterns](#promql-patterns)
- [Aggregated Metrics](#aggregated-metrics)
- [MCP Tool Usage](#mcp-tool-usage)

## Available Metrics

### HTTP Server Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `http_server_request_duration_seconds_bucket` | Histogram | HTTP request duration buckets |
| `http_server_request_duration_seconds_count` | Counter | Total HTTP request count |
| `http_server_request_duration_seconds_sum` | Counter | Total HTTP request duration |
| `http_server_active_requests` | Gauge | Currently active requests |

**Key Labels**: `job`, `http_route`, `http_request_method`, `http_response_status_code`, `url_scheme`

### HTTP Client Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `http_client_request_duration_seconds_bucket` | Histogram | Outgoing HTTP request duration buckets |
| `http_client_request_duration_seconds_count` | Counter | Total outgoing HTTP request count |
| `http_client_request_duration_seconds_sum` | Counter | Total outgoing HTTP request duration |
| `http_client_active_requests` | Gauge | Currently active outgoing requests |
| `http_client_open_connections` | Gauge | Open HTTP client connections |

### GenAI/LLM Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `gen_ai_client_operation_duration_seconds_*` | Histogram | LLM operation duration |
| `gen_ai_client_operation_requests_total` | Counter | Total LLM operation requests |
| `gen_ai_client_operation_requests_successful_total` | Counter | Successful LLM requests |
| `gen_ai_client_operation_requests_failed_total` | Counter | Failed LLM requests |
| `gen_ai_client_token_usage_input_total` | Counter | Input tokens consumed |
| `gen_ai_client_token_usage_output_total` | Counter | Output tokens generated |
| `gen_ai_client_token_usage_input_per_request_*` | Histogram | Input tokens per request |
| `gen_ai_client_token_usage_output_per_request_*` | Histogram | Output tokens per request |
| `gen_ai_client_cost_microdollars_total` | Counter | Total cost in microdollars |
| `gen_ai_client_cost_per_request_*` | Histogram | Cost per request distribution |
| `gen_ai_client_streaming_first_token_latency_seconds_*` | Histogram | Time to first token (streaming) |
| `gen_ai_client_embeddings_requests_total` | Counter | Total embedding requests |
| `gen_ai_client_embeddings_requests_failed_total` | Counter | Failed embedding requests |
| `gen_ai_client_deserialization_failures_total` | Counter | Response parsing failures |

**Key Labels**: `gen_ai_provider_name`, `gen_ai_request_model`, `gen_ai_token_type`, `llm_purpose`, `llm_complexity`, `llm_task_name`, `search_mode`, `embedding_purpose`

### Background Jobs (Hangfire)

| Metric | Type | Description |
|--------|------|-------------|
| `hangfire_job_duration_seconds_bucket` | Histogram | Job execution duration buckets |
| `hangfire_job_duration_seconds_count` | Counter | Total job executions |
| `hangfire_job_duration_seconds_sum` | Counter | Total job duration |
| `hangfire_job_started_total` | Counter | Jobs started |
| `hangfire_job_succeeded_total` | Counter | Jobs completed successfully |
| `hangfire_job_failed_total` | Counter | Jobs failed |

**Key Labels**: `job_name`, `failure_reason`

### PR Review Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `core_workflow_duration_seconds_*` | Histogram | PR review total duration |
| `agent_processing_duration_seconds_*` | Histogram | Agent processing time |
| `core_workflow_started_total` | Counter | Reviews started |
| `core_workflow_completed_total` | Counter | Reviews completed |
| `core_workflow_failed_total` | Counter | Reviews failed |
| `core_workflow_in_progress` | Gauge | Currently processing |
| `core_workflow_pending` | Gauge | Pending reviews |
| `core_workflow_stale` | Gauge | Stale reviews |
| `agent_outputs_posted_total` | Counter | Inline comments posted |
| `review_processing_time_milliseconds_*` | Histogram | Review processing time |
| `active_reviews_ratio` | Gauge | Ratio of active reviews |
| `pending_reviews_ratio` | Gauge | Ratio of pending reviews |
| `completed_reviews_total` | Counter | Completed reviews |
| `failed_reviews_total` | Counter | Failed reviews |

**Key Labels**: `repository_id`, `pull_request_id`, `review_id`, `review_state`

### API Calls (External)

| Metric | Type | Description |
|--------|------|-------------|
| `api_calls_count_total` | Counter | Total API calls |
| `api_calls_duration_milliseconds_*` | Histogram | API call duration |

### gRPC Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `grpc_responses_duration_seconds_*` | Histogram | gRPC response duration |
| `grpc_responses_total` | Counter | Total gRPC responses |
| `grpc_responses_fail_total` | Counter | Failed gRPC responses |
| `grpc_responses_avg_duration_seconds` | Gauge | Average gRPC duration |
| `grpc_responses_max_duration_seconds` | Gauge | Max gRPC duration |
| `grpc_responses_min_duration_seconds` | Gauge | Min gRPC duration |

### REST Responses

| Metric | Type | Description |
|--------|------|-------------|
| `rest_responses_duration_seconds_*` | Histogram | REST response duration |
| `rest_responses_total` | Counter | Total REST responses |
| `rest_responses_fail_total` | Counter | Failed REST responses |
| `rest_responses_avg_duration_seconds` | Gauge | Average REST duration |

### ASP.NET Core Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `aspnetcore_routing_match_attempts_total` | Counter | Routing match attempts |
| `aspnetcore_rate_limiting_requests_total` | Counter | Rate-limited requests |
| `aspnetcore_rate_limiting_active_request_leases` | Gauge | Active rate limit leases |
| `aspnetcore_authentication_authenticate_duration_seconds_*` | Histogram | Auth duration |
| `aspnetcore_authentication_challenges_total` | Counter | Auth challenges |
| `aspnetcore_authentication_forbids_total` | Counter | Auth forbids |
| `aspnetcore_authorization_attempts_total` | Counter | Authorization attempts |
| `aspnetcore_memory_pool_allocated_bytes_total` | Counter | Memory pool allocated |
| `aspnetcore_memory_pool_pooled_bytes` | Gauge | Memory pool pooled |

**Key Labels**: `aspnetcore_authentication_scheme`, `aspnetcore_authorization_result`, `aspnetcore_rate_limiting_result`

### Kestrel (Web Server)

| Metric | Type | Description |
|--------|------|-------------|
| `kestrel_active_connections` | Gauge | Active connections |
| `kestrel_connection_duration_seconds_*` | Histogram | Connection duration |
| `kestrel_queued_connections` | Gauge | Queued connections |

### .NET Runtime Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `process_cpu_time_seconds_total` | Counter | CPU time consumed |
| `process_memory_usage_bytes` | Gauge | Memory usage |
| `process_memory_virtual_bytes` | Gauge | Virtual memory |
| `process_thread_count` | Gauge | Thread count |
| `process_cpu_count` | Gauge | CPU count |
| `dotnet_gc_collections_total` | Counter | GC collections by generation |
| `dotnet_gc_heap_allocated_bytes_total` | Counter | Heap allocated |
| `dotnet_gc_pause_time_seconds_total` | Counter | GC pause time |
| `dotnet_gc_last_collection_heap_size_bytes` | Gauge | Last GC heap size |
| `dotnet_gc_last_collection_memory_committed_size_bytes` | Gauge | Last GC committed |
| `dotnet_exceptions_total` | Counter | Exceptions thrown |
| `dotnet_thread_pool_thread_count_total` | Counter | Thread pool threads |
| `dotnet_thread_pool_queue_length_total` | Counter | Thread pool queue |
| `dotnet_thread_pool_work_item_count_total` | Counter | Work items processed |
| `dotnet_assembly_count` | Gauge | Loaded assemblies |
| `dotnet_jit_compilation_time_seconds_total` | Counter | JIT compilation time |
| `dotnet_jit_compiled_methods_total` | Counter | JIT compiled methods |
| `dotnet_timer_count` | Gauge | Active timers |
| `dotnet_monitor_lock_contentions_total` | Counter | Lock contentions |

**Key Labels**: `gc_heap_generation`, `exception_type`, `process_cpu_state`

### Memory Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `memory_active_bytes` | Gauge | Active memory |
| `memory_allocated_bytes` | Gauge | Allocated memory |
| `memory_resident_bytes` | Gauge | Resident memory |
| `memory_retained_bytes` | Gauge | Retained memory |
| `memory_metadata_bytes` | Gauge | Metadata memory |

### Collection Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `collections_total` | Gauge | Total collections |
| `collections_vector_total` | Gauge | Vector collections |

### Application Info

| Metric | Type | Description |
|--------|------|-------------|
| `app_info` | Gauge | Application metadata |
| `app_status_recovery_mode` | Gauge | Recovery mode status |
| `target_info` | Gauge | Target metadata |
| `up` | Gauge | Target health |

## Key Labels

### Common Labels

| Label | Description | Example Values |
|-------|-------------|----------------|
| `job` | Service name | web-server, jobs-heavy, jobs-light, indexer, ai-server |
| `instance` | Service instance | pod-name:port |
| `deployment_environment` | Environment | production, staging |

### HTTP Labels

| Label | Description | Example Values |
|-------|-------------|----------------|
| `http_route` | API endpoint | api/chat/completions, api/search |
| `http_request_method` | HTTP method | GET, POST, PUT, DELETE |
| `http_response_status_code` | Response code | 200, 400, 500 |
| `url_scheme` | URL scheme | http, https |

### LLM Labels

| Label | Description | Example Values |
|-------|-------------|----------------|
| `search_mode` | Search mode used | <your-mode-1>, <your-mode-2>, <your-mode-3>, <your-mode-4> |
| `llm_purpose` | Purpose of LLM call | Answering, CodeGeneration, QueryAnalyze |
| `llm_complexity` | Complexity level | Medium, Complex, GeniusMedium, GeniusHigh |
| `llm_task_name` | Task name | specific task identifier |
| `gen_ai_request_model` | Model used | claude-3-sonnet, gpt-4 |
| `gen_ai_provider_name` | Provider | anthropic, openai |
| `gen_ai_token_type` | Token type | input, output |
| `embedding_purpose` | Embedding purpose | search, indexing |
| `provider_type` | Provider type | anthropic, openai |

### Organization/Tenant Labels

| Label | Description | Example Values |
|-------|-------------|----------------|
| `organization_id` | Organization ID | UUID |
| `organization_root_id` | Root organization ID | UUID |
| `repository_id` | Repository ID | UUID |

### Error Labels

| Label | Description | Example Values |
|-------|-------------|----------------|
| `error_type` | Error type | timeout, validation |
| `exception_type` | Exception class | System.NullReferenceException |
| `failure_reason` | Failure reason | specific reason |
| `status_code` | Status code | numeric |
| `success` | Success flag | true, false |

## PromQL Patterns

### Latency Percentiles

```promql
# P50 latency
histogram_quantile(0.50, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="web-server"}[5m])))

# P95 latency
histogram_quantile(0.95, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="web-server"}[5m])))

# P99 latency
histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job="web-server"}[5m])))

# Latency by endpoint
histogram_quantile(0.95, sum by (le, http_route) (rate(http_server_request_duration_seconds_bucket{job="web-server"}[5m])))
```

### Request Rates

```promql
# Total request rate
sum(rate(http_server_request_duration_seconds_count{job="web-server"}[5m]))

# Request rate by endpoint
sum by (http_route) (rate(http_server_request_duration_seconds_count{job="web-server"}[5m]))

# Request rate by status code
sum by (http_response_status_code) (rate(http_server_request_duration_seconds_count{job="web-server"}[5m]))
```

### Error Rates

```promql
# Error rate percentage
100 * sum(rate(http_server_request_duration_seconds_count{job="web-server", http_response_status_code=~"5.."}[5m]))
    / sum(rate(http_server_request_duration_seconds_count{job="web-server"}[5m]))

# 4xx rate
sum(rate(http_server_request_duration_seconds_count{job="web-server", http_response_status_code=~"4.."}[5m]))

# Exceptions per minute
rate(dotnet_exceptions_total{job="web-server"}[5m]) * 60
```

### LLM/Search Metrics

```promql
# Average duration by search mode
sum by (search_mode) (rate(gen_ai_client_operation_duration_seconds_sum[1h]))
  / sum by (search_mode) (rate(gen_ai_client_operation_duration_seconds_count[1h]))

# Request count by search mode
sum by (search_mode) (rate(gen_ai_client_operation_duration_seconds_count[1h]))

# Token usage by model
sum by (gen_ai_request_model) (rate(gen_ai_client_token_usage_input_total[1h]))

# Cost by provider (dollars per hour)
sum by (gen_ai_provider_name) (rate(gen_ai_client_cost_microdollars_total[1h])) / 1000000

# First token latency P95
histogram_quantile(0.95, sum by (le) (rate(gen_ai_client_streaming_first_token_latency_seconds_bucket[1h])))
```

### Background Jobs

```promql
# Job success rate
sum(rate(hangfire_job_succeeded_total[1h])) / sum(rate(hangfire_job_started_total[1h])) * 100

# Failed jobs by name
sum by (job_name) (rate(hangfire_job_failed_total[5m]))

# Job duration P95
histogram_quantile(0.95, sum by (le) (rate(hangfire_job_duration_seconds_bucket[1h])))

# Job duration by name
histogram_quantile(0.95, sum by (le, job_name) (rate(hangfire_job_duration_seconds_bucket[1h])))
```

### PR Review Metrics

```promql
# Active reviews
core_workflow_in_progress

# Review completion rate
sum(rate(core_workflow_completed_total[1h])) / sum(rate(core_workflow_started_total[1h])) * 100

# Review duration P95
histogram_quantile(0.95, sum by (le) (rate(core_workflow_duration_seconds_bucket[1h])))

# Inline comments per review
sum(rate(agent_outputs_posted_total[1h])) / sum(rate(core_workflow_completed_total[1h]))
```

### Resource Usage

```promql
# CPU usage percentage
sum by (instance) (rate(process_cpu_time_seconds_total{job="web-server"}[5m])) * 100

# Memory usage MB
process_memory_usage_bytes{job="web-server"} / 1024 / 1024

# GC collections per minute
rate(dotnet_gc_collections_total{job="web-server"}[5m]) * 60

# Thread pool queue depth
dotnet_thread_pool_queue_length_total{job="web-server"}
```

## Aggregated Metrics

Grafana Cloud aggregates high-cardinality metrics. When querying aggregated metrics, you **must** use aggregation functions.

### Error Message

```
Can't query aggregated metric X without aggregation because the following labels are aggregated: ...
```

### Solution

```promql
# Wrong - direct query fails
gen_ai_client_operation_duration_seconds_sum

# Correct - use aggregation
sum by (search_mode) (rate(gen_ai_client_operation_duration_seconds_sum[1h]))
```

### Commonly Aggregated Metrics

- `gen_ai_client_operation_duration_seconds_*`
- `gen_ai_client_token_usage_*`
- `gen_ai_client_cost_*`
- `gen_ai_client_streaming_first_token_latency_seconds_*`

## Advanced PromQL Patterns

### Time Comparisons

```promql
# Compare error rate to 1 hour ago
sum(rate(http_server_request_duration_seconds_count{http_response_status_code=~"5.."}[5m]))
  - sum(rate(http_server_request_duration_seconds_count{http_response_status_code=~"5.."} offset 1h[5m]))

# Compare to yesterday
sum(rate(http_server_request_duration_seconds_count{job="web-server"}[5m]))
  / sum(rate(http_server_request_duration_seconds_count{job="web-server"} offset 24h[5m]))

# Detect changes (value flaps)
changes(up{job="web-server"}[1h])
```

### Prediction & Trends

```promql
# Predict disk space exhaustion in 4 hours
predict_linear(node_filesystem_avail_bytes{mountpoint="/"}[6h], 4 * 3600) < 0

# Average over 24 hours (smoothing)
avg_over_time(process_memory_usage_bytes{job="web-server"}[24h])
```

### Recording Rules (for frequently-used queries)

```yaml
groups:
  - name: your_aggregations
    interval: 30s
    rules:
      - record: job:http_requests:rate5m
        expr: sum by (job) (rate(http_server_request_duration_seconds_count[5m]))

      - record: job:http_errors:rate5m
        expr: sum by (job) (rate(http_server_request_duration_seconds_count{http_response_status_code=~"5.."}[5m]))

      - record: job:http_latency:p95
        expr: |
          histogram_quantile(0.95,
            sum by (job, le) (rate(http_server_request_duration_seconds_bucket[5m])))

      - record: job:llm_cost_per_hour
        expr: sum by (gen_ai_provider_name) (rate(gen_ai_client_cost_microdollars_total[1h])) / 1000000
```

### Alerting Rules

```yaml
groups:
  - name: your_alerts
    rules:
      - alert: HighErrorRate
        expr: |
          100 * sum(rate(http_server_request_duration_seconds_count{job="web-server", http_response_status_code=~"5.."}[5m]))
          / sum(rate(http_server_request_duration_seconds_count{job="web-server"}[5m])) > 5
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on Web Server ({{ $value | humanizePercentage }})"

      - alert: ServiceDown
        expr: up{job=~"web-server|jobs-engine-.*|indexer|ai-server"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"

      - alert: HighLLMCost
        expr: sum(rate(gen_ai_client_cost_microdollars_total[1h])) / 1000000 > 10
        for: 15m
        labels:
          severity: warning
        annotations:
          summary: "LLM cost exceeding $10/hour"

      - alert: JobFailureSpike
        expr: sum(rate(hangfire_job_failed_total[5m])) > 0.5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Background job failure rate spiking"
```

## MCP Tool Usage

### List Available Metrics
```
mcp__grafana__list_prometheus_metric_names(
  datasourceUid: "grafanacloud-prom",
  regex: "http_server|gen_ai|hangfire",
  limit: 50
)
```

### List Label Names
```
mcp__grafana__list_prometheus_label_names(
  datasourceUid: "grafanacloud-prom",
  matches: [{"filters": [{"name": "__name__", "type": "=", "value": "http_server_request_duration_seconds_count"}]}]
)
```

### List Label Values
```
mcp__grafana__list_prometheus_label_values(
  datasourceUid: "grafanacloud-prom",
  labelName: "search_mode"
)
```

### Instant Query
```
mcp__grafana__query_prometheus(
  datasourceUid: "grafanacloud-prom",
  expr: "histogram_quantile(0.95, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\"web-server\"}[1h])))",
  queryType: "instant",
  startTime: "now"
)
```

### Range Query
```
mcp__grafana__query_prometheus(
  datasourceUid: "grafanacloud-prom",
  expr: "sum(rate(http_server_request_duration_seconds_count{job=\"web-server\"}[5m]))",
  queryType: "range",
  startTime: "now-1h",
  endTime: "now",
  stepSeconds: 60
)
```

### Time Formats

- Relative: `now`, `now-1h`, `now-24h`, `now-7d`
- RFC3339: `2026-01-26T12:00:00Z`
- Units: `ns`, `us`, `ms`, `s`, `m`, `h`, `d`
