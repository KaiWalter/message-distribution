using Azure.Storage.Blobs;
using Bogus;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.ServiceBus.Management;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;
using Microsoft.Azure.ServiceBus;

namespace test_data
{
    public static class PushIngress
    {
        [FunctionName("PushIngress")]
        public static IActionResult Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.Read, Connection = "STORAGE_CONNECTION")] string ordersTestData,
            [ServiceBus("order-ingress", Connection = "SERVICEBUS_CONNECTION")] ICollector<Message> outputMessages,
            ILogger log)
        {
            JsonSerializerOptions options = new JsonSerializerOptions
            {
                Converters = {
                    new JsonStringEnumConverter()
                }
            };
            var orderList = JsonSerializer.Deserialize<List<Order>>(ordersTestData, options);

            foreach (var order in orderList)
            {
                log.LogInformation($"pushing order {order.OrderId} into ingress");

                outputMessages.Add(new Message
                {
                    ContentType = "application/json",
                    Body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(order)),
                    MessageId = order.OrderId.ToString(),
                });
            }

            return new CreatedResult(string.Empty, string.Empty);
        }
    }
}
