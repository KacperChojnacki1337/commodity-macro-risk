output "budget_name" {
  description = "Name of the subscription budget."
  value       = azurerm_consumption_budget_subscription.monthly.name
}

output "monthly_budget_amount" {
  description = "Configured monthly budget (billing currency)."
  value       = azurerm_consumption_budget_subscription.monthly.amount
}

output "budget_alert_thresholds" {
  description = "Thresholds (percent) that notify the subscription Owner."
  value       = var.budget_alert_thresholds
}
