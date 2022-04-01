using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;

namespace BgeGetter
{
    public class BgeGetterTimer
    {
        [FunctionName("BgeGetterTimer")]
        public void Run([TimerTrigger("0 0 14 * * *")] TimerInfo myTimer, ILogger log)
        {
            log.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
            var getterService = new GetterService(log);
            var result = getterService.GetBge().GetAwaiter().GetResult();
        }
    }
}