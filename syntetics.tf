variable "enable_synthetics" {
  type    = bool
  default = true
}

variable "synthetics" {
  type = map(any)
}

variable "cluster_name" {
  type = string
}
resource "datadog_synthetics_test" "this" {
  for_each = var.enable_synthetics ? var.synthetics : {}

  name = "${each.value.name} - ${var.cluster_name}"
  type = each.value.type

  subtype = lookup(each.value, "subtype", null)

  locations = lookup(each.value, "locations", [])

  status = "live"

  tags = [
    "cluster:${var.cluster_name}",
    "managed-by:terraform"
  ]

  # -----------------------
  # REQUEST DEFINITION
  # -----------------------
  dynamic "request_definition" {
    for_each = lookup(each.value, "request", null) != null ? [each.value.request] : []
    content {
      method = lookup(request_definition.value, "method", null)
      url    = lookup(request_definition.value, "url", null)
    }
  }

  # -----------------------
  # ASSERTIONS
  # -----------------------
  dynamic "assertion" {
    for_each = lookup(each.value, "assertions", [])

    content {
      type     = assertion.value.type
      operator = assertion.value.operator
      target   = assertion.value.target
    }
  }
}
output "synthetic_test_ids" {
  value = {
    for k, v in datadog_synthetics_test.this :
    k => v.id
  }
}
locals {
  synthetics_raw = yamldecode(
    file("${path.module}/configs/synthetics.yaml")
  )

  synthetics_map = {
    for k, v in local.synthetics_raw.synthetics :
    k => v
  }
}

module "datadog_synthetics" {
  source            = "./modules/datadog/synthetics"
  enable_synthetics = true
  synthetics        = local.synthetics_map
  cluster_name      = var.cluster_name
}
