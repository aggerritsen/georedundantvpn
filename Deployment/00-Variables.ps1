#
### Deployment Variables
### Version 1.0
#

#$WarningPreference = "SilentlyContinue"
#$ErrorActionPreference = "SilentlyContinue"

# Init
"Initialize Global Variables"
$global:name = @()
$name += @("HQ")
$name += @("West")
$name += @("North")

$global:region = @()
$region += @("westeurope")
$region += @("westeurope")
$region += @("northeurope")

$global:asn = @()
$asn += "65510"
$asn += "65511"
$asn += "65512"

