# Message Distribution

With this repository I want to evaluate and performance test various asynchronous message distribution options with **Azure** resources and hosting platforms.

## create environment

**Azure Dev CLI** is used to create the environment:

- initialize - select region and subscription
- pull `azd` values into environment variables
- deploy environment

```shell
azd init
source <(azd env get-values | sed 's/AZURE_/export AZURE_/g')
azd up
```
