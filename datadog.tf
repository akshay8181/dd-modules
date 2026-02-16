locals {

  raw_config = yamldecode(
    file("${path.module}/configs/monitors.yaml")
  )

  monitors_list = local.raw_config.monitors

  monitors = {
    for m in local.monitors_list :
    m.id => merge(
      m,
      {
        query = replace(m.query, "${cluster}", var.cluster_name)

        tags = [
          "cluster:${var.cluster_name}",
          "managed_by:terraform",
          "team:platform",
          "severity:${m.severity}"
        ]
      }
    )
  }
}

module "datadog_monitors" {
  source   = "./modules/datadog/monitor"
  monitors = local.monitors
}


resource "datadog_monitor" "this" {
  for_each = var.monitors

  name    = each.value.name
  type    = each.value.type
  query   = each.value.query
  message = "Monitor: ${each.value.name}"

  tags = lookup(each.value, "tags", [])

  notify_no_data = true
  include_tags   = true

  dynamic "monitor_thresholds" {
    for_each = lookup(each.value, "thresholds", null) != null ? [each.value.thresholds] : []
    content {
      critical          = lookup(monitor_thresholds.value, "critical", null)
      warning           = lookup(monitor_thresholds.value, "warning", null)
      critical_recovery = lookup(monitor_thresholds.value, "critical_recovery", null)
      warning_recovery  = lookup(monitor_thresholds.value, "warning_recovery", null)
    }
  }

  dynamic "monitor_threshold_windows" {
    for_each = lookup(each.value, "threshold_windows", null) != null ? [each.value.threshold_windows] : []
    content {
      trigger_window  = lookup(monitor_threshold_windows.value, "trigger_window", null)
      recovery_window = lookup(monitor_threshold_windows.value, "recovery_window", null)
    }
  }

  evaluation_delay = lookup(each.value, "evaluation_delay", null)
  timeout_h        = lookup(each.value, "timeout_h", null)
  priority         = lookup(each.value, "priority", null)
}
variable "monitors" {
  description = "Map of Datadog monitors"
  type        = map(any)
}
output "monitor_ids" {
  value = {
    for k, v in datadog_monitor.this :
    k => v.id
  }
}
