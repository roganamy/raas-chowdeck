################################################################################
# First trigger: refinery_dropped_incoming_events
################################################################################
resource "honeycombio_query" "refinery_dropped_incoming_events_query" {
  dataset    = var.refinery_metrics_dataset
  query_json = data.honeycombio_query_specification.refinery_dropped_incoming_events_query_spec.json
  depends_on = [null_resource.create_metrics_columns]
}

data "honeycombio_query_specification" "refinery_dropped_incoming_events_query_spec" {
  calculation {
    op     = "SUM"
    column = "incoming_router_dropped"
  }

  filter {
    column = "incoming_router_dropped"
    op     = "exists"
  }

  breakdowns = ["hostname"]

  order {
    op     = "SUM"
    column = "incoming_router_dropped"
    order  = "descending"
  }

  time_range = 900
}

resource "honeycombio_trigger" "refinery_dropped_incoming_events" {
  alert_type  = "on_change"
  dataset     = var.refinery_metrics_dataset
  description = "If Refinery is dropping incoming events that means the receive buffers are full, and indicates either `CacheCapacity` is set too low or the instance is under-sized for the given load. \nFor more information, see: https://docs.honeycomb.io/manage-data-volume/refinery/scale-and-troubleshoot/#sizing-the-receive-buffers"
  disabled    = "false"
  frequency   = "900"
  name        = "Refinery Dropped Incoming Events"
  query_id    = honeycombio_query.refinery_dropped_incoming_events_query.id

  recipient {
    id = var.create_slack_recipient ? honeycombio_slack_recipient.alerts[0].id : var.existing_slack_recipient_id
  }

  threshold {
    exceeded_limit = "1"
    op             = ">"
    value          = "1000"
  }
}

################################################################################
# Second trigger refinery_stress_relief_activated
################################################################################
resource "honeycombio_query" "refinery_stress_relief_activated_query" {
  dataset    = var.refinery_metrics_dataset
  query_json = data.honeycombio_query_specification.refinery_stress_relief_activated_query_spec.json
  depends_on = [null_resource.create_metrics_columns]
}

data "honeycombio_query_specification" "refinery_stress_relief_activated_query_spec" {
  calculation {
    op     = "MAX"
    column = "stress_relief_activated"
  }

  filter {
    column = "stress_relief_activated"
    op     = "exists"
  }

  filter {
    column = "stress_relief_activated"
    op     = ">"
    value  = 0
  }

  breakdowns = ["hostname"]

  order {
    op     = "MAX"
    column = "stress_relief_activated"
    order  = "descending"
  }

  time_range = 900
}

resource "honeycombio_trigger" "refinery_stress_relief_activated" {
  alert_type  = "on_change"
  dataset     = var.refinery_metrics_dataset
  description = "Stress Relief has been activated in the Refinery Cluster, check the Refinery Logs dataset messages for the exact reason why. For more info see: https://docs.honeycomb.io/manage-data-volume/refinery/scale-and-troubleshoot/#stress-relief-metrics"
  disabled    = "false"
  frequency   = "900"
  name        = "Refinery Stress Relief Activated"
  query_id    = honeycombio_query.refinery_stress_relief_activated_query.id

  recipient {
    id = var.create_slack_recipient ? honeycombio_slack_recipient.alerts[0].id : var.existing_slack_recipient_id
  }

  threshold {
    exceeded_limit = "2"
    op             = ">"
    value          = "0"
  }
}

################################################################################
# Third trigger refinery_dropped_peer_events
################################################################################
resource "honeycombio_query" "refinery_dropped_peer_events_query" {
  dataset    = var.refinery_metrics_dataset
  query_json = data.honeycombio_query_specification.refinery_dropped_peer_events_query_spec.json
  depends_on = [null_resource.create_metrics_columns]
}

