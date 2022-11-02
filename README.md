# Message Distribution

With this repository I want to evaluate and performance test various asynchronous message distribution options with **Azure** resources and hosting platforms.

## TL;DR conclusion

Running the same payload profile through Azure Functions and ASP.NET Core with Dapr (both C#) ...

_as of 2022-11-02_

... shows that :

- processing time E2E : Dapr only needs 80% of time Functions need
- total runtime durations aggregated : Dapr only needs 10% of Functions request processing time (duration of request within Dapr sidecar was not measured, but would not have a significant increase)

## Approach

- a Function App generates a test data payload (e.g. with 10'000 orders) and puts those in a blob storage
- this Function App is then be triggered to schedule all orders at one time on an ingress Service Bus queue - either for Functions or for Dapr
- 

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
```

## run test

```
./generate-test-data.sh
```


then either push test data into the Dapr or Functions application scenario:

```shell
push-ingress.sh dapr
```

or

```shell
push-ingress.sh func
```

---

## Observations

These queries - especially the 2nd one - where used to measure end-to-end throughput (from time of first message activated to time last message processed):

### Dapr batching

Dapr input binding and pub/sub Service Bus components need to be set to values much higher than [the defaults](https://docs.dapr.io/reference/components-reference/supported-bindings/servicebusqueues/) to get a processing time better than Functions - keeping defaults shows Dapr E2E processing time almost factor 2 compared to Functions.

```
        {
          name: 'maxActiveMessages'
          value: '1000'
        }
        {
          name: 'maxConcurrentHandlers'
          value: '8'
        }
```

### Functions batching

Changing from single message dispatching to batched message dispatching and thus using batching `"MaxMessageBatchSize": 1000` did not have a positive effect - on the contrary: processing time was 10-20% longer.

_single message dispatching_

```csharp
        [FunctionName("Dispatch")]
        public void Run(
            [ServiceBusTrigger("order-ingress-func", Connection = "SERVICEBUS_CONNECTION")] string ingressMessage,
            [ServiceBus("order-express-func", Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputExpressMessages,
            [ServiceBus("order-standard-func", Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputStandardMessages,
            ILogger log)
        {
            ArgumentNullException.ThrowIfNull(ingressMessage,nameof(ingressMessage));

            var order = JsonSerializer.Deserialize<Order>(ingressMessage);

            ArgumentNullException.ThrowIfNull(order,nameof(ingressMessage));
```

_batched_

```csharp
        [FunctionName("Dispatch")]
        public void Run(
            [ServiceBusTrigger("order-ingress-func", Connection = "SERVICEBUS_CONNECTION")] ServiceBusReceivedMessage[] ingressMessages,
            [ServiceBus("order-express-func", Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputExpressMessages,
            [ServiceBus("order-standard-func", Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputStandardMessages,
            ILogger log)
        {
            foreach (var ingressMessage in ingressMessages)
            {
                var order = JsonSerializer.Deserialize<Order>(Encoding.UTF8.GetString(ingressMessage.Body));
                ArgumentNullException.ThrowIfNull(order, nameof(ingressMessage));
```

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

---

### errors with Azure Developer CLI

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

## unsorted

### enhance telemetry in Dapr (no cloud_RoleInstance populated over OpenTelemetry -> Application Insights)

- [mapping OpenTelemetry attribute to Application Insights attribute](https://github.com/frigus02/opentelemetry-application-insights/blob/2e5eda625779e7c04ab22126b628639d1873e656/src/lib.rs#L157)

### fine tuning Azure Service bus configuration

compare <https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus?tabs=in-process%2Cextensionv5%2Cextensionv3&pivots=programming-language-csharp> vs <https://docs.dapr.io/reference/components-reference/supported-bindings/servicebusqueues/>

---

## to dos

- [ ] [deploy AKS alternative](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-bicep?tabs=azure-cli%2CCLI#review-the-bicep-file)
- [ ] evaluate Dapr / WasmEdge - <https://youtu.be/uGo_1KY-QSM> <https://github.com/second-state/dapr-sdk-wasi> <https://github.com/second-state/dapr-wasm>
