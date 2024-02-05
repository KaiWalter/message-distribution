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
using Azure.Storage.Blobs;
using System.Threading.Tasks;
using Azure.Storage.Blobs.Models;
using System.Threading;

namespace testdata
{
    public static class PushIngress
    {
        private const int SCHEDULE_PER_MINUTE = 4000;

        [FunctionName(nameof(ClearTargets))]
        public async static Task<IActionResult> ClearTargets(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("express-outbox/*", FileAccess.ReadWrite, Connection = "STORAGE_CONNECTION")] BlobContainerClient expressContainer,
            [Blob("standard-outbox/*", FileAccess.ReadWrite, Connection = "STORAGE_CONNECTION")] BlobContainerClient standardContainer
            )
        {
            var responses = new
            {
                deletions = new List<Azure.Response<bool>>(),
                creations = new List<Azure.Response<BlobContainerInfo>>(),
            }; ;

            responses.deletions.Add(await expressContainer.DeleteIfExistsAsync());
            responses.deletions.Add(await standardContainer.DeleteIfExistsAsync());
            Thread.Sleep(5000);
            responses.creations.Add(await expressContainer.CreateIfNotExistsAsync(PublicAccessType.None));
            responses.creations.Add(await standardContainer.CreateIfNotExistsAsync(PublicAccessType.None));

            return new OkObjectResult(responses);
        }

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
