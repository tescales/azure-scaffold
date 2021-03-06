<#PSScriptInfo
.VERSION .1
.AUTHOR Toby Scales
.COMPANYNAME Microsoft Corporation
.ICONURI
.EXTERNALMODULEDEPENDENCIES
    Requires PowerShellCore. 
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES

    Initial release.

#>
<#

.SYNOPSIS
    Creates new parameter files for the Azure Scaffold, based on input from a config.json in the root.

.DESCRIPTION
    Requires PSCore. Config.json must exist in the parent directory.

.PARAMETER rootURL
    OPTIONAL - If you store your DSC configs in a dedicated GH repo, you can specify it here to maintain links.

.PARAMETER CreateConfig2
    OPTIONAL - Switch to enable creating a config2.json file rather than parsing content into dedicated files.
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$rootUrl,
    [Parameter(Mandatory = $false)]
    [switch]$CreateConfig2
)

$ErrorActionPreference = 'Stop'

function get-TechNetItem { #Deprecated, no more TechNet...
    param(
        [string]$itemName
    )
    [hashtable]$return = @{ }

    try { $response = invoke-webrequest "https://social.technet.microsoft.com/search/en-US/feed?query=$itemName&format=RSS&theme=scriptcenter&refinement=200" } catch { $response = $_.Exception.Response } 
    [xml]$xml = $response.Content

    $scriptPage = $xml.rss.channel.item[0].link
    $return.description = $xml.rss.channel.item[0].description

    try { $response = invoke-webrequest "$scriptPage" } catch { $response = $_.Exception.Response }
    $relativeUrl = ($response.Links | where-object { $_.class -eq "Button" }).href
    $return.fullUrl = "https://gallery.technet.microsoft.com$relativeUrl"
    $type=$relativeUrl.split(".")[1]

    switch ($type) {

        "ps1" { $return.type = "Script" }
        "graphrunbook" { $return.type = "Graph" }
        "py" { $return.type = "Script" }
    }

    $return.name = (split-path -leaf $return.fullUrl).split('.')[0]

    return $return
}
function get-PSGalleryItem {
    param(
        [string]$itemName, [string]$itemType
    )
    [hashtable]$return = @{ }

    switch ($itemType) {
        "module" { $info = find-module -name $itemName -repository PSGallery ; $return.type = "Module" }
        "script" { $info = find-script -name $itemName; $return.type = "Script" }
    }
    
    $response = Invoke-WebRequest "https://www.powershellgallery.com/api/v2/package/$($info.name)/$($info.version)" -UseBasicParsing -method Get -MaximumRedirection 0 -ErrorAction SilentlyContinue
         
    $return.fullUrl = $response.Headers.Location
    write-Verbose "Update-Config.ps1: Using $($return.fullUrl) for $itemname... "
    $return.description = $info.description
    $return.name = $itemname
    #$return.name = (split-path -leaf $return.fullUrl).split('.')[0]
    
    # modules return weird names, so use the default
    #if ($itemType -eq "module") { $return.name = $itemName } 
    return $return
}

$startPath = $pwd.path
$rootPath = (get-item $PSScriptRoot).Parent.FullName

if ($CreateConfig2) {write-host -ForegroundColor Yellow "Creating/updating config2.json..."}
#$dscParamsFile = (Join-Path $rootPath "templates" -AdditionalChildPath "dsc", "azuredeploy.parameters.json")
#$runbooksParamsFile = (Join-Path $rootPath "templates" -AdditionalChildPath "runbooks", "azuredeploy.parameters.json")
#$runnowbooksParamsFile = (Join-Path $rootPath "templates" -AdditionalChildPath "automation", "azuredeploy.parameters.json")
#$solutionsParamsFile = (Join-Path $rootPath "templates" -AdditionalChildPath "solutions", "azuredeploy.parameters.json")

$dscConfigsFile = (Join-Path $rootPath "dscConfigs.json")
$dscModulesFile = (Join-Path $rootPath "dscModules.json")
$runbooksFile = (Join-Path $rootPath "runbooks.json")
$runnowbooksFile = (Join-Path $rootPath "runnowbooks.json")
$solutionsFile = (Join-Path $rootPath "solutions.json")

