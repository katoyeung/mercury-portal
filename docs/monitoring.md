# Monitoring Nginx with Prometheus

## Overview

This document outlines the approach to monitor Nginx using Prometheus with the Virtual Host Traffic Status (VTS) module. It includes steps to set up Prometheus scraping, explains key Nginx metrics, and introduces basic PromQL techniques for querying metrics.

## Prerequisites

- Nginx with the VTS module enabled
- Prometheus setup to scrape metrics from Nginx
- Grafana (optional) for visualizing the metrics

## Key Metrics

The VTS module exposes several crucial metrics that provide insights into Nginx's performance and traffic:

- `nginx_vts_info`: Metadata about the Nginx instance.
- `nginx_vts_start_time_seconds`: Start time of the Nginx server.
- `nginx_vts_main_connections`: Connection-related metrics, including accepted, active, and handled connections.
- `nginx_vts_server_bytes_total`: Total bytes served by Nginx, split by direction (in/out).
- `nginx_vts_server_requests_total`: Total number of requests served by Nginx, categorized by response status codes.
- `nginx_vts_server_request_seconds_total`: Total request processing time.
- `nginx_vts_server_request_duration_seconds`: Histogram of request processing times.

## Prometheus Querying Techniques

### Rate Function

The `rate()` function in PromQL is used to calculate the per-second average rate of increase of a given time series within a specified time range. It is particularly useful for metrics like `nginx_vts_server_requests_total` which are counters.

Example Query:

```promql
rate(nginx_vts_server_requests_total[5m])
```

This query calculates the average rate of total requests per second over the last 5 minutes.

### Increase Function

Another useful function is `increase()`, which returns the increase in the value of a counter over the specified time range. Unlike `rate()`, `increase()` provides the total increase, making it useful for understanding total counts over specific intervals.

Example Query:

```promql
increase(nginx_vts_server_requests_total[1h])
```

This query shows the total increase in requests over the last hour.

### Histograms and Summaries

For metrics like `nginx_vts_server_request_duration_seconds`, which are histograms, you can use functions like `histogram_quantile()` to calculate quantiles.

Example Query:

```promql
histogram_quantile(0.95, sum(rate(nginx_vts_server_request_duration_seconds_bucket[10m])) by (le))
```

This query calculates the 95th percentile of request duration over the last 10 minutes.

## Integrating with Grafana

To visualize these metrics in Grafana:

1. Add Prometheus as a data source in Grafana.
2. Create a new dashboard and add panels.
3. Use PromQL queries to display metrics such as request rates, error rates, or response times.

## Conclusion

Monitoring Nginx with Prometheus and the VTS module offers comprehensive insights into web server performance and traffic. By employing PromQL functions like `rate()`, `increase()`, and `histogram_quantile()`, developers and system administrators can effectively analyze and visualize Nginx metrics to ensure optimal performance and reliability.
