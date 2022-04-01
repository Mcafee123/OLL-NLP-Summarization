module.exports = async function (context, req) {
  async function detectLang(test = true) {
    try {
      const LanguageDetect = require("languagedetect");
      const txt = req.query["txt"] ?? req.body;
      const lngDetector = new LanguageDetect();
      const lang = lngDetector.detect(txt, 3);
      return {
        error: null,
        lang,
      };
    } catch (err) {
      return {
        error: err,
        lang: null,
      };
    }
  };

  const { error, lang, txt } = await detectLang();
  context.res = {
    status: error ? 500 : 200 /* Defaults to 200 */,
    body: error ? 'Oops, Nodebot internal Server Error' : lang,
  };
};
