using System;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text;
using System.Threading.Tasks;
using HtmlAgilityPackCore;

namespace BgeGetter;

public class GetterService
{
    private const int TwitterLinkLength = 23;
    private string _apiKey = Environment.GetEnvironmentVariable("API_KEY");
    private string _eventName = "BGE-Update-Test";

    private bool foundToday = false;

    public GetterService()
    {
        var eventName = Environment.GetEnvironmentVariable("EVENT_NAME");
        if (!string.IsNullOrWhiteSpace(eventName))
        {
            _eventName = eventName;
        }
    }
    
    public async Task<string> GetBge(DateTime? runDate = null)
    {
        var sb = new StringBuilder();
        if (runDate == null)
        {
            runDate = DateTime.Now;
            if (runDate.Value.Hour < 12)
            {
                runDate = runDate.Value.AddDays(-1);
            }
        }

        if (runDate.Value.DayOfWeek == DayOfWeek.Saturday || runDate.Value.DayOfWeek == DayOfWeek.Sunday)
        {
            return "does not run on saturdays and sundays as there are no new decisionson these days";
        }

        var url = $"https://www.bger.ch/ext/eurospider/live/de/php/aza/http/index_aza.php?date={runDate.Value:yyyyMMdd}&lang=de&mode=news";
        var client = new HttpClient();
        var response = await client.GetAsync(url);
        var html = await response.Content.ReadAsStringAsync();
        var doc = new HtmlDocument();
        await doc.LoadHtml(html);
        var trs = doc.DocumentNode.SelectNodes("//tr").ToList();
        var runDateText = $"{runDate:dd.MM.yyyy}";
        sb.Append("Main URL:\n");
        sb.Append($"- {url}\n");
        sb.Append("\n");
        sb.Append("Jobs:");
        
        foreach (var tr in trs)
        {
            var innerText = tr.InnerText.ToString().Trim();
            if (innerText.EndsWith("*"))
            {
                var parts = innerText.Split("\n").Where(p => !string.IsNullOrEmpty(p)).ToArray();
                if (parts.Length != 3)
                {
                    throw new InvalidOperationException("OpenLegalLab Parser: Tr of BGE invalid parts length");
                }

                var pubDate = parts[0].Split(".");
                if (parts.Length != 3)
                {
                    throw new InvalidOperationException($"OpenLegalLab Parser: Date of BGE invalid {parts[0]}");
                }

                var idxOfNext = trs.IndexOf(tr) + 1;
                var txtTitle = parts[2].Replace("*", "");
                string txtAdditional = "";
                if (trs.Count > idxOfNext)
                {
                    var nextTr = trs[idxOfNext];
                    txtAdditional = nextTr.InnerText.ToString().Trim();
                }
                
                var m = new LinkModel
                {
                    RunDate = runDateText,
                    Bge = parts[0].Trim(),
                    DecisionDateDay = pubDate[0],
                    DecisionDateMonth = pubDate[1],
                    DecisionDateYear = pubDate[2],
                    Text = $"{txtTitle}-{txtAdditional}"
                };
                
                if (m.ToString().Length - m.Url.Length + TwitterLinkLength > 280)
                {
                    m.Text = txtTitle;
                }

                var sent = await SendToIfttt(m.ToString());
                sb.Append($"- {sent}: {m}\n");
            }
        }

        if (!foundToday)
        {
            sb.Append("- nothing to do\n");
            await SendToIfttt($"Das Bundesgericht hat am {runDateText} keine zur Publikation vorgesehenen Entscheide veröffentlicht.");
        }

        return "ok";
    }

    private async Task<string> SendToIfttt(string msg)
    {
        var url = "https://maker.ifttt.com/trigger/" + _eventName + "/json/with/key/" + _apiKey;
        var client = new HttpClient();
        var content = JsonContent.Create(new { update = msg });
        var response = await client.PostAsync(url, content);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"could not send {msg}");
        }

        foundToday = true;
        return url;
    }
}