data "honeycombio_query_specification" "refinery_dropped_peer_events_query_spec" {
  calculation {
    op     = "MAX"
    column = "stress_relief_activated"
  }

  filter {
    column = "stress_relief_activated"
    op     = "exists"
  }

  filter {
    column = "stress_relief_activated"
    op     = ">"
    value  = 0
  }

  breakdowns = ["hostname"]

  order {
    op     = "MAX"
    column = "stress_relief_activated"
    order  = "descending"
  }

  time_range = 900
}

resource "honeycombio_trigger" "refinery_dropped_peer_events" {
  alert_type  = "on_change"
  dataset     = var.refinery_metrics_dataset
  description = "If Refinery is dropping incoming events from peers, that means the receive buffers are full, and indicates either `CacheCapacity` is set too low or the instance is under-sized for the given load.  Note that peer traffic is prioritized over incoming traffic. \nFor more information, see: https://docs.honeycomb.io/manage-data-volume/refinery/scale-and-troubleshoot/#sizing-the-receive-buffers"
  disabled    = "false"
  frequency   = "900"
  name        = "Refinery Dropped Peer Events"
  query_id    = honeycombio_query.refinery_dropped_peer_events_query.id

  recipient {
    id = var.create_slack_recipient ? honeycombio_slack_recipient.alerts[0].id : var.existing_slack_recipient_id
  }

  threshold {
    exceeded_limit = "1"
    op             = ">"
    value          = "1000"
  }
}


################################################################################
# Fourth trigger: refinery_cache_buffer_overrun
################################################################################
resource "honeycombio_query" "refinery_cache_buffer_overrun_query" {
  dataset    = var.refinery_metrics_dataset
  query_json = data.honeycombio_query_specification.refinery_cache_buffer_overrun_query_spec.json
  depends_on = [null_resource.create_metrics_columns]
}

data "honeycombio_query_specification" "refinery_cache_buffer_overrun_query_spec" {
  calculation {
    op     = "SUM"
    column = "collect_cache_buffer_overrun"
  }

  filter {
    column = "collect_cache_buffer_overrun"
    op     = "exists"
  }

  breakdowns = ["hostname"]

  order {
    op     = "SUM"
    column = "collect_cache_buffer_overrun"
    order  = "descending"
  }

  time_range = 900
}

resource "honeycombio_trigger" "refinery_cache_buffer_overrun" {
  alert_type  = "on_change"
  dataset     = var.refinery_metrics_dataset
  description = "Indicates buffer and/or memory capacity under-sizing on the Refinery cluster for the given traffic load, resulting in significant (> 1000) events dropped.\nFor more info, see: https://docs.honeycomb.io/manage-data-volume/refinery/scale-and-troubleshoot/#scaling-the-ram"
  disabled    = "false"
  frequency   = "900"
  name        = "Refinery Cache Buffer Overrun"
  query_id    = honeycombio_query.refinery_cache_buffer_overrun_query.id

  recipient {
    id = var.create_slack_recipient ? honeycombio_slack_recipient.alerts[0].id : var.existing_slack_recipient_id
  }

  threshold {
    exceeded_limit = "4"
    op             = ">"
    value          = "1000"
  }
}

################################################################################
# Fifth query: refinery_peer_queue_buffer_overflow
################################################################################
resource "honeycombio_query" "refinery_peer_queue_buffer_overflow_query" {
  dataset    = var.refinery_metrics_dataset
  query_json = data.honeycombio_query_specification.refinery_peer_queue_buffer_overflow_query_spec.json
  depends_on = [null_resource.create_metrics_columns]
}

data "honeycombio_query_specification" "refinery_peer_queue_buffer_overflow_query_spec" {
  calculation {
    op     = "SUM"
    column = "libhoney_peer_queue_overflow"
  }

  filter {
    column = "libhoney_peer_queue_overflow"
    op     = "exists"
  }

  breakdowns = ["hostname"]

  order {
    op     = "SUM"
    column = "libhoney_peer_queue_overflow"
    order  = "descending"
  }

  time_range = 900
}

