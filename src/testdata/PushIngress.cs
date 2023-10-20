using Azure.Messaging.ServiceBus;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Models;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;

namespace testdata
{
    public static class PushIngress
    {
        private const int SCHEDULE_PER_MINUTE = 4000;

        [FunctionName(nameof(PushIngressACAFQ))]
        public static IActionResult PushIngressACAFQ(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.Read, Connection = "STORAGE_CONNECTION")] string ordersTestData,
            [ServiceBus("q-order-ingress-acaf", Microsoft.Azure.WebJobs.ServiceBus.ServiceBusEntityType.Queue, Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputMessages)
            => SplitAndScheduleOrders(nameof(PushIngressACAFQ), ordersTestData, outputMessages);

        [FunctionName(nameof(PushIngressFuncQ))]
        public static IActionResult PushIngressFuncQ(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.Read, Connection = "STORAGE_CONNECTION")] string ordersTestData,
            [ServiceBus("q-order-ingress-func", Microsoft.Azure.WebJobs.ServiceBus.ServiceBusEntityType.Queue, Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputMessages)
            => SplitAndScheduleOrders(nameof(PushIngressFuncQ), ordersTestData, outputMessages);

        [FunctionName(nameof(PushIngressDaprQ))]
        public static IActionResult PushIngressDaprQ(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.Read, Connection = "STORAGE_CONNECTION")] string ordersTestData,
            [ServiceBus("q-order-ingress-dapr", Microsoft.Azure.WebJobs.ServiceBus.ServiceBusEntityType.Queue, Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputMessages)
            => SplitAndScheduleOrders(nameof(PushIngressDaprQ), ordersTestData, outputMessages);

        [FunctionName(nameof(PushIngressDCRAQ))]
        public static IActionResult PushIngressDCRAQ(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.Read, Connection = "STORAGE_CONNECTION")] string ordersTestData,
            [ServiceBus("q-order-ingress-dcra", Microsoft.Azure.WebJobs.ServiceBus.ServiceBusEntityType.Queue, Connection = "SERVICEBUS_CONNECTION")] ICollector<ServiceBusMessage> outputMessages)
            => SplitAndScheduleOrders(nameof(PushIngressDCRAQ), ordersTestData, outputMessages);

        [FunctionName(nameof(PushIngressDCRAT))]
        public static async Task<IActionResult> PushIngressDCRAT(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.Read, Connection = "STORAGE_CONNECTION")] string ordersTestData,
            ILogger log)
            => await SplitAndPostOrders(nameof(PushIngressDCRAQ), ordersTestData, log);

        private static IActionResult SplitAndScheduleOrders(string source, string ordersTestData, ICollector<ServiceBusMessage> outputMessages)
        {
            var startTimeStamp = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture);

            JsonSerializerOptions options = new JsonSerializerOptions
            {
                Converters = {
                    new JsonStringEnumConverter()
                }
            };
            var orderList = JsonSerializer.Deserialize<List<Order>>(ordersTestData, options);

            ArgumentNullException.ThrowIfNull(orderList, nameof(ordersTestData));

            DateTime scheduleTime = DetermineScheduleTime(orderList.Count);

            foreach (var order in orderList)
            {
                outputMessages.Add(CreateOrderMessage(scheduleTime, order));
            }

            return new CreatedResult(
                source.ToLowerInvariant(),
                new
                {
                    Count = orderList.Count.ToString(),
                    StartTimestamp = startTimeStamp,
                    ScheduledTimestamp = scheduleTime.ToString("o", CultureInfo.InvariantCulture),
                }
            );
        }

        private static async Task<IActionResult> SplitAndPostOrders(string source, string ordersTestData, ILogger log)
        {
            var startTimeStamp = DateTime.UtcNow.ToString("o", CultureInfo.InvariantCulture);

            JsonSerializerOptions options = new JsonSerializerOptions
            {
                Converters = {
                    new JsonStringEnumConverter()
                }
            };
            var orderList = JsonSerializer.Deserialize<List<Order>>(ordersTestData, options);

            ArgumentNullException.ThrowIfNull(orderList, nameof(ordersTestData));

            var url = System.Environment.GetEnvironmentVariable("DAPR_HTTP_ENDPOINT") ?? string.Empty;
            var apiToken = System.Environment.GetEnvironmentVariable("DAPR_API_TOKEN") ?? string.Empty;

            var httpClient = new HttpClient();
            httpClient.DefaultRequestHeaders.Add("dapr-api-token", apiToken);
            httpClient.BaseAddress = new Uri(url);

            foreach (var order in orderList)
            {
                var request = new HttpRequestMessage(HttpMethod.Post, "v1.0/publish/order-pubsub/t-order-ingress-dcra");
                request.Content = new StringContent(
                  JsonSerializer.Serialize(order),
                  Encoding.UTF8,
                  "application/json");

                var response = await httpClient.SendAsync(request);
            }

            return new CreatedResult(
                source.ToLowerInvariant(),
                new
                {
                    Count = orderList.Count.ToString(),
                    StartTimestamp = startTimeStamp,
                    ScheduledTimestamp = startTimeStamp,
                }
            );
        }

        private static ServiceBusMessage CreateOrderMessage(DateTime scheduleTime, Order order)
        {
            return new ServiceBusMessage(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(order)))
            {
                ContentType = "application/json",
                MessageId = order.OrderGuid.ToString(),
                CorrelationId = order.OrderGuid.ToString(),
                ScheduledEnqueueTime = scheduleTime,
            };
        }

        private static DateTime DetermineScheduleTime(int orderListCount)
        {
            int scheduleDuration = 60;
            if (orderListCount >= SCHEDULE_PER_MINUTE)
            {
                scheduleDuration = orderListCount * 60 / SCHEDULE_PER_MINUTE;
            }

            var scheduleTime = DateTime.UtcNow.AddSeconds(scheduleDuration);
            return scheduleTime;
        }
    }
}
