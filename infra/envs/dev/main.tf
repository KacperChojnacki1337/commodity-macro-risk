# DEV root module: just calls the shared platform module with dev values.
# All the real resource logic lives in modules/platform.

module "platform" {
  source = "../../modules/platform"

  environment = "dev"
  location    = var.location
  name_prefix = var.name_prefix
}
