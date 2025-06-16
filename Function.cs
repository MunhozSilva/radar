using Amazon.Lambda.Core;
using Radar.Services;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace Radar;

public class Function
{
    public async Task<string> FunctionHandler(object input, ILambdaContext context)
    {
        var executor = new RadarExecutor();
        await executor.ExecutarRadarAsync();
        return "OK";
    }
}
