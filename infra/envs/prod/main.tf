# PROD root module: calls the shared platform module with prod values.

module "platform" {
  source = "../../modules/platform"

  environment = "prod"
  location    = var.location
  name_prefix = var.name_prefix
}
