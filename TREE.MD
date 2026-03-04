1️⃣ Mapa de archivos
git ls-files > repo_map.txt
2️⃣ Árbol real de carpetas

En Windows:

tree /F /A > tree_map.txt

### Code Map
Get-ChildItem -Recurse -Include *.dart,*.cs,*.gd,*.ts,*.json,*.sql |
Select-Object FullName |
Out-File code_map.txt


3️⃣ Estado actual de commits
git log --oneline --graph --decorate --all > git_history.txt

Eso te genera:

repo_map.txt

tree_map.txt

git_history.txt

Con eso puedo ver:

Qué archivos existen

Estructura real

Qué commits hay

Qué branches existen

No necesito más que eso para entender el estado físico del repo.