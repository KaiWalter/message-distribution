using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace funcrecvstd
{
    public class Receiver
    {
        [FunctionName("Receiver")]
        public void Run([ServiceBusTrigger("order-standard-func", Connection = "SERVICEBUS_CONNECTION")]string myQueueItem, ILogger log)
        {
            log.LogInformation($"C# ServiceBus queue trigger function processed message: {myQueueItem}");
        }
    }
}
