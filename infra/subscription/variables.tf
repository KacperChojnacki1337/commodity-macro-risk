# Inputs for the subscription-scoped root module.

variable "budget_name" {
  description = "Name of the subscription budget."
  type        = string
  default     = "budget-commodity-risk-monthly"
}

variable "monthly_budget_amount" {
  description = "Monthly budget, in the subscription's billing currency. Our measured usage is a fraction of this — it is a safety net, not a forecast."
  type        = number
  default     = 20

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
