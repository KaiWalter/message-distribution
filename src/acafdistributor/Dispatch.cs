using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Models;
using System.Text;
using System.Text.Json;

namespace funcdistributor
{
    public class Dispatch
    {
        [Function("Dispatch")]
        public DispatchedOutput Run(
            [ServiceBusTrigger("q-order-ingress-acaf", Connection = "SERVICEBUS_CONNECTION")] string ingressMessage,
            ILogger log)
        {
            ArgumentNullException.ThrowIfNull(ingressMessage, nameof(ingressMessage));

            var order = JsonSerializer.Deserialize<Order>(ingressMessage);

            ArgumentNullException.ThrowIfNull(order, nameof(ingressMessage));

            var outputMessage = new DispatchedOutput();

            switch (order.Delivery)
            {
                case Delivery.Express:
                    outputMessage.ExpressMessage = new ServiceBusMessage(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(order)))
                    {
                        ContentType = "application/json",
                        MessageId = order.OrderId.ToString(),
                    };
                    break;
                case Delivery.Standard:
                    outputMessage.StandardMessage = new ServiceBusMessage(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(order)))
                    {
                        ContentType = "application/json",
                        MessageId = order.OrderId.ToString(),
                    };
                    break;
                default:
                    log.LogError($"invalid Delivery type: {order.Delivery}");
                    break;
            }

            return outputMessage;
        }
    }

    public class DispatchedOutput
    {
        [ServiceBusOutput("q-order-express-acaf", Connection = "SERVICEBUS_CONNECTION")]
        public ServiceBusMessage? ExpressMessage { get; set; }

        [ServiceBusOutput("q-order-standard-acaf", Connection = "SERVICEBUS_CONNECTION")]
        public ServiceBusMessage? StandardMessage { get; set; }
    }
}


