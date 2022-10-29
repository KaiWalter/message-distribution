using System.Diagnostics;

public static class DaprDiagnosticExtension
{
    public static void AddTraceStateEntry(this Activity activity, string key, string value)
    {
        ArgumentNullException.ThrowIfNull(activity, nameof(activity));
        ArgumentNullException.ThrowIfNull(key, nameof(key));
        ArgumentNullException.ThrowIfNull(value, nameof(value));
        var str = key.Trim() + "=" + value.Trim();

        if (string.IsNullOrEmpty(activity.TraceStateString))
        {
            activity.TraceStateString = str;
        }
        else
        {
            if (activity.TraceStateString.Contains(str, StringComparison.InvariantCulture))
            {
                return;
            }

            var activityNew = activity;
            activityNew.TraceStateString += "," + str;
        }
    }
}