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

#### Dapr


```
requests
| where name startswith "pubsub/order" or name startswith "bindings/order"
| where timestamp > todatetime('2022-10-29T10:31:11.0515593Z')
| summarize count() by cloud_RoleName, bin(timestamp, 15s)
| render columnchart

requests
| where name startswith "pubsub/order" or name startswith "bindings/order"
| where timestamp > todatetime('2022-10-29T10:31:11.0515593Z')
| summarize count(),sum(duration),min(timestamp),max(timestamp)
| extend datetime_diff('millisecond', max_timestamp, min_timestamp)
```

```
"count_","sum_duration","min_timestamp [UTC]","max_timestamp [UTC]",Column1
20000,"211611.27200000006","10/29/2022, 10:33:42.183 AM","10/29/2022, 10:35:59.885 AM",137702

# 4/400  | where timestamp between( todatetime('2022-10-29T17:35:10.0176800Z') .. todatetime('2022-10-29T17:40:10.0176800Z') )
# 8/800  | where timestamp between( todatetime('2022-10-29T11:25:17.0033012Z') .. todatetime('2022-10-29T11:29:48.0033012Z') )
#16/1600 | where timestamp between( todatetime('2022-10-29T11:06:11.7950005Z') .. todatetime('2022-10-29T11:16:11.7950005Z') )
#16/1000 | where timestamp between( todatetime('2022-10-29T10:31:11.0515593Z') .. todatetime('2022-10-29T10:36:11.0515593Z') )


```

#### Functions


```
requests
| where cloud_RoleName startswith "func"
| where name != "Health"
| where timestamp > todatetime('2022-10-29T10:43:09.5562353Z')
| summarize count() by cloud_RoleInstance, bin(timestamp, 15s)
| render columnchart

requests
| where cloud_RoleName startswith "func"
| where name != "Health"
| where timestamp > todatetime('2022-10-29T10:43:09.5562353Z')
| summarize count(),sum(duration),min(timestamp),max(timestamp)
| extend datetime_diff('millisecond', max_timestamp, min_timestamp)
```

```
"count_","sum_duration","min_timestamp [UTC]","max_timestamp [UTC]",Column1
20000,"3689825.1065000026","10/29/2022, 10:45:41.187 AM","10/29/2022, 10:46:44.034 AM",62847
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