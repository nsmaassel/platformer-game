// Azure Static Web App for game.maassel.dev
// Deploy: az deployment group create --resource-group <rg> --template-file swa.bicep

@description('Static Web App name')
param siteName string = 'platformer-game'

@description('Azure region')
param location string = 'eastus2'

resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
  name: siteName
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    buildProperties: {
      appLocation: 'dist'
      skipGithubActionWorkflowGeneration: true
    }
  }
}

resource customDomain 'Microsoft.Web/staticSites/customDomains@2023-01-01' = {
  parent: staticWebApp
  name: 'game.maassel.dev'
  properties: {}
}

output defaultHostname string = staticWebApp.properties.defaultHostname
output deploymentToken string = listSecrets(staticWebApp.id, staticWebApp.apiVersion).properties.apiKey
