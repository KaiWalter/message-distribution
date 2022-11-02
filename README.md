# Message Distribution

With this repository I want to evaluate and performance test various asynchronous message distribution options with **Azure** resources and hosting platforms.

## create environment

**Azure Dev CLI** is used to create the environment:

- initialize - select region and subscription
- deploy environment
- create local (and application) settings files for local debugging
- create local secrets files
- generate a test data set to be used for performance tests into Azure Storage

```shell
azd new
azd up
./create-local-settings.sh
./create-secrets.sh
./generate-test-data.sh
```

## test environment

then either push test data into the Dapr or Functions application scenario:

```shell
push-ingress.sh dapr
```

or

```shell
push-ingress.sh func
```

---

## unsorted

### fine tuning Azure Service bus configuration

compare <https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus?tabs=in-process%2Cextensionv5%2Cextensionv3&pivots=programming-language-csharp> vs <https://docs.dapr.io/reference/components-reference/supported-bindings/servicebusqueues/>

### get telemetry results

#### Dapr with App Insights

```
requests
| where timestamp >= todatetime('2022-11-02T06:45:45.8897869Z')
| where name startswith "POST" and cloud_RoleName matches regex "^[\\d\\w]+dapr"
| summarize count() by cloud_RoleInstance, bin(timestamp, 15s)
| render columnchart

requests
| where timestamp >= todatetime('2022-11-02T06:45:45.8897869Z')
| where name startswith "POST" and cloud_RoleName matches regex "^[\\d\\w]+dapr"
| summarize count(),sum(duration),min(timestamp),max(timestamp)
| extend datetime_diff('millisecond', max_timestamp, min_timestamp)
```

```
count_,"sum_duration","min_timestamp [UTC]","max_timestamp [UTC]",Column1
20000,"427845.1506999994","11/2/2022, 6:48:16.600 AM","11/2/2022, 6:49:11.000 AM",54400
# 8 / 1000 | where timestamp >= todatetime('2022-11-02T06:45:45.8897869Z')
```

#### Functions

```
requests
| where cloud_RoleName startswith "func"
| where name != "Health"
| where timestamp > todatetime('2022-11-02T06:55:55.0296786Z')
| summarize count() by cloud_RoleInstance, bin(timestamp, 15s)
| render columnchart

requests
| where cloud_RoleName startswith "func"
| where name != "Health"
| where timestamp > todatetime('2022-11-02T06:55:55.0296786Z')
| summarize count(),sum(duration),min(timestamp),max(timestamp)
| extend datetime_diff('millisecond', max_timestamp, min_timestamp)
```

```
count_,"sum_duration","min_timestamp [UTC]","max_timestamp [UTC]",Column1
20000,"4636740.856899991","11/2/2022, 6:58:26.504 AM","11/2/2022, 6:59:34.671 AM",68167
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


### sample order

```
{
    "OrderId": 1009041,
    "Description": "ote16qzk4a7s8zcs708b6nmaokc8vijlduue2fde",
    "FirstName": "Newton",
    "LastName": "Treutel",
    "Delivery": 0,
    "Items": [
        {
            "OrderItemId": 1,
            "SKU": "5480-9625-7727",
            "Quantity": 10
        }
    ]
}
```

---

## enhance telemetry

- [mapping OpenTelemetry attribute to Application Insights attribute](https://github.com/frigus02/opentelemetry-application-insights/blob/2e5eda625779e7c04ab22126b628639d1873e656/src/lib.rs#L157)

## to dos

- [ ] [deploy AKS alternative](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-bicep?tabs=azure-cli%2CCLI#review-the-bicep-file)