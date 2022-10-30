using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Models;
using System;
using System.Text.Json;

namespace funcrecvstd
{
    public class Receiver
    {
        [FunctionName("Receiver")]
        public void Run(
            [ServiceBusTrigger("order-standard-func", Connection = "SERVICEBUS_CONNECTION")] string ingressMessage,
            ILogger log
            )
        {
            ArgumentNullException.ThrowIfNull(ingressMessage, nameof(ingressMessage));

            var order = JsonSerializer.Deserialize<Order>(ingressMessage);

            ArgumentNullException.ThrowIfNull(order, nameof(order));

            log.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);
        }
    }
}
