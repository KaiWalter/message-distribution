using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using Models;
using System.Diagnostics;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddSingleton<DaprClient>(new DaprClientBuilder().Build());

var app = builder.Build();
if (app.Environment.IsDevelopment()) { app.UseDeveloperExceptionPage(); }

app.UseCloudEvents();

app.MapGet("/health", () => Results.Ok());

app.MapPost("/order-ingress-dapr", async (
    [FromBody] Order order,
    [FromServices] DaprClient daprClient
    ) =>
{
    Activity.Current?.AddTraceStateEntry("OrderGuid", order.OrderGuid.ToString());

    switch (order.Delivery)
    {
        case Delivery.Express:
            // await daprClient.InvokeBindingAsync("order-express-dapr", "create", order);
            await daprClient.PublishEventAsync("order-pubsub","order-express-dapr",order);
            break;
        case Delivery.Standard:
            // telemetryClient.TrackTrace($"send {order.OrderId} to Standard", trace);
            await daprClient.PublishEventAsync("order-pubsub","order-standard-dapr",order);
            break;
    }

    return Results.Ok(order);
});

await app.RunAsync();
