mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  context = {
    organization = "olensys"
    environment  = "test"
    application  = "example"
    owner        = "platform"
    cost_center  = "eng"
  }
  name       = "example"
  project_id = "example-project"
}

run "test_owasp_defaults" {
  command = plan

  assert {
    condition = toset([for r in values(var.preconfigured_rules) : r.target_rule_set]) == toset([
      "sqli-v33-stable", "xss-v33-stable", "lfi-v33-stable", "rfi-v33-stable", "rce-v33-stable",
      "methodenforcement-v33-stable", "scannerdetection-v33-stable", "protocolattack-v33-stable", "sessionfixation-v33-stable",
    ])
    error_message = "Default preconfigured_rules must cover the OWASP CRS v33 top rule sets."
  }

  assert {
    condition     = alltrue([for r in values(var.preconfigured_rules) : r.sensitivity == 1 && r.action == "deny(403)"])
    error_message = "Default OWASP rules must run at sensitivity 1 with deny(403)."
  }

  assert {
    condition     = output.rules_config.preconfigured == 9
    error_message = "Nine preconfigured rules must be passed upstream by default."
  }
}

run "test_default_rule_allow" {
  command = plan

  assert {
    condition     = output.rules_config.default_rule_action == "allow"
    error_message = "Default rule action must be allow."
  }
}

run "test_rate_limit_when_set" {
  command = plan

  variables {
    rate_limit = { count = 100, interval_s = 60 }
  }

  assert {
    condition     = output.rules_config.rate_limit == 1 && output.rules_config.rate_limit_ban_duration_s == 600
    error_message = "A rate limit rule with the default 600s ban must be added when rate_limit is set."
  }
}

run "test_rate_limit_absent_by_default" {
  command = plan

  assert {
    condition     = output.rules_config.rate_limit == 0
    error_message = "No rate limit rule unless rate_limit is set."
  }
}

run "test_create_false_plans_nothing" {
  command = plan

  variables {
    create = false
  }

  assert {
    condition     = output.id == null && output.name == null && output.self_link == null && output.labels == null && output.rules_config == null
    error_message = "Every output must be null when create is false."
  }
}

run "test_tags_contract" {
  command = plan

  variables {
    labels = { owner = "x" }
    context = {
      organization = "olensys"
      environment  = "test"
      application  = "example"
      owner        = "platform"
      cost_center  = "eng"
      extra_tags   = { Owner = "y", Team = "Core Team" }
    }
  }

  assert {
    condition     = output.labels.owner == "x"
    error_message = "var.labels must win over context.extra_tags."
  }

  assert {
    condition     = output.labels.team == "core-team"
    error_message = "context.extra_tags must be merged into labels."
  }
}

run "test_ip_cidr_validation" {
  command = plan

  variables {
    allow_ips = ["not-a-cidr"]
  }

  expect_failures = [var.allow_ips]
}

run "test_deny_ip_cidr_validation" {
  command = plan

  variables {
    deny_ips = ["10.0.0.0/33"]
  }

  expect_failures = [var.deny_ips]
}

run "test_ip_rules_when_lists_set" {
  command = plan

  variables {
    allow_ips = ["203.0.113.0/24"]
    deny_ips  = ["198.51.100.7/32", "2001:db8::/32"]
  }

  assert {
    condition     = output.rules_config.ip_allow == 1 && output.rules_config.ip_deny == 1
    error_message = "One allow rule and one deny rule must be added when the lists are non-empty."
  }
}

run "test_no_ip_rules_when_lists_empty" {
  command = plan

  assert {
    condition     = output.rules_config.ip_allow == 0 && output.rules_config.ip_deny == 0
    error_message = "No IP rules when allow_ips and deny_ips are empty."
  }
}

run "test_name_length_validation" {
  command = plan

  variables {
    name = "this-name-is-way-too-long-for-a-security-policy-because-it-exceeds-63"
  }

  expect_failures = [var.name]
}
