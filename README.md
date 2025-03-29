# Azure Infrastructure as Code

Deploying a CRUD application to Azure using Azure CLI and Bicep templates.

## Architecture Diagram

Below is the Azure architecture of my implementation, created with [diagrams.net]


## Implementation Process

### Step 1: Learn About IaC and Bicep

- **Objective**: Understand Infrastructure-as-Code and Bicep templates
- **Actions**:
  - Completed [MS Learn - Introduction to Infrastructure as Code](https://learn.microsoft.com/en-us/training/modules/intro-to-infrastructure-as-code/)
  - Followed [MS Learn - Build Your First Bicep Template](https://learn.microsoft.com/en-us/training/modules/build-first-bicep-template/)
- **Outcome**: Gained skills to automate Azure resource provisioning with Bicep

### Step 2: Build the Container Image

- **Objective**: Containerize the Flask CRUD application
- **Actions**:
  - Cloned [example-flask-crud](https://github.com/gurkanakdeniz/example-flask-crud)
  - Created a Dockerfile:

```dockerfile
FROM python:3.9

WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . .

RUN apt-get update && apt-get install -y libpq-dev gcc

RUN python3 -m venv venv

RUN /bin/bash -c "source venv/bin/activate && pip install --upgrade pip && pip install -r requirements.txt"

ENV FLASK_APP=crudapp.py
ENV FLASK_RUN_HOST=0.0.0.0

RUN /bin/bash -c "source venv/bin/activate && flask db init && flask db migrate -m 'entries table' && flask db upgrade"

EXPOSE 80

CMD ["/bin/bash", "-c", "source venv/bin/activate && flask run --host=0.0.0.0 --port=80"]
```

  - Built the image locally:

```bash
docker build -t mycrudapp:latest .
```

- **Outcome**: Created `mycrudapp:latest` container image, ready for deployment to Azure Container Registry

### Step 3: Create Azure Container Registry (ACR)

- **Objective**: Set up ACR to store the container image
- **Actions**:
  - Created `acr.bicep` for Azure Container Registry:

```bicep
param location string = 'westeurope'
param acrName string = 'rjacr2025' // Customize with your own name

resource acr 'Microsoft.ContainerRegistry/registries@2022-12-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic' 
  }
  properties: {
    adminUserEnabled: true
  }
}

resource acrToken 'Microsoft.ContainerRegistry/registries/tokens@2022-12-01' = {
  name: 'rjtoken'
  parent: acr 
  properties: {
    scopeMapId: resourceId('Microsoft.ContainerRegistry/registries/scopeMaps', acrName, '_repositories_pull')
    status: 'enabled'
  }
}

output acrLoginServer string = acr.properties.loginServer
```

  - Deployed ACR using Azure CLI:

```bash
az deployment group create --resource-group rj-rg --template-file acr.bicep
```

- **Outcome**: Successfully created an Azure Container Registry for storing application images

### Step 4: Push Docker Image to ACR

- **Objective**: Upload the local container image to Azure Container Registry
- **Actions**:
  - Authenticated with Azure and ACR:

```bash
az login
docker login acrusername.azurecr.io --username acrusername --password acrpassword
```

  - Tagged and pushed the image:

```bash
docker tag mycrudapp:latest acrusername.azurecr.io/mycrudapp:latest
# Verify tag creation
docker images
# Push image to ACR
docker push acrusername.azurecr.io/mycrudapp:latest
```

  - Troubleshooting tip: If push fails, try logging out of Docker and logging back in
- **Outcome**: Container image successfully stored in Azure Container Registry

### Step 5: Deploy to Azure Container Instance (ACI) & Implement Best Practices

- **Objective**: Deploy the containerized application and implement Azure best practices
- **Actions**:
  - Created `aci.bicep` deployment template:

```bicep
@description('Name for the container group')
param name string = 'rjcrudapp'

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
@allowed([
  'Always'
  'Never'
  'OnFailure'
])
param restartPolicy string = 'Always'

@description('ACR admin username')
param registryUsername string = 'rjacr2025'

@description('ACR admin password')
@secure()
param registryPassword string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'rjlogs'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
  }
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: name
  location: location
  properties: {
    containers: [
      {
        name: name
        properties: {
          image: image
          ports: [
            {
              port: port
              protocol: 'TCP'
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
          environmentVariables: []
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
      ports: [
        {
          port: port
          protocol: 'TCP'
        }
      ]
    }
    diagnostics: {
      logAnalytics: {
        workspaceId: logAnalytics.properties.customerId
        workspaceKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

targetScope = 'resourceGroup'

output containerGroupName string = containerGroup.name
output resourceGroupName string = resourceGroup().name
output resourceId string = containerGroup.id
output publicIpAddress string = containerGroup.properties.ipAddress.ip
output location string = location
```

  - Best practices implemented:
    - Resource optimization: Used minimal resources (1 CPU, 2 GB memory) to reduce costs
    - Monitoring: Added Azure Monitor integration via Log Analytics workspace
    - Security parameters: Used `@secure()` decorator for sensitive information
    - Documentation: Included detailed parameter descriptions
    - Outputs: Added deployment outputs for reference and automation
  - Deployment limitations: Couldn't implement VNet/NSG integration with public IP due to ACI constraints
- **Outcome**: Successfully deployed containerized application with monitoring and optimized resource usage

### Extra: Custom Domain with DuckDNS

- **Objective**: Improve user experience by adding a custom domain
- **Actions**:
  - Registered `khaibcrud.duckdns.org` at DuckDNS.org
  - Updated DNS records with the container instance's public IP (obtained from deployment output)
  - Verified accessibility through the custom domain
- **Benefits**: Provides a user-friendly URL instead of a raw IP address
- **Outcome**: Application accessible at [http://khaibcrud.duckdns.org](http://khaibcrud.duckdns.org)
  ![Architecture Diagram](https://github.com/user-attachments/assets/62c41922-bfc0-4d90-ad05-68149fcb1174)


## Conclusion

This project demonstrates the implementation of Infrastructure as Code principles using Azure's native IaC solution, Bicep. The containerized CRUD application is deployed following best practices for resource optimization, security, and monitoring while maintaining easy accessibility.
