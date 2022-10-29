using Azure.Storage.Blobs;
using Bogus;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Models;
using System;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace testdata
{
    public static class Generate
    {
        [FunctionName("Generate")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [Blob("test-data/orders.json", FileAccess.ReadWrite, Connection = "STORAGE_CONNECTION")] BlobClient outputBlob,
            ILogger log)
        {
            var generationRequest = await JsonSerializer.DeserializeAsync<GenerationRequest>(req.Body);

            ArgumentNullException.ThrowIfNull(generationRequest,nameof(generationRequest));

            int count = generationRequest.Count ?? 10;

            int orderIds = 1000000;
            int orderItemIds = 0;

            var fakeOrderItems = new Faker<OrderItem>()
                    .RuleFor(oi => oi.OrderItemId, _ => orderItemIds++)
                    .RuleFor(oi => oi.SKU, f => f.Random.Replace("####-####-####"))
                    .RuleFor(oi => oi.Quantity, f => f.Random.Number(1, 10));

            var fakeOrders = new Faker<Order>()
                    .RuleFor(o => o.OrderId, _ => orderIds++)
                    .RuleFor(u => u.OrderGuid, f => Guid.NewGuid())
                    .RuleFor(o => o.Description, f => f.Random.AlphaNumeric(40))
                    .RuleFor(o => o.FirstName, f => f.Name.FirstName())
                    .RuleFor(o => o.LastName, f => f.Name.LastName())
                    .RuleFor(o => o.Delivery, f => f.PickRandom<Delivery>())
                    .RuleFor(o => o.Items, f =>
                    {
                        orderItemIds = 1;
                        var items = fakeOrderItems.GenerateBetween(1, 10);
                        return items;
                    });

            var orders = fakeOrders.Generate(count);

            JsonSerializerOptions options = new JsonSerializerOptions
            {
                Converters = {
                    new JsonStringEnumConverter()
                }
            };
            string jsonToUpload = JsonSerializer.Serialize(orders, options);

            using (MemoryStream ms = new MemoryStream(Encoding.UTF8.GetBytes(jsonToUpload)))
            {
                await outputBlob.UploadAsync(ms, overwrite: true);
            }

            return new CreatedResult(string.Empty, jsonToUpload);
        }
    }
}