resource "honeycombio_trigger" "refinery_peer_queue_buffer_overflow" {
  alert_type  = "on_change"
  dataset     = var.refinery_metrics_dataset
  description = "Indicates that either `PeerBufferSize` is set too low in Refinery, or that there are bandwidth or other communication constraints between Refinery nodes."
  disabled    = "false"
  frequency   = "900"
  name        = "Refinery Peer Queue Buffer Overflow"
  query_id    = honeycombio_query.refinery_peer_queue_buffer_overflow_query.id

  recipient {
    id = var.create_slack_recipient ? honeycombio_slack_recipient.alerts[0].id : var.existing_slack_recipient_id
  }

  threshold {
    exceeded_limit = "4"
    op             = ">"
    value          = "1000"
  }
}

################################################################################
# Fifth query: refinery_upstream_queue_overflow
################################################################################
resource "honeycombio_query" "refinery_upstream_queue_overflow_query" {
  dataset    = var.refinery_metrics_dataset
  query_json = data.honeycombio_query_specification.refinery_upstream_queue_overflow_query_spec.json
  depends_on = [null_resource.create_metrics_columns]
}

data "honeycombio_query_specification" "refinery_upstream_queue_overflow_query_spec" {
  calculation {
    op     = "SUM"
    column = "libhoney_upstream_queue_overflow"
  }

  filter {
    column = "libhoney_upstream_queue_overflow"
    op     = "exists"
  }

  breakdowns = ["hostname"]

  order {
    op     = "SUM"
    column = "libhoney_upstream_queue_overflow"
    order  = "descending"
  }

  time_range = 900
}

resource "honeycombio_trigger" "refinery_upstream_queue_overflow" {
  alert_type  = "on_change"
  dataset     = var.refinery_metrics_dataset
  description = "Indicates that either `UpstreamBufferSize` is set too low in Refinery, or that there are bandwidth or other communication constraints between your Refinery cluster and Honeycomb, or a potential issue with Honeycomb itself."
  disabled    = "false"
  frequency   = "900"
  name        = "Refinery Upstream Queue Overflow"
  query_id    = honeycombio_query.refinery_upstream_queue_overflow_query.id

  recipient {
    id = var.create_slack_recipient ? honeycombio_slack_recipient.alerts[0].id : var.existing_slack_recipient_id
  }

  threshold {
    exceeded_limit = "1"
    op             = ">"
    value          = "1000"
  }
}



################################################################################
# Fifth query: refinery_incoming_traffic_stopped
################################################################################
resource "honeycombio_query" "refinery_incoming_traffic_stopped_query" {
  dataset    = var.refinery_metrics_dataset
  query_json = data.honeycombio_query_specification.refinery_incoming_traffic_stopped_query_spec.json
  depends_on = [null_resource.create_metrics_columns]
}

data "honeycombio_query_specification" "refinery_incoming_traffic_stopped_query_spec" {
  calculation {
    op     = "SUM"
    column = "incoming_router_span"
  }

  filter {
    column = "incoming_router_span"
    op     = "exists"
  }

  breakdowns = ["hostname"]

  order {
    op     = "SUM"
    column = "incoming_router_span"
  }

  time_range = 3600
}

resource "honeycombio_trigger" "refinery_incoming_traffic_stopped" {
  alert_type  = "on_change"
  dataset     = var.refinery_metrics_dataset
  description = "Indicates that incoming traffic to given Refinery nodes has stopped, which may point to a problem with an upstream component (e.g. Refinery load balancers, client SDK configuration, etc)"
  disabled    = "false"
  frequency   = "3600"
  name        = "Refinery Incoming Traffic has Stopped"
  query_id    = honeycombio_query.refinery_incoming_traffic_stopped_query.id

  recipient {
    id = var.create_slack_recipient ? honeycombio_slack_recipient.alerts[0].id : var.existing_slack_recipient_id
  }

  threshold {
    exceeded_limit = "4"
    op             = "<"
    value          = "10"
  }
}
