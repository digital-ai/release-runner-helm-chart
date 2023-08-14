# Release Remote Runner Helm Chart
## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- ReadWriteOnly volume for deployment

## Installing the Chart

To install the chart with the release name `one-remote-runner`:

```console
helm repo add bitnami-repo https://charts.bitnami.com/bitnami
helm dependency update .
helm install one-remote-runner .  -n remote-runner --values values-custom-example.yaml
```

### Minimal configuration for the AWS cluster

Create values file with correct release configuration:
- update the `release.url`
- update the `release.registrationToken`
- update the global storage class with the correct AWS EFS based storage class

```shell
cat <<EOF > ./values-custom-aws.yaml
global:
  persistence:
    storageClass: aws-efs

release:
  url: "http://dai-xlr.ns1.svc.cluster.local"
  registrationToken: rpa_...

replicaCount: 2
EOF
```

Run helm release `one-remote-runner` installation with creation of the namespace:
```shell
helm repo add bitnami-repo https://charts.bitnami.com/bitnami
helm dependency update .
helm install one-remote-runner . -n remote-runner --create-namespace --values ./values-custom-aws.yaml
```

On finish of the last command you will see information about helm release.

### Minimal configuration for the k3d cluster

Follow k3d installation instructions on release-remote-runner wiki.\
Be sure to create cluster using following command (replace the path to local directory):
```
k3d cluster create xlrcluster --volume /sandbox-dir/kube-cluster-pv:/workspace --registry-create xlr-registry:5050
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
global:
  persistence:
    createVolume: true
    baseHostPath: /workspace
    
release:
  url: "http://host.k3d.internal:5516"
  registrationToken: rpa_64698aea344382bc954cea9158292a7a21c1f427

persistence:
  work:
    accessModes:
      - ReadWriteOnce
    volume:
      create: true
      baseHostPath: /workspace
  db:
    volume:
      create: true

replicaCount: 2

resources:
  limits:
    cpu: 3

image:
  pullPolicy: Always
  registry: xlr-registry:5050
  repository: digitalai
  name: release-remote-runner
  tag: 0.2.0
EOF
```

Run helm release `one-remote-runner` installation with creation of the namespace:
```shell
helm repo add bitnami-repo https://charts.bitnami.com/bitnami
helm dependency update .
helm install one-remote-runner . -n remote-runner --create-namespace --values ./values-custom-local.yaml
```

On finish of the last command you will see information about helm release.

### Cloud connector template generation

```shell
helm repo add bitnami-repo https://charts.bitnami.com/bitnami
helm dependency update .
helm template my-release . -n remote-runner --values ./values-cloud-connector.yaml > remote-runner.yaml
helm template my-release . -n remote-runner --values ./values-cloud-connector.yaml --set persistence.work.volume.create=true > remote-runner.yaml
```

## Uninstalling the Chart

To uninstall/delete the `my-release` deployment:

```shell
helm uninstall my-release -n remote-runner
```
The command removes all the Kubernetes components associated with the chart and deletes the release.
Uninstalling the chart will not remove the PVCs, you need to delete them manually.

To delete all resources with one command (if in the namespace is only remote-runner installed) you can delete namespace with:
```shell
kubectl delete namespace remote-runner
```

## Parameters

### Global parameters

| Name                              | Description                                                        | Value   |
| --------------------------------- | ------------------------------------------------------------------ | ------- |
| `global.persistence.storageClass` | PVC Storage Class for Remote Runner data volume                    | `""`    |
| `global.persistence.createVolume` | Provide for created claims explicit volume creation withing chart. | `false` |
| `global.persistence.baseHostPath` | The host path for the k3d cluster.                                 | `nil`   |

### Digital.ai Remote Runner parameters

