using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace BgeGetter
{
    public static class GetBge
    {
        [FunctionName("GetBge")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)]
            HttpRequest req,
            ILogger log)
        {
            string date = req.Query["date"];
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody);
            date = date ?? data?.date;
            var getterService = new GetterService(log);
            string result = "";
            if (!string.IsNullOrWhiteSpace(date))
            {
                var pubDate = date.Split(".");
                if (pubDate.Length == 3
                    && int.TryParse(pubDate[0], out var day)
                    && int.TryParse(pubDate[1], out var month)
                    && int.TryParse(pubDate[2], out var year))
                {
                    try
                    {
                        var d = new DateTime(year, month, day);
                        result = await getterService.GetBge(d);
                    }
                    catch
                    {
                        result = await getterService.GetBge();
                    }
                }
            }
            else
            {
                result = await getterService.GetBge();
            }

            return new OkObjectResult(result);
        }
    }
}