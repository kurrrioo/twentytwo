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

# 4. Bereinigung: Wir löschen nur die Dateien/Ordner im Root,
# die NICHT der Build-Inhalt sein sollen.
# Wir löschen NICHT den Ordner 'whoami' selbst, sondern nur seinen Inhalt,
# falls dort Reste liegen, und alle anderen Dateien im Root.
echo "Bereinige gh-page Branch..."
# Alles im Root löschen, was nicht .git oder whoami ist
find . -maxdepth 1 -not -name '.' -not -name '.git' -not -name '..' -not -name 'whoami' -exec rm -rf {} +

# 5. Jetzt den Inhalt von whoami/public (der in temp liegt) ins Root verschieben
# (Wir überschreiben das alte whoami/public im gh-page Branch nicht,
# sondern legen die Webseiten-Dateien direkt ins Root)
cp -r ../temp_site_deploy/* .

# 6. Jetzt löschen wir den Ordner 'whoami' im gh-page Branch,
# damit nur die Webseite übrig bleibt
rm -rf whoami

# 7. Commit & Push
git add .
git commit -m "Deploy: Update site content"
git push origin gh-page

# 8. Zurück zum master Branch
git checkout master
rm -rf ../temp_site_deploy
echo "Deployment auf gh-page abgeschlossen!"