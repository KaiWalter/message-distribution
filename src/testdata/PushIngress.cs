using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.ServiceBus;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace testdata
{
    public static class PushIngress
    {
        [FunctionName(nameof(PushIngressFunc))]
        public static IActionResult PushIngressFunc(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.Read, Connection = "STORAGE_CONNECTION")] string ordersTestData,
            [ServiceBus("order-ingress-func", Connection = "SERVICEBUS_CONNECTION")] ICollector<Message> outputMessages,
            ILogger log)
        {
            JsonSerializerOptions options = new JsonSerializerOptions
            {
                Converters = {
                    new JsonStringEnumConverter()
                }
            };
            var orderList = JsonSerializer.Deserialize<List<Order>>(ordersTestData, options);

            DateTime scheduleTime = DetermineScheduleTime(orderList.Count);

            foreach (var order in orderList)
            {
                outputMessages.Add(new Message
                {
                    ContentType = "application/json",
                    Body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(order)),
                    MessageId = order.OrderId.ToString(),
                    ScheduledEnqueueTimeUtc = scheduleTime,
                });
            }

            return new CreatedResult("order-ingress-func", orderList.Count.ToString());
        }

        [FunctionName(nameof(PushIngressDapr))]
        public static IActionResult PushIngressDapr(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.Read, Connection = "STORAGE_CONNECTION")] string ordersTestData,
            [ServiceBus("order-ingress-dapr", Connection = "SERVICEBUS_CONNECTION")] ICollector<Message> outputMessages,
            ILogger log)
        {
            JsonSerializerOptions options = new JsonSerializerOptions
            {
                Converters = {
                    new JsonStringEnumConverter()
                }
            };
            var orderList = JsonSerializer.Deserialize<List<Order>>(ordersTestData, options);

            DateTime scheduleTime = DetermineScheduleTime(orderList.Count);

            foreach (var order in orderList)
            {
                outputMessages.Add(new Message
                {
                    ContentType = "application/json",
                    Body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(order)),
                    MessageId = order.OrderId.ToString(),
                    ScheduledEnqueueTimeUtc = scheduleTime,
                });
            }

            return new CreatedResult("order-ingress-dapr", orderList.Count.ToString());
        }

        private static DateTime DetermineScheduleTime(int orderListCount)
        {
            int scheduleDuration = 60;
            if (orderListCount >= 2000)
            {
                scheduleDuration += (orderListCount / 2000) * 60;
            }

            var scheduleTime = DateTime.UtcNow.AddSeconds(scheduleDuration);
            return scheduleTime;
        }
    }
}
