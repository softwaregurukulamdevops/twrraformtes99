

## Starting of Update Manager configurations
resource "azurerm_automation_runbook" "runbook_aum" {
  name                    = var.runbook_name_aum
  description             = "This is a runbook to start/stop VMs based on tags"
  location                = "eastus"
  resource_group_name     = "rg-pkautomation"
  automation_account_name = data.azurerm_automation_account.automation_acc.name
  log_verbose             = true
  log_progress            = true
  runbook_type            = "PowerShell"

  content = data.local_file.psscript_aum.content  # Content of the runbook from the file
}

# Automation schedule resource CSSPZ_eu_office_hours_stop
resource "azurerm_automation_schedule" "R-CSSPZ-Workload-MW-PatchNightly-12am" {
  name                    = "R-CSSPZ-Workload-MW-PatchNightly-12am"
  resource_group_name     = "rg-pkautomation"
  automation_account_name = data.azurerm_automation_account.automation_acc.name
  frequency               = "Day"
  interval                = 1
  start_time              = "2025-06-17T23:00:00Z"  # 12am Dublin time (Europe/Dublin)
  timezone                = "GTB Standard Time"
  description             = "Run every day at 12am"
}

resource "azurerm_automation_job_schedule" "R-CSSPZ-Workload-MW-PatchNightly-12am_schedule" {
  resource_group_name     = "rg-pkautomation"
  automation_account_name = data.azurerm_automation_account.automation_acc.name
  schedule_name           = azurerm_automation_schedule.R-CSSPZ-Workload-MW-PatchNightly-12am.name
  runbook_name            = azurerm_automation_runbook.runbook.name

  
  depends_on = [
    azurerm_automation_runbook.runbook
  ]
}

# # Schedule for 12pm
resource "azurerm_automation_schedule" "R-CSSPZ-Workload-MW-PatchNightly-12pm" {
  name                    = "R-CSSPZ-Workload-MW-PatchNightly-12pm"
  resource_group_name     = "rg-pkautomation"
  automation_account_name = data.azurerm_automation_account.automation_acc.name
  frequency               = "Day"
  interval                = 1
  start_time              = "2025-06-17T11:00:00Z"  # 12pm Dublin time (Europe/Dublin)
  timezone                = "GTB Standard Time"
  description             = "Run every day at 12pm"
}

resource "azurerm_automation_job_schedule" "R-CSSPZ-Workload-MW-PatchNightly-12pm_schedule" {
  resource_group_name     = "rg-pkautomation"
  automation_account_name = data.azurerm_automation_account.automation_acc.name
  schedule_name           = azurerm_automation_schedule.R-CSSPZ-Workload-MW-PatchNightly-12pm.name
  runbook_name            = azurerm_automation_runbook.runbook.name

  depends_on = [
    azurerm_automation_runbook.runbook
  ]
}


