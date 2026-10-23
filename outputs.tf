output "id" {
  description = "Identifier of the security policy. Null when create is false."
  value       = var.create ? module.this[0].policy.id : null
}

output "name" {
  description = "Name of the security policy. Null when create is false."
  value       = var.create ? var.name : null
}

output "self_link" {
  description = "Self link of the security policy; pass it as the security_policy of a backend service. Null when create is false."
  value       = var.create ? module.this[0].policy.self_link : null
}

output "labels" {
  description = "Labels applied to the security policy, with context.extra_tags merged in. Null when create is false."
  value       = var.create ? local.labels : null
}

output "rules_config" {
  description = "Count of rules passed to the policy per kind, the rate-limit ban duration, the adaptive protection flag and the default rule action. Null when create is false."
  value       = var.create ? local.rules_config : null
}
