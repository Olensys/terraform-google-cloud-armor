variable "name" {
  description = "Resource name. Lowercase letters, digits and hyphens."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{1,63}$", var.name))
    error_message = "name must match ^[a-z0-9-]{1,63}$."
  }
}

variable "context" {
  description = "Deployment context used for naming, tagging and environment-dependent defaults."
  type = object({
    organization = string
    environment  = string
    application  = string
    component    = optional(string)
    owner        = string
    cost_center  = string
    extra_tags   = optional(map(string), {})
  })
  validation {
    condition     = contains(["dev", "staging", "prod", "test", "shared"], var.context.environment)
    error_message = "context.environment must be one of dev, staging, prod, test, shared."
  }
}

variable "project_id" {
  description = "Project that hosts the security policy."
  type        = string
}

variable "create" {
  description = "Whether to create any resources. Set false to plan nothing."
  type        = bool
  default     = true
}

variable "preconfigured_rules" {
  description = "Preconfigured WAF rules keyed by rule name. Defaults to the OWASP CRS v33 top rule sets at sensitivity 1, denying with 403."
  type = map(object({
    target_rule_set = string
    sensitivity     = optional(number, 1)
    action          = optional(string, "deny(403)")
    priority        = number
  }))
  default = {
    sqli              = { target_rule_set = "sqli-v33-stable", priority = 1000 }
    xss               = { target_rule_set = "xss-v33-stable", priority = 1010 }
    lfi               = { target_rule_set = "lfi-v33-stable", priority = 1020 }
    rfi               = { target_rule_set = "rfi-v33-stable", priority = 1030 }
    rce               = { target_rule_set = "rce-v33-stable", priority = 1040 }
    methodenforcement = { target_rule_set = "methodenforcement-v33-stable", priority = 1050 }
    scannerdetection  = { target_rule_set = "scannerdetection-v33-stable", priority = 1060 }
    protocolattack    = { target_rule_set = "protocolattack-v33-stable", priority = 1070 }
    sessionfixation   = { target_rule_set = "sessionfixation-v33-stable", priority = 1080 }
  }
  validation {
    condition     = alltrue([for r in values(var.preconfigured_rules) : r.sensitivity >= 0 && r.sensitivity <= 4])
    error_message = "preconfigured_rules sensitivity must be between 0 and 4."
  }
  validation {
    condition     = alltrue([for r in values(var.preconfigured_rules) : r.priority >= 0 && r.priority < 2147483647])
    error_message = "preconfigured_rules priority must be between 0 and 2147483646."
  }
}

variable "allow_ips" {
  description = "CIDR ranges always allowed (priority 100). No rule is created when empty."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for c in var.allow_ips : can(cidrhost(c, 0))])
    error_message = "allow_ips entries must be valid CIDR ranges."
  }
}

variable "deny_ips" {
  description = "CIDR ranges denied with 403 (priority 200). No rule is created when empty."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for c in var.deny_ips : can(cidrhost(c, 0))])
    error_message = "deny_ips entries must be valid CIDR ranges."
  }
}

variable "rate_limit" {
  description = "Per-client-IP rate limit (priority 300). count requests per interval_s seconds; clients exceeding it are banned for ban_duration_s seconds and receive 429. Null disables."
  type = object({
    count          = number
    interval_s     = number
    ban_duration_s = optional(number, 600)
  })
  default = null
  validation {
    condition     = var.rate_limit == null ? true : (var.rate_limit.count > 0 && var.rate_limit.interval_s > 0 && var.rate_limit.ban_duration_s > 0)
    error_message = "rate_limit count, interval_s and ban_duration_s must be positive."
  }
}

variable "adaptive_protection" {
  description = "Enable Cloud Armor Adaptive Protection (layer 7 DDoS defence)."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels merged onto the security policy, applied last."
  type        = map(string)
  default     = {}
}
