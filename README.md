# Azure-Infrastructure-as-Code
deploying CRUD app to azure using azure cli and bicep remplates

## Architecture Diagram
Below is the Azure design of my implementation, created with [diagrams.net]
img

### Step 1: Learn About IaC and Bicep
- **Objective**: Understand Infrastructure-as-Code and Bicep templates.
- **Actions**:
  - Completed [MS Learn - Intro to IaC](https://learn.microsoft.com/en-us/training/modules/intro-to-infrastructure-as-code/).
  - Followed [MS Learn - Build Your First Bicep Template](https://learn.microsoft.com/en-us/training/modules/build-first-bicep-template/).
- **Outcome**: Gained skills to automate Azure resource provisioning with Bicep.


### Step 2: Build the Container Image
- **Objective**: Containerize the Flask CRUD app.
- **Actions**:
  - Cloned [example-flask-crud](https://github.com/gurkanakdeniz/example-flask-crud).
  - Built the image locally:
    cd C:\Users\...\...\CloudManagement\example-flask-crud
    added a dockerfile:
    ``` Dockerfile
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
    ```
    docker build -t mycrudapp:latest .

- **Outcome**: Created mycrudapp:latest, ready for ACR.

### Step 3: Create Azure Container Registry (ACR)
- **Objective**: Set up ACR to store the container image.
 - **Actions**:
   -   Created acr.bicep:
     ``` bicep
    param location string = 'westeurope'
    param acrName string = 'rjacr2025' // U eigen naam
    
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
   -   Deployed ACR:
   -   az deployment group create --resource-group rj-rg --template-file acr.bicep


### Step 4: Pushing docker image to (ACR)
- **Objective**: pushing the created docker image to your ACR
 - **Actions**:
   - cd C:\Users\...\...\CloudManagement\example-flask-crud
   - az login
   - docker login acrusername.azurecr.io --username acrusername –password acrpassword
   - docker tag mycrudapp:latest acrusername.azurecr.io/mycrudapp:latest
   - check with docker images if your tag has been made
   - docker push acrusername.azurecr.io/mycrudapp:latest
   - if it fails try logging out of docker and logging back in


### Step 5: Deploy to Azure Container Instance (ACI) & implement best practises
- **Objective**: pushing the created docker image to your ACR and implementing best practises
 - **Actions**:
   - created aci.bicep file:
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

// Log Analytics Workspace voor Azure Monitor
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'rjlogs'
  location: location
  properties: {
    sku: { name: 'PerGB2018' } // Goedkope optie
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
      type: 'Public' // Public IP for direct access
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

// Set the target resource group
targetScope = 'resourceGroup'

// Outputs
output containerGroupName string = containerGroup.name
output resourceGroupName string = resourceGroup().name
output resourceId string = containerGroup.id
output publicIpAddress string = containerGroup.properties.ipAddress.ip
output location string = location
```

   - Used minimal resources (1 CPU, 2 GB memory) to save credits.
   - Added Azure Monitor logging via rjlogs.
   - Configured public IP and port 80 for accessibility.
   - Limitation: Couldn’t use VNet/NSG with public IP due to ACI constraints; prioritized accessibility and logging.
 - **Outcome**: Balanced best practices with assignment requirements.


### EXTRA: Custom Domain with DuckDNS
- **Objective**: Add a custom domain to the public ip of the ACI
 - **Actions**:
   - Registered khaibcrud.duckdns.org at duckdns.org.
   - Updated DNS with ACI’s public IP from deployment output.
   - Tested accessibility without modifying the image.
- **Why I did it**: Provides a user-friendly URL instead of raw IP address
- **Outcome**: http://khaibcrud.duckdns.org
- ![image](https://github.com/user-attachments/assets/62c41922-bfc0-4d90-ad05-68149fcb1174)


