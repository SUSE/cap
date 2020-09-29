# Cloud Application Platform release pipelines

The pipelines in this sub-directory test KubeCF on CaaSP4, GKE, EKS, AKS. The
main focus are:

* Deploy KubeCF with:
    * Eirini or Diego enabled.
    * Autoscaler enabled and disabled.
    * Single-availability (SA) or high-availability (HA).
* Run tests:
    * CF Smoke Tests - usually references as only smoke.
    * CF Acceptance Tests (CATS).
    * Brain.
    * Minibroker Integration Tests (MITS).
    * Sync Integration Tests (SITS).
* Upgrade KubeCF deployment.
* Install Stratos and its metrics.

# Deploying the pipeline

    $ ./create_pipeline.sh <concourse-target> <pipeline-name>

Configure all the required options in a `<pipeline-name>.yaml`.
The new `<pipeline-name>` pipeline will make use of kuceconfigs uploaded to a
Concourse pool resource in github.com/SUSE/cf-ci-pools, or create them on its
own.

E.g: to deploy the `cap-pre-release` pipeline:

    $ ./create_pipeline.sh <concourse-target> cap-pre-release

E.g: to deploy the `cap-release` pipeline:

    $ ./create_pipeline.sh <concourse-target> cap-release

Note: If you wish to deploy a custom pipeline, copy and modify either
`cap-pre-release.yaml` or `cap-release.yaml`. The name of your config file will
be used as the `<pipeline-name>`.

# Implementation

The pipeline strives to have the minimum concourse YAML to do the job, and put
the logic somewhere so one can run and iterate on the pipeline locally.

# Kubernetes cluster management

The pipeline consumes clusters by putting a lock on unclaimed kubeconfigs from
git@github.com:SUSE/cf-ci-pools.git.

Add your kubeconfigs to cf-ci-pools.git in the `${Backend}-kube-hosts` branch
under the `unclaimed` folder so CI can pick them up.
