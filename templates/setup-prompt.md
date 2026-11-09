# Setup-Prompt: Wissensbasis vorbefüllen

Begleitmaterial zu [Kapitel 8, Schritt 2](../BLUEPRINT.md#schritt-2-das-repository-für-agenten-vorbereiten) des Blueprints.

Der Setup-Skill `/setup-matt-pocock-skills` legt die Struktur der Wissensbasis an (`AGENTS.md` bzw. `CLAUDE.md`, `GLOSSARY.md`, `docs/adr/`, `docs/agents/`), lässt die fachlichen Inhalte aber leer. Mit diesem Prompt untersucht der Agent das bestehende Projekt und schlägt eine erste Grundbefüllung vor. Er schreibt nur, was ihr vorher bestätigt habt.

**So geht ihr vor:**

1. Skills installieren und `/setup-matt-pocock-skills` ausführen (Kapitel 8, Schritte 1 und 2).
2. Eine Session im Wurzelverzeichnis des Repositories starten, am besten mit dem leistungsfähigsten verfügbaren Modell.
3. Den Prompt unten vollständig einfügen und die Vorschläge Runde für Runde beantworten.
4. Den Diff prüfen und die Änderungen per Pull Request übernehmen.

In Projekten mit mehreren Repositories wird der Prompt in jedem Repository ausgeführt, das eine eigene Einrichtung hat, bei einer zentralen Einrichtung im Root-Repository ([Anhang B](../BLUEPRINT.md#anhang-b-projekte-mit-mehreren-repositories)).

Derselbe Prompt ist auch in [Anhang C](../BLUEPRINT.md#anhang-c-setup-prompt-zur-grundbefüllung) des Blueprints abgedruckt.

<!-- Prompt-Text identisch mit Anhang C in BLUEPRINT.md halten. -->

## Prompt

````text
Du hilfst mir, die Wissensbasis dieses Repositories für die Arbeit mit KI-Agenten vorzubefüllen. Die Struktur ist bereits eingerichtet: Projektanweisungen in der AGENTS.md (oder CLAUDE.md), Fachbegriffe in der GLOSSARY.md, Architekturentscheidungen unter docs/adr/ und die Skill-Konfiguration unter docs/agents/. Untersuche das Projekt und leite daraus Vorschläge für diese Dateien ab. Du änderst keine Datei, bevor ich den jeweiligen Vorschlag bestätigt habe.

## Leitlinien

- Halte nur fest, was sich nicht ohnehin aus dem Code ergibt: Konventionen, Begründungen, Fallstricke und Fachbegriffe. Beschreibe keine Module, Dateien oder Funktionen, die ein Agent beim Lesen des Codes selbst versteht.
- Die AGENTS.md wird in jede Session geladen und bleibt deshalb kompakt. Prüfe bei jedem Vorschlag: Würde ein Agent ohne diesen Hinweis wahrscheinlich einen Fehler machen oder unnötig lange suchen? Wenn nicht, gehört er nicht hinein.
- Lieber wenige belastbare Einträge als viele vage. Die Grundbefüllung muss nicht vollständig sein; weitere Begriffe und Entscheidungen entstehen später im Grilling mit /grill-with-docs.
- Erfinde keine Begründungen. Du kannst erkennen, dass etwas ungewöhnlich gelöst ist, aber nicht, warum. Solche Stellen legst du mir als Frage vor.
- Belege jeden Vorschlag mit einer Fundstelle (Datei, Konfiguration oder Commit) und gib an, wie sicher du dir bist (hoch, mittel, niedrig).
- Bestehende Inhalte haben Vorrang. Den vom Setup-Skill angelegten Abschnitt zu den Agent-Skills und die Dateien unter docs/agents/ lässt du unverändert. Andere bestehende Inhalte änderst oder entfernst du nur nach Rückfrage. Widersprüche zwischen Dokumentation und Code meldest du, statt sie selbst aufzulösen.
- Für Glossar und ADRs übernimmst du das Format der vorhandenen Dateien oder, falls installiert, die Vorgaben des Skills domain-modeling.
- Schreibe in der Sprache, die die Projektdokumentation bereits verwendet. Ist das nicht eindeutig, frag mich.
- Übernimm keine Zugangsdaten, Tokens, personenbezogenen Daten oder anderen vertraulichen Werte in die Dateien.
- Du änderst keinen Code und committest nichts.

## Phase 1: Projekt untersuchen

Verschaffe dir zuerst einen Überblick und vertiefe dann gezielt. Du musst nicht jede Datei lesen. Relevant sind vor allem:

- README, CONTRIBUTING und weitere Dokumentation, etwa unter docs/
- Anweisungsdateien anderer Agent-Tools, zum Beispiel .github/copilot-instructions.md, .github/instructions/, .cursor/rules/ oder .cursorrules
- Paket- und Build-Dateien, Skripte und Dockerfiles
- Konfigurationen für CI, Linter, Formatter, Typechecks und Tests
- die Verzeichnisstruktur und die zentralen Einstiegspunkte des Codes
- PR- und Issue-Vorlagen
- die Git-Historie: Branch- und Commit-Konventionen sowie Commits, deren Nachricht eine Entscheidung begründet

Fasse mir danach in wenigen Sätzen zusammen, was du verstanden hast: Zweck des Projekts, Aufbau, Technologien und wie gebaut und getestet wird. So kann ich grobe Fehleinschätzungen korrigieren, bevor du Vorschläge ableitest.

Frag mich außerdem, ob dieses Repository zu einem Projekt mit mehreren Repositories gehört. Wenn ja, frag, welche Repositories dazugehören, wofür sie zuständig sind und wo gemeinsame Fachbegriffe gepflegt werden. Für die AGENTS.md schlägst du dann einen kurzen Abschnitt mit diesen Angaben vor. Gemeinsame Begriffe übernimmst du von dort, sofern ich dir den Ort zugänglich mache, statt eigene Definitionen zu formulieren.

## Phase 2: Vorschläge ableiten

Sammle Kandidaten in vier Gruppen:

A. AGENTS.md: Build-, Test- und Lint-Befehle, soweit sie nicht offensichtlich sind; Architekturregeln und Modulgrenzen; Konventionen für Benennung, Branches und Commits; Fallstricke, an denen ein Agent wahrscheinlich scheitern würde; Hinweise auf veraltete Dokumente, die ein Agent nicht als gültig behandeln soll.

B. GLOSSARY.md: Fachbegriffe der Domäne, die im Code, in der Oberfläche oder in der Dokumentation mit fester Bedeutung verwendet werden und nicht selbsterklärend oder mehrdeutig sind. Pro Begriff eine kurze Definition und gegebenenfalls Synonyme, die vermieden werden sollen. Keine allgemeinen Technikbegriffe. Begriffe, deren Bedeutung erst geklärt werden müsste, gehören in Gruppe D.

C. ADR-Kandidaten: Entscheidungen, die schwer rückgängig zu machen sind, ohne Kontext überraschend wirken und auf einer echten Abwägung beruhen. Beschreibe, was du beobachtet hast, welche Alternative naheliegend gewesen wäre und was du über die Gründe wissen müsstest. Einen ADR entwirfst du erst, wenn ich dir die Begründung geliefert habe.

D. Offene Fragen und Auffälligkeiten: Widersprüche zwischen Dokumentation und Code, veraltete oder doppelte Anweisungen, unklare Begriffe und alles, was du nicht einordnen konntest.

## Phase 3: Vorschläge in Runden abstimmen

Leg mir die Vorschläge gruppenweise vor, beginnend mit Gruppe A, mit höchstens etwa zehn Vorschlägen pro Runde und den wichtigsten zuerst. Nummeriere jeden Vorschlag (A1, A2, ...) und gib jeweils an:

- den vorgeschlagenen Text, so wie er in die Datei kommen würde
- die Zieldatei und gegebenenfalls den Abschnitt
- die Fundstelle
- deine Sicherheit (hoch, mittel, niedrig)

Ich antworte pro Nummer mit „übernehmen“, „ändern“ (mit meiner Korrektur) oder „verwerfen“. Bei ADR-Kandidaten liefere ich die Begründung oder verwerfe den Kandidaten. Frag nach, wenn eine Antwort unklar ist, und geh erst zur nächsten Runde über, wenn die aktuelle abgeschlossen ist.

## Phase 4: Bestätigte Vorschläge schreiben

Schreibe nach jeder abgeschlossenen Runde ausschließlich die bestätigten Vorschläge in der bestätigten Fassung. Fasse zum Schluss zusammen, welche Dateien du geändert hast, welche Vorschläge verworfen wurden und welche Fragen offen geblieben sind. Ich prüfe den Diff und übernehme die Änderungen anschließend per Pull Request.
````
