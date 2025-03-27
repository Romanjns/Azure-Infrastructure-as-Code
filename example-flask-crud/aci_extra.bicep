@description('Name for the container group')
param name string = 'rjcrudappextra'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Container image to deploy from ACR')
param image string = 'rjacr2025.azurecr.io/mycrudapp:latest'

@description('Port to open on the container and public IP')
param port int = 80

@description('Number of CPU cores for the container')
param cpuCores int = 1

@description('Memory in GB for the container')
param memoryInGb int = 2

@description('Restart policy for the container')
@allowed(['Always', 'Never', 'OnFailure'])
param restartPolicy string = 'Always'

@description('ACR admin username')
param registryUsername string = 'rjacr2025'

@description('ACR admin password')
@secure()
param registryPassword string

@description('Custom domain name (e.g., khaibcrud.duckdns.org)')
param customDomain string = 'khaibcrud.duckdns.org' // Replace with your DuckDNS subdomain

// Log Analytics Workspace voor Azure Monitor
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'rjlogs'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
  }
}

// ACI resource
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: name
  location: location
  properties: {
    containers: [
      {
        name: name
        properties: {
          image: image
          ports: [{ port: port, protocol: 'TCP' }]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
          environmentVariables: [
            {
              name: 'APP_DOMAIN'
              value: customDomain // Pass domain to app if needed
            }
          ]
        }
      }
    ]
    imageRegistryCredentials: [
      {
        server: 'rjacr2025.azurecr.io'
        username: registryUsername
        password: registryPassword
      }
    ]
    osType: 'Linux'
    restartPolicy: restartPolicy
    ipAddress: {
      type: 'Public'
      ports: [{ port: port, protocol: 'TCP' }]
    }
    diagnostics: {
      logAnalytics: {
        workspaceId: logAnalytics.properties.customerId
        workspaceKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Target scope
targetScope = 'resourceGroup'

// Outputs
output containerGroupName string = containerGroup.name
output publicIpAddress string = containerGroup.properties.ipAddress.ip
output customDomainUrl string = 'http://${customDomain}' // HTTP for now