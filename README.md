
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
Run the following commands to deploy the cluster:

bash
terraform init
terraform apply

1.2 Deploy Jenkins on GKE using Helm
Connect to your GKE cluster:

bash
gcloud container clusters get-credentials jenkins-cluster --region us-central1
Install Jenkins on the GKE cluster:

bash
helm repo add jenkins https://charts.jenkins.io
helm repo update
helm install jenkins jenkins/jenkins
Retrieve the Jenkins admin password:

bash
kubectl get secret --namespace default jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
Access Jenkins at the external IP of the Jenkins service, then configure authentication in Jenkins.


terraform/
└── gcs-website/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf


Set Jenkins Credentials in GitHub Secrets
Go to your GitHub repository settings.
Add JENKINS_USER and JENKINS_API_TOKEN under "Secrets and variables" > "Actions."