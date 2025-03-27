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
