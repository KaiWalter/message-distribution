using Azure.Messaging.ServiceBus;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Models;
using System;
using System.Text;
using System.Text.Json;

namespace funcdistributor
{
    public class Dispatch
    {
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

            var outputMessage = new ServiceBusMessage(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(order)))
            {
                ContentType = "application/json",
                MessageId = order.OrderId.ToString(),
            };

            switch (order.Delivery)
            {
                case Delivery.Express:
                    outputExpressMessages.Add(outputMessage);
                    break;
                case Delivery.Standard:
                    outputStandardMessages.Add(outputMessage);
                    break;
                default:
                    log.LogError($"invalid Delivery type: {order.Delivery}");
                    break;
            }
        }
    }
}
