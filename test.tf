resource "datadog_monitor" "this" {
  for_each = var.monitors

  name  = each.value.name
  type  = each.value.type
  query = each.value.query

  tags = lookup(each.value, "tags", [])

  notify_no_data = lookup(each.value, "notify_no_data", true)
  include_tags   = true

  # -------------------------
  # Smart Enterprise Message
  # -------------------------
  message = <<-EOT
{{#is_alert}}
🚨 ALERT: ${each.value.name}
${lookup(each.value, "alert_message", "Threshold breached.")}

${join(" ", lookup(each.value, "notify_emails", []))}
{{/is_alert}}

{{#is_warning}}
⚠️ WARNING: ${each.value.name}
${lookup(each.value, "warning_message", "")}

${join(" ", lookup(each.value, "notify_emails", []))}
{{/is_warning}}

{{#is_recovery}}
✅ RECOVERY: ${each.value.name}
${lookup(each.value, "recovery_message", "Monitor recovered.")}

${join(" ", lookup(each.value, "notify_emails", []))}
{{/is_recovery}}

{{#is_no_data}}
❓ NO DATA: ${each.value.name}
${lookup(each.value, "no_data_message", "No data received.")}

${join(" ", lookup(each.value, "notify_emails", []))}
{{/is_no_data}}
EOT

  dynamic "monitor_thresholds" {
    for_each = lookup(each.value, "thresholds", null) != null ? [each.value.thresholds] : []
    content {
      critical          = lookup(monitor_thresholds.value, "critical", null)
      warning           = lookup(monitor_thresholds.value, "warning", null)
      critical_recovery = lookup(monitor_thresholds.value, "critical_recovery", null)
      warning_recovery  = lookup(monitor_thresholds.value, "warning_recovery", null)
    }
  }

  evaluation_delay = lookup(each.value, "evaluation_delay", null)
  timeout_h        = lookup(each.value, "timeout_h", null)
  priority         = lookup(each.value, "priority", null)
}
