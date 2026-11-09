# Templates

Vorlagen zum Kopieren ins eigene Projekt — die praktischen Gegenstücke zu den Kapiteln des [Blueprints](../BLUEPRINT.md).

| Template | Zweck | Blueprint-Kapitel |
|---|---|---|
| [`setup-prompt.md`](setup-prompt.md) | Setup-Prompt zur Grundbefüllung: Der Agent untersucht das Repository und schlägt Inhalte für `AGENTS.md`, Glossar und ADR-Kandidaten vor; geschrieben wird erst nach Bestätigung (auch in Anhang C abgedruckt) | Kapitel 8 (Schritt 2), Anhang C |
| [`pr-template-dod.md`](pr-template-dod.md) | PR-Template mit der DoD-2.0-Checkliste (auf GitHub als `.github/PULL_REQUEST_TEMPLATE.md` ins Ziel-Repo kopieren; Ablageorte anderer Plattformen in Kapitel 5.3) | Kapitel 5 |
| [`skills/code-review/`](skills/code-review/) | Repo-eigenes Review am Beispiel eines Python/FastAPI-Backends: schlanker Einstieg (`SKILL.md`) plus Referenz-Files je Prüfbereich (Security, Architektur, Clean Code, Tests, Domain-Integrität), Schweregrad-Rubrik, PR-fertiger Report | Kapitel 4.5, 6.1, 8 (Schritt 6) |
| [`skills/dependabot-prs/`](skills/dependabot-prs/) | Automatisierte Dependabot-PR-Verarbeitung für ein Frontend- und ein Backend-Repo: prüft, fixt und merget grüne PRs, meldet nur, was menschliches Urteil braucht | Kapitel 6.2 |

> [!IMPORTANT]
> Die Beispiel-Skills sind **Vorlagen, keine Drop-ins**: Sie sind aus einem internen Referenzprojekt hervorgegangen und für diese Veröffentlichung neutralisiert. Pfade, Domänennamen und Regeln beschreiben ein fiktives Beispielprojekt. Sie zeigen, wie ein fertig customizter Skill aussieht. Fürs eigene Projekt werden die projektspezifischen Teile durch die eigenen Konventionen ersetzt (Kapitel 6).

## Quellen

Aufbau und Teile der Prüfdimensionen des Code-Review-Skills sind angelehnt an den Skill `code-review` aus der [Skill-Library von Matt Pocock](https://github.com/mattpocock/skills) (MIT License, Copyright (c) 2026 Matt Pocock). Die Bezeichnungen der Code Smells folgen dem Refactoring-Katalog von Martin Fowler.
