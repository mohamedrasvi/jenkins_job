
Here’s a step-by-step code-based guide for setting up Jenkins on GKE, creating a Terraform module to deploy a static website to GCS, configuring HTTPS load balancing, and integrating GitHub Actions with Jenkins.

Prerequisites
Google Cloud SDK: Ensure that the Google Cloud SDK is installed and authenticated to your GCP project.
Terraform: Install Terraform.
Kubectl: Install kubectl and authenticate with your GKE cluster.
Helm: Install Helm for deploying Jenkins.
GitHub Repository: A GitHub repository for storing code and CI/CD integration.
Step 1: Set Up Jenkins on Google Kubernetes Engine (GKE)
1.1 Create a GKE Cluster with Terraform
hcl
```
# main.tf
provider "google" {
  project = "<your-gcp-project-id>"
  region  = "us-central1"
}

resource "google_container_cluster" "jenkins_cluster" {
  name               = "jenkins-cluster"
  location           = "us-central1"
  initial_node_count = 3

  node_config {
    machine_type = "e2-medium"
  }
}
```
Run the following commands to deploy the cluster:

bash
```
terraform init
terraform apply
```
1.2 Deploy Jenkins on GKE using Helm
Connect to your GKE cluster:

bash
```
gcloud container clusters get-credentials jenkins-cluster --region us-central1
```
# Install Jenkins on the GKE cluster:

```
helm repo add jenkins https://charts.jenkins.io
helm repo update
helm install jenkins jenkins/jenkins
Retrieve the Jenkins admin password:

```

bash
```
kubectl get secret --namespace default jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
```
Access Jenkins at the external IP of the Jenkins service, then configure authentication in Jenkins.

Step 2: Create a Terraform Module to Deploy a Static Website on GCS
Module Folder Structure:

css
Copy code
terraform/
└── gcs-website/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf

Set Up GitHub Actions to Trigger Jenkins Builds
Create GitHub Action Workflow
Add a GitHub Actions workflow file in your repository under .github/workflows/jenkins-trigger.yml:




To enable Jenkins to apply Terraform resources automatically, we'll set up a Jenkins pipeline that triggers on GitHub pushes. This pipeline will use Terraform to deploy the infrastructure defined in your configuration.

Here's the step-by-step setup:

Step 1: Install Terraform on Jenkins
Add Terraform to Jenkins: You need to make sure Terraform is installed on the Jenkins server.

If you’re using a Docker-based Jenkins instance, add Terraform to your Jenkins Docker image.
If running on GKE, create a custom Jenkins Docker image with Terraform.
Example Dockerfile for Jenkins with Terraform:

Dockerfile
```
FROM jenkins/jenkins:lts
USER root

# Install Terraform
RUN apt-get update && \
    apt-get install -y wget unzip && \
    wget https://releases.hashicorp.com/terraform/1.0.11/terraform_1.0.11_linux_amd64.zip && \
    unzip terraform_1.0.11_linux_amd64.zip -d /usr/local/bin && \
    rm terraform_1.0.11_linux_amd64.zip

USER jenkins
```
Build and Push Image:

```
docker build -t my-jenkins-with-terraform .
docker tag my-jenkins-with-terraform gcr.io/<your-gcp-project-id>/my-jenkins-with-terraform
docker push gcr.io/<your-gcp-project-id>/my-jenkins-with-terraform
```
Update Jenkins Deployment on GKE to Use This Image: Modify the Jenkins Deployment in GKE to use the custom image you created.

SConfigure Service Account and Permissions
Create a Service Account for Jenkins to interact with GCP resources.

bash
```
gcloud iam service-accounts create jenkins-sa --display-name "Jenkins Service Account"
Grant Permissions: Assign necessary roles to the service account, such as roles/compute.admin, roles/storage.admin, and roles/viewer.
```
bash
```
gcloud projects add-iam-policy-binding <your-gcp-project-id> \
  --member "serviceAccount:jenkins-sa@<your-gcp-project-id>.iam.gserviceaccount.com" \
  --role "roles/compute.admin"

gcloud projects add-iam-policy-binding <your-gcp-project-id> \
  --member "serviceAccount:jenkins-sa@<your-gcp-project-id>.iam.gserviceaccount.com" \
  --role "roles/storage.admin"

```
Create and Download a JSON Key for the Service Account:

bash
```
gcloud iam service-accounts keys create jenkins-sa-key.json \
  --iam-account=jenkins-sa@<your-gcp-project-id>.iam.gserviceaccount.com

```
Add JSON Key to Jenkins:

Go to Jenkins > Manage Jenkins > Manage Credentials.
Add a new Secret file with the key file jenkins-sa-key.json, naming it gcp-credentials.
Step 3: Configure Jenkins Pipeline to Apply Terraform
Create a New Pipeline Job in Jenkins:

Go to Jenkins > New Item > Pipeline and name it Terraform-Apply.
Set Up Pipeline Script: In the pipeline script, set up steps to initialize, plan, and apply Terraform configurations.

groovy
```
pipeline {
    agent any

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-credentials')
        GCP_PROJECT_ID = '<your-gcp-project-id>'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh '''
                export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS
                terraform init
                '''
            }
        }

        stage('Terraform Plan') {
            steps {
                sh '''
                export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS
                terraform plan -out=tfplan
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                export GOOGLE_APPLICATION_CREDENTIALS=$GOOGLE_APPLICATION_CREDENTIALS
                terraform apply -auto-approve tfplan
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '**/*.tfplan', allowEmptyArchive: true
        }
        failure {
            mail to: '<your-email@example.com>', subject: "Terraform Apply Failed", body: "Check Jenkins logs for details."
        }
    }
}
```
Explanation of the Pipeline:

Environment Variables: We set the GOOGLE_APPLICATION_CREDENTIALS and project ID.
Stages:
Checkout: Checks out the GitHub repository.
Terraform Init: Initializes Terraform.
Terraform Plan: Generates a Terraform execution plan.
Terraform Apply: Applies the plan with -auto-approve.
Post Actions:
Archives the Terraform plan file for future reference.
Sends an email on failure (if email notifications are configured in Jenkins).
Configure GitHub Webhook: In your GitHub repository settings, add a webhook pointing to your Jenkins URL with /github-webhook/.

Trigger Jenkins Pipeline from GitHub Actions (Optional): If you want to use GitHub Actions to trigger this Jenkins job, use the GitHub Actions configuration below:

yaml
```
name: Trigger Jenkins Job

on:
  push:
    branches:
      - main

jobs:
  trigger-jenkins:
    runs-on: ubuntu-latest

    steps:
      - name: Trigger Jenkins
        uses: appleboy/jenkins-action@master
        with:
          jenkins_url: "http://<jenkins-url>/job/Terraform-Apply/build"
          username: ${{ secrets.JENKINS_USER }}
          password: ${{ secrets.JENKINS_API_TOKEN }}

```
Summary
Terraform on Jenkins: We configured Jenkins with Terraform, service account credentials, and access to GCP resources.
Pipeline for Terraform: Jenkins runs Terraform commands (init, plan, and apply) to provision resources.
Integration with GitHub: GitHub Webhooks or GitHub Actions can trigger the Jenkins job for automatic deployments.
With these configurations, Jenkins will handle the Terraform deployment whenever triggered by GitHub pushes, fully automating your infrastructure deployment pipeline.






