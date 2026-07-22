# Inputs for the subscription-scoped root module.

variable "budget_name" {
  description = "Name of the subscription budget."
  type        = string
  default     = "budget-commodity-risk-monthly"
}

variable "monthly_budget_amount" {
  description = <<-EOT
    Monthly budget, in the subscription's billing currency (EUR here).
    Deliberately small: measured usage is ~0.1-0.3/month (ADF activity runs plus
    a few MB in ADLS), and ~0 when dev is destroyed between sessions. At 2 the
    alerts fire at 1.00 / 1.60 / 2.00 — roughly 5x expected spend, so a runaway
    workload is caught early instead of after the damage.
  EOT
  type        = number
  default     = 2

  validation {
    condition     = var.monthly_budget_amount > 0
    error_message = "monthly_budget_amount must be greater than 0."
  }
}

variable "budget_start_date" {
  description = "Budget start, RFC3339 UTC. Azure requires the FIRST day of a month."
  type        = string
  default     = "2026-07-01T00:00:00Z"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-01T00:00:00Z$", var.budget_start_date))
    error_message = "budget_start_date must be the first day of a month, e.g. 2026-07-01T00:00:00Z."
  }
}

variable "budget_alert_thresholds" {
  description = "Percent-of-budget thresholds that trigger a notification to the Owner role."
  type        = list(number)
  default     = [50, 80, 100]
}
