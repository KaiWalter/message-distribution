using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Models;
using System.Text.Json;

namespace funcreceiver
{
    public class Receiver
    {
        [Function(nameof(Receiver))]
        [BlobOutput("%INSTANCE%-outbox/{MessageId}", Connection = "STORAGE_CONNECTION")]
        public string Run(
            [ServiceBusTrigger("%QUEUE_NAME%", Connection = "SERVICEBUS_CONNECTION")] string ingressMessage,
            FunctionContext executionContext
            )
        {
            var logger = executionContext.GetLogger("Receiver");

            ArgumentNullException.ThrowIfNull(ingressMessage, nameof(ingressMessage));

            var order = JsonSerializer.Deserialize<Order>(ingressMessage);

            ArgumentNullException.ThrowIfNull(order, nameof(order));

            logger.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);

            return ingressMessage;
        }
    }
}
