<!--
  PR-Template nach Definition of Done 2.0 — siehe Blueprint, Kapitel 5.
  Verwendung: Diese Datei ins eigene Repo kopieren, damit jeder PR die Checkliste
  automatisch trägt — auf GitHub als `.github/PULL_REQUEST_TEMPLATE.md`. Andere
  Plattformen erwarten PR-Vorlagen an einem eigenen Ablageort, etwa GitLab unter
  `.gitlab/merge_request_templates/` oder Azure DevOps unter
  `.azuredevops/pull_request_template.md` (siehe Blueprint, Kapitel 5.3).

  Tipp: Nicht jeder Punkt muss ausschließlich manuell geprüft werden. Ein Agent kann
  beim Erstellen des PRs kontrollieren, ob das AI-Review gelaufen ist, die Dokumentation
  konsistent ist und Funktionstests nachgewiesen sind, und das Ergebnis im PR festhalten.
  Die menschliche Prüfung der Funktionalität (Punkt 4) ersetzt das nicht.
-->

## Zusammenfassung

<!-- Was wurde geändert und warum? Ticket/Sub-Issue und ggf. Spec verlinken. -->

## Definition of Done 2.0

### Grundlegende Qualitätsanforderungen — gelten für jeden Change

- [ ] **1 · Developer Ownership** — Ich verstehe die Umsetzung als Ganzes (Aufbau, Funktionsweise, Zusammenhang der Teile) und übernehme die Verantwortung. *Prüffrage: Könnte ich einem Kollegen erklären, wie dieses Feature gebaut ist und warum — ohne den Chat-Verlauf zu öffnen?*
- [ ] **2 · Requirement Validation** — Gegen Spec und Akzeptanzkriterien abgeglichen: Jede Anforderung ist erfüllt, nichts Unbestelltes ist zusätzlich gebaut (kein Scope Creep). *Prüffrage: Kann ich jede Änderung im Diff einem Satz im Ticket zuordnen — und jeden Satz im Ticket einer Änderung?*
- [ ] **3 · Technical Validation** — Tests, Typechecking, Linting, Build und weitere Quality-Checks sind gelaufen und grün, vor der Übergabe einschließlich der vollständigen Test-Suite. *Prüffrage: Habe ich die Ausgabe der Checks gesehen — oder nehme ich nur an, dass sie durchlaufen?*
- [ ] **4 · Human-Verified Functionality** — Ich habe das Feature selbst am laufenden System nachvollzogen und es entspricht den fachlichen Erwartungen. KI-gestützte Funktionstests (z. B. Playwright) können unterstützen, ersetzen diese Prüfung aber nicht. *Prüffrage: Habe ich das Feature selbst laufen sehen — oder verlasse ich mich nur auf Tests und Agenten?*
- [ ] **5 · Risk Review** — Security, Privacy, Wartbarkeit, Lizenzen und Architektur sind berücksichtigt. *Prüffrage: Welchen Schaden könnte dieser Change im schlimmsten Fall anrichten — und habe ich diesen Pfad geprüft?*
- [ ] **6 · Transparent Pull Request** — Zusammenfassung, Test-Nachweise, bekannte Risiken und KI-Kontext stehen in diesem PR (Abschnitte unten). *Prüffrage: Kann der Reviewer aus der PR-Beschreibung allein entscheiden, wo er genau hinschauen muss?*

### Ergänzungen aus dem AI Workflow

<!-- Diese beiden Punkte kann auch der Agent selbst prüfen und abhaken (siehe Hinweis oben). -->

- [ ] **7 · AI-Review abgeschlossen und Findings bearbeitet** — `/code-review` bzw. das projekteigene Review ist über die Änderungen gelaufen; jedes Finding ist behoben oder mit nachvollziehbarer Begründung am PR zurückgewiesen.
- [ ] **8 · Projektstand und Dokumentation aktuell und konsistent** — Tickets und Spec spiegeln den tatsächlichen Endstand; neue Begriffe stehen in `GLOSSARY.md`, neue Konventionen in `AGENTS.md`/`CLAUDE.md`, relevante Architekturentscheidungen in ADRs. Keine stillen Widersprüche zu Glossar oder ADRs; bewusst geänderte Entscheidungen sind samt Begründung aktualisiert.

## Test-Nachweise

<!-- Welche Tests und Checks liefen (Ausgabe/Screenshot), was wurde manuell verifiziert? -->

## Bekannte Risiken / offene Punkte

<!-- Was sollte der Reviewer wissen? Wo besteht Restunsicherheit? -->

## KI-Kontext

<!-- Wo hat KI substanziell mitgewirkt? Keine Beichte, sondern Kontext: Der Reviewer liest generierte Abschnitte mit dem richtigen Blick. -->
