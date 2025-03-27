param location string = 'westeurope'
param acrName string = 'rjacr2025' // Of een andere unieke naam als je iets nieuws wilt

// ACR resource met een ondersteunde API-versie
resource acr 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic' // Goedkoop
  }
  properties: {
    adminUserEnabled: true
  }
}

// Token resource met vereenvoudigde syntax en ondersteunde API-versie
resource acrToken 'Microsoft.ContainerRegistry/registries/tokens@2022-12-01' = {
  name: 'rjtoken'
  parent: acr // Gebruik 'parent' om de relatie met acr te definiëren
  properties: {
    scopeMapId: resourceId('Microsoft.ContainerRegistry/registries/scopeMaps', acrName, '_repositories_pull')
    status: 'enabled'
  }
}

output acrLoginServer string = acr.properties.loginServer