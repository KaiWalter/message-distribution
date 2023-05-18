using System.Net;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;

namespace acafrecvexp
{
    public static class Health
    {
        [Function("Health")]
        public static HttpResponseData Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequestData req,
            ILogger log)
        {
            var response = req.CreateResponse(HttpStatusCode.OK);
            return response;
        }
    }
}