#Nightly - 2am every day
resource "azurerm_maintenance_configuration" "Nightly_2am" {
  name                = "Nightly-2am"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-02 02:00" # 2am Ireland time (UTC+1)
    duration        = "04:00"
    time_zone      = "GMT Standard Time"
    recur_every     = "1Day"
  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# Nightly - 3am every day
resource "azurerm_maintenance_configuration" "Nightly_3am" {
  name                = "Nightly-3am"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-02 03:00" # 3am Ireland time (UTC+1)
    duration        = "04:00"
    time_zone      = "GMT Standard Time"
    recur_every     = "1Day"
  }

  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# PilotGrp1 - 2am, 1st Tuesday of every month
resource "azurerm_maintenance_configuration" "PilotGrp1" {
  name                = "PilotGrp1"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-01 02:00" # 2am, 1st Tuesday
    duration        = "04:00"
    time_zone      = "GMT Standard Time"
    recur_every     = "Month First Tuesday"
   
   
  }
  
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# PilotGrp2 - 3am, 1st Tuesday of every month
resource "azurerm_maintenance_configuration" "PilotGrp2" {
  name                = "PilotGrp2"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-01 03:00" # 3am, 1st Tuesday
    duration        = "04:00"
   time_zone = "GMT Standard Time"
    recur_every     = "Month First Tuesday"
   
  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# PilotGrp3 - 4am, 1st Tuesday of every month
resource "azurerm_maintenance_configuration" "PilotGrp3" {
  name                = "PilotGrp3"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-01 04:00" # 4am, 1st Tuesday
    duration        = "04:00"
   time_zone = "GMT Standard Time"
    recur_every     = "Month First Tuesday"
    
  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# TestGrp1 - 2am, 2nd Tuesday of every month
resource "azurerm_maintenance_configuration" "TestGrp1" {
  name                = "TestGrp1"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-08 02:00" # 2am, 2nd Tuesday
    duration        = "04:00"
   time_zone = "GMT Standard Time"
    recur_every     = "Month Second Tuesday"

  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# TestGrp2 - 3am, 2nd Tuesday of every month
resource "azurerm_maintenance_configuration" "TestGrp2" {
  name                = "TestGrp2"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-08 03:00" # 3am, 2nd Tuesday
    duration        = "04:00"
   time_zone = "GMT Standard Time"
    recur_every     = "Month Second Tuesday"

  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# TestGrp3 - 4am, 2nd Tuesday of every month
resource "azurerm_maintenance_configuration" "TestGrp3" {
  name                = "TestGrp3"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-08 04:00" # 4am, 2nd Tuesday
    duration        = "04:00"
   time_zone = "GMT Standard Time"
    recur_every     = "Month Second Tuesday"

  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# PrepGrp1 - 2am, 3rd Tuesday of every month
resource "azurerm_maintenance_configuration" "PrepGrp1" {
  name                = "PrepGrp1"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-15 02:00" # 2am, 3rd Tuesday
    duration        = "04:00"
   time_zone = "GMT Standard Time"
    recur_every     = "Month Third Tuesday"

  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# PrepGrp2 - 2am, 3rd Wednesday of every month
resource "azurerm_maintenance_configuration" "PrepGrp2" {
  name                = "PrepGrp2"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-16 02:00" # 2am, 3rd Wednesday
    duration        = "04:00"
   time_zone = "GMT Standard Time"
    recur_every     = "Month Third Wednesday"

  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# PrepGrp3 - 2am, 3rd Thursday of every month
resource "azurerm_maintenance_configuration" "PrepGrp3" {
  name                = "PrepGrp3"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-17 02:00" # 2am, 3rd Thursday
    duration        = "04:00"
   time_zone = "GMT Standard Time"
    recur_every     = "Month Third Thursday"

  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# ProdGrp1 - 2am, 4th Tuesday of every month
resource "azurerm_maintenance_configuration" "ProdGrp1" {
  name                = "ProdGrp1"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-22 02:00" # 2am, 4th Tuesday
    duration        = "04:00"
    time_zone = "GMT Standard Time"
    recur_every     = "Month Fourth Tuesday"

  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# ProdGrp2 - 2am, 4th Wednesday of every month
resource "azurerm_maintenance_configuration" "ProdGrp2" {
  name                = "ProdGrp2"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-23 02:00" # 2am, 4th Wednesday
    duration        = "04:00"
    time_zone = "GMT Standard Time"
    recur_every     = "Month Fourth Wednesday"

  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

# ProdGrp3 - 2am, 4th Thursday of every month
resource "azurerm_maintenance_configuration" "ProdGrp3" {
  name                = "ProdGrp3"
  resource_group_name = "rg-pkautomation"
  location            = "eastus"
  scope               = "InGuestPatch"
  window {
    start_date_time = "2025-07-24 02:00" # 2am, 4th Thursday
    duration        = "04:00"
   time_zone = "GMT Standard Time"
    recur_every     = "Month Fourth Thursday"

  }
  install_patches {
    reboot = "IfRequired"
    linux {
      classifications_to_include = ["Critical", "Security"]
    }
    windows {
      classifications_to_include = ["Critical", "Security"]
    }
  }

  in_guest_user_patch_mode = "User"
}