$configFile = (Join-Path $rootPath config.json)
$j = get-content -Raw $configFile | ConvertFrom-Json

$runbookModules = @()
$runbookParams = @()
$runnowParams = @()
$dscConfigParams = @()
$dscModuleParams = @()
$solutionsParams = @()

Write-Host "Adding Automation Modules..."
foreach ($module in $j.automationModules) {
    Write-Verbose "Update-Config.ps1: Adding Automation Module $($module.name)..."
    $item = get-PSGalleryItem -itemName $module.name -itemType "module"

    $runbookModules += [ordered]@{
        'name'        = $item.name
        'description' = $item.description
        'runbookType' = $item.type
        'uri'         = $item.fullUrl
    }
}

Write-Host "Adding Automation Runbooks..."
foreach ($runbook in $j.automationRunbooks) {
    Write-Verbose "Update-Config.ps1: Adding Automation Runbook $($runbook.name)..."
    ## TechNet functionality no longer supported (3/20/20)
#    if ( $runbook.location -eq "TechNet" ) { $item = get-TechNetItem -itemName $runbook.name } 
#    elseif ( $runbook.location -eq "PSGallery" ) { $item = get-PSGalleryItem -itemName $runbook.name -itemType "script" }

$item = get-PSGalleryItem -itemName $runbook.name -itemType "script"

    if ($runbook.run -eq "now") {
        $runnowParams += [ordered]@{ 
            'name'        = $item.name
            'description' = $item.description
            'runbookType' = $item.type
            'uri'         = $item.fullUrl
        }
    }
    else {
        $runbookParams += [ordered]@{ 
            'name'        = $item.name
            'description' = $item.description
            'runbookType' = $item.type
            'uri'         = $item.fullUrl
        }
    }
}

Write-Host "Adding DSC Configurations..."
foreach ($config in $j.dscConfigs) {
    Write-Verbose "Update-Config.ps1: Adding DSC Configuration $($config.name)..."
    if ($rootUrl) {
        $dscConfigParams += [ordered]@{ 
            'name'        = $config.name
            'description' = $config.description
            'uri'         = "$rootUrl/$($config.location)"
        }
    }
    else {
        $dscConfigParams += [ordered]@{ 
            'name'        = $config.name
            'description' = $config.description
            'uri'         = $config.location
        }
    }
}

Write-Host "Adding DSC Modules..."
foreach ($dscModule in $j.dscModules) {
    Write-Verbose "Update-Config.ps1: Adding DSC Module $($dscModule.name)..."

    if ($dscModule.location -eq "PSGallery") { 
        $item = Get-PSGalleryItem -itemName $dscModule.name -itemType "module"
    }

    $dscModuleParams += [ordered]@{ 
        'name' = $dscModule.name
        'uri'  = $item.fullUrl
    }
}

Write-Host "Adding Solutions..."
$solutionsParams = $j.solutions

$j | add-member -MemberType NoteProperty -Name "automationRunbooks" -Value $runbookParams -Force
$j | add-member -MemberType NoteProperty -Name "automationRunnowbooks" -Value $runnowParams -Force
$j | add-member -MemberType NoteProperty -Name "automationModules" -Value $runbookModules -Force
$j | add-member -MemberType NoteProperty -Name "dscConfigs" -Value $dscConfigParams -Force
$j | add-member -MemberType NoteProperty -Name "dscModules" -Value $dscModuleParams -Force
$j | add-member -MemberType NoteProperty -Name "solutions" -Value $solutionsParams -Force


# Optional behavior: save to config2.json file
if ($CreateConfig2) {
    $j | convertto-json | set-content config2.json -Force
} 
# Default behavior: save to dedicated .json files
else {
    
    #$k = get-content -raw $automationParamsFile | ConvertFrom-Json
    #$j.parameters.automationRunbooks.value = $runbookParams
    #$j.parameters.automationRunnowbooks.value = $runnowParams
    $j.dscConfigs | convertto-json | set-content $dscConfigsFile
    $j.dscModules | convertto-json | set-content $dscModulesFile
    $j.automationRunbooks | convertto-json | set-content $runbooksFile
    $j.automationRunnowbooks | convertto-json | set-content $runnowbooksFile
    $j.solutions | convertto-json | set-content $solutionsFile

}