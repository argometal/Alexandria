git add .
git commit -m "lighting stable corridor baseline"

====================================
Para marcarlo como stable real (no solo commit normal), tienes dos opciones:

###Opción 1 — Tag (recomendado)

Esto congela exactamente ese punto:

git tag stable-v0-lighting
git tag

Verás el tag listado.
Ese tag es tu ancla permanente.
====================================
Para volver ahí en el futuro:

git checkout stable-v0-lighting
Opción 2 — Branch estable
====================================
Si quieres seguir trabajando sin tocar ese estado:

git branch stable-lighting

Eso crea una rama que apunta exactamente a este commit.

Recomendación técnica limpia:

Usa tag para “stable confirmado”.
Usa branch para “línea alternativa de trabajo”.

======================================
commit format to use each chat iteration
git status
git add .
git commit -m "xx locus editor stable — children groundwork — create child intent wired"
git tag -a vxx_locus_editor -m "vxx_locus_editor"
git log --oneline --decorate -5
git push
git push --tags

git reset --hard 0aab2dd

======================================
cd "C:\Raz 13\alexandria"
git add .
git commit -m "RAZ12 builder - bridge watcher"

cd "..\alexandria-gatekeeper-v-13.2"
git add .
git commit -m "RAZ13.2 gatekeeper - bridge writer"