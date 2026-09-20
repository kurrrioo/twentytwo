i#!/bin/bash

# 1. Build im Unterordner
echo "Starte Hugo Build..."
cd whoami
rm -rf public
hugo --minify --config hugo.toml --destination public
cd ..

# 2. Inhalt in einen temporären Ordner außerhalb des Repo-Stammverzeichnisses sichern
echo "Sichere Build-Dateien..."
rm -rf ../temp_site_deploy
mkdir ../temp_site_deploy
cp -r whoami/public/* ../temp_site_deploy/

# 3. Zum gh-page Branch wechseln
git checkout gh-page

# 4. Alles löschen (außer .git und den temp Ordner)
echo "Bereinige gh-page Branch..."
find . -maxdepth 1 -not -name '.' -not -name '.git' -not -name '..' -not -name 'temp_site_deploy' -exec rm -rf {} +

# 5. Daten aus dem Temp-Ordner ins Root holen
cp -r ../temp_site_deploy/* .

# 6. Aufräumen: Entwickler-Dateien im gh-page Branch entfernen
rm -f .gitignore gh.sh

# 7. Commit & Push
git add .
git commit -m "Deploy: Update site content"
git push origin gh-page

# 8. Zurück zum master Branch
git checkout master
rm -rf ../temp_site_deploy
echo "Deployment auf gh-page abgeschlossen!"