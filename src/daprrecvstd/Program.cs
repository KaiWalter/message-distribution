using Dapr;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Mvc;
using Models;
using Utils;

var testCase = Environment.GetEnvironmentVariable("TESTCASE");

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplicationInsightsTelemetry();
builder.Services.Configure<TelemetryConfiguration>((o) =>
{
    o.TelemetryInitializers.Add(new AppInsightsTelemetryInitializer());
});

var app = builder.Build();
if (app.Environment.IsDevelopment()) { app.UseDeveloperExceptionPage(); }

app.UseCloudEvents();

app.MapGet("/health", () => Results.Ok());

app.MapGet("/dapr/subscribe", () => Results.Ok(new[]{
    new {
        pubsubname = "order-pubsub",
        topic = $"t-order-standard-{testCase}",
        route = $"/t-order-standard-{testCase}",
    }}));

app.MapPost($"/t-order-standard-{testCase}", (
    ILogger<Program> log,
    Order order
    ) =>
{
    log.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);
    return Results.Ok();
});

app.MapPost($"/q-order-standard-{testCase}-input", (
    ILogger<Program> log,
    [FromBody] Order order
    ) =>
{
    log.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);
    return Results.Ok();
});

await app.RunAsync();
