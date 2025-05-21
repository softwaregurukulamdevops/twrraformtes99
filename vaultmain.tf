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
}

# Create the custom policy at the subscription scope
resource "azurerm_policy_definition" "traffic_analytics_enabled" {
  name         = "network-watcher-flow-logs-traffic-analytics-enabled"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Network Watcher flow logs should have traffic analytics enabled"
  description  = "Traffic analytics analyzes flow logs to provide insights into traffic flow in your Azure cloud. It can be used to visualize network activity across your Azure subscriptions and identify hot spots, identify security threats, understand traffic flow patterns, pinpoint network misconfigurations and more."

  # Scope: subscription-level
  #subscription_id = "3bc8f069-65c7-4d08-b8de-534c20e56c38" # ✅ Ensure the policy definition is created at the same scope

  metadata = jsonencode({
    version  = "1.0.1"
    category = "Network"
  })

  parameters = jsonencode({
    effect = {
      type         = "String"
      metadata     = {
        displayName = "Effect"
        description = "Enable or disable the execution of the policy"
      }
      allowedValues = ["Audit", "Disabled"]
      defaultValue  = "Audit"
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Network/networkWatchers/flowLogs"
        },
        {
          anyOf = [
            {
              field  = "Microsoft.Network/networkWatchers/flowLogs/flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration.enabled"
              equals = false
            },
            {
              field  = "Microsoft.Network/networkWatchers/flowLogs/flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration.trafficAnalyticsInterval"
              notIn  = ["10", "60"]
            }
          ]
        }
      ]
    },
    then = {
      effect = "[parameters('effect')]"
    }
  })
}

resource "azurerm_subscription_policy_assignment" "assign_traffic_analytics_policy" {
  name                 = "enforce-traffic-analytics-policy"
  display_name         = "Enforce Traffic Analytics on Flow Logs"
  description          = "Assigns policy to audit if Network Watcher flow logs have traffic analytics enabled"
  policy_definition_id = azurerm_policy_definition.traffic_analytics_enabled.id
  subscription_id      = "/subscriptions/95d6c462-6712-41f0-974a-956027bf3fc8"
5f
  parameters = jsonencode({
    effect = {
      value = "Audit"
    }
  })
}
