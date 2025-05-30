# Honeycomb Refinery Cluster

This repository demonstrates best practices for using Helm to deploy Refinery, and Terraform to manage Honeycomb objects.

1. Configure a Refinery cluster
1. Install the Refinery 
1. Install opentelemetry collectors into the cluster to observe health and performance
1. Use terraform to configure triggers in Honeycomb
1. The GitHub actions to handle deployment and reconfiguration

For more information about Refinery, please check out the docs on the Honeycomb website:
[Honeycomb Refinery Docs](https://docs.honeycomb.io/manage-data-volume/refinery/)

## Functions of this Repository

The main repository files are listed below, each guiding its own function of Refinery deployment and monitoring

- `refinery-values.yaml` - Used to deploy Refinery to an AWS EKS clsuter. There are specific Annotations on the Ingress sections of the values which trigger the [AWS Load Balancer Controller](https://github.com/kubernetes-sigs/aws-load-balancer-controller) and the [External DNS Controllers](https://github.com/kubernetes-sigs/external-dns) on an EKS cluster to enable the creation of an ALB with a reachable URL from the Internet.  Using a different Kubernetes provider will likely require different annotations in the Ingress sections.
- `k8sevents-values.yaml` - Deploys an opentelemetry collector pod that monitors Kuberenetes Events API for events happening in the namespace that the refinery cluster is deployed to.  It does not have OTLP inputs or use any receivers other than the k8sobject receiver.  It has transform processors for these logs to be most useful in Honeycomb.
- `kubeletstats-values.yaml` - Another deployment of the opentelemetry collector with most receivers removed exept for the kubeletstats receiver used to get metrics about pods, containers, and nodes from each node in the nodegroup specified by the `nodeSelector` option in the values file.
- `terraform/**.tf files` -  These terraform files can be used to setup some basic triggers on the Refinery metrics to assure that data is going through Refinery, and that stress relief isn't being activated for extended periods of time.

There are also github actions workflow files used to deploy these helm chart values and terraform plans to test environments that the field engineering teams maintain

- `refinery-deploy.yaml && eu1-deploy.yaml` - These use the `refinery-values.yaml` file to deploy test refinery clusters to EKS in our US1 region as well as our EU1 region.  The EU1 workflow adds a config option that tells Refinery to send data to the EU honeycomb instace, rather than the default US one.
- `k8s-monitoring-deploy.yaml && eu1-k8s-monitoring-deploy.yaml` - deploys the two collector helm values files to the US and EU clusters where Refinery was deployed.
- `terraform-hny-triggers.yaml` - pushes the terraform apply command against the terraform files which build triggers for alerting based on refinery metrics.

## Installing Refinery (and monitoring) With Helm

To use these helm charts in your own Kubernetes cluster, you'll need to update some portion of the values files, or deploy through GitHub Actions the way that we are, using [Actions secrets in Github](/settings/secrets/actions) to allow us to reference sensitive information.

## Creating K8s Secrets Used By Helm Charts

If you're deploying manually, you can create a kubernetes manifest to deploy the secrets manually:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <SECRET_NAME>
stringData:
  refinery-metrics-api-key: <YOUR_HONEYCOMB_API_KEY>
  refinery-query-auth-token: <KEY_YOU_WANT_FOR_YOUR_REFINERY_ENDPOINT>
```

Then by running the following command, apply those secrets to your Kubenetes cluster:

```shell
kubectl apply -f refinery-secrets.yaml
```

These secrets are then used in the values files in blocks of code like this (for Refinery):

```yaml
environment:
  - name: REFINERY_HONEYCOMB_API_KEY
    valueFrom:
      secretKeyRef:
        key: refinery-metrics-api-key
        name: raas-secrets
  - name: REFINERY_QUERY_AUTH_TOKEN
    valueFrom:
      secretKeyRef:
        key: refinery-query-auth-token
        name: raas-secrets
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
```

and (for the collectors)

```yaml
extraEnvs:
  - name: HONEYCOMB_API_KEY
    valueFrom:
      secretKeyRef:
        key: refinery-metrics-api-key
        name: raas-secrets
```

Those environment variables are then used in the config for the helm charts like so:

```yaml
config:
  exporters:
    otlp/hnytest:
      endpoint: api.honeycomb.io:443
      headers:
        X-Honeycomb-Dataset: refinery-k8s-events
        X-Honeycomb-Team: ${env:HONEYCOMB_API_KEY}
```

### Deploying Refinery

**NOTE**: _Refinery does not require external Ingress. It is only necessary to have the `ingress` and `grpcIngress` sections of this values file if you need to send telemetry to Refinery from outside of your Kubernetes cluster.  And even if you are, you should work with your Kubernetes administrators on what values to use in these sections, as they will probably not be using the AWS Load Balancer Controller or External DNS Controller for managing ingresses the way we are with these files._

If you are going to use the values files as-is, and want the Load Balancer and Route53 entries to work properly, you'll need to find the sections of the ingress configs with the `_replaceme_` value and put in your own ACM Cert ARN and DNS Name. You can see how we've done that by looking at the GitHub Actions workflows for deploying Refinery, where we keep those values as Secrets and reference those secrets with the Helm commands.

Once you've sorted out your Ingress needs, you'll want to update your nodeselectors.  In our testing environment we create node labels on our EKS nodegroup, that we can then reference with the `nodeSelector` value to pin our Refinery pods to specific, dedicated Kubernetes nodes.  These values look like this:

```yaml
nodeSelector:
  customer: hnytest

redis:
  nodeSelector:
    customer: hnytest
```

We use the `customer` label name when creating our nodegroups so that we know what internal project the nodegroup belongs to. You probably have different labels in your environment, so you'll need to update the key as well as the value in these nodeSelector settings.  You could also just remove this section if you don't use dedicated nodes for your refinery instances.

After this, applying the helm chart values is pretty straightforward:

```shell
NAMESPACE='mynamespace'
helm repo add honeycomb https://honeycombio.github.io/helm-charts
helm repo update
helm upgrade -n ${NAMESPACE} --install refinery honeycomb/refinery -f refinery-values.yaml --wait
```

This will deploy Refinery to your Kubernetes cluster in the namespace specified, to the nodes you desire Refinery to run on.

### Deploying Kuberenetes Monitoring

**NOTE**: _These collectors are designed to work with dedicated nodegroups for Refinery. If you have other Kubernetes monitoring across your entire cluster, and you aren't limiting your Refinery pods to specific nodes, these will likely replicate metrics and events about a large portion of your kubernetes environment you're already monitoring, and create way more events being sent to Honeycomb than you probably want_

These files are more ready for use than even the Refinery values files.  They should be pretty straitforward to update.  We don't set up any ingress for these collectors, as they're not used by external services, and are only scraping our Kubernetes APIs for data.

You should update the `nodeSelector` settings to match what you've done for Refinery:

```yaml
nodeSelector:
  customer: hnytest
```

You should also update the `k8sevents-values.yaml` file so that it targets the appropriate `namespaces`:

```yaml
config:
  receivers:
    k8sobjects:
      objects:
        - name: events
          exclude_watch_type:
            - DELETED
          group: events.k8s.io
          mode: watch
          namespaces: [hnytest]
```

Once you've updated the values files accordingly, you can install them similarly to how we installed Refinery:

```shell
NAMESPACE='mynamespace'
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
helm upgrade -n ${NAMESPACE} --install otelcol-kubeletstats open-telemetry/opentelemetry-collector -f kubeletstats-values.yaml --wait
helm upgrade -n ${NAMESPACE} --install otelcol-k8sevents open-telemetry/opentelemetry-collector -f k8sevents-values.yaml --wait
```

This should get your kubernetes monitoring of your refinery cluster up and running

## Honeycomb Triggers via Terraform

This repository uses Terraform via the `honeycombio` provider to apply triggers to a given environment.
As an example only, it uses Github Actions with the [Terraform State Artifact](https://github.com/marketplace/actions/terraform-state-artifact) module to store TF state as an artifact in GHA.  It should be noted that artifacts expire after 90 days, so this is not recommended for production use cases.

Prequisites:

1. Create the following [Actions secrets in Github](/settings/secrets/actions)
  a. `HONEYCOMB_API_KEY` - should contain a configuration API key for the given environment
  b. `TF_STATE_PASSPHRASE` - should contain a randomly generated passphrase for encrypting TF state
2. Create the following [Actions environment variables in Github](/settings/variables/actions)
  a. `HONEYCOMB_API_ENDPOINT` - either `https://api.honeycomb.io` or `https://api.eu1.honeycomb.io`
