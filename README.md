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

### fine tuning

compare <https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus?tabs=in-process%2Cextensionv5%2Cextensionv3&pivots=programming-language-csharp> vs <https://docs.dapr.io/reference/components-reference/supported-bindings/servicebusqueues/>

### check telemetry

```
requests
| where cloud_RoleInstance startswith "kw-pubsubdapr"
| where name startswith "POST /order"
| where timestamp > todatetime('2022-10-27T13:03:00.00Z')
| summarize count() by cloud_RoleInstance, bin(timestamp, 15s)
| render columnchart

requests
| where cloud_RoleInstance startswith "kw-pubsubdapr"
| where name startswith "POST /order"
| where timestamp > todatetime('2022-10-27T13:03:00.00Z')
| summarize count(),min(timestamp),max(timestamp)
| extend datetime_diff('millisecond', max_timestamp, min_timestamp)

requests
| where cloud_RoleName startswith "func"
| where name != "Health"
| where timestamp > todatetime('2022-10-27T13:19:00.00Z')
| summarize count() by cloud_RoleInstance, bin(timestamp, 15s)
| render columnchart

requests
| where cloud_RoleName startswith "func"
| where name != "Health"
| where timestamp > todatetime('2022-10-27T13:19:00.00Z')
| summarize count(),min(timestamp),max(timestamp)
| extend datetime_diff('millisecond', max_timestamp, min_timestamp)
```

### errors

```
{
  "error": {
    "code": "InvalidTemplateDeployment",
    "message": "The template deployment 'kw-pubsub-dapr-distributor' is not valid according to the validation procedure. The tracking id is 'daac92e9-7dfe-404d-86f0-214b711aac5d'. See inner errors for details.",
    "details": [
      {
        "code": "ValidationForResourceFailed",
        "message": "Validation failed for a resource. Check 'Error.Details[0]' for more information.",
        "details": [
          {
            "code": "ContainerAppImageRequired",
            "message": "Container with name 'dapr-distributor' must have an 'Image' property specified."
          }
        ]
      }
    ]
  }
}

{
  "status": "Failed",
  "error": {
    "code": "DeploymentFailed",
    "message": "At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.",
    "details": [
      {
        "code": "Conflict",
        "message": "{\r\n  \"status\": \"Failed\",\r\n  \"error\": {\r\n    \"code\": \"ResourceDeploymentFailure\",\r\n    \"message\": \"The resource operation completed with terminal provisioning state 'Failed'.\",\r\n    \"details\": [\r\n      {\r\n        \"code\": \"DeploymentFailed\",\r\n        \"message\": \"At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.\",\r\n        \"details\": [\r\n          {\r\n            \"code\": \"Conflict\",\r\n            \"message\": \"{\\r\\n  \\\"status\\\": \\\"Failed\\\",\\r\\n  \\\"error\\\": {\\r\\n    \\\"code\\\": \\\"ResourceDeploymentFailure\\\",\\r\\n    \\\"message\\\": \\\"The resource operation completed with terminal provisioning state 'Failed'.\\\",\\r\\n    \\\"details\\\": [\\r\\n      {\\r\\n        \\\"code\\\": \\\"DeploymentFailed\\\",\\r\\n        \\\"message\\\": \\\"At least one resource deployment operation failed. Please list deployment operations for details. Please see https://aka.ms/DeployOperations for usage details.\\\",\\r\\n        \\\"details\\\": [\\r\\n          {\\r\\n            \\\"code\\\": \\\"BadRequest\\\",\\r\\n            \\\"message\\\": \\\"{\\\\r\\\\n  \\\\\\\"error\\\\\\\": {\\\\r\\\\n    \\\\\\\"target\\\\\\\": \\\\\\\"scopes\\\\\\\"\\\\r\\\\n  },\\\\r\\\\n  \\\\\\\"code\\\\\\\": \\\\\\\"DaprComponentInvalidProperty\\\\\\\",\\\\r\\\\n  \\\\\\\"message\\\\\\\": \\\\\\\"Dapr component property 'scopes' with value 'dapr_distributor' is invalid, it must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character.\\\\\\\",\\\\r\\\\n  \\\\\\\"target\\\\\\\": \\\\\\\"scopes\\\\\\\"\\\\r\\\\n}\\\"\\r\\n          },\\r\\n          {\\r\\n            \\\"code\\\": \\\"BadRequest\\\",\\r\\n            \\\"message\\\": \\\"{\\\\r\\\\n  \\\\\\\"error\\\\\\\": {\\\\r\\\\n    \\\\\\\"target\\\\\\\": \\\\\\\"scopes\\\\\\\"\\\\r\\\\n  },\\\\r\\\\n  \\\\\\\"code\\\\\\\": \\\\\\\"DaprComponentInvalidProperty\\\\\\\",\\\\r\\\\n  \\\\\\\"message\\\\\\\": \\\\\\\"Dapr component property 'scopes' with value 'dapr_distributor' is invalid, it must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character.\\\\\\\",\\\\r\\\\n  \\\\\\\"target\\\\\\\": \\\\\\\"scopes\\\\\\\"\\\\r\\\\n}\\\"\\r\\n          },\\r\\n          {\\r\\n            \\\"code\\\": \\\"BadRequest\\\",\\r\\n            \\\"message\\\": \\\"{\\\\r\\\\n  \\\\\\\"error\\\\\\\": {\\\\r\\\\n    \\\\\\\"target\\\\\\\": \\\\\\\"scopes\\\\\\\"\\\\r\\\\n  },\\\\r\\\\n  \\\\\\\"code\\\\\\\": \\\\\\\"DaprComponentInvalidProperty\\\\\\\",\\\\r\\\\n  \\\\\\\"message\\\\\\\": \\\\\\\"Dapr component property 'scopes' with value 'dapr_distributor' is invalid, it must consist of lower case alphanumeric characters, '-' or '.', and must start and end with an alphanumeric character.\\\\\\\",\\\\r\\\\n  \\\\\\\"target\\\\\\\": \\\\\\\"scopes\\\\\\\"\\\\r\\\\n}\\\"\\r\\n          }\\r\\n        ]\\r\\n      }\\r\\n    ]\\r\\n  }\\r\\n}\"\r\n          }\r\n        ]\r\n      }\r\n    ]\r\n  }\r\n}"
      }
    ]
  }
}
```