using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace func_recvstd
{
    public class Receiver
    {
        [FunctionName("Receiver")]
        public void Run([ServiceBusTrigger("order-standard", Connection = "SERVICEBUS_CONNECTION")]string myQueueItem, ILogger log)
        {
            log.LogInformation($"C# ServiceBus queue trigger function processed message: {myQueueItem}");
        }
    }
}
