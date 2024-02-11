using Dapr.AspNetCore;
using Dapr.Client;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Mvc;
using Models;
using Utils;

var testCase = Environment.GetEnvironmentVariable("TESTCASE") ?? "dapr";
var instance = Environment.GetEnvironmentVariable("INSTANCE") ?? "NOT_SET";

var daprGrpcEndpoint = Environment.GetEnvironmentVariable("DAPR_GRPC_ENDPOINT");
var daprPort = Environment.GetEnvironmentVariable("DAPR_PORT");
var daprApiToken = Environment.GetEnvironmentVariable("DAPR_API_TOKEN");

var builder = WebApplication.CreateBuilder(args);
if (!string.IsNullOrEmpty(daprGrpcEndpoint) && !string.IsNullOrEmpty(daprPort) && !string.IsNullOrEmpty(daprApiToken))
{
    builder.Services.AddSingleton<DaprClient>(new DaprClientBuilder().UseGrpcEndpoint($"{daprGrpcEndpoint}:{daprPort}").UseDaprApiToken(daprApiToken).Build());
}
else
{
    builder.Services.AddSingleton<DaprClient>(new DaprClientBuilder().Build());
}

builder.Services.AddApplicationInsightsTelemetry();
builder.Services.Configure<TelemetryConfiguration>((o) =>
{
    o.TelemetryInitializers.Add(new AppInsightsTelemetryInitializer());
});

var app = builder.Build();
if (app.Environment.IsDevelopment()) { app.UseDeveloperExceptionPage(); }

if (testCase.Equals("dapr"))
{
    app.MapGet("/dapr/subscribe", () => Results.Ok(new[]{
    new {
        pubsubname = "order-pubsub",
        topic = $"q-order-{instance}-{testCase}",
        route = $"/q-order-{instance}-{testCase}-pubsub",
        bulkSubscribe = new {
          enabled = true,
          maxMessagesCount = 100,
          maxAwaitDurationMs = 40,
        }
    }}));
}
else
{
    app.UseCloudEvents();
}

app.MapGet("/health", () => Results.Ok());

app.MapPost($"/q-order-{instance}-{testCase}-pubsub", async (
    [FromBody] BulkSubscribeMessage<Order> bulkOrders,
    [FromServices] DaprClient daprClient,
    ILogger<Program> log
    ) =>
{
    log.LogInformation("{Count} Orders received", bulkOrders.Entries.Count);
    List<BulkSubscribeAppResponseEntry> responseEntries = new List<BulkSubscribeAppResponseEntry>();

    foreach (var entry in bulkOrders.Entries)
    {
        var order = entry.Event;

        var metadata = new Dictionary<string, string>
        {
          { "blobName", order.OrderId.ToString() }
        };

        try
        {
            await daprClient.InvokeBindingAsync<Order>($"{instance}-output", "create", order);
            log.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);
            responseEntries.Add(new BulkSubscribeAppResponseEntry(entry.EntryId, BulkSubscribeAppResponseStatus.SUCCESS));
        }
        catch (Exception e)
        {
            log.LogError(e.Message);
            responseEntries.Add(new BulkSubscribeAppResponseEntry(entry.EntryId, BulkSubscribeAppResponseStatus.RETRY));
        }
    }

    return new BulkSubscribeAppResponse(responseEntries);
});

app.MapPost($"/q-order-{instance}-{testCase}-input", async (
    [FromBody] Order order,
    [FromServices] DaprClient daprClient,
    ILogger<Program> log
    ) =>
{
    log.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);

    var metadata = new Dictionary<string, string>
    {
      { "blobName", order.OrderId.ToString() }
    };
    await daprClient.InvokeBindingAsync<Order>($"{instance}-output", "create", order);

    return Results.Ok();
});

await app.RunAsync();
