module.exports = async function (context, req) {
  try {
    let responseMessage =
      "JavaScript HTTP trigger function processed a request.";

    const axios = require("axios").default;
    const cheerio = require("cheerio");
    require("dotenv").config();

    const regexBGer = /(\d+)([A-Z])_(\d+\/\d+)/g;

    const regexDate = /\d{2}.\d{2}.\d{4}/g;
    const apikey = process.env.API_KEY;
    const env = "BGE-Update-Test"; //Todo: Change to production
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

      const response = await axios.get(url);
      let $ = cheerio.load(response.data);
      $("tr").each(async (index, element) => {
        let txt = $(element).text();
        if (txt.match(/\*/g)) {
          let date = txt.match(regexDate);
          txt = txt.replace(regexDate, " ");
          let BGer = txt.match(regexBGer);
          txt = txt.replace(regexBGer, " ");
          txt = txt.replace(/\s\s+/g, " ");
          txt = txt.replace(/\*/g, "");
          let output =
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
            txt +
            "Link: " +
            url;
          console.log(output);
          let axiosResponse = await axios.post(ifttt, { update: output })
          console.log("Posted to IFTTT: "+ axiosResponse);
        }
      });
      context.res = {
        // status: 200, /* Defaults to 200 */
        body: response.data,
      };
    }
  } catch (err) {
    context.res = {
      response: 'Oops, Nodebot internal Server Error',
      status: 500,
    };
  }
};
