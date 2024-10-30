# Digital.ai Release Runner Helm Chart
## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+

## Installing the Chart

To install the chart with the release name `one-runner`:

```console
helm repo add bitnami-repo https://charts.bitnami.com/bitnami
helm dependency update .
helm install one-runner .  -n runner --values values-custom-example.yaml
```

### Minimal configuration for the AWS cluster

Create values file with correct release configuration:
- update the `release.url`
- update the `release.registrationToken`
- update the global storage class with the correct AWS EFS based storage class

```shell
cat <<EOF > ./values-custom-aws.yaml
release:
  url: "http://dai-xlr.ns1.svc.cluster.local"
  registrationToken: rpa_...

replicaCount: 2
EOF
```

Run helm release `one-runner` installation with creation of the namespace:
```shell
helm repo add bitnami-repo https://charts.bitnami.com/bitnami
helm dependency update .
helm install one-runner . -n runner --create-namespace --values ./values-custom-aws.yaml
```

On finish of the last command you will see information about helm release.

### Minimal configuration for the k3d cluster

Follow k3d installation instructions on release-runner wiki.\
Be sure to create cluster using following command (replace the path to local directory):
```
k3d cluster create xlrcluster --registry-create xlr-registry:5050
```
Publish your artefacts to local registry if you are using it for images.

Create values file with correct release configuration:
- update the `release.url`
- update the `release.registrationToken`
- update the `image.registry`
- update the `image.name`
- update the `image.tag`

```shell
cat <<EOF > ./values-custom-local.yaml
release:
  url: "http://host.k3d.internal:5516"
  registrationToken: rpa_64698aea344382bc954cea9158292a7a21c1f427

replicaCount: 2

resources:
  limits:
    cpu: 3

image:
  pullPolicy: Always
  registry: xlr-registry:5050
  repository: digitalai
  name: release-runner
  tag: 0.2.0
EOF
```

Run helm release `one-runner` installation with creation of the namespace:
```shell
helm repo add bitnami-repo https://charts.bitnami.com/bitnami
helm dependency update .
helm install one-runner . -n runner --create-namespace --values ./values-custom-local.yaml
```

On finish of the last command you will see information about helm release.

### Cloud connector template generation

