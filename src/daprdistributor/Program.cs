using Dapr.AspNetCore;
using Dapr.Client;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Mvc;
using Models;
using Utils;

var testCase = Environment.GetEnvironmentVariable("TESTCASE") ?? "dapr";

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
        topic = $"q-order-ingress-{testCase}",
        route = $"/q-order-ingress-{testCase}-pubsub",
        bulkSubscribe = new {
          enabled = true,
          maxMessagesCount = 100,
          maxAwaitDurationMs = 10,
        }
    }}));
}
else
{
    app.UseCloudEvents();
    app.MapGet("/dapr/subscribe", () => Results.Ok(new[]{
    new {
        pubsubname = "order-pubsub",
        topic = $"t-order-ingress-{testCase}",
        route = $"/t-order-ingress-{testCase}",
    }}));
}

app.MapGet("/health", () => Results.Ok());

app.MapPost($"/q-order-ingress-{testCase}-pubsub", async (
    [FromBody] BulkSubscribeMessage<Order> bulkOrders,
    [FromServices] DaprClient daprClient,
    ILogger<Program> log
    ) =>
{
    log.LogInformation("{Count} Orders to distribute", bulkOrders.Entries.Count);
    List<BulkSubscribeAppResponseEntry> responseEntries = new List<BulkSubscribeAppResponseEntry>(bulkOrders.Entries.Count);
    var expressEntries = new List<BulkSubscribeMessageEntry<Order>>(bulkOrders.Entries.Count);
    var standardEntries = new List<BulkSubscribeMessageEntry<Order>>(bulkOrders.Entries.Count);

    foreach (var entry in bulkOrders.Entries)
    {
        var order = entry.Event;

        switch (order.Delivery)
        {
            case Delivery.Express:
                expressEntries.Add(entry);
                break;
            case Delivery.Standard:
                standardEntries.Add(entry);
                break;
        }
    }

    var metadata = new Dictionary<string, string>
        {
          { "rawPayload", "true"}
        };

    if (expressEntries.Count > 0)
    {
        try
        {
            var orders = from e in expressEntries select e.Event;
            await daprClient.BulkPublishEventAsync("order-pubsub", $"q-order-express-{testCase}", orders.ToArray(), metadata);
            foreach (var entry in expressEntries)
            {
                responseEntries.Add(new BulkSubscribeAppResponseEntry(entry.EntryId, BulkSubscribeAppResponseStatus.SUCCESS));
            }
        }
        catch (Exception e)
        {
            log.LogError(e.Message);
            foreach (var entry in expressEntries)
            {
                responseEntries.Add(new BulkSubscribeAppResponseEntry(entry.EntryId, BulkSubscribeAppResponseStatus.RETRY));
            }
        }
    }

    if (standardEntries.Count > 0)
    {
        try
        {
            var orders = from e in standardEntries select e.Event;
            await daprClient.BulkPublishEventAsync("order-pubsub", $"q-order-standard-{testCase}", orders.ToArray(), metadata);
            foreach (var entry in standardEntries)
            {
                responseEntries.Add(new BulkSubscribeAppResponseEntry(entry.EntryId, BulkSubscribeAppResponseStatus.SUCCESS));
            }
        }
        catch (Exception e)
        {
            log.LogError(e.Message);
            foreach (var entry in standardEntries)
            {
                responseEntries.Add(new BulkSubscribeAppResponseEntry(entry.EntryId, BulkSubscribeAppResponseStatus.RETRY));
            }
        }
    }


    return new BulkSubscribeAppResponse(responseEntries);
});

app.MapPost($"/t-order-ingress-{testCase}", async (
    [FromBody] Order order,
    [FromServices] DaprClient daprClient
    ) =>
{
    switch (order.Delivery)
    {
        case Delivery.Express:
            await daprClient.PublishEventAsync("order-pubsub", $"t-order-express-{testCase}", order);
            break;
        case Delivery.Standard:
            await daprClient.PublishEventAsync("order-pubsub", $"t-order-standard-{testCase}", order);
            break;
    }

    return Results.Ok(order);
});

app.MapPost($"/q-order-ingress-{testCase}-input", async (
    [FromBody] Order order,
    [FromServices] DaprClient daprClient
    ) =>
{
    switch (order.Delivery)
    {
        case Delivery.Express:
            await daprClient.InvokeBindingAsync($"q-order-express-{testCase}-output", "create", order);
            break;
        case Delivery.Standard:
            await daprClient.InvokeBindingAsync($"q-order-standard-{testCase}-output", "create", order);
            break;
    }

    return Results.Ok(order);
});

await app.RunAsync();
