#!/bin/bash
echo "Starte Build..."
cd whoami
rm -rf public
hugo --minify
cd ..

echo "Pushe in gh-pages Branch..."
git subtree push --prefix whoami/public origin gh-pages
echo "Fertig!"