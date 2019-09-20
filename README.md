# Deploy A Management and Governance Scaffold for Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Ftescales%2Fazure-scaffold%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>
<a href="http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Ftescales%2Fazure-scaffold%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="http://armviz.io/visualizebutton.png"/>
</a>

This creates a scaffold in Azure.

## TODO: 
 * Add bastion host support
 * Refactor RunNow logic using a .runnow value (collect true/false and deploy jobs for them)
 * Use KV to generate cert for VM authentication:
    https://www.rahulpnath.com/blog/manage-certificates-in-azure-key-vault/
 * Consider adding Function to pull UserObjectID: 
    https://github.com/jussiroine/TenantIDLookup
 * Add Alerts Toolkit:
    https://github.com/Microsoft/manageability-toolkits
    https://www.powershellgallery.com/packages/Enable-AzureDiagnostics/1.1
 * Look at CAF integration:
    https://github.com/microsoft/CloudAdoptionFramework
 * Add AzureAutomation RunAs Account:
    https://docs.microsoft.com/en-us/azure/automation/manage-runas-account
 * Add Update-KVCert script from automation: 
    https://github.com/jefffanjoy/DemoCode/blob/master/Scripts/Azure%20Automation/RenewRunAsCertificate.ps1
 * Investigate DeploymentManager for simplification:
    https://docs.microsoft.com/en-us/azure/azure-resource-manager/deployment-manager-overview#rollout-template

 * Azsecrets?
 https://www.gollahalli.com/blog/azsecrets-a-cli-to-set-azure-key-vault-as-environment-variables/

 * Secure web app? (web+appgw):
 https://blogs.msdn.microsoft.com/mihansen/2018/02/15/web-app-with-vnet-only-access-using-app-gateway-powershell-automation/