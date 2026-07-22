# Subscription-scoped resources: things that belong to the Azure account as a
# whole rather than to a single environment.
#
# Why a separate root module: root modules are split by SCOPE and lifecycle.
# `envs/dev` and `envs/prod` manage per-environment resources; this root manages
# the account. Keeping them apart means `terraform destroy` on dev (our routine
# between sessions) cannot remove the account-wide cost guard.

data "azurerm_subscription" "current" {}

# Monthly spend guard.
#
# IMPORTANT: an Azure budget only NOTIFIES — unlike the Snowflake resource
# monitor it does not stop spending. It is an early warning; the actual brake is
# `terraform destroy` between sessions (see ../../docs/cost_model.md).
#
# Notifications target the subscription Owner role rather than a hard-coded
# address, so no personal email ends up in this public repository.
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = var.budget_name
  subscription_id = data.azurerm_subscription.current.id
  amount          = var.monthly_budget_amount
  time_grain      = "Monthly"

  time_period {
    start_date = var.budget_start_date
  }

  dynamic "notification" {
    for_each = var.budget_alert_thresholds
    content {
      enabled       = true
      threshold     = notification.value
      operator      = "GreaterThan"
      contact_roles = ["Owner"]
    }
  }
}
