locals {
  dashboards_raw = yamldecode(
    file("${path.module}/configs/dashboards.yaml")
  )

  dashboards_map = {
    for k, v in local.dashboards_raw.dashboards :
    k => v
  }
}

module "datadog_dashboards" {
  source            = "./modules/datadog/dashboard"
  enable_dashboards = true
  dashboards        = local.dashboards_map
  cluster_name      = var.cluster_name
}
resource "datadog_dashboard" "this" {
  for_each = var.enable_dashboards ? var.dashboards : {}

  title       = "${each.value.title} - ${var.cluster_name}"
  description = lookup(each.value, "description", "")
  layout_type = "ordered"

  dynamic "widget" {
    for_each = lookup(each.value, "widgets", [])

    content {

      # -----------------------
      # TIMESERIES
      # -----------------------
      dynamic "timeseries_definition" {
        for_each = widget.value.type == "timeseries" ? [1] : []
        content {
          title = widget.value.title

          request {
            q = "${widget.value.query}{cluster_name:${var.cluster_name}}"
          }
        }
      }

      # -----------------------
      # QUERY VALUE
      # -----------------------
      dynamic "query_value_definition" {
        for_each = widget.value.type == "query_value" ? [1] : []
        content {
          title = widget.value.title

          request {
            q = "${widget.value.query}{cluster_name:${var.cluster_name}}"
          }
        }
      }

      # -----------------------
      # TOPLIST
      # -----------------------
      dynamic "toplist_definition" {
        for_each = widget.value.type == "toplist" ? [1] : []
        content {
          title = widget.value.title

          request {
            q = "${widget.value.query}{cluster_name:${var.cluster_name}}"
          }
        }
      }
    }
  }
}
dashboards:

  eks_dashboard:
    title: "EKS Cluster Dashboard"
    description: "Cluster observability"

    widgets:

      - type: "timeseries"
        title: "CPU Usage"
        query: "avg:system.cpu.user"

      - type: "timeseries"
        title: "Memory Usage"
        query: "avg:system.mem.used"

      - type: "query_value"
        title: "Running Pods"
        query: "sum:kubernetes.pods.running"

      - type: "toplist"
        title: "Top Pods by CPU"
        query: "top(avg:container.cpu.usage by {pod_name}, 10, 'mean', 'desc')"

        
variable "enable_dashboards" {
  type    = bool
  default = true
}

variable "dashboards" {
  type = map(any)
}

variable "cluster_name" {
  type = string
}
