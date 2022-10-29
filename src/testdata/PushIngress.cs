using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.ServiceBus;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Models;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace testdata
{
    public static class PushIngress
    {
        private const int SCHEDULE_PER_MINUTE = 4000;

        [FunctionName(nameof(PushIngressFunc))]
        public static IActionResult PushIngressFunc(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.Read, Connection = "STORAGE_CONNECTION")] string ordersTestData,
            [ServiceBus("order-ingress-func", Connection = "SERVICEBUS_CONNECTION")] ICollector<Message> outputMessages)
            => SplitAndScheduleOrders(nameof(PushIngressFunc),ordersTestData, outputMessages);

        [FunctionName(nameof(PushIngressDapr))]
        public static IActionResult PushIngressDapr(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.Read, Connection = "STORAGE_CONNECTION")] string ordersTestData,
            [ServiceBus("order-ingress-dapr", Connection = "SERVICEBUS_CONNECTION")] ICollector<Message> outputMessages)
            => SplitAndScheduleOrders(nameof(PushIngressDapr),ordersTestData, outputMessages);

        private static IActionResult SplitAndScheduleOrders(string source, string ordersTestData, ICollector<Message> outputMessages)
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
                new {Count = orderList.Count.ToString(), StartTimestamp=startTimeStamp}
            );
        }

        private static Message CreateOrderMessage(DateTime scheduleTime, Order order)
        {
            return new Message
            {
                ContentType = "application/json",
                Body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(order)),
                MessageId = order.OrderGuid.ToString(),
                CorrelationId = order.OrderGuid.ToString(),
                ScheduledEnqueueTimeUtc = scheduleTime,
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
