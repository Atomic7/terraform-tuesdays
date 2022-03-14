# Azure DevOps

This is the beginning of a multi-part series looking into deploying Terraform using Azure DevOps. There are several goals I want to accomplish in this project.

1. Create a pipeline in Azure DevOps using YAML
1. Validate the Terraform code as part of the pipeline (validate and format)
1. Move credentials and sensitive data into Azure Key Vault
1. Use Azure Storage for remote backend with credentials in Key Vault
1. Generate a plan for the Terraform code
1. Stash the plan in an Azure Storage account
1. Validate the plan with a manual step
1. Deploy the code once the manual step is approved
1. Separate the pipeline into two pipelines, one for PR and one for merge
1. Add code scanning to the process using Checkov
1. Add testing to the process using terratest or Module Testing

Admittedly, that's a lot of stuff for a pipeline, but we don't have to do everything all at once. In the first phase, I simply want to get a basic pipeline working and creating an Azure Vnet. This will require remote state for consistency, so that should be there from the get-go. I also would really like to use Azure Key Vault for credential storage.

## Setup

Before I set up the pipeline, I'm going to need an Azure Storage Account and Azure Key Vault. I'm also going to need to configure the pipeline with access to the Key Vault. Not sure if I can do that through Terraform or if I'll need to do it after the fact. Within ADO, I'm going to need a project for the pipeline to live in, and that project will need to be wired to a GitHub repo where my code is stored. Not sure if I can do any of that with Terraform, but I'll check it out. The results will be in the setup folder in this directory.

    az storage account keys list -g azurek8stest -n terraformstatestoacc
        {
            "creationTime": "2022-03-14T11:38:09.134827+00:00",
            "keyName": "key1",
            "permissions": "FULL",
            "value": "vNAlH3kV6xp62aPz4vdPuD1Ba3LV30+F5nOIcx0ipBZCb32m59QWLUmEbSly4FwS/L8NJFfJmPZBXetwlSkNjA=="
        },
        blob sas token: 
            sp=r&st=2022-03-14T15:57:15Z&se=2022-03-14T23:57:15Z&spr=https&sv=2020-08-04&sr=c&sig=abqTr%2FzAHrQFn06MzICcZ4bB3pgFtc%2FLK41Ogtlyvmo%3D
        sas sas url:
            https://terraformstatestoacc.blob.core.windows.net/terraform-state?sp=r&st=2022-03-14T15:57:15Z&se=2022-03-14T23:57:15Z&spr=https&sv=2020-08-04&sr=c&sig=abqTr%2FzAHrQFn06MzICcZ4bB3pgFtc%2FLK41Ogtlyvmo%3D


    az ad sp create-for-rbac --name tftuesdays --role contributor --scopes /subscriptions/df762d06-9685-438e-aed0-d55b807198a7
        {
        "appId": "fe40b964-81a6-42f6-8f0e-e205c8c9a4b9",
        "displayName": "tftuesdays",
        "password": "cZFkJ83-hOsPGWLxlTLTELG37U2hhKvc-H",
        "tenant": "b7540979-5063-4ba1-a9a0-49b436141ffb"
        }
    GIThub
        Personal Access Token:
        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
    
    azure DevOps
        organization: ned-in-the-cloud
        access token name: terraform-cli-2
            secret: t46atx3mm3u25kzxm26cbrajv5p2pv3qcxfxfzk4hfnmuliu2g4q

    azure DevOps 

*An indeterminate amount of time later*

Okay, it looks like I can create a project, GitHub service connection, and pipeline all through Terraform. Excellent! If you're following along, you'll notice I'm using the Terraform Cloud backend. You're going to need to set some variables and environment variables for your workspace to make it all hum. I'll list those out below.

### Terraform Cloud Variables

Here is a list of variables and values you'll need to specify for the config to work:

**Terraform Variables**

* `ado_org_service_url` - Org service url for Azure DevOps
* `ado_github_repo` - Name of the repository in the format `<GitHub Org>/<RepoName>`. You'll need to fork my repo and use your own.
* `ado_github_pat` (**sensitive**) - Personal authentication token for GitHub repo.


**Environment Variables**

* `AZDO_PERSONAL_ACCESS_TOKEN` (**sensitive**) - Personal authentication token for Azure DevOps. 
* `ARM_SUBSCRIPTION_ID` - Subscription ID where you will create the Azure Storage Account.
* `ARM_CLIENT_ID` (**sensitive**) - Client ID of service principal with the necessary rights in the referenced subscription.
* `ARM_CLIENT_SECRET` (**sensitive**) - Secret associated with the Client ID.
* `ARM_TENANT_ID` - Azure AD tenant where the Client ID is located.
* `TF_VAR_az_client_id` (**sensitive**) - Client ID of service principal that will be used in the Azure DevOps pipeline.
* `TF_VAR_az_client_secret` (**sensitive**) - Client secret of service principal that will be used in the Azure DevOps pipeline.
* `TF_VAR_az_subscription` - Subscription ID where resources will be created by the ADO pipeline.
* `TF_VAR_az_tenant` - Tenant ID for the `az_client_id` value.

You can decide if you want to mark anything else as **sensitive**. The client id might not really need to be sensitive, but that's what I decided to do. I went with environment variables for a bunch of these, but the long term plan is to dynamically create the necessary service principals and store the information in Key Vault.

## Phase One

The whole purpose behind phase one is to get the basic framework in place for an Azure DevOps pipeline. You might look at this setup and think that it is too simple or is missing out on using a bunch of features. You're right! It is intentionally simple for phase one, and I plan to add complexity as we go. Right now the set up script is creating the following:

* Azure storage account for remote state
* SAS token for storage account access
* Azure DevOps project
* Service endpoint to GitHub repo for ADO
* Variable group for pipeline to use
* Build pipeline

The pipeline itself is deploying a simple Azure virtual network with two subnets. Nothing fancy. The stages validate the Terraform code, run a plan, wait for approval, and run an apply. That's it. The trigger is a commit to the 2021-05-11-ADO/vnet directory. That will change eventually.