| Name                        | Description                                                                        | Value                                                                                                     |
| --------------------------- | ---------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `runner.activeProfiles`     | is used to change the active spring profile.                                       | `k8s`                                                                                                     |
| `runner.capabilities`       | comma separated list of capabilities for the remote runner                         | `remote,container,k8s`                                                                                    |
| `runner.truststore`         | the truststore base64 encoded value                                                | `nil`                                                                                                     |
| `runner.truststorePassword` | the truststore password                                                            | `nil`                                                                                                     |
| `runner.config`             | Map configuration variables that are set in the config map and used as environment | `{}`                                                                                                      |

### Digital.ai Release parameters

| Name                        | Description                                                                     | Value |
| --------------------------- | ------------------------------------------------------------------------------- | ----- |
| `release.registrationToken` | is the token you create in Release that the runner will use to register itself. | `nil` |
| `release.url`               | is the url of your release instance.                                            | `nil` |

### Persistence parameters

| Name                                   | Description                                                        | Value               |
| -------------------------------------- | ------------------------------------------------------------------ | ------------------- |
| `persistence.enabled`                  | Enable Remote Runner data persistence using PVC                    | `true`              |
| `persistence.db.storageClass`          | PVC Storage Class for Remote Runner data volume                    | `""`                |
| `persistence.db.selector`              | Selector to match an existing Persistent Volume                    | `{}`                |
| `persistence.db.accessModes`           | PVC Access Modes for Remote Runner data volume                     | `["ReadWriteOnce"]` |
| `persistence.db.existingClaim`         | Provide an existing PersistentVolumeClaims                         | `""`                |
| `persistence.db.size`                  | PVC Storage Request for DB storage                                 | `256Mi`             |
| `persistence.db.volume.create`         | Provide for created claims explicit volume creation withing chart. | `false`             |
| `persistence.db.volume.baseHostPath`   | The host path for the k3d cluster.                                 | `nil`               |
| `persistence.db.volume.size`           | PV Storage Capacity for DB storage                                 | `1Gi`               |
| `persistence.db.annotations`           | Persistence annotations. Evaluated as a template                   | `{}`                |

### Image parameters

