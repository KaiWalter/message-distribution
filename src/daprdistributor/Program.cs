using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using Models;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddApplicationInsightsTelemetry();
builder.Services.AddSingleton<DaprClient>(new DaprClientBuilder().Build());

var app = builder.Build();
if (app.Environment.IsDevelopment()) { app.UseDeveloperExceptionPage(); }

app.UseCloudEvents();
app.MapSubscribeHandler();

app.MapGet("/health", () => Results.Ok());

app.MapPost("/order-ingress-dapr", async (
    [FromBody] Order order,
    [FromServices] DaprClient daprClient
    ) =>
{
    switch (order.Delivery)
    {
        case Delivery.Express:
            await daprClient.InvokeBindingAsync("order-express-dapr", "create", order);
            break;
        case Delivery.Standard:
            await daprClient.InvokeBindingAsync("order-standard-dapr", "create", order);
            break;
    }

    Console.WriteLine(order.OrderId);

    return Results.Ok();
});

await app.RunAsync();
