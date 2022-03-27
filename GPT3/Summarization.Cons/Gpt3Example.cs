using System.Text;
using Microsoft.Extensions.Configuration;
using OpenAI_API;
using Spectre.Console;

namespace Summarization.Cons;

public class Gpt3Example
{
    private const string openApiKeyKey = "OpenApiKey";
    private const string bgeFile1 = "/Users/martin/Documents/Source/OpenLegalLab/BGE/91_IV_216.txt";
    private const string bgeFile2 = "/Users/martin/Documents/Source/OpenLegalLab/BGE/96_IV_39.txt";
    private const string bgeFile3 = "/Users/martin/Documents/Source/OpenLegalLab/BGE/102_IV_256.txt";
    
    private const string manualPrompt = "Was sind die wesentlichen rechtlichen Erwägungen?";
    
    public async Task Example()
    {
        var configuration = new ConfigurationManager();
        var openApiKey = configuration[openApiKeyKey];
        Console.WriteLine(openApiKey);

        var models = new List<BgeModel>
        {
            new(bgeFile1),
            new(bgeFile2),
            new(bgeFile3)
        };

        var sb = new StringBuilder();
        sb.Append($"Entscheid: {models[0].Prompt}\n");
        sb.Append($"Regeste: {models[0].Regeste}\n");
        // sb.Append($"Entscheid2: {models[1].Prompt}\n");
        // sb.Append($"Regeste2: {models[1].Regeste}\n");
        sb.Append($"Entscheid: {models[2].Prompt}\n");
        sb.Append("Regeste:");
        
        // sb.Append($"\n\n{manualPrompt}");
        var prompt = sb.ToString();
        // AnsiConsole.MarkupLine($"[red]{prompt}[/]");

        var api = new OpenAIAPI(openApiKey, engine: Engine.Davinci);
        var result = await api.Completions.CreateCompletionAsync(
            prompt,
            temperature: 0.63, 
            max_tokens: 150, 
            top_p: 1, 
            frequencyPenalty:0.2, 
            presencePenalty:0
        );
        
        AnsiConsole.MarkupLine($"[blue]{prompt}[/]");
        AnsiConsole.MarkupLine($"[yellow]{result.ToString().Trim()}[/]");
    }
}