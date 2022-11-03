using Dapr;
using Dapr.Client;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Mvc;
using Models;
using Utils;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<DaprClient>(new DaprClientBuilder().Build());

builder.Services.AddApplicationInsightsTelemetry();
builder.Services.Configure<TelemetryConfiguration>((o) =>
{
    o.TelemetryInitializers.Add(new AppInsightsTelemetryInitializer());
});

var app = builder.Build();
if (app.Environment.IsDevelopment()) { app.UseDeveloperExceptionPage(); }

app.UseCloudEvents();
app.MapSubscribeHandler();

app.MapGet("/health", () => Results.Ok());

// app.MapGet("/dapr/subscribe", () => Results.Ok(new[]{
//     new {
//         pubsubname = "order-pubsub",
//         topic = "t-order-ingress-dapr",
//         route = "/t-order-ingress-dapr",
//         metadata = new {
//             rawPayload= "true",
//         }
//     }}));

app.MapPost("/t-order-ingress-dapr", [Topic("order-pubsub", "t-order-ingress-dapr", enableRawPayload: true)] async (
    [FromBody] Order order,
    [FromServices] DaprClient daprClient
    ) =>
{
    switch (order.Delivery)
    {
        case Delivery.Express:
            await daprClient.PublishEventAsync("order-pubsub", "t-order-express-dapr", order);
            break;
        case Delivery.Standard:
            await daprClient.PublishEventAsync("order-pubsub", "t-order-standard-dapr", order);
            break;
    }

    return Results.Ok(order);
});

app.MapPost("/q-order-ingress-dapr", async (
    [FromBody] Order order,
    [FromServices] DaprClient daprClient
    ) =>
{
    switch (order.Delivery)
    {
        case Delivery.Express:
            await daprClient.InvokeBindingAsync("q-order-express-dapr", "create", order);
            break;
        case Delivery.Standard:
            await daprClient.InvokeBindingAsync("q-order-standard-dapr", "create", order);
            break;
    }

    return Results.Ok(order);
});

await app.RunAsync();
