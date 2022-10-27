using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace funcrecvexp
{
    public class Receiver
    {
        [FunctionName("Receiver")]
        public void Run([ServiceBusTrigger("order-express-func", Connection = "SERVICEBUS_CONNECTION")] string myQueueItem, ILogger log)
        {
            log.LogInformation($"C# ServiceBus queue trigger function processed message: {myQueueItem}");
        }
    }
}
