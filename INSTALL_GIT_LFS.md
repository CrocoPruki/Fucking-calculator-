Instrukcja instalacji git-lfs lokalnie (kopiuj i wklej w terminal)

Czyszczenie ewentualnych, nieudanych pobrań:
```bash
rm -f /tmp/git-lfs.tar.gz
rm -rf /tmp/git-lfs-*
```

Pobranie i instalacja `git-lfs` lokalnie do `~/bin`:
```bash
mkdir -p ~/bin
curl -sL "https://github.com/git-lfs/git-lfs/releases/latest/download/git-lfs-linux-amd64.tar.gz" -o /tmp/git-lfs.tar.gz
tar -xzf /tmp/git-lfs.tar.gz -C /tmp
find /tmp -maxdepth 2 -type f -name git-lfs -print
# jeśli powyżej zwróci ścieżkę np. /tmp/git-lfs-2.13.3/git-lfs
cp /tmp/<rozpakowany-folder>/git-lfs ~/bin/
chmod +x ~/bin/git-lfs
export PATH="$HOME/bin:$PATH"
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.profile
```

Inicjalizacja i weryfikacja:
```bash
git lfs install
git lfs version
```

Konfiguracja śledzenia GIF-ów i przygotowanie commitów:
```bash
cd /workspaces/Fucking-calculator-
git lfs track "*.gif"
git add .gitattributes
# jeśli GIF-y były już zatwierdzone, usuń je z indeksu i dodaj ponownie (przeniesienie do LFS)
git rm --cached -r --ignore-unmatch "*.gif"
git add "*.gif"
git commit -m "Move GIFs to Git LFS"
git push origin main
```

Uwaga: jeżeli chcesz przepisać historię (gdy GIFy są w wcześniejszych commitach), użyj:
```bash
git lfs migrate import --include="*.gif"
git push --force origin main
```

Jak skopiować tekst na Android (Codespaces web):
- Otwórz ten plik w Codespaces (explorer → INSTALL_GIT_LFS.md).
- Długo przytrzymaj tekst, przeciągnij uchwyty i wybierz "Kopiuj".
- Jeśli nie możesz zaznaczyć: w przeglądarce włącz "Request desktop site" (tryb pulpitu), odśwież i spróbuj ponownie.
- Alternatywnie: otwórz terminal w Codespaces, wpisz `cat INSTALL_GIT_LFS.md`, potem dłuższe przytrzymanie i kopiuj z terminala.

Jeśli coś pójdzie nie tak, wklej tu output (błędy) — pomogę dalej.
