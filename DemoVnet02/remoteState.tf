terraform {
 backend "azurerm" {
  storage_account_name = "tdemosa"
  container_name = "terraform-container"
  key = "prod.terraform.tfstate"
  access_key = ""
 }
}
