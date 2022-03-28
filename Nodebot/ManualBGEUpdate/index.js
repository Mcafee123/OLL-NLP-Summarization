module.exports = async function (context, req) {
  async function getNewCourtDecisions(test = true) {
    try {
      const axios = require("axios").default;
      const cheerio = require("cheerio");
      require("dotenv").config();
      const LanguageDetect = require("languagedetect");

      const lngDetector = new LanguageDetect();
      const regexBGer = /(\d+)([A-Z])_(\d+\/\d+)/g;
      const regexDate = /\d{2}.\d{2}.\d{4}/g;
      const apikey = process.env.API_KEY;
      const env = test ? "BGE-Update-Test" : "BGE-Update";
      const ifttt =
        "https://maker.ifttt.com/trigger/" + env + "/json/with/key/" + apikey;

      //TODO: Remove String from date to get actual date.
      let d = new Date("March 25, 2022 18:00:00"),
        month = "" + (d.getMonth() + 1),
        day = "" + d.getDate(),
        year = d.getFullYear(),
        dayOfWeek = d.getDay();
      if (month.length < 2) {
        month = "0" + month;
      }
      if (day.length < 2) {
        day = "0" + day;
      }
      console.log("ok?");
      if (!(dayOfWeek === 6) && !(dayOfWeek === 0)) {
        let url =
          "https://www.bger.ch/ext/eurospider/live/de/php/aza/http/index_aza.php?date=" +
          year +
          month +
          day +
          "&lang=de&mode=news";

        const response = await axios.get('https://www.bger.ch', { responseType: 'text/html' });
        let $ = cheerio.load(response.data);
        let allElements = []; //convert cheerio object to normal array
        $("tr").each((index, element) => {
          let txt = $(element).text();
          txt = txt.replace(/\s\s+/g, " ");
          allElements.push(txt);
        });
        for (let i = 0; i < allElements.length; i++) {
          // Runs 5 times, with values of step 0 through 4.
          let text = allElements[i];
          if (text.match(/\*/g)) {
            console.log(lngDetector.detect(text, 3));
            let date = text.match(regexDate);
            text = text.replace(regexDate, " ");
            let BGer = text.match(regexBGer);
            text = text.replace(regexBGer, " ");
            text = text.replace(/\*/g, "");
            next = allElements[i + 1];
            next = next.replace(/\*/g, "");
            text = text.replace(/\n/g, "");
            next = next.replace(/\n/g, "");
            let output;
            //Language detector performs very bad. We neet more text to classify. Todo: Read full decision.
            let lang = "";
            if (lngDetector.detect(text, 1)[0][0] == "french") {
              lang = "french";
              output =
                "Le " +
                day +
                "." +
                month +
                "." +
                year +
                " le Tribunal féderal a proposé la décision " +
                BGer +
                " du " +
                date +
                " pour la publication. Il traite: " +
                text +
                " -" +
                next +
                " Link: " +
                url;
            } else if (lngDetector.detect(text, 1)[0][0] == "italian") {
              lang = "italian";
              output =
                "Il " +
                day +
                "." +
                month +
                "." +
                year +
                ", il Tribunale federale ha destinato alla pubblicazione la decisione " +
                BGer +
                " del " +
                date +
                ". Si tratta di: " +
                text +
                " -" +
                next +
                " Link: " +
                url;
            } else {
              lang = "german";
              output =
                "Das Bundesgericht hat am " +
                day +
                "." +
                month +
                "." +
                year +
                " den Entscheid " +
                BGer +
                " vom " +
                date +
                " zur Publikation vorgesehen. Er behandelt: " +
                text +
                " -" +
                next +
                " Link: " +
                url;
            }

            if (output) {
              output = output.replace(/\s+/g, " ").trim();
              console.log(output);
              console.log(output);
              const r = await axios.post(ifttt, { update: output });
              console.log(r);
            }
          }
        }
        return { error: null, output, lang, txt: "<this will be the text" };
      }
    } catch (err) {
      return {
        error: err,
        output: null,
        lang: null,
        txt: "Oops, Nodebot internal Server Error",
      };
    }
  };

  const { error, url, lang, txt } = await getNewCourtDecisions();
  context.res = {
    status: error ? 500 : 200 /* Defaults to 200 */,
    body: error || txt,
  };
};
