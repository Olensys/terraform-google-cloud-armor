locals {
  extra_labels = { for k, v in var.context.extra_tags :
  substr(replace(lower(k), "/[^a-z0-9_-]/", "-"), 0, 63) => substr(replace(lower(v), "/[^a-z0-9_-]/", "-"), 0, 63) }
  labels = merge(local.extra_labels, var.labels)

  ip_rules = merge(
    length(var.allow_ips) > 0 ? {
      allow = {
        action        = "allow"
        priority      = 100
        description   = "Allow listed source ranges"
        src_ip_ranges = var.allow_ips
      }
    } : {},
    length(var.deny_ips) > 0 ? {
      deny = {
        action        = "deny(403)"
        priority      = 200
        description   = "Deny listed source ranges"
        src_ip_ranges = var.deny_ips
      }
    } : {},
    var.rate_limit != null ? {
      rate_limit = {
        action        = "rate_based_ban"
        priority      = 300
        description   = "Rate limit per client IP"
        src_ip_ranges = ["*"]
        rate_limit_options = {
          enforce_on_key                       = "IP"
          exceed_action                        = "deny(429)"
          rate_limit_http_request_count        = try(var.rate_limit.count, null)
          rate_limit_http_request_interval_sec = try(var.rate_limit.interval_s, null)
          ban_duration_sec                     = try(var.rate_limit.ban_duration_s, null)
        }
      }
    } : {},
  )

  preconfigured_rules = {
    for k, r in var.preconfigured_rules : k => {
      action            = r.action
      priority          = r.priority
      description       = "OWASP ${r.target_rule_set}"
      target_rule_set   = r.target_rule_set
      sensitivity_level = r.sensitivity
    }
  }

  default_rule_action = "allow"

  rules_config = {
    preconfigured             = length(var.preconfigured_rules)
    ip_allow                  = length(var.allow_ips) > 0 ? 1 : 0
    ip_deny                   = length(var.deny_ips) > 0 ? 1 : 0
    rate_limit                = var.rate_limit != null ? 1 : 0
    rate_limit_ban_duration_s = try(var.rate_limit.ban_duration_s, null)
    adaptive_protection       = var.adaptive_protection
    default_rule_action       = local.default_rule_action
  }
}

module "this" {
  source  = "GoogleCloudPlatform/cloud-armor/google"
  version = "9.0.0"

  count = var.create ? 1 : 0

  project_id  = var.project_id
  name        = var.name
  description = "Cloud Armor policy ${var.name}"
  type        = "CLOUD_ARMOR"

  default_rule_action = local.default_rule_action
  json_parsing        = "STANDARD"
  log_level           = "VERBOSE"

  pre_configured_rules = local.preconfigured_rules
  security_rules       = local.ip_rules

  layer_7_ddos_defense_enable          = var.adaptive_protection
  layer_7_ddos_defense_rule_visibility = "STANDARD"

  labels = local.labels
}
