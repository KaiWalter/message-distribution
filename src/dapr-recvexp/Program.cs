using Dapr.Client;
using Microsoft.AspNetCore.Mvc;
using Models;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
if (app.Environment.IsDevelopment()) { app.UseDeveloperExceptionPage(); }

app.UseCloudEvents();
app.MapSubscribeHandler();

app.MapGet("/health", () => Results.Ok());

app.MapPost("/order-express-dapr", async ([FromBody] Order order) =>
{
    Console.WriteLine(order.OrderId);
    return Results.Ok(order.OrderId);
});

await app.RunAsync();
