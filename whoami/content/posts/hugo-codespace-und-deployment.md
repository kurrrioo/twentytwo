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