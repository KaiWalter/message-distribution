using Dapr.Client;
using Dapr.AspNetCore;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Mvc;
using Models;
using Utils;
using System.Text.Json;

var testCase = Environment.GetEnvironmentVariable("TESTCASE");

var builder = WebApplication.CreateBuilder(args);

if (testCase.ToLowerInvariant().Equals("dapr"))
{
    builder.Services.AddSingleton<DaprClient>(new DaprClientBuilder().Build());
}
else
{
    var daprGrpcEndpoint = Environment.GetEnvironmentVariable("DAPR_GRPC_ENDPOINT");
    var daprApiToken = Environment.GetEnvironmentVariable("DAPR_API_TOKEN");
    builder.Services.AddSingleton<DaprClient>(new DaprClientBuilder().UseGrpcEndpoint($"{daprGrpcEndpoint}:443").UseDaprApiToken(daprApiToken).Build());
}

builder.Services.AddApplicationInsightsTelemetry();
builder.Services.Configure<TelemetryConfiguration>((o) =>
{
    o.TelemetryInitializers.Add(new AppInsightsTelemetryInitializer());
});

var app = builder.Build();
if (app.Environment.IsDevelopment()) { app.UseDeveloperExceptionPage(); }

app.UseCloudEvents();

app.MapGet("/health", () => Results.Ok());

app.MapGet("/dapr/subscribe", () =>
    Results.Ok(new[]{
    new {
        pubsubname = "order-pubsub",
        topic = $"t-order-ingress-{testCase}-bulk",
        route = $"/t-order-ingress-{testCase}-bulk",
        bulkSubscribe = new {
            enabled = true,
            maxMessagesCount = 10,
            maxAwaitDurationMs = 100,
        },
    },
}));

app.MapPost($"/t-order-ingress-{testCase}-bulk", async (
    [FromBody] BulkSubscribeMessage<BulkMessageModel<Order>> orders,
    [FromServices] DaprClient daprClient,
    ILogger<Program> log
    ) =>
{
    log.LogWarning(JsonSerializer.Serialize(orders));

    if (orders == null)
    {
        log.LogWarning($"{nameof(orders)} is null");
    }

    if (orders?.Entries == null)
    {
        log.LogWarning($"{nameof(orders.Entries)} is null");
    }

    var responseEntries = new List<BulkSubscribeAppResponseEntry>();

    if (orders?.Entries != null)
    {
        foreach (var entry in orders?.Entries)
        {
            var order = entry.Event.Data;

            switch (order.Delivery)
            {
                case Delivery.Express:
                    await daprClient.PublishEventAsync("order-pubsub", $"t-order-express-{testCase}", order);
                    break;
                case Delivery.Standard:
                    await daprClient.PublishEventAsync("order-pubsub", $"t-order-standard-{testCase}", order);
                    break;
            }
            responseEntries.Add(new BulkSubscribeAppResponseEntry(entry.EntryId, BulkSubscribeAppResponseStatus.SUCCESS));
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
