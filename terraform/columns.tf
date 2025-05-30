# Send a dummy event to create columns in Honeycomb, just in case they haven't been sent yet
locals {
  metrics_columns = {
    "hostname"                         = "terraform"
    "incoming_router_dropped"          = 0.0
    "stress_relief_activated"          = 0.0
    "collect_cache_buffer_overrun"     = 0.0
    "libhoney_peer_queue_overflow"     = 0.0
    "libhoney_upstream_queue_overflow" = 0.0
    "incoming_router_span"             = 0.0
  }
}

resource "null_resource" "create_metrics_columns" {
  provisioner "local-exec" {
    command = <<-EOT

    HONEYCOMB_DATASET="${var.refinery_metrics_dataset}"

    curl -s --retry 3 --retry-delay 5 --retry-max-time 30 \
      $${HONEYCOMB_API_ENDPOINT}/1/events/$${HONEYCOMB_DATASET} \
      -X POST \
      -H "X-Honeycomb-Team: $${HONEYCOMB_API_KEY}" \
      -d '${jsonencode(local.metrics_columns)}'

      # sleep to allow Honeycomb to process the event and create columns
      sleep 15
    EOT
  }
}
