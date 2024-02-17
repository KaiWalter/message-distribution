using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Models;
using System.Text.Json;
using System.Text;

namespace funcreceiver
{
    public class Receiver
    {
        [Function(nameof(ReceiverUpload))]
        public async Task ReceiverUpload(
            [ServiceBusTrigger("%QUEUE_NAME%", Connection = "SERVICEBUS_CONNECTION", IsBatched = true)] string[] ingressMessages,
            [BlobInput("%INSTANCE%-outbox/{rand-guid}", Connection = "STORAGE_CONNECTION")] BlobContainerClient containerClient,
            FunctionContext context)
        {
            ArgumentNullException.ThrowIfNull(ingressMessages, nameof(ingressMessages));

            var logger = context.GetLogger(nameof(Receiver));

            foreach (var ingressMessage in ingressMessages)
            {
                var order = JsonSerializer.Deserialize<Order>(ingressMessage);

                ArgumentNullException.ThrowIfNull(order, nameof(order));

                logger.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);

                var blobClient = containerClient.GetBlobClient(order.OrderId.ToString());
                var content = Encoding.UTF8.GetBytes(ingressMessage);
                using (var ms = new MemoryStream(content))
                    await blobClient.UploadAsync(ms, overwrite: true);
            }
        }

    }
}
