# CAP release pipeline

[This pipeline](https://concourse.suse.dev/teams/main/pipelines/product-release)
tests KubeCF on Kubernetes distributions CaaSP4, GKE, EKS, AKS:
* Eirini or Diego enabled.
* Instance groups as single availability or high availability.
* Autoscaler enabled and disabled,
* Runs Smokes, CATS, Brain and SITS.
* Upgrades KubeCF deployment.
* Installs Stratos and metrics.

# Deploying the pipeline

    $ ./create_pipeline.sh <concourse-target> <pipeline-name>

Configure all the required options in a `<pipeline-name>.yaml`.
The new `<pipeline-name>` pipeline will make use of kuceconfigs uploaded to a Concourse pool resource in github.com/SUSE/cf-ci-pools, or create them on its own.

E.g: to deploy the `cap-pre-release` pipeline:

    $ ./create_pipeline.sh <concourse-target> cap-pre-release

E.g: to deploy the `cap-release` pipeline:

    $ ./create_pipeline.sh <concourse-target> cap-release

Note: If you wish to deploy a custom pipeline, copy and modify either `cap-pre-release.yaml` or `cap-release.yaml`. The name of your config file will be used as the `<pipeline-name>`.

# Implementation

The pipeline strives to have the minimum concourse yaml to do the job, and put
the logic somewhere so one can run and iterate on the pipeline locally.
It's still in flux.

# K8s cluster management

The pipeline consumes clusters by putting a lock on unclaimed kubeconfigs from git@github.com:SUSE/cf-ci-pools.git

Add your kubeconfigs to cf-ci-pools.git in ${Backend}-kube-hosts branch in the unclaimed folder for CI to pick it up.
