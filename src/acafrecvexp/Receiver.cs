using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Models;
using System.Text.Json;
using System;

namespace acafrecvexp
{
    public class Receiver
    {
        [Function("Receiver")]
        public void Run(
            [ServiceBusTrigger("q-order-express-acaf", Connection = "SERVICEBUS_CONNECTION")] string ingressMessage,
            FunctionContext executionContext
            )
        {
            var logger = executionContext.GetLogger("Receiver");

            ArgumentNullException.ThrowIfNull(ingressMessage, nameof(ingressMessage));

            var order = JsonSerializer.Deserialize<Order>(ingressMessage);

            ArgumentNullException.ThrowIfNull(order, nameof(order));

            logger.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);
        }
    }
}
