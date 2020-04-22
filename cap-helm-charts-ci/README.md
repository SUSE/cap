# cap-helm-charts-ci

## Description

This pipeline is responsible for opening a PR against SUSE helm charts repo for the latest CAP release containing [kubecf](https://github.com/cloudfoundry-incubator/kubecf) and [cf-operator](https://github.com/cloudfoundry-incubator/cf-operator) helm chart releases. The pipeline instance is deployed on SUSE concourse.

## Steps to deploy/modify pipeline

1. Use the sample `vars.yaml.template` to create a file named `vars.yaml` and replace all required values.

2. Define `${CONCOURSE_SECRETS_FILE}` with path to your `concourse-secrets.yml.gpg` in blackbox.

3. Make sure the concourse target is set and you are logged in.

4. Deploy or update the pipeline using the following command:

```
./deploy-pipeline <concourse-target> <pipeline-name>
```

**Note:** Make sure that you update the CI URI and branch appropriately before deploying.
