using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using Models;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationInsightsTelemetry();
var app = builder.Build();
if (app.Environment.IsDevelopment()) { app.UseDeveloperExceptionPage(); }

app.UseCloudEvents();
app.MapSubscribeHandler();

app.MapGet("/health", () => Results.Ok());

app.MapPost("/order-ingress-dapr", async ([FromBody] Order order) =>
{
    var daprClient = new DaprClientBuilder().Build();

    switch (order.Delivery)
    {
        case Delivery.Express:
            await daprClient.InvokeBindingAsync("order-express-dapr", "create", order);
            break;
        case Delivery.Standard:
            await daprClient.InvokeBindingAsync("order-standard-dapr", "create", order);
            break;
    }

    return Results.Ok(order.OrderId);
});

await app.RunAsync();
