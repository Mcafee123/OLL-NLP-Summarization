namespace BgeGetter;

public class LinkModel
{
    public string RunDate { get; set; }
    public string Bge { get; set; }
    public string DecisionDateDay { get; set; }
    public string DecisionDateMonth { get; set; }
    public string DecisionDateYear { get; set; }
    public string Text { get; set; }

    public string Lang { get; set; }

    public string Url =>
        $"https://www.bger.ch/ext/eurospider/live/it/php/aza/http/index.php?highlight_docid=aza%3A%2F%2Faza://{DecisionDateDay}-{DecisionDateMonth}-{DecisionDateYear}-{Bge.Replace("/", "-")}&lang=it&zoom=&type=show_document";
    
    public override string ToString()
    {
        // if(Lang == "french"){
        //     output = "Le "+day +"." +month+"."+year+" le Tribunal féderal a proposé la décision " + BGer + " du "+ date + " pour la publication. Il traite: "+text+" -" +next +" Link: " + url; 
        // } else if(lngDetector.detect(text, 1)[0][0] == 'italian'){
        //     output = "Il "+day +"." +month+"."+year+", il Tribunale federale ha destinato alla pubblicazione la decisione " + BGer + " del "+ date + ". Si tratta di: "+text+" -" +next +" Link: " + url; 
        // } else {
        //     output = "Das Bundesgericht hat am "+day +"." +month+"."+year+" den Entscheid " + BGer + " vom "+ date + " zur Publikation vorgesehen. Er behandelt: "+text+" -" +next +" Link: " + url; 
        // }
        var output = $"Das Bundesgericht hat am {RunDate} den Entscheid {Bge} vom {DecisionDateDay}.{DecisionDateMonth}.{DecisionDateYear} zur Publikation vorgesehen. Er behandelt: {Text} Link: {Url}";
        return output;
    }
}