using Azure.Storage.Blobs;
using Bogus;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading.Tasks;

namespace test_data
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

            int count = generationRequest.Count ?? 10;

            int orderIds = 1000000;

            var orders = new List<Order>();

            for (int i = 0; i < count; i++)
            {
                orders.Add(new Faker<Order>()
                    .RuleFor(o => o.OrderId, f => orderIds++)
                    .RuleFor(o => o.Description, f => f.Random.AlphaNumeric(40))
                    .RuleFor(o => o.FirstName, f => f.Name.FirstName())
                    .RuleFor(o => o.LastName, f => f.Name.LastName())
                    .RuleFor(o => o.Delivery, f => f.PickRandom<Delivery>())
                );
            }

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
