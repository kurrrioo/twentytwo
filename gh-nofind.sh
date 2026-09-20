#!/bin/bash
git stash
# 1. Build im Unterordner
echo "Starte Hugo Build..."
cd whoami
rm -rf public
hugo --minify
cd ..

# 2. Inhalt in einen temporären Ordner sichern
echo "Sichere Build-Dateien..."
rm -rf ../temp_site_deploy
mkdir ../temp_site_deploy
cp -r whoami/public/* ../temp_site_deploy/

# 3. Zum gh-page Branch wechseln
git checkout gh-page

# 4. Radikale Bereinigung: Lösche alles außer den Git-Ordner
# Dies ist sicher, da wir im 'gh-page' Branch sind
git rm -rf . > /dev/null 2>&1

# 5. Build-Dateien zurückholen
cp -r ../temp_site_deploy/* .

# 6. Falls du eine .nojekyll Datei brauchst (sehr empfohlen für Hugo!)
# Damit umgehst du, dass GitHub versucht, Jekyll über deine Seite laufen zu lassen
touch .nojekyll

# 7. Commit & Push
git add .
git commit -m "Deploy: Update site content"
git push origin gh-page --force

# 8. Zurück zum master Branch
git checkout master
rm -rf ../temp_site_deploy
echo "Deployment auf gh-page abgeschlossen!"