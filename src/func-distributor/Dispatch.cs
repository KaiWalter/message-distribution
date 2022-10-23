using System;
using System.Text;
using System.Text.Json;
using Microsoft.Azure.ServiceBus;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace func_distributor
{
    public class Dispatch
    {
        [FunctionName("Dispatch")]
        public void Run(
            [ServiceBusTrigger("order-ingress", Connection = "SERVICEBUS_CONNECTION")] string ingressMessage,
            [ServiceBus("order-express", Connection = "SERVICEBUS_CONNECTION")] ICollector<Message> outputExpressMessages,
            [ServiceBus("order-standard", Connection = "SERVICEBUS_CONNECTION")] ICollector<Message> outputStandardMessages,
            ILogger log)
        {
            if (ingressMessage == null)
            {
                throw new ArgumentNullException(nameof(ingressMessage));
            }

            var order = JsonSerializer.Deserialize<Order>(ingressMessage);

            var outputMessage = new Message
            {
                ContentType = "application/json",
                Body = Encoding.UTF8.GetBytes(JsonSerializer.Serialize(order)),
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
