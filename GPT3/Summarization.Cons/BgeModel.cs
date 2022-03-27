namespace Summarization.Cons;

public class BgeModel
{
    private List<string> _regeste = new();
    private List<string>  _prompt = new();
    
    public BgeModel(string fileName)
    {
        var lines =  File.ReadAllLines(fileName).ToList();
        bool split = false;
        foreach (var line in lines)
        {
            var l = line.Trim();
            if (split == false)
            {
                if (string.IsNullOrWhiteSpace(l))
                {
                    split = true;
                    continue;
                }
                _regeste.Add(l);
            }
            else
            {
                _prompt.Add(l);
            }
        }
    }

    public string Regeste => string.Join("", _regeste);
    public string Prompt => string.Join("", _prompt);
}