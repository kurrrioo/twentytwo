+++
date = '2026-09-24T17:23:00Z'
draft = false
title = 'Hugo im Codespace lokal testen und veröffentlichen'
+++

## Voraussetzungen

Dieses Repository enthält die Hugo-Website im Unterordner `whoami`. Die
folgenden Befehle werden daher aus dem Repository-Hauptverzeichnis ausgeführt.
Nach dem Erstellen eines neuen Codespaces müssen im Hugo-Verzeichnis zunächst
die Go-Module eingerichtet werden:

```sh
cd whoami
hugo mod tidy
```

## Hugo im Codespace starten

Zum Testen der Website startet man den Hugo-Entwicklungsserver mit:

```sh
hugo server -D --bind 0.0.0.0 --port 1313
```

Die Optionen haben folgende Bedeutung:

- `server` startet den Entwicklungsserver.
- `-D` (`--buildDrafts`) nimmt auch Beiträge mit `draft = true` in die
  Vorschau auf. Ohne dieses Flag werden Drafts ausgeblendet — genau das
  Verhalten, das später beim Deployment gewünscht ist.
- `--bind 0.0.0.0` macht den Server innerhalb des Codespaces erreichbar. Eine
  Bind-Adresse wie `127.0.0.1` wäre nur innerhalb des Codespaces erreichbar.
- `--port 1313` verwendet den üblichen Hugo-Port.

Der Server bleibt im Terminal aktiv. Zum Beenden genügt `Ctrl+C`.

## Port zum lokalen Rechner weiterleiten

In einem zweiten lokalen Terminal wird der Port des Codespaces weitergeleitet:

```sh
gh codespace ports forward 1313:1313 --codespace "$CSname"
```

Dabei steht der erste Port für den lokalen Rechner und der zweite für den
Codespace. `$CSname` muss den Namen des gewünschten Codespaces enthalten, zum
Beispiel:

```sh
CSname="mein-codespace"
gh codespace ports forward 1313:1313 --codespace "$CSname"
```

