namespace Summarization.Cons;

public class BgeModel
{
    private string _regesteDe;
    private string _regesteFr;
    private string _regesteIt;
    private string  _prompt;
    
    public BgeModel(string fileName)
    {
        var lines =  File.ReadAllLines(fileName)
            .Select(l => l.Trim())
            .Where(l => !string.IsNullOrWhiteSpace(l))
            .ToList();
        if (lines.Count == 4)
        {
            _regesteDe = lines[0];
            _regesteFr = lines[1];
            _regesteIt = lines[2];
            _prompt = lines[3];
        }
    }

    public string RegesteDe => string.Join("", _regesteDe);
    public string RegesteFr => string.Join("", _regesteFr);
    public string RegesteIt => string.Join("", _regesteIt);
    
    public string Prompt => string.Join("", _prompt);
}