using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Models;
using System.Text.Json;

namespace funcdistributor
{
    public class Dispatch
    {
        [Function("DispatchBatch")]
        public DispatchedOutput DispatchBatch(
            [ServiceBusTrigger("%QUEUE_NAME_INGRESS%", Connection = "SERVICEBUS_CONNECTION", IsBatched = true)] string[] ingressMessages,
            FunctionContext context)
        {
            ArgumentNullException.ThrowIfNull(ingressMessages, nameof(ingressMessages));

            var logger = context.GetLogger(nameof(Dispatch));

            var outputMessage = new DispatchedOutput();

            foreach (var ingressMessage in ingressMessages)
            {
                var order = JsonSerializer.Deserialize<Order>(ingressMessage);

                ArgumentNullException.ThrowIfNull(order, nameof(ingressMessage));

                logger.LogInformation("dispatching {OrderId} with {Delivery}", order.OrderId, order.Delivery);

                switch (order.Delivery)
                {
                    case Delivery.Express:
                        outputMessage.ExpressMessage.Add(ingressMessage);
                        break;
                    case Delivery.Standard:
                        outputMessage.StandardMessage.Add(ingressMessage);
                        break;
                    default:
                        logger.LogError($"invalid Delivery type: {order.Delivery}");
                        break;
                }
            }

            return outputMessage;
        }
    }

    public class DispatchedOutput
    {
        [ServiceBusOutput("%QUEUE_NAME_EXPRESS%", Connection = "SERVICEBUS_CONNECTION")]
        public List<string> ExpressMessage { get; } = new List<string>();

        [ServiceBusOutput("%QUEUE_NAME_STANDARD%", Connection = "SERVICEBUS_CONNECTION")]
        public List<string> StandardMessage { get; } = new List<string>();
    }
}


