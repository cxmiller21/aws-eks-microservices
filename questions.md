# General Project Questions I Ran Into

## Helm

- How to modify pod values from a helm chart?
  - Ex. Set deployment.x.pod.env.ENV_VAR_NAME to a value
    - Do I need to pull helm chart, manually modify it, and then deploy with that? Assuming there's no `extraEnvVars` option in the helm chart values.yaml
- How to modify grafana config.ini file while using helm?
  - Store config.ini file in a configmap and mount it to the grafana pod?