```shell
helm repo add bitnami-repo https://charts.bitnami.com/bitnami
helm dependency update .
helm template my-release . -n runner --values ./values-cloud-connector.yaml > runner.yaml
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```shell
helm uninstall my-release -n runner
```
The command removes all the Kubernetes components associated with the chart and deletes the release.
Uninstalling the chart will not remove the PVCs, you need to delete them manually.

To delete all resources with one command (if in the namespace is only runner installed) you can delete namespace with:
```shell
kubectl delete namespace runner
```

## Parameters

### Digital.ai Release Runner parameters

| Name                        | Description                                                                        | Value                                                                                                     |
|-----------------------------|------------------------------------------------------------------------------------| --------------------------------------------------------------------------------------------------------- |
| `runner.activeProfiles`     | is used to change the active spring profile.                                       | `k8s`                                                                                                     |
| `runner.capabilities`       | comma separated list of capabilities for the Digital.ai Release Runner             | `remote,container,k8s`                                                                                    |
| `runner.truststore`         | the truststore base64 encoded value                                                | `nil`                                                                                                     |
| `runner.truststorePassword` | the truststore password                                                            | `nil`                                                                                                     |
| `runner.restClientCa`       | the certificates base64 encoded value                                         | `nil`                                                                                                     |
| `runner.config`             | Map configuration variables that are set in the config map and used as environment | `{}`                                                                                                      |

### Digital.ai Release parameters

| Name                        | Description                                                                     | Value |
| --------------------------- | ------------------------------------------------------------------------------- | ----- |
| `release.registrationToken` | is the token you create in Release that the runner will use to register itself. | `nil` |
| `release.url`               | is the url of your release instance.                                            | `nil` |

### Image parameters

| Name                | Description                                                                                         | Value                   |
| ------------------- | --------------------------------------------------------------------------------------------------- |-------------------------|
| `image.pullPolicy`  | Specify a imagePullPolicy                                                                           | `IfNotPresent`          |
| `image.registry`    | Digital.ai Release Runner image registry                                                                        | `docker.io`             |
| `image.repository`  | runner image repository                                                                             | `xebialabs`             |
| `image.name`        | Digital.ai Release Runner image name                                                                            | `release-runner` |
| `image.tag`         | Digital.ai Release Runner image tag                                                                             | `0.1.33`                |
| `image.pullSecrets` | Optionally specify an array of imagePullSecrets (secrets must be manually created in the namespace) | `[]`                    |

### Common parameters

| Name                     | Description                                                                             | Value          |
| ------------------------ | --------------------------------------------------------------------------------------- | -------------- |
| `nameOverride`           | String to partially override release.fullname template (will maintain the release name) | `""`           |
| `fullnameOverride`       | String to fully override release.fullname template                                      | `""`           |
| `commonAnnotations`      | Annotations to add to all deployed objects                                              | `{}`           |
| `commonLabels`           | Labels to add to all deployed objects                                                   | `{}`           |
| `namespaceOverride`      | String to fully override namespace                                                      | `nil`          |
| `namespace.create`       | enable creation in the custom namespace                                                 | `false`        |
| `namespace.annotations`  | Annotations to add to all namespace resource                                            | `{}`           |
| `diagnosticMode.enabled` | Enable diagnostic mode (all probes will be disabled and the command will be overridden) | `false`        |
| `diagnosticMode.command` | Command to override all containers in the deployment                                    | `["sleep"]`    |
| `diagnosticMode.args`    | Args to override all containers in the deployment                                       | `["infinity"]` |

### Statefulset parameters

| Name                                    | Description                                                                                                                              | Value           |
| --------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `schedulerName`                         | Use an alternate scheduler, e.g. "stork".                                                                                                | `""`            |
| `podManagementPolicy`                   | Pod management policy                                                                                                                    | `Parallel`      |
| `podLabels`                             | Digital.ai Release Runner Pod labels. Evaluated as a template                                                                                        | `{}`            |
| `podAnnotations`                        | Digital.ai Release Runner Pod annotations. Evaluated as a template                                                                                   | `{}`            |
| `replicaCount`                          | Number of Digital.ai Release Runner replicas to deploy                                                                                               | `1`             |
| `updateStrategy.type`                   | Update strategy type for Digital.ai Release Runner statefulset                                                                                       | `RollingUpdate` |
| `statefulsetLabels`                     | Digital.ai Release Runner statefulset labels. Evaluated as a template                                                                                | `{}`            |
| `priorityClassName`                     | Name of the priority class to be used by Digital.ai Release Runner pods, priority class needs to be created beforehand                               | `""`            |
| `podAffinityPreset`                     | Pod affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                      | `""`            |
| `podAntiAffinityPreset`                 | Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                 | `soft`          |
| `nodeAffinityPreset.type`               | Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                | `""`            |
| `nodeAffinityPreset.key`                | Node label key to match Ignored if `affinity` is set.                                                                                    | `""`            |
| `nodeAffinityPreset.values`             | Node label values to match. Ignored if `affinity` is set.                                                                                | `[]`            |
| `affinity`                              | Affinity for pod assignment. Evaluated as a template                                                                                     | `{}`            |
| `nodeSelector`                          | Node labels for pod assignment. Evaluated as a template                                                                                  | `{}`            |
| `tolerations`                           | Tolerations for pod assignment. Evaluated as a template                                                                                  | `[]`            |
| `topologySpreadConstraints`             | Topology Spread Constraints for pod assignment spread across your cluster among failure-domains. Evaluated as a template                 | `[]`            |
| `podSecurityContext.enabled`            | Enable Digital.ai Release Runner pods' Security Context                                                                                              | `false`         |
| `podSecurityContext.runAsUser`          | Set Digital.ai Release Runner pod's Security Context runAsUser                                                                                       | `1001`          |
| `podSecurityContext.runAsGroup`         | Set Digital.ai Release Runner pod's Security Context runAsGroup                                                                                      | `1001`          |
| `podSecurityContext.fsGroup`            | Set Digital.ai Release Runner pod's Security Context fsGroup                                                                                         | `1001`          |
| `containerSecurityContext.enabled`      | Enabled Digital.ai Release Runner containers' Security Context                                                                                       | `false`         |
| `containerSecurityContext.runAsUser`    | Set Digital.ai Release Runner containers' Security Context runAsUser                                                                                 | `1001`          |
| `containerSecurityContext.runAsNonRoot` | Set Digital.ai Release Runner container's Security Context runAsNonRoot                                                                              | `true`          |
| `extraVolumeMounts`                     | Optionally specify extra list of additional volumeMounts                                                                                 | `[]`            |
| `extraVolumes`                          | Optionally specify extra list of additional volumes .                                                                                    | `[]`            |
| `hostAliases`                           | Deployment pod host aliases                                                                                                              | `[]`            |
| `dnsPolicy`                             | DNS Policy for pod                                                                                                                       | `ClusterFirst`  |
| `hostNetwork`                           | allows a pod to use the node network namespace. If enabled health monitoring will be disabled because of port conflict on the same node. | `false`         |
| `dnsConfig`                             | DNS Configuration pod                                                                                                                    | `{}`            |
| `command`                               | Override default container command (useful when using custom images)                                                                     | `nil`           |
| `args`                                  | Override default container args (useful when using custom images)                                                                        | `nil`           |
| `lifecycleHooks`                        | Overwrite livecycle for the Digital.ai Release Runner container(s) to automate configuration before or after startup                                 | `{}`            |
| `terminationGracePeriodSeconds`         | Default duration in seconds k8s waits for container to exit before sending kill signal.                                                  | `200`           |
| `extraEnvVars`                          | Extra environment variables to add to Digital.ai Release Runner pods                                                                                 | `[]`            |
| `extraEnvVarsCM`                        | Name of existing ConfigMap containing extra environment variables                                                                        | `""`            |
| `extraEnvVarsSecret`                    | Name of existing Secret containing extra environment variables (in case of sensitive data)                                               | `""`            |
| `health.enabled`                        | Enable health monitoring with readiness and liveness probes based on the Digital.ai Release Runner actuator management endpoints                     | `true`          |
| `health.periodScans`                    | Defines how frequently the probe will be executed after the initial delay.                                                               | `5`             |
| `health.probeFailureThreshold`          | Instructs Kubernetes to retry the probe this many times after a failure is first recorded.                                               | `12`            |
| `health.probesLivenessTimeout`          | Set a delay between the time the container starts and the first time the probe is executed.                                              | `10`            |
| `health.probesReadinessTimeout`         | Set a delay between the time the container starts and the first time the probe is executed.                                              | `10`            |
| `resources.limits`                      | The resources limits for Digital.ai Release Runner containers                                                                                        | `{}`            |
| `resources.requests`                    | The requested resources for Digital.ai Release Runner containers                                                                                     | `{}`            |

### RBAC parameters

| Name                         | Description                                                                                                                             | Value  |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| `serviceAccount.create`      | Enable creation of ServiceAccount for Digital.ai Release Runner pods                                                                                | `true` |
| `serviceAccount.name`        | Name of the created serviceAccount                                                                                                      | `""`   |
| `serviceAccount.annotations` | Annotations for service account. Evaluated as a template. Only used if `create` is `true`.                                              | `{}`   |
| `rbac.create`                | Whether RBAC rules should be created binding Digital.ai Release Runner ServiceAccount to a role that allows Digital.ai Release Runner pods querying the K8s API | `true` |

