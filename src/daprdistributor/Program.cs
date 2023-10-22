using Dapr;
using Dapr.Client;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Mvc;
using Models;
using Utils;
using System.Text.Json;

var testCase = Environment.GetEnvironmentVariable("TESTCASE");

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

app.UseCloudEvents();
app.MapSubscribeHandler();

app.MapGet("/health", () => Results.Ok());

app.MapGet("/dapr/subscribe", () => Results.Ok(new[]{
    new {
        pubsubname = "order-pubsub",
        topic = $"t-order-ingress-{testCase}",
        route = $"/t-order-ingress-{testCase}",
        metadata = new {
            rawPayload= "true",
        }
    }}));

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
