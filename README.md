# Message Distribution

With this repository I want to evaluate and performance test various asynchronous message distribution options with **Azure** resources and hosting platforms. Focus is on measuring the end-to-end **throughput** regardless whether or not certain platform constellations scale or not.

Currently hosted only Azure Container Apps (ACA) is implemented in this repo

| code used for solution elements | implementation and deployment approach                                                                                             |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **ACAF**                        | .NET [Azure Functions on ACA deployment](https://learn.microsoft.com/en-us/azure/azure-functions/functions-container-apps-hosting) |
| **DAPR**                        | ASP.NET with Dapr in a plain container on ACA                                                                                      |
| **FUNC**                        | .NET Azure Functions as plain container on ACA                                                                                     |

For pub/sub both variants - Azure Service Bus Queues and Topics are to be tested - designated by the suffix **Q** or **T**. Currently only the queues track is completely implemented and tested. Hence only tests with these codes can be started:

- **ACAFQ**
- **DAPRQ**
- **FUNCQ**

## Approach

- a Function App generates a test data payload (e.g. with 10k orders) and puts those in a blob storage
- this Function App is then be triggered to schedule all orders at one time on an ingress Service Bus queue - either for Functions or for Dapr
- at the end of message processing, the messages are put in a blob storage
- to measure throughput, time between original schedule and the time of the last blob written is observed

![setup of environment](./media/test-setup.png)

## TL;DR conclusion

To run a sequence of tests I used `scripts/cli/loop.sh` renders troughput results into this [log file](./LOG.md).

As of 2023-08-08 (and with only 10k orders, with no heavy logic) there is no significant

![comparing runtimes](./media/2023-08-08-results.png)

What is strange and can be observed consistantly is, that Functions in Containers scale as expected (up then down)

![scaling behavior Functions in Container](./media/2023-08-08-scaling-func.png)

and [Functions on ACA show this gap](https://github.com/Azure/azure-functions-on-container-apps/issues/33) in processing

![scaling behavior Functions on ACA](./media/2023-08-08-scaling-acaf.png)

It seems that the 2 receiver Functions pick up traffic from the queue with a delay - or are scaled up with a delay.

---

## environment creation

### with az/Azure CLI

> as of Aug'23 some of constellations of Functions on Azure Container Apps where not working, I created an alternate slate of **Azure CLI** based script to deploy the same set of **Bicep** templates, as used with **azd**

script path: `{repo-root}/scripts/cli/`

create an `.env` file in root of this repository to control environment name and location (subscription is determined by subscription set with **azd**):

```
AZURE_ENV_NAME="my-messdist"
AZURE_LOCATION="westus"
```

and then

```shell
az login --use-device-code
./scripts/cli/deploy-infra.sh
./scripts/cli/deploy-apps.sh build
```

### with azd/Azure Developer CLI

**Azure Developer CLI** is used to create the environment:

- install
- initialize - select region and subscription
- deploy environment
- create local (and application) settings files for local debugging
- create local secrets files
- generate a test data set to be used for performance tests into Azure Storage

script path: `{repo-root}/scripts/azd/`

```shell
azd login --use-device-code
az login --use-device-code
azd init
azd up
./scripts/azd/create-local-settings.sh
./scripts/azd/create-secrets.sh
```

## run test

> `{deployment}` refers to either `azd`=**azd** or `cli`=**az** deployment - see above

```shell
./scripts/{deployment}/generate-test-data.sh
```

then either push test data into the Dapr or Functions application scenario (in this sample the q=queue scenarios):

```shell
./scripts/{deployment}/push-ingress.sh daprq
```

or

```shell
./scripts/{deployment}/push-ingress.sh funcq
```

or

```shell
./scripts/{deployment}/push-ingress.sh acafq
```

> persisted [test results](./LOG.md)

---

## Observations

These queries - especially the 2nd one - where used to measure end-to-end throughput (from time of first message activated to time last message processed):

### get telemetry results

#### DAPR=Dapr

```
requests
| where timestamp > todatetime('2022-11-03T07:09:26.9394443Z')
| where name startswith "POST" and cloud_RoleName matches regex "^[\\d\\w\\-]+dapr"
| where success == true
| summarize count() by cloud_RoleInstance, bin(timestamp, 15s)
| render columnchart

requests
| where timestamp > todatetime('2022-11-03T07:09:26.9394443Z')
| where name startswith "POST" and cloud_RoleName matches regex "^[\\d\\w\\-]+dapr"
| where success == true
| summarize count(),sum(duration),min(timestamp),max(timestamp)
| extend runtimeMs=datetime_diff('millisecond', max_timestamp, min_timestamp)
```

```
"count_","sum_duration","min_timestamp [UTC]","max_timestamp [UTC]",runtimeMs
20000,"397686.0827000005","5/13/2023, 5:42:41.564 PM","5/13/2023, 5:43:10.280 PM",28716
```

#### FUNC=(plain) Functions containers on Container Apps

```
requests
| where cloud_RoleName startswith "func"
| where name != "Health"
| where timestamp > todatetime('2022-11-03T07:09:26.9394443Z')
| where success == true
| summarize count() by cloud_RoleInstance, bin(timestamp, 15s)
| render columnchart

requests
| where cloud_RoleName startswith "func"
| where name != "Health"
| where timestamp > todatetime('2022-11-03T07:09:26.9394443Z')
| where success == true
| summarize count(),sum(duration),min(timestamp),max(timestamp)
| extend runtimeMs=datetime_diff('millisecond', max_timestamp, min_timestamp)
```

```
"count_","sum_duration","min_timestamp [UTC]","max_timestamp [UTC]",runtimeMs
20000,"3599606.129400003","5/13/2023, 5:47:45.643 PM","5/13/2023, 5:49:07.432 PM",81789
```

#### ACAF=Functions on Container Apps

```
requests
| where cloud_RoleName matches regex "acaf"
| where name != "Health"
| where timestamp > todatetime('2023-08-06T13:18:27.0499471Z')
| where success == true
| summarize count() by cloud_RoleInstance, bin(timestamp, 15s)
| render columnchart

requests
| where cloud_RoleName matches regex "acaf"
| where name != "Health"
| where timestamp > todatetime('2023-08-06T13:18:27.0499471Z')
| where success == true
| summarize count(),sum(duration),min(timestamp),max(timestamp)
| extend runtimeMs=datetime_diff('millisecond', max_timestamp, min_timestamp)
```

```
"count_","sum_duration","min_timestamp [UTC]","max_timestamp [UTC]",runtimeMs
19860,"2314818.319500003","27.5.2023, 14:34:38.222","27.5.2023, 14:36:05.652",87430
```

> in that test run not all records processed are logged

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
            [ServiceBusTrigger("q-order-ingress-func", Connection = "SERVICEBUS_CONNECTION")] string ingressMessage,
            [ServiceBus("q-order-express  {
    name: 'WEBSITE_SITE_NAME'
    value: appName
  }
ollector<ServiceBusMessage> outputExpressMessages,
            [ServiceBus("q-order-standard-func", Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputStandardMessages,
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
            [ServiceBusTrigger("q-order-ingress-func", Connection = "SERVICEBUS_CONNECTION")] ServiceBusReceivedMessage[] ingressMessages,
            [ServiceBus("q-order-express-func", Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputExpressMessages,
            [ServiceBus("q-order-standard-func", Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputStandardMessages,
            ILogger log)-func", Connection = "SERVICEBUS_CONNECTION")] IC
        {
            foreach (var ingressMessage in ingressMessages)
            {
                var order = JsonSerializer.Deserialize<Order>(Encoding.UTF8.GetString(ingressMessage.Body));
                ArgumentNullException.ThrowIfNull(order, nameof(ingressMessage));
```

## Error Situtations

At a point I had a suspicous error which I could not make sense of:

```
ERROR: failed packaging service 'acafdistributor': failing invoking action 'package', tagging image: tagging image: exit code: 1, stdout: , stderr: Error parsing reference: "message-distribution/acafdistributor-:azd-deploy-1696684259" is not a valid repository/tag: invalid reference format
```

It turned out I accidentally removed `AZURE_ENV_NAME` from my environment configuration in `.azure/kw-messdist/.env`:

```
AZURE_ENV_NAME="kw-messdist"
AZURE_LOCATION="westeurope"
AZURE_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
```

---

# ERROR

time="2024-02-13T16:14:05.778260655Z" level=warning msg="Error renewing message locks for queue q-order-ingress-dapr (failed: 43/758): couldn't renew active message lock for message ff3d2095-effb-428e-87bf-e131c961ac4e: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 07a44f9a-bc9e-41f5-b9d5-c7892860f495: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message aaad8131-1cc6-4238-8b3f-2b520d8bfc5d: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 8899eaba-f10a-48c4-9152-91693f0933b6: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 2f9c1f2e-0d48-4d1a-af0a-65436a2a5835: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 7703bd5c-10e3-4419-88eb-f39bce7b7a39: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 1291db97-b3fc-40ba-ad95-f2f40e6c5970: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 6e5b816d-0778-44d6-ba7a-1965903501d5: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message c3337d54-ea6c-4bb4-b842-07c713d05296: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 85fb4ccf-14ee-4311-beaf-015b0de5607f: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 67ab0c60-cdc1-4914-a48d-bc70872880de: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 416b2070-c122-455e-accd-311a23a016b0: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message ac17f345-971b-416e-9131-a96098376ea5: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 12a8611b-4480-490c-9922-01ca876b6719: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 33a25577-6892-4f83-9c99-0c60fe7963ae: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 185ad0df-63f6-42cd-8187-9a3dbf6d79ba: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 04fe2b85-f75e-4836-a232-cb5a8282bf9d: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 17f1e057-a57b-451c-8156-29de17ee34ad: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 5d372f90-a503-4bed-8a4f-c60728f7d1b6: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message a885a9f8-d3ab-4ec3-8634-a15d3a806552: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 66f4c554-724b-48fe-a001-1d60d7421eed: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message ceb4d8be-7c70-4f91-b8d9-41fedec1c367: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 51428ea9-e1de-4e0a-8982-67646125ea7b: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 3a351de7-8bd5-4d32-aa84-9dd049dfdb21: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message dd82823a-ca2a-4abb-88e8-e053f7106c40: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 488e598e-1b98-46f0-b4d7-ad5cdba1b9bd: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message bb5bbd6d-1099-43f7-b956-bbbaa9ca45fe: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 64d3fcae-d0cd-4e42-b431-199b9c1586b1: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 529485fe-8b68-448c-874c-bdcb08d9633f: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 2a454ac9-736d-46da-8927-a9498fc345f2: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 22d8205c-825f-4a0e-828b-130ec7cdd76c: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 000f63d9-09bc-4b4f-8dee-8416f7030877: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message b5f9c6e2-f451-4c7d-83ef-56aa50f8634e: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message a2054241-a38d-46fe-abbc-ac3a573ee515: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 109119d2-a00c-4df2-9ffe-385c7386a7cf: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message e6810cef-dc16-47f9-bb4e-88f1709976c0: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 22917f08-e8ea-4328-8041-f5656798adbc: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 73cfc00a-fd02-4aa1-8b29-36edc5baa951: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 65e75ba2-d444-4927-aadb-b7a79949f949: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 3491a8a3-37d5-4e06-b314-b4f50a165199: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 8354b911-de0c-453d-8294-4bce7cd6d105: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message b390adf2-3b88-4323-9a2f-d42b1e30a366: lock has been lost (this often happens if the message has already been completed or abandoned); couldn't renew active message lock for message 0f2e21d5-5130-4ad9-b56c-ab97e760eebb: lock has been lost (this often happens if the message has already been completed or abandoned)" app_id=daprdistributor component="order-pubsub (pubsub.azure.servicebus.queues/v1)" instance=kw-m2daprdistributor--d16p3yq-689bfffd59-x7l4m scope=dapr.contrib type=log ver=1.11.6
