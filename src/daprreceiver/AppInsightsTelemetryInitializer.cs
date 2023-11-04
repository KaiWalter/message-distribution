using Microsoft.ApplicationInsights.Channel;
using Microsoft.ApplicationInsights.Extensibility;

namespace Utils
{

    public class AppInsightsTelemetryInitializer : ITelemetryInitializer
    {
        public void Initialize(ITelemetry telemetry)
        {
            if (string.IsNullOrEmpty(telemetry.Context.Cloud.RoleName))
            {
                telemetry.Context.Cloud.RoleName = System.Environment.GetEnvironmentVariable("CONTAINER_APP_NAME") ?? "CONTAINER_APP_NAME-not-set";
            }
            if (string.IsNullOrEmpty(telemetry.Context.Cloud.RoleInstance))
            {
                telemetry.Context.Cloud.RoleInstance = System.Environment.GetEnvironmentVariable("HOSTNAME") ?? "HOSTNAME-not-set";
            }
        }
    }

}
