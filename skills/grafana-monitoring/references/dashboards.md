# Grafana Dashboards Reference

## Table of Contents
- [[YOUR_PRODUCT] Dashboards](#[your-product]-dashboards)
- [Infrastructure Dashboards](#infrastructure-dashboards)
- [Grafana Cloud Dashboards](#grafana-cloud-dashboards)
- [Incident & OnCall Dashboards](#incident--oncall-dashboards)
- [Dashboard Folders](#dashboard-folders)
- [MCP Tool Usage](#mcp-tool-usage)
- [Quick Reference by Use Case](#quick-reference-by-use-case)

## [YOUR_PRODUCT] Dashboards

| Dashboard | UID | Tags | Description |
|-----------|-----|------|-------------|
| **Agents GenAI Observability** | `cdiz9piuoa3gge` | GPU, GenAI, LLM, VectorDB | LLM operations, token usage, costs, and AI agent metrics |
| **[YOUR_PRODUCT] Web Server Test** | `040cee27-2c68-47e4-8e73-e69975e8cc4f` | [your-product], test | Web server testing and performance |
| **Hangfire Jobs Monitoring** | `sc5pdf5` | hangfire, jobs, performance | Background job execution and health |

## Infrastructure Dashboards

| Dashboard | UID | Folder | Tags | Description |
|-----------|-----|--------|------|-------------|
| **AWS ALB - ELB Rejections & Health** | `6bda3609-f311-40d2-9640-54494c666aec` | AWS Infrastructure | alb, aws, elb, fargate, rejections, waf | Load balancer health and request rejections |

## Grafana Cloud Dashboards

| Dashboard | UID | Tags | Description |
|-----------|-----|------|-------------|
| **Billing/Usage** | `decs0mx4dtlogb` | billing, grafanacloud | Grafana Cloud billing and usage metrics |
| **Cardinality management - 1 - overview** | `cardinality-management` | cardinality-management, grafanacloud | Metrics cardinality overview |
| **Cardinality management - 2 - metrics** | `cardinality-management-metrics-detail` | cardinality-management, grafanacloud | Per-metric cardinality details |
| **Cardinality management - 3 - labels** | `cardinality-management-label-detail` | cardinality-management, grafanacloud | Per-label cardinality details |
| **Cloud Logs Export Insights** | `4_D6mSh4z` | - | Loki logs export metrics |
| **Usage Insights - 1 - Overview** | `XU8HAD5Gk` | grafanacloud | Grafana usage overview |
| **Usage Insights - 2 - Data sources** | `AEbrOO2Mz` | grafanacloud | Datasource usage details |
| **Usage Insights - 3 - Query Errors** | `MpmkYhRVz` | grafanacloud | Query error analysis |
| **Usage Insights - 4 - Alertmanager** | `ntS5Ujs7z` | alertmanager, grafanacloud | Alertmanager usage |
| **Usage Insights - 5 - Metrics Ingestion** | `cdn9jukg55bswb` | grafanacloud | Metrics ingestion rates |
| **Usage Insights - 6 - Loki Query Fair Usage Drilldown** | `cdybdibbio2dcd` | grafanacloud | Loki query heavy hitters |

## Incident & OnCall Dashboards

| Dashboard | UID | Tags | Description |
|-----------|-----|------|-------------|
| **OnCall Insights** | `eecs0mupvu6m8c` | oncall | On-call schedule and alert metrics |
| **Alert Groups Insights** | `d40b6dfd-dcaa-42a2-a2d0-67c317148c47` | alert groups, irm, oncall | Alert group analysis |
| **Incident Insights** | `7bd957e1-e311-4cf5-b87b-29e270ff3775` | grafana-incident, insights | Incident response metrics |

## Dashboard Folders

| Folder | UID |
|--------|-----|
| AWS Infrastructure | `aws-infrastructure` |
| [YOUR_PRODUCT] Alerts | `[your-product]-alerts` |
| GrafanaCloud | `decs0mwwjn2m8c` |
| Vector DB Infrastructure | `<your-folder-uid>` |
| Usage Alerts | `grafana-cmab-usage-alerts` |

## MCP Tool Usage

### Search Dashboards
```
mcp__grafana__search_dashboards(
  query: "[YOUR_PRODUCT]"
)
```

### Get Dashboard Summary
```
mcp__grafana__get_dashboard_summary(
  uid: "cdiz9piuoa3gge"
)
```

### Get Dashboard Panel Queries
```
mcp__grafana__get_dashboard_panel_queries(
  uid: "cdiz9piuoa3gge"
)
```

### Get Specific Dashboard Property
```
mcp__grafana__get_dashboard_property(
  uid: "cdiz9piuoa3gge",
  jsonPath: "$.panels[*].title"
)
```

### Get Full Dashboard (use sparingly - large context)
```
mcp__grafana__get_dashboard_by_uid(
  uid: "cdiz9piuoa3gge"
)
```

### Generate Dashboard Deeplink
```
mcp__grafana__generate_deeplink(
  resourceType: "dashboard",
  dashboardUid: "cdiz9piuoa3gge",
  timeRange: { from: "now-1h", to: "now" }
)
```

### Generate Panel Deeplink
```
mcp__grafana__generate_deeplink(
  resourceType: "panel",
  dashboardUid: "cdiz9piuoa3gge",
  panelId: 1,
  timeRange: { from: "now-1h", to: "now" }
)
```

## Quick Reference by Use Case

### LLM/AI Performance
- **Primary**: Agents GenAI Observability (`cdiz9piuoa3gge`)
- Shows: Token usage, costs, operation duration, model performance

### Background Jobs
- **Primary**: Hangfire Jobs Monitoring (`sc5pdf5`)
- Shows: Job success/failure rates, duration, queue depth

### API Performance
- **Primary**: [YOUR_PRODUCT] Web Server Test (`040cee27-2c68-47e4-8e73-e69975e8cc4f`)
- Shows: Request rates, latency, error rates

### Cost Management
- **Primary**: Billing/Usage (`decs0mx4dtlogb`)
- **Secondary**: Cardinality management dashboards
- Shows: Grafana Cloud costs, metric cardinality (cost driver)

### Incident Response
- **Primary**: Incident Insights (`7bd957e1-e311-4cf5-b87b-29e270ff3775`)
- **Secondary**: OnCall Insights (`eecs0mupvu6m8c`), Alert Groups Insights
- Shows: Incident trends, MTTR, on-call coverage
