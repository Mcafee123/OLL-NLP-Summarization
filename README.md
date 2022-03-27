# OLL-NLP-Summarization

Open Legal Lab, Summarization of Court decisions

# Ziel

Ziel ist es aus Bundesgerichtsentscheiden eine kurze Zusammenfassung zu erstellen.
Dafür werden verschiedene NLP-Modelle getestet und die Möglichkeiten abgeschätzt.

# Prozess

1. Es werden 2-3 BGE ausgewählt aus dem Strassenverkehrsrecht (Wahl fiel auf SVG, da Urteile übersichtlich kurz und kurze Regesten).
2. Mit diesen BGE werden verschiedene NLP-Modelle getestet.

### BART Large CNN (English)

**Model Parameter:** English (Da das deutsche Model nicht in der kostenlosen Version verfügbar ist).

**BGE**
91_IV_216

**Ziel (Regeste):** Auf die vorsätzliche konkrete Gefährdung des Strassenverkehrs, herbeigeführt durch Verletzung von Verkehrsregeln, ist unter Ausschluss von Art. 90 SVG Art. 237 Ziff. 1 StGB anzuwenden.

**Output des Models:** Wie der Kassationshof entschieden hat, ist Art. 237 StGB nicht mehr anwendbar (BGE 90 IV 156). Offen gelassen wurde dagegen bisher, ob in Fällen vorsätzlicher Verkehrsgefährdung auch die Anwendung von Art. 237 Ziff. 1 StGB ausgeschlossen sei.

## **Beurteilung des Outputs:** TODO

### GTP3 (Davinci):

**Model Parameter**

```
curl https://api.openai.com/v1/engines/text-davinci-002/completions \
 -H "Content-Type: application/json" \
 -H "Authorization: Bearer $OPENAI_API_KEY" \
 -d '{
"prompt": "<91_IV_216>",
"temperature": 0.63,
"max_tokens": 506,
"top_p": 1,
"frequency_penalty": 0,
"presence_penalty": 0
}'

Prompt: "Was sind die wesentlichen rechtlichen Erwägungen?"
```

**BGE**
91_IV_216

**Ziel (Regeste):** Auf die vorsätzliche konkrete Gefährdung des Strassenverkehrs, herbeigeführt durch Verletzung von Verkehrsregeln, ist unter Ausschluss von Art. 90 SVG Art. 237 Ziff. 1 StGB anzuwenden.

**Output des Models:**
Der Bundesgerichtshof hat entschieden, dass Art. 237 StGB sowohl in den von Art. 90 Ziff. 2 SVG als auch in den von Ziff. 1 erfassten Fällen nicht mehr anwendbar ist. Offen gelassen wurde dagegen bisher, ob in Fällen vorsätzlicher Verkehrsgefährdung auch die Anwendung von Art. 237 Ziff. 1 StGB ausgeschlossen sei. Diese Frage ist entgegen der in der Gesetzesberatung vertretenen Auffassung, dass sowohl die fahrlässige wie vorsätzliche Gefährdung unter Art. 90 Ziff. 2 SVG fallen, und obschon Abs. 2 dieser Bestimmung die Anwendung des Art. 237 StGB ohne Einschränkung ausschliesst, zu verneinen.

---

### Pegasus XSUM (English)

**Model Parameter:** English (Da das deutsche Model nicht in der kostenlosen Version verfügbar ist).

**BGE**
91_IV_216

**Ziel (Regeste):** Auf die vorsätzliche konkrete Gefährdung des Strassenverkehrs, herbeigeführt durch Verletzung von Verkehrsregeln, ist unter Ausschluss von Art. 90 SVG Art. 237 Ziff. 1 StGB anzuwenden.

**Output des Models:** Fllen vorstzlicher Verkehrsgefhrdung die Anwendung von Art 237 Ziff.

**Beurteilung des Outputs:** TODO
