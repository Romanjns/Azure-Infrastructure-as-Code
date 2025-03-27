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
    
    docker build -t mycrudapp:latest .

- **Outcome**: Created mycrudapp:latest, ready for ACR.

### Step 3: Create Azure Container Registry (ACR)
- **Objective**: Set up ACR to store the container image.
 - **Actions**:
   -   Created acr.bicep:
   -   file
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
   - file
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

