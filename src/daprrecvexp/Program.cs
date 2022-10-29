using Dapr;
using Models;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
if (app.Environment.IsDevelopment()) { app.UseDeveloperExceptionPage(); }

app.UseCloudEvents();
app.MapSubscribeHandler();

app.MapGet("/health", () => Results.Ok());

app.MapPost("/order-express-dapr", [Topic("order-pubsub", "order-express-dapr")] (Order order) =>
{
    return Results.Ok();
});

await app.RunAsync();
