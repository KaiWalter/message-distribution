using Dapr.Client;
using Microsoft.ApplicationInsights.Extensibility;
using Microsoft.AspNetCore.Mvc;
using Models;
using Utils;

var testCase = Environment.GetEnvironmentVariable("TESTCASE");
var instance = Environment.GetEnvironmentVariable("INSTANCE");

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

app.MapPost($"/q-order-{instance}-{testCase}-input", async (
    [FromBody] Order order,
    [FromServices] DaprClient daprClient,
    ILogger<Program> log
    ) =>
{
    log.LogInformation("{Delivery} Order received {OrderId}", order.Delivery, order.OrderId);

    var metadata = new Dictionary<string, string>
    {
      { "blobName", order.OrderId.ToString() }
    };
    await daprClient.InvokeBindingAsync<Order>($"{instance}-output", "create", order);

    return Results.Ok();
});

await app.RunAsync();
