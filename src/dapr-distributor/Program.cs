using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using Models;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
if (app.Environment.IsDevelopment()) {app.UseDeveloperExceptionPage();}

app.UseCloudEvents();
app.MapSubscribeHandler();

app.MapGet("/health", () => Results.Ok());

app.MapPost("/order-ingress-dapr", async ([FromBody] Order order) => {
       Console.WriteLine(order.OrderId);
    var daprClient = new DaprClientBuilder().Build();
    await daprClient.InvokeBindingAsync("order-express-dapr", "create", order);
    return Results.Ok(order.OrderId);
});

await app.RunAsync();
