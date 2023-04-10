using Dapr;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Mvc;
using Models;
using Utils;

var builder = WebApplication.CreateBuilder(args);

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

app.MapPost("/t-order-express-dapr", [Topic("order-pubsub", "t-order-express-dapr")] (
    ILogger<Program> log, 
    Order order
    ) =>
{
    log.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);
    return Results.Ok();
});

app.MapPost("/q-order-express-dapr", (
    ILogger<Program> log, 
    [FromBody] Order order
    ) => 
{
    log.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);
    return Results.Ok();
});

await app.RunAsync();