Anschließend ist die Vorschau unter
[http://localhost:1313](http://localhost:1313) erreichbar. Der Bind-Befehl
und die Portweiterleitung gehören zusammen: Hugo muss auf `0.0.0.0` lauschen,
damit die Weiterleitung den Server erreicht.

## Deployment-Script ausführen

Das Deploy-Script liegt im Repository-Hauptverzeichnis und wird von dort
gestartet:

```sh
./deploy.sh
```

Der aktuelle Stand des Scripts ist hier einsehbar:
[deploy.sh (Raw)](https://github.com/kurrrioo/kurrrioo.github.io/raw/refs/heads/master/deploy.sh)

Falls die Datei noch nicht ausführbar ist, kann die Berechtigung einmalig
gesetzt werden:

```sh
chmod +x deploy.sh
```

Vor dem eigentlichen Build prüft das Script einige Voraussetzungen und bricht
bei Problemen mit einer klaren Fehlermeldung ab: ob `git` und `hugo`
installiert sind, ob das Script innerhalb eines Git-Repositories liegt, ob
`whoami/hugo.toml` existiert und ob das Remote `origin` konfiguriert ist.

### Was das Script macht — Schritt für Schritt für GitHub-Einsteiger

Wer neu bei Git und GitHub ist, findet in einem Deploy-Script schnell
Begriffe, die zunächst verwirrend wirken. Die folgenden Abschnitte erklären
die wichtigsten Konzepte anhand des Scripts.

**Branches: zwei getrennte "Zustände" desselben Repositories**

Ein Git-Repository kann mehrere sogenannte Branches (Zweige) enthalten. Man
kann sich das wie mehrere parallele Versionen desselben Ordners vorstellen,
die sich unabhängig voneinander weiterentwickeln. In diesem Projekt gibt es
zwei relevante Branches:

- `master` enthält den **Quellcode**: die Hugo-Konfiguration, Markdown-Dateien
  wie diesen Blogpost, Templates usw.
- `gh-page` enthält das **fertige, gebaute Ergebnis**: reine HTML-, CSS- und
  JavaScript-Dateien, die ein Browser direkt anzeigen kann.

GitHub Pages liest nur den zweiten Branch aus und stellt dessen Inhalt als
Website bereit. Der Quellcode im `master`-Branch wird von GitHub Pages nicht
interpretiert — Hugo muss ihn erst in fertiges HTML "übersetzen" (bauen).

**Warum ein Build nötig ist**

Hugo-Markdown-Dateien sind kein direkt darstellbares Website-Format. Der
Befehl `hugo` liest alle Inhalte im Hugo-Projekt und erzeugt daraus statische
Dateien. Dieser Vorgang heißt "Build". Erst diese gebauten Dateien werden
veröffentlicht, nicht die Markdown-Quellen selbst.

**Was ein "Worktree" ist**

Normalerweise kann man in einem lokalen Git-Ordner immer nur einen Branch
gleichzeitig ausgecheckt haben. Ein `git worktree` erlaubt es, einen zweiten
Branch (hier: `gh-page`) parallel in einem eigenen, temporären Ordner
verfügbar zu machen — ohne den aktuellen `master`-Branch zu verlassen oder
dessen ungesicherte Änderungen zu gefährden. Das Script legt diesen
temporären Ordner selbst an und entfernt ihn am Ende automatisch wieder.

**Der Ablauf im Detail**

1. **Referenz aktualisieren:** Das Script lädt zunächst den aktuellen Stand
   von `origin/gh-page` herunter, um sicherzustellen, dass später nichts
   überschrieben wird, was zwischenzeitlich von anderer Stelle verändert
   wurde.

2. **Bauen:** Hugo erzeugt aus dem Quellcode in `whoami` eine fertige Website
   in einem temporären Build-Ordner. Dabei wird die `baseURL` explizit auf
   die echte Ziel-Adresse (`https://kurrrioo.github.io/`) gesetzt — unabhängig
   davon, was in der lokalen `hugo.toml` für die Entwicklung eingetragen ist.

3. **Worktree vorbereiten:** Das Script öffnet den `gh-page`-Branch in einem
   separaten, temporären Ordner, leert dessen Inhalt und kopiert den frisch
   gebauten Website-Code hinein. Eine leere Datei `.nojekyll` wird ebenfalls
   angelegt; sie weist GitHub an, den Inhalt nicht zusätzlich mit einem
   eigenen Verarbeitungssystem (Jekyll) zu bearbeiten, was bei Hugo-Websites
   zu Problemen führen könnte.

4. **Commit und Push:** Die neuen Dateien werden im `gh-page`-Branch
   committet — also als neuer, dokumentierter Änderungsstand festgehalten —
   und anschließend mit `git push` zum GitHub-Server hochgeladen. Erst durch
   diesen Push wird die Änderung tatsächlich online sichtbar. Gibt es gar
   keine inhaltlichen Unterschiede zum letzten Stand, bricht das Script an
   dieser Stelle ohne Commit ab, um leere Änderungen zu vermeiden.

5. **Aufräumen:** Am Ende entfernt das Script automatisch sowohl den
   temporären Worktree-Ordner als auch den Build-Ordner — unabhängig davon,
   ob alles erfolgreich durchgelaufen ist oder das Script vorher wegen eines
   Fehlers abgebrochen wurde. Das eigentliche Arbeitsverzeichnis (`master`)
   bleibt davon zu jedem Zeitpunkt unberührt.

**Was das für den `master`-Branch bedeutet**

Ein großer Vorteil dieses Ansatzes: Weil mit einem Worktree statt mit
`git checkout` gearbeitet wird, bleibt man während des gesamten Deployments
durchgehend auf dem `master`-Branch. Es entsteht kein Zeitpunkt, an dem der
Arbeitsordner unerwartet den Inhalt wechselt, und lokale, noch nicht
committete Änderungen auf `master` werden vom Deployment nicht beeinflusst.

### Vor dem Deployment beachten

Branch, Ziel-URL und Commit-Nachricht lassen sich über Umgebungsvariablen
anpassen, ohne das Script selbst zu verändern:

```sh
DEPLOY_BRANCH="gh-pages" SITE_URL="https://example.org" ./deploy.sh
```

Der Standard-Zielbranch im Script ist `gh-page`. GitHub Pages erwartet
üblicherweise `gh-pages` (mit „s") — die Pages-Einstellung im Repository muss
exakt auf den Branch zeigen, in den tatsächlich gepusht wird, sonst wird der
Build zwar erzeugt, aber nicht veröffentlicht. Außerdem muss der Remote
`origin` auf das GitHub-Repository zeigen und Schreibrechte auf den
Zielbranch besitzen.