| Name                | Description                                                                                         | Value               |
| ------------------- | --------------------------------------------------------------------------------------------------- | ------------------- |
| `image.pullPolicy`  | Specify a imagePullPolicy                                                                           | `IfNotPresent`      |
| `image.registry`    | Remote runner image registry                                                                        | `docker.io`         |
| `image.repository`  | runner image repository                                                                             | `xebialabs`         |
| `image.name`        | Remote runner image name                                                                            | `xlr-remote-runner` |
| `image.tag`         | Remote runner image tag                                                                             | `0.1.33`            |
| `image.pullSecrets` | Optionally specify an array of imagePullSecrets (secrets must be manually created in the namespace) | `[]`                |

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
| `podLabels`                             | Remote Runner Pod labels. Evaluated as a template                                                                                        | `{}`            |
| `podAnnotations`                        | Remote Runner Pod annotations. Evaluated as a template                                                                                   | `{}`            |
| `replicaCount`                          | Number of Remote Runner replicas to deploy                                                                                               | `1`             |
| `updateStrategy.type`                   | Update strategy type for Remote Runner statefulset                                                                                       | `RollingUpdate` |
| `statefulsetLabels`                     | Remote Runner statefulset labels. Evaluated as a template                                                                                | `{}`            |
| `priorityClassName`                     | Name of the priority class to be used by Remote Runner pods, priority class needs to be created beforehand                               | `""`            |
| `podAffinityPreset`                     | Pod affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                      | `""`            |
| `podAntiAffinityPreset`                 | Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                 | `soft`          |
| `nodeAffinityPreset.type`               | Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard`                                                | `""`            |
| `nodeAffinityPreset.key`                | Node label key to match Ignored if `affinity` is set.                                                                                    | `""`            |
| `nodeAffinityPreset.values`             | Node label values to match. Ignored if `affinity` is set.                                                                                | `[]`            |
| `affinity`                              | Affinity for pod assignment. Evaluated as a template                                                                                     | `{}`            |
| `nodeSelector`                          | Node labels for pod assignment. Evaluated as a template                                                                                  | `{}`            |
| `tolerations`                           | Tolerations for pod assignment. Evaluated as a template                                                                                  | `[]`            |
| `topologySpreadConstraints`             | Topology Spread Constraints for pod assignment spread across your cluster among failure-domains. Evaluated as a template                 | `[]`            |
| `podSecurityContext.enabled`            | Enable Remote Runner pods' Security Context                                                                                              | `false`         |
| `podSecurityContext.runAsUser`          | Set Remote Runner pod's Security Context runAsUser                                                                                       | `1001`          |
| `podSecurityContext.runAsGroup`         | Set Remote Runner pod's Security Context runAsGroup                                                                                      | `1001`          |
| `podSecurityContext.fsGroup`            | Set Remote Runner pod's Security Context fsGroup                                                                                         | `1001`          |
| `containerSecurityContext.enabled`      | Enabled Remote Runner containers' Security Context                                                                                       | `false`         |
| `containerSecurityContext.runAsUser`    | Set Remote Runner containers' Security Context runAsUser                                                                                 | `1001`          |
| `containerSecurityContext.runAsNonRoot` | Set Remote Runner container's Security Context runAsNonRoot                                                                              | `true`          |
| `extraVolumeMounts`                     | Optionally specify extra list of additional volumeMounts                                                                                 | `[]`            |
| `extraVolumes`                          | Optionally specify extra list of additional volumes .                                                                                    | `[]`            |
| `hostAliases`                           | Deployment pod host aliases                                                                                                              | `[]`            |
| `dnsPolicy`                             | DNS Policy for pod                                                                                                                       | `ClusterFirst`  |
| `hostNetwork`                           | allows a pod to use the node network namespace. If enabled health monitoring will be disabled because of port conflict on the same node. | `false`         |
| `dnsConfig`                             | DNS Configuration pod                                                                                                                    | `{}`            |
| `command`                               | Override default container command (useful when using custom images)                                                                     | `nil`           |
| `args`                                  | Override default container args (useful when using custom images)                                                                        | `nil`           |
| `lifecycleHooks`                        | Overwrite livecycle for the Remote Runner container(s) to automate configuration before or after startup                                 | `{}`            |
| `terminationGracePeriodSeconds`         | Default duration in seconds k8s waits for container to exit before sending kill signal.                                                  | `200`           |
| `extraEnvVars`                          | Extra environment variables to add to Remote Runner pods                                                                                 | `[]`            |
| `extraEnvVarsCM`                        | Name of existing ConfigMap containing extra environment variables                                                                        | `""`            |
| `extraEnvVarsSecret`                    | Name of existing Secret containing extra environment variables (in case of sensitive data)                                               | `""`            |
| `health.enabled`                        | Enable health monitoring with readiness and liveness probes based on the remote runner actuator management endpoints                     | `true`          |
| `health.periodScans`                    | Defines how frequently the probe will be executed after the initial delay.                                                               | `5`             |
| `health.probeFailureThreshold`          | Instructs Kubernetes to retry the probe this many times after a failure is first recorded.                                               | `12`            |
| `health.probesLivenessTimeout`          | Set a delay between the time the container starts and the first time the probe is executed.                                              | `10`            |
| `health.probesReadinessTimeout`         | Set a delay between the time the container starts and the first time the probe is executed.                                              | `10`            |
| `resources.limits`                      | The resources limits for Remote Runner containers                                                                                        | `{}`            |
| `resources.requests`                    | The requested resources for Remote Runner containers                                                                                     | `{}`            |

### RBAC parameters

| Name                         | Description                                                                                                                             | Value  |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| `serviceAccount.create`      | Enable creation of ServiceAccount for Remote Runner pods                                                                                | `true` |
| `serviceAccount.name`        | Name of the created serviceAccount                                                                                                      | `""`   |
| `serviceAccount.annotations` | Annotations for service account. Evaluated as a template. Only used if `create` is `true`.                                              | `{}`   |
| `rbac.create`                | Whether RBAC rules should be created binding Remote Runner ServiceAccount to a role that allows Remote Runner pods querying the K8s API | `true` |

