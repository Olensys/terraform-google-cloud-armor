# terraform-google-cloud-armor

Cloud Armor security policy with OWASP preconfigured rules, IP allow and deny lists, rate limiting and adaptive protection

## Opinions

- Default rule action is `allow`; protection comes from explicit deny rules.
- Policy `type = "CLOUD_ARMOR"`, `json_parsing = "STANDARD"`, `log_level = "VERBOSE"`.
- OWASP CRS v33 rule sets (`sqli`, `xss`, `lfi`, `rfi`, `rce`, `methodenforcement`, `scannerdetection`, `protocolattack`, `sessionfixation`) at sensitivity 1, `deny(403)`, priorities 1000 to 1080.
- `allow_ips` (priority 100, allow) and `deny_ips` (priority 200, `deny(403)`) create a rule only when non-empty and must be valid CIDRs.
- `rate_limit` adds a per-client-IP `rate_based_ban` rule at priority 300 (exceed action `deny(429)`, ban for `ban_duration_s`, default 600). `rate_based_ban` is used rather than `throttle` because upstream only honours the ban duration for bans.
- `adaptive_protection = true` (default) enables layer 7 DDoS defence with standard rule visibility.
- Labels are merged from `context.extra_tags` and `labels` and applied to the policy.
- Upstream creates the policy with the `google-beta` provider, so both `google` and `google-beta` (>= 7.17, < 8.0) are required. 7.17 is the minimum of the pinned upstream, above the library floor.
- `context.extra_tags` keys and values are normalised to valid GCP label syntax (lowercase, `[^a-z0-9_-]` → `-`, 63 chars); `labels` are applied verbatim and win.

## Usage

```hcl
module "naming" {
  source  = "git::https://github.com/Olensys/terraform-null-naming.git?ref=v1.0.1"
  context = var.context
}

module "this" {
  source = "git::https://github.com/Olensys/terraform-google-cloud-armor.git?ref=v1.1.0"

  name       = module.naming.name
  project_id = "my-project"
  context = {
    organization = "olensys"
    environment  = "dev"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }

  labels = module.naming.labels
}
```

Attach to a load balancer by passing the `self_link` output as the `security_policy` input of `terraform-google-https-lb`:

```hcl
security_policy = module.cloud_armor.self_link
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 7.17, < 8.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 7.17, < 8.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_this"></a> [this](#module\_this) | GoogleCloudPlatform/cloud-armor/google | 9.0.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_context"></a> [context](#input\_context) | Deployment context used for naming, tagging and environment-dependent defaults. | <pre>object({<br/>    organization = string<br/>    environment  = string<br/>    application  = string<br/>    component    = optional(string)<br/>    owner        = string<br/>    cost_center  = string<br/>    extra_tags   = optional(map(string), {})<br/>  })</pre> | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Resource name. Lowercase letters, digits and hyphens. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project that hosts the security policy. | `string` | n/a | yes |
| <a name="input_adaptive_protection"></a> [adaptive\_protection](#input\_adaptive\_protection) | Enable Cloud Armor Adaptive Protection (layer 7 DDoS defence). | `bool` | `true` | no |
| <a name="input_allow_ips"></a> [allow\_ips](#input\_allow\_ips) | CIDR ranges always allowed (priority 100). No rule is created when empty. | `list(string)` | `[]` | no |
| <a name="input_create"></a> [create](#input\_create) | Whether to create any resources. Set false to plan nothing. | `bool` | `true` | no |
| <a name="input_deny_ips"></a> [deny\_ips](#input\_deny\_ips) | CIDR ranges denied with 403 (priority 200). No rule is created when empty. | `list(string)` | `[]` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels merged onto the security policy, applied last. | `map(string)` | `{}` | no |
| <a name="input_preconfigured_rules"></a> [preconfigured\_rules](#input\_preconfigured\_rules) | Preconfigured WAF rules keyed by rule name. Defaults to the OWASP CRS v33 top rule sets at sensitivity 1, denying with 403. | <pre>map(object({<br/>    target_rule_set = string<br/>    sensitivity     = optional(number, 1)<br/>    action          = optional(string, "deny(403)")<br/>    priority        = number<br/>  }))</pre> | <pre>{<br/>  "lfi": {<br/>    "priority": 1020,<br/>    "target_rule_set": "lfi-v33-stable"<br/>  },<br/>  "methodenforcement": {<br/>    "priority": 1050,<br/>    "target_rule_set": "methodenforcement-v33-stable"<br/>  },<br/>  "protocolattack": {<br/>    "priority": 1070,<br/>    "target_rule_set": "protocolattack-v33-stable"<br/>  },<br/>  "rce": {<br/>    "priority": 1040,<br/>    "target_rule_set": "rce-v33-stable"<br/>  },<br/>  "rfi": {<br/>    "priority": 1030,<br/>    "target_rule_set": "rfi-v33-stable"<br/>  },<br/>  "scannerdetection": {<br/>    "priority": 1060,<br/>    "target_rule_set": "scannerdetection-v33-stable"<br/>  },<br/>  "sessionfixation": {<br/>    "priority": 1080,<br/>    "target_rule_set": "sessionfixation-v33-stable"<br/>  },<br/>  "sqli": {<br/>    "priority": 1000,<br/>    "target_rule_set": "sqli-v33-stable"<br/>  },<br/>  "xss": {<br/>    "priority": 1010,<br/>    "target_rule_set": "xss-v33-stable"<br/>  }<br/>}</pre> | no |
| <a name="input_rate_limit"></a> [rate\_limit](#input\_rate\_limit) | Per-client-IP rate limit (priority 300). count requests per interval\_s seconds; clients exceeding it are banned for ban\_duration\_s seconds and receive 429. Null disables. | <pre>object({<br/>    count          = number<br/>    interval_s     = number<br/>    ban_duration_s = optional(number, 600)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | Identifier of the security policy. Null when create is false. |
| <a name="output_labels"></a> [labels](#output\_labels) | Labels applied to the security policy, with context.extra\_tags merged in. Null when create is false. |
| <a name="output_name"></a> [name](#output\_name) | Name of the security policy. Null when create is false. |
| <a name="output_rules_config"></a> [rules\_config](#output\_rules\_config) | Count of rules passed to the policy per kind, the rate-limit ban duration, the adaptive protection flag and the default rule action. Null when create is false. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | Self link of the security policy; pass it as the security\_policy of a backend service. Null when create is false. |
<!-- END_TF_DOCS -->
