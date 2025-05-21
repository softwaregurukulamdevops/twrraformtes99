terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
  subscription_id = "95d6c462-6712-41f0-974a-956027bf3fc8" # ✅ Set your subscription here
}

resource "azurerm_policy_definition" "deny_specific_vault_redundancy" {
  name         = "deny-specific-vault-redundancy"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "[Preview]: Do not allow creation of Recovery Services vaults of chosen storage redundancy."
  description  = "Recovery Services vaults can be created with any one of three storage redundancy options today, namely, Locally-redundant Storage, Zone-redundant storage and Geo-redundant storage. If the policies in your organization requires you to block the creation of vaults that belong to a certain redundancy type, you may achieve the same using this Azure policy."

  metadata = jsonencode({
    version  = "1.0.0-preview"
    preview  = true
    category = "Backup"
  })

  parameters = jsonencode({
    effect = {
      type = "String"
      metadata = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy."
      }
      allowedValues = ["Deny", "Disabled"]
      defaultValue  = "Deny"
    },
    BackupStorageRedundancy = {
      type = "String"
      metadata = {
        displayName = "Backup Storage Redundancy"
        description = "Specify the storage redundancy for which creation of Recovery Services vaults should not be allowed by policy."
      }
      allowedValues = [
        "GeoRedundant",
        "ZoneRedundant",
        "LocallyRedundant"
      ]
      defaultValue = "GeoRedundant"
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.RecoveryServices/vaults"
        },
        {
          field  = "Microsoft.RecoveryServices/vaults/redundancySettings.standardTierStorageRedundancy"
          equals = "[parameters('BackupStorageRedundancy')]"
        }
      ]
    },
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "deny_geo_redundant_vault_creation" {
  name                 = "deny-geo-redundant-vault-creation"
  display_name         = "Deny Recovery Vaults with GeoRedundant Storage"
  description          = "Blocks creation of Recovery Services vaults with GeoRedundant storage redundancy"
  policy_definition_id = azurerm_policy_definition.deny_specific_vault_redundancy.id
  subscription_id      = "/subscriptions/95d6c462-6712-41f0-974a-956027bf3fc8"

  parameters = jsonencode({
    effect = {
      value = "Deny"
    },
    BackupStorageRedundancy = {
      value = "GeoRedundant"
    }
  })
}
