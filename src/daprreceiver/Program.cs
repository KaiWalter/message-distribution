using Dapr;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Mvc;
using Models;
using Utils;

var testCase = Environment.GetEnvironmentVariable("TESTCASE");
var instance = Environment.GetEnvironmentVariable("INSTANCE");

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

app.MapPost($"/q-order-{instance}-{testCase}-input", (
    ILogger<Program> log,
    [FromBody] Order order
    ) =>
{
    log.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);
    return Results.Ok();
});

await app.RunAsync();
