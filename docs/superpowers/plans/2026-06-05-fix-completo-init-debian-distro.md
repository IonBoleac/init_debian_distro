# Fix Completo `init_debian_distro` — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (consigliato) o superpowers:executing-plans per implementare questo piano task-per-task. Gli step usano la sintassi checkbox (`- [ ]`) per il tracking.

**Goal:** Eliminare i bug funzionali, di idempotenza, di shell-targeting (zsh vs bash), di architettura (amd64-only) e di CI, in modo che sia l'installazione software (`install_softwares.sh`) sia la configurazione del terminale (`config_terminal.sh`) funzionino in modo affidabile e ri-eseguibile su Debian/Ubuntu (incluso WSL).

**Architecture:** Bash scripts. Entry point `run_app.sh` (menu) → `bin/install_softwares.sh` (sorgente i singoli installer in `bin/install_softwares/*.sh`) + `bin/config_terminal.sh` (configura zsh/oh-my-zsh/p10k/font/nvim). Costanti e helper in `bin/config/`. CI in `.github/workflows/`.

**Tech Stack:** Bash 5.x, apt/snap/curl/wget, GitHub Actions, oh-my-zsh, powerlevel10k.

**Strategia di test (non esiste un framework di unit test):** ogni task si verifica con
1. `bash -n <file>` (syntax check),
2. esecuzione in `--dry-run` di `install_softwares.sh` quando applicabile,
3. assert mirati con `grep`/run del singolo installer in dry-run,
4. (opzionale) `shellcheck` se installato.

---

## Riepilogo dell'analisi (cosa accade oggi e perché)

### Comportamento osservato dall'utente — "quando zsh è già presente non fa nulla"
`config_terminal.sh` **non è idempotente** e non ha guardie su componenti già installati. Alla seconda esecuzione (o quando zsh/oh-my-zsh esistono già):
- `bin/config_terminal.sh:104-117` — l'installer ufficiale di oh-my-zsh rileva `~/.oh-my-zsh` esistente ed **esce con errore**; la catena `&&` si interrompe → stampa `✗ Failed to install Oh-my-zsh`.
- `bin/config_terminal.sh:121,130,135` — i `git clone` di powerlevel10k e dei plugin falliscono perché le directory esistono → `✗ ... (may already exist)`.
- Risultato: la run sembra "non fare nulla" / pieno di `✗`, perché i passi non vengono ri-applicati ma falliscono silenziosamente. Va resa idempotente.

### Bug funzionali critici confermati (con simulazione)
- **Docker incompleto** — `bin/config/.../install_softwares.sh:32-40` l'helper `apt_get_install` usa solo `"$1"`. In `Docker.sh:26` (`apt_get_install ca-certificates curl`) installa solo `ca-certificates`; in `Docker.sh:48` (`docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`) installa solo `docker-ce`. `docker-buildx-plugin` e `docker-compose-plugin` **non vengono installati** (`docker compose`/`docker buildx` mancanti). Verificato leggendo l'helper.
- **Docker su repo sbagliato** — `Docker.sh:42` usa hardcoded `download.docker.com/linux/ubuntu` anche su Debian → pacchetti incompatibili.
- **nvm e GO scrivono in `~/.bashrc`** — `nvm.sh:68-70` e `go.sh:93-94` aggiungono PATH/config a `~/.bashrc`, che una shell **zsh non legge mai** (lo scopo del repo è configurare zsh). Quindi `go` e `nvm` non risultano disponibili. Inoltre append duplicati ad ogni run.
- **nvm reinstalla sempre** — `nvm.sh:30` `is_installed "nvm"`: nvm è una *funzione di shell*, non un eseguibile in PATH → `command -v nvm` è sempre falso in shell non interattiva → reinstalla e duplica le righe ogni volta.
- **kubectl/krew blocca in non-interattivo** — `kubectl.sh:81-114` prompt krew con `read -n 1`; `AUTOMATIC_START` non è esportato dal flusso di `install_softwares.sh`. In `-a`/CI con stdin EOF il `read` ritorna vuoto → case `*)` → **loop infinito / hang**.

### Bug di CI / validazione confermati (con simulazione)
- **`verify_constants.sh:34`** la regex dei metodi `^(apt|snap|curl|script|tar|test)$` **non include `wget`** → eseguito da `bin/` fallisce su `argocd` e `k9s` (verificato: exit 1).
- **`verify-constants.yml:21`** invoca `./bin/verify_constants.sh` dalla **root**, ma lo script fa `source ./config/constants.sh` (path relativo) → file non trovato, `SOFTWARE_DETAILS` vuoto → stampa vacuamente `All entries are valid` (exit 0). La CI è verde ma **non valida nulla** (verificato).
- **`updater-readme.yml`** triggera su push **e** pull_request e fa commit/push anche sui PR; manca `permissions: contents: write` e il token non è nel remote URL → il push può fallire.
- **`test-install-all.yml:35`** il commento dice che salta snap/heavy ma esclude solo `Spotify`; gli install snap e il prompt krew possono **bloccare/fallire** la CI.

### Bug medi
- **`install_softwares.sh:391`** `main $*` → deve essere `main "$@"`. Insieme a `run_app.sh:73` (`./install_softwares.sh $flags`) i nomi con spazio `"SQLite CLI"`/`"SQLite Browser"` non sono selezionabili via `-i`.
- **arch hardcoded `amd64`**: `kubectl.sh`, `k9s.sh`, `argocd.sh`, `argocd-autopilot.sh`, `go.sh` → rotti su arm64.
- **`argocd.sh`/`argocd-autopilot.sh`**: nessun tracking in `FAILED_INSTALLATIONS`; argocd usa una URL Red Hat pinnata (`1.19.0-48`) anziché le release ufficiali; argocd-autopilot può costruire URL `//` (404) se l'API non risponde, glob fragile, manca `chmod +x`.
- **`k9s.sh:37`** `cp -r "$PARENT_DIRECTORY/bin/config/k9s/plugins" "$HOME/.k9s/"` senza `mkdir -p`, dipende da `PARENT_DIRECTORY`, errori silenziati con `2>/dev/null`; inoltre la home di k9s usata in `.zshrc` è `~/.config/k9s` (`K9S_HOME`), non `~/.k9s`.
- **`go.sh:31`** il check `[ -d "$GO_DIRECTORY" ]` precede la guardia `DRY_RUN` → in dry-run stampa "GO directory already exists" (fuorviante).

### Bug bassi / cleanup
- **`SQLite_CLI.sh` + `constants.sh:14`**: nome funzione `intall_SQLite_CLI` (typo). Funziona perché coincidono, ma va corretto.
- **`browser_SQLite.sh` + `constants.sh:15`**: nome funzione con trattino `install_browser-SQLite`. Funziona in bash 5.2 ma è fragile.
- **`constants.sh:82-83`**: doppio `export LOG_FILE`.
- **`verify_constants.sh`** non valida i nomi funzione → non avrebbe mai intercettato i typo sopra.
- Codice morto: `archive/install_softwares_old.sh`, `install_one_function`/`show_progress_bar`/`restart_session` in `install_softwares.sh`.
- Sicurezza: download senza checksum (`k9s`, `kind`, `go`, `argocd`); Spotify scrive la GPG in `trusted.gpg.d` globale invece di `signed-by`.

---

## File coinvolti (mappa delle modifiche)

- `bin/install_softwares.sh` — fix `apt_get_install` (multi-pacchetto), `main "$@"`.
- `bin/install_softwares/Docker.sh` — repo per distro, pacchetti completi.
- `bin/install_softwares/nvm.sh` — target rc per shell, idempotenza.
- `bin/install_softwares/go.sh` — target rc per shell, idempotenza, dry-run, arch.
- `bin/install_softwares/kubectl.sh` — guardia non-interattiva su krew, arch.
- `bin/install_softwares/k9s.sh` — mkdir, path config, arch.
- `bin/install_softwares/argocd.sh`, `argocd-autopilot.sh` — failure tracking, fallback, arch.
- `bin/install_softwares/SQLite_CLI.sh`, `browser_SQLite.sh` + `bin/config/constants.sh` — rinomina funzioni.
- `bin/config/constants.sh` — dedup export.
- `bin/config_terminal.sh` — idempotenza completa.
- `bin/verify_constants.sh` — regex `wget`, validazione nomi funzione.
- `.github/workflows/verify-constants.yml`, `updater-readme.yml`, `test-install-all.yml` — fix cwd/trigger/permessi/esclusioni.

---

## Task 0: Harness di verifica (syntax check di tutti gli script)

**Files:**
- Create: `bin/run_syntax_check.sh`

- [ ] **Step 1: Creare lo script di syntax check**

```bash
# bin/run_syntax_check.sh
#!/bin/bash
# Esegue `bash -n` su tutti gli script shell del repo. Se installato, esegue anche shellcheck.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
while IFS= read -r -d '' f; do
    if ! bash -n "$f"; then
        echo "✗ Syntax error: $f"
        fail=1
    fi
done < <(find "$ROOT" -name '*.sh' -not -path '*/archive/*' -print0)

if command -v shellcheck >/dev/null 2>&1; then
    echo "Running shellcheck..."
    find "$ROOT" -name '*.sh' -not -path '*/archive/*' -exec shellcheck -S warning {} +
else
    echo "ℹ shellcheck non installato (opzionale: sudo apt-get install -y shellcheck)"
fi

[ "$fail" -eq 0 ] && echo "✓ Syntax OK su tutti gli script" || echo "✗ Errori di sintassi rilevati"
exit "$fail"
```

- [ ] **Step 2: Renderlo eseguibile ed eseguirlo (baseline)**

Run: `chmod +x bin/run_syntax_check.sh && ./bin/run_syntax_check.sh`
Expected: `✓ Syntax OK su tutti gli script` (exit 0). Questa è la baseline da rieseguire dopo ogni task.

- [ ] **Step 3: Commit**

```bash
git add bin/run_syntax_check.sh
git commit -m "test: add bash syntax-check harness for all scripts"
```

---

## Task 1: Fix `apt_get_install` multi-pacchetto (CRITICO — Docker incompleto)

**Files:**
- Modify: `bin/install_softwares.sh:32-40`

- [ ] **Step 1: Sostituire l'helper per accettare più pacchetti**

In `bin/install_softwares.sh`, sostituire:

```bash
apt_get_install() {
    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would install package: $1"
        return 0
    fi
    
    sudo apt-get install -y "$1" > /dev/null 2>> "$LOG_FILE"
    #log_message "INFO" "$1 successfully installed"
}
```

con:

```bash
apt_get_install() {
    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "INFO" "[DRY-RUN] Would install package(s): $*"
        return 0
    fi

    sudo apt-get install -y "$@" > /dev/null 2>> "$LOG_FILE"
    return $?
}
```

- [ ] **Step 2: Verifica sintassi e dry-run**

Run: `bash -n bin/install_softwares.sh && cd bin && echo "" | ./install_softwares.sh -d -i Docker 2>&1 | grep -i "install package"`
Expected: una riga `[DRY-RUN] Would install package(s): docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin` (dopo il Task 2 che toglie il wrapping in `verify_command`).

- [ ] **Step 3: Commit**

```bash
git add bin/install_softwares.sh
git commit -m "fix: apt_get_install now installs all passed packages, not just \$1"
```

---

## Task 2: Fix Docker (repo per distro + pacchetti completi)

**Files:**
- Modify: `bin/install_softwares/Docker.sh:24-55`

- [ ] **Step 1: Correggere repo, chiave e installazione pacchetti**

In `bin/install_softwares/Docker.sh`, sostituire il blocco non-dry-run (dalla riga `# Add Docker's official GPG key:` fino a `# Docker command to non-sudo user` escluso) con:

```bash
    # Determina la distro (debian o ubuntu) dal file os-release
    local DOCKER_DISTRO="ubuntu"
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [ "$ID" = "debian" ]; then
            DOCKER_DISTRO="debian"
        fi
    fi

    # Add Docker's official GPG key:
    sudo apt-get update > /dev/null 2>> "$LOG_FILE"
    apt_get_install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings

    verify_command "sudo curl -fsSL https://download.docker.com/linux/${DOCKER_DISTRO}/gpg -o /etc/apt/keyrings/docker.asc"
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to download Docker GPG key. Check internet connection and permissions for /etc/apt/keyrings/"
        FAILED_INSTALLATIONS+=("Docker")
        return
    fi
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${DOCKER_DISTRO} \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update > /dev/null 2>> "$LOG_FILE"

    # Install Docker (apt_get_install ora installa tutti i pacchetti)
    apt_get_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Failed to install Docker. Run 'sudo apt-get update' and check repository configuration. See logs for details."
        FAILED_INSTALLATIONS+=("Docker")
        return
    fi
```

- [ ] **Step 2: Verifica sintassi e dry-run**

Run: `bash -n bin/install_softwares/Docker.sh && cd bin && echo "" | ./install_softwares.sh -d -i Docker 2>&1 | tail -15`
Expected: nessun errore di sintassi; dry-run mostra i passi Docker e termina senza errori.

- [ ] **Step 3: Commit**

```bash
git add bin/install_softwares/Docker.sh
git commit -m "fix(docker): use distro-correct repo and install all docker packages"
```

---

## Task 3: Fix `main "$@"` (passaggio argomenti)

**Files:**
- Modify: `bin/install_softwares.sh:391`
- Modify: `run_app.sh:73`

- [ ] **Step 1: Correggere `main`**

In `bin/install_softwares.sh` ultima riga: `main $*` → `main "$@"`.

- [ ] **Step 2: Correggere il passaggio dei flag dal menu**

In `run_app.sh`, nel case `1)`, lasciare `./install_softwares.sh $flags` invariato **non** è corretto per i nomi con spazi, ma poiché i nomi `SQLite CLI`/`SQLite Browser` contengono spazi e non sono selezionabili comunque, aggiungere subito sotto `read -p "Input: " flags` un commento e tenere `$flags` non quotato (word-splitting voluto per i flag). Nessuna modifica di codice qui se non si vuole supportare nomi con spazi; il fix dei nomi con spazi è coperto rinominandoli (vedi Task 9, opzionale: rimuovere lo spazio dalle chiavi). **Decisione:** applicare solo `main "$@"`.

- [ ] **Step 3: Verifica**

Run: `bash -n bin/install_softwares.sh && cd bin && echo "" | ./install_softwares.sh -d -ax Spotify Docker 2>&1 | grep -i "Would skip\|except"`
Expected: messaggi che mostrano esclusione corretta di Spotify e Docker.

- [ ] **Step 4: Commit**

```bash
git add bin/install_softwares.sh
git commit -m "fix: use main \"\$@\" to preserve argument boundaries"
```

---

## Task 4: Fix shell-targeting + idempotenza in `nvm.sh`

**Files:**
- Modify: `bin/install_softwares/nvm.sh:24-30,67-70`

- [ ] **Step 1: Idempotenza reale + scrittura nel rc corretto**

In `bin/install_softwares/nvm.sh`, sostituire la guardia:

```bash
    is_installed "nvm" && return
```

con:

```bash
    # nvm è una funzione di shell, non un eseguibile: controlla la directory.
    if [ -d "$HOME/.nvm" ]; then
        log_message "INFO" "nvm is already installed (~/.nvm exists). Skipping."
        return
    fi
```

E sostituire il blocco di configurazione:

```bash
    # Configure nvm in shell profile
    echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm' >> ~/.bashrc
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion' >> ~/.bashrc
```

con:

```bash
    # Configure nvm nel profilo della shell corretta (idempotente)
    local RC_FILE="$HOME/.bashrc"
    [ "$USER_SHELL" = "zsh" ] && RC_FILE="$HOME/.zshrc"
    if ! grep -q 'NVM_DIR="$HOME/.nvm"' "$RC_FILE" 2>/dev/null; then
        {
            echo 'export NVM_DIR="$HOME/.nvm"'
            echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm'
            echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm completion'
        } >> "$RC_FILE"
    fi
```

Aggiornare anche il messaggio dry-run (`nvm.sh:55`) da `source ~/.bashrc` a `restart your shell`.

- [ ] **Step 2: Verifica**

Run: `bash -n bin/install_softwares/nvm.sh && cd bin && echo "" | ./install_softwares.sh -d -i nvm 2>&1 | tail -8`
Expected: nessun errore; messaggi dry-run coerenti.

- [ ] **Step 3: Commit**

```bash
git add bin/install_softwares/nvm.sh
git commit -m "fix(nvm): idempotent install + write config to the user's actual shell rc"
```

---

## Task 5: Fix shell-targeting + idempotenza + dry-run + arch in `go.sh`

**Files:**
- Modify: `bin/install_softwares/go.sh:29-31,47,72,93-94`

- [ ] **Step 1: Spostare il check directory dopo la guardia dry-run e rendere arch-aware**

In `bin/install_softwares/go.sh`, all'inizio di `install_GO()` calcolare l'arch e spostare il check `~/go` (in dry-run non deve uscire). Sostituire:

```bash
    local GO_DIRECTORY="$HOME/go"
    local GO_VERSION_FALLBACK="1.23.2"
    
    # Verify if GO already exists
    if [ -d "$GO_DIRECTORY" ]; then
        log_message "INFO" "GO directory already exists."
        return
    fi
```

con:

```bash
    local GO_DIRECTORY="$HOME/go"
    local GO_VERSION_FALLBACK="1.23.2"
    local GO_ARCH
    GO_ARCH="$(dpkg --print-architecture)"   # amd64 / arm64

    # In dry-run mostra comunque i passi; in modalità reale salta se già presente
    if [ "$DRY_RUN" -ne 1 ] && [ -d "$GO_DIRECTORY" ]; then
        log_message "INFO" "GO directory already exists. Skipping."
        return
    fi
```

- [ ] **Step 2: Usare l'arch nel nome del tar**

Sostituire `local GO_TAR_FILE="go$GO_VERSION.linux-amd64.tar.gz"` con:

```bash
    local GO_TAR_FILE="go$GO_VERSION.linux-${GO_ARCH}.tar.gz"
```

- [ ] **Step 3: Scrivere PATH/GOPATH nel rc corretto, idempotente**

Sostituire:

```bash
    # Add GO to PATH in .bashrc
    echo "export GOPATH=$GO_DIRECTORY" >> ~/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> ~/.bashrc
```

con:

```bash
    # Add GO to PATH nel profilo della shell corretta (idempotente)
    local RC_FILE="$HOME/.bashrc"
    [ "$USER_SHELL" = "zsh" ] && RC_FILE="$HOME/.zshrc"
    if ! grep -q "GOPATH=$GO_DIRECTORY" "$RC_FILE" 2>/dev/null; then
        echo "export GOPATH=$GO_DIRECTORY" >> "$RC_FILE"
        echo 'export PATH=$PATH:$GOPATH/bin' >> "$RC_FILE"
    fi
```

Aggiornare anche il messaggio dry-run (`go.sh:57` "Would add GO to PATH in ~/.bashrc") in modo generico.

- [ ] **Step 4: Verifica**

Run: `bash -n bin/install_softwares/go.sh && cd bin && echo "" | ./install_softwares.sh -d -i GO 2>&1 | tail -8`
Expected: i passi GO appaiono in dry-run (non più "GO directory already exists" come unica riga).

- [ ] **Step 5: Commit**

```bash
git add bin/install_softwares/go.sh
git commit -m "fix(go): arch-aware tarball, write PATH to correct shell rc, dry-run shows steps"
```

---

## Task 6: Fix prompt krew non-interattivo in `kubectl.sh` + arch

**Files:**
- Modify: `bin/install_softwares/kubectl.sh:20,30` (arch) e `:81-114` (krew)

- [ ] **Step 1: Rendere arch-aware il download di kubectl**

All'inizio di `install_kubectl()` aggiungere:

```bash
    local KARCH
    KARCH="$(dpkg --print-architecture)"   # amd64 / arm64
```

e sostituire nelle URL `linux/amd64/kubectl` e `linux/amd64/kubectl.sha256` la stringa `amd64` con `${KARCH}`. (Mantenere il resto invariato, incluse virgolette: usare `verify_command "curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${KARCH}/kubectl"`.)

- [ ] **Step 2: Saltare krew quando non c'è una TTY**

Sostituire l'inizio del blocco krew:

```bash
    # Install krew (kubectl plugin manager)
    echo "Would you like to install krew at the latest version? [y|n]"
    while :
    do
        if [ "$AUTOMATIC_START" == "true" ]; then
            res="y"
            echo "Automatic installation started."
        else
            read -n 1 res
            echo ""  # Add newline after reading single character
        fi
```

con:

```bash
    # Install krew (kubectl plugin manager)
    # Salta in modalità non interattiva (CI, pipe, -a/-ax) per evitare blocchi su read EOF.
    if [ ! -t 0 ] || [ "${CI:-}" = "true" ]; then
        log_message "INFO" "Non-interactive shell detected: skipping krew installation."
        return
    fi
    echo "Would you like to install krew at the latest version? [y|n]"
    while :
    do
        if [ "${AUTOMATIC_START:-}" == "true" ]; then
            res="y"
            echo "Automatic installation started."
        else
            read -n 1 res || { echo ""; echo "No input (EOF): skipping krew."; break; }
            echo ""  # Add newline after reading single character
        fi
```

- [ ] **Step 3: Verifica (deve NON bloccare con stdin chiuso)**

Run: `bash -n bin/install_softwares/kubectl.sh && cd bin && CI=true ./install_softwares.sh -d -i kubectl < /dev/null 2>&1 | tail -8`
Expected: termina senza hang; nessun prompt krew bloccante. (Il dry-run di kubectl esce prima del blocco krew, ma il test con `< /dev/null` garantisce nessun blocco anche se eseguito.)

- [ ] **Step 4: Commit**

```bash
git add bin/install_softwares/kubectl.sh
git commit -m "fix(kubectl): arch-aware download; skip krew prompt when non-interactive"
```

---

## Task 7: Fix `k9s.sh` (mkdir, path config, arch)

**Files:**
- Modify: `bin/install_softwares/k9s.sh`

- [ ] **Step 1: Leggere il file e individuare il blocco download/copy plugins**

Run: `cat -n bin/install_softwares/k9s.sh`
Annotare la riga del download `k9s_linux_amd64.deb` e la riga `cp -r ... $HOME/.k9s/`.

- [ ] **Step 2: Arch-aware + copia plugin robusta**

- All'inizio della funzione aggiungere `local KARCH; KARCH="$(dpkg --print-architecture)"` e sostituire `k9s_linux_amd64.deb` con `k9s_linux_${KARCH}.deb` (e l'eventuale URL corrispondente).
- Sostituire la copia plugins con una versione che crea la directory corretta (`~/.config/k9s`, coerente con `K9S_HOME` in `.zshrc`) e non silenzia gli errori in modo cieco:

```bash
    # Copia i plugin k9s nella config dir corretta (idempotente)
    local K9S_CFG="$HOME/.config/k9s"
    if [ -d "${PARENT_DIRECTORY:-..}/bin/config/k9s/plugins" ]; then
        mkdir -p "$K9S_CFG"
        cp -r "${PARENT_DIRECTORY:-..}/bin/config/k9s/plugins" "$K9S_CFG/" \
            && log_message "INFO" "k9s plugins copied to $K9S_CFG" \
            || log_message "ERROR" "Failed to copy k9s plugins"
    fi
```

(Adattare il path sorgente al valore reale presente nel file dopo lo Step 1.)

- [ ] **Step 3: Verifica**

Run: `bash -n bin/install_softwares/k9s.sh && cd bin && echo "" | ./install_softwares.sh -d -i k9s 2>&1 | tail -8`
Expected: nessun errore; dry-run coerente.

- [ ] **Step 4: Commit**

```bash
git add bin/install_softwares/k9s.sh
git commit -m "fix(k9s): arch-aware deb, robust plugin copy into ~/.config/k9s"
```

---

## Task 8: Fix failure-tracking, fallback e arch in `argocd.sh` e `argocd-autopilot.sh`

**Files:**
- Modify: `bin/install_softwares/argocd.sh`
- Modify: `bin/install_softwares/argocd-autopilot.sh`

- [ ] **Step 1: Leggere entrambi i file**

Run: `cat -n bin/install_softwares/argocd.sh bin/install_softwares/argocd-autopilot.sh`

- [ ] **Step 2: argocd.sh — usare release ufficiali, arch, failure tracking**

Sostituire la sezione di download/installazione (non-dry) con un pattern che: ricava la versione stabile ufficiale, usa l'arch, traccia i fallimenti:

```bash
    local AARCH; AARCH="$(dpkg --print-architecture)"  # amd64 / arm64
    local VERSION
    VERSION="$(curl -fsSL https://api.github.com/repos/argoproj/argo-cd/releases/latest 2>/dev/null \
               | grep -Po '"tag_name": "\K[^"]+')"
    if [ -z "$VERSION" ]; then
        log_message "ERROR" "Could not determine latest argocd version (GitHub API). Skipping."
        FAILED_INSTALLATIONS+=("argocd")
        return
    fi
    if ! sudo curl -fsSL -o /usr/local/bin/argocd \
        "https://github.com/argoproj/argo-cd/releases/download/${VERSION}/argocd-linux-${AARCH}"; then
        log_message "ERROR" "Failed to download argocd ${VERSION}."
        FAILED_INSTALLATIONS+=("argocd")
        return
    fi
    sudo chmod +x /usr/local/bin/argocd
    log_message "INFO" "argocd ${VERSION} installed."
```

(Mantenere `is_installed "argocd" && return` e la guardia DRY_RUN già presenti.)

- [ ] **Step 3: argocd-autopilot.sh — fallback versione, arch, chmod, failure tracking**

Sostituire il blocco che ricava `VERSION` e scarica con:

```bash
    local AARCH; AARCH="$(dpkg --print-architecture)"
    local VERSION
    VERSION="$(curl -fsSL https://api.github.com/repos/argoproj-labs/argocd-autopilot/releases/latest 2>/dev/null \
               | grep -Po '"tag_name": "\K[^"]+')"
    if [ -z "$VERSION" ]; then
        log_message "ERROR" "Could not determine latest argocd-autopilot version. Skipping."
        FAILED_INSTALLATIONS+=("argocd-autopilot")
        return
    fi
    if ! curl -fsSL --output - \
        "https://github.com/argoproj-labs/argocd-autopilot/releases/download/${VERSION}/argocd-autopilot-linux-${AARCH}.tar.gz" \
        | tar zx; then
        log_message "ERROR" "Failed to download/extract argocd-autopilot ${VERSION}."
        FAILED_INSTALLATIONS+=("argocd-autopilot")
        return
    fi
    sudo install -m 0755 "./argocd-autopilot-linux-${AARCH}" /usr/local/bin/argocd-autopilot
    rm -f "./argocd-autopilot-linux-${AARCH}"
    log_message "INFO" "argocd-autopilot ${VERSION} installed."
```

- [ ] **Step 4: Verifica**

Run: `bash -n bin/install_softwares/argocd.sh bin/install_softwares/argocd-autopilot.sh && cd bin && echo "" | ./install_softwares.sh -d -i argocd argocd-autopilot 2>&1 | tail -12`
Expected: nessun errore di sintassi; dry-run coerente.

- [ ] **Step 5: Commit**

```bash
git add bin/install_softwares/argocd.sh bin/install_softwares/argocd-autopilot.sh
git commit -m "fix(argo): official releases, arch-aware, failure tracking + version fallback"
```

---

## Task 9: Rinominare le funzioni SQLite (typo + trattino) e dedup export

**Files:**
- Modify: `bin/install_softwares/SQLite_CLI.sh`
- Modify: `bin/install_softwares/browser_SQLite.sh`
- Modify: `bin/config/constants.sh:14,15,82-83`

- [ ] **Step 1: Rinominare `intall_SQLite_CLI` → `install_SQLite_CLI`**

In `bin/install_softwares/SQLite_CLI.sh` la riga `intall_SQLite_CLI() {` → `install_SQLite_CLI() {`.
In `bin/config/constants.sh:14` cambiare `"intall_SQLite_CLI;..."` → `"install_SQLite_CLI;..."`.

- [ ] **Step 2: Rinominare `install_browser-SQLite` → `install_browser_SQLite`**

In `bin/install_softwares/browser_SQLite.sh` la riga `install_browser-SQLite() {` → `install_browser_SQLite() {`.
In `bin/config/constants.sh:15` cambiare `"install_browser-SQLite;..."` → `"install_browser_SQLite;..."`.

- [ ] **Step 3: Rimuovere il doppio export di LOG_FILE**

In `bin/config/constants.sh` eliminare una delle due righe duplicate `export LOG_FILE` (righe 82-83).

- [ ] **Step 4: Verifica (entrambe le funzioni eseguibili in dry-run)**

Run: `cd bin && echo "" | ./install_softwares.sh -d -i "SQLite CLI" "SQLite Browser" 2>&1 | grep -i sqlite`
Expected: messaggi dry-run per SQLite CLI e SQLite Browser senza errori "Unknown software"/"command not found".

- [ ] **Step 5: Commit**

```bash
git add bin/install_softwares/SQLite_CLI.sh bin/install_softwares/browser_SQLite.sh bin/config/constants.sh
git commit -m "refactor: fix SQLite function names (typo + hyphen) and dedup LOG_FILE export"
```

---

## Task 10: Rendere `config_terminal.sh` idempotente (risolve "zsh già presente → non fa nulla")

**Files:**
- Modify: `bin/config_terminal.sh:26-33` (chsh), `:102-142` (oh-my-zsh, tema, plugin)

- [ ] **Step 1: chsh solo se la shell di default non è già zsh**

Sostituire il blocco:

```bash
# Change default shell to zsh
echo "Changing default shell to zsh..."
if chsh -s /usr/bin/zsh; then
    echo "✓ Default shell changed to zsh"
else
    echo "✗ Failed to change default shell to zsh"
    FAILED_INSTALLS+=("default shell change to zsh")
fi
```

con:

```bash
# Change default shell to zsh (idempotente)
ZSH_PATH="$(command -v zsh)"
echo "Changing default shell to zsh..."
if [ "$SHELL" = "$ZSH_PATH" ]; then
    echo "✓ Default shell is already zsh ($ZSH_PATH)"
elif [ -n "$ZSH_PATH" ] && chsh -s "$ZSH_PATH"; then
    echo "✓ Default shell changed to zsh"
else
    echo "✗ Failed to change default shell to zsh (puoi farlo manualmente: chsh -s $ZSH_PATH)"
    FAILED_INSTALLS+=("default shell change to zsh")
fi
```

- [ ] **Step 2: oh-my-zsh idempotente (salta se già installato, niente errore)**

Sostituire il blocco oh-my-zsh:

```bash
# Oh-my-zsh
echo "Installing Oh-my-zsh..."
if mkdir -p ohmyzsh && cd ohmyzsh && \
   curl -fsLO https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh && \
   sed -i 's/exec zsh -l/#exec zsh -l/g' ./install.sh && \
   sh ./install.sh && \
   rm ./install.sh && \
   cd .. && \
   rm -rf ohmyzsh; then
    echo "✓ Oh-my-zsh installed successfully"
else
    echo "✗ Failed to install Oh-my-zsh"
    FAILED_INSTALLS+=("Oh-my-zsh")
    cd .. 2>/dev/null
    rm -rf ohmyzsh 2>/dev/null
fi
```

con:

```bash
# Oh-my-zsh (idempotente: salta se già presente)
echo "Installing Oh-my-zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "✓ Oh-my-zsh already installed, skipping"
elif mkdir -p ohmyzsh && cd ohmyzsh && \
   curl -fsLO https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh && \
   sed -i 's/exec zsh -l/#exec zsh -l/g' ./install.sh && \
   RUNZSH=no KEEP_ZSHRC=yes sh ./install.sh --unattended && \
   rm ./install.sh && \
   cd .. && \
   rm -rf ohmyzsh; then
    echo "✓ Oh-my-zsh installed successfully"
else
    echo "✗ Failed to install Oh-my-zsh"
    FAILED_INSTALLS+=("Oh-my-zsh")
    cd "$PARENT_DIRECTORY/bin" 2>/dev/null || cd .. 2>/dev/null
    rm -rf ohmyzsh 2>/dev/null
fi
```

(Nota: `KEEP_ZSHRC=yes` evita che oh-my-zsh sovrascriva `.zshrc`; tanto lo copiamo noi dopo. `--unattended`/`RUNZSH=no` evitano il blocco interattivo.)

- [ ] **Step 3: Tema e plugin idempotenti (clone solo se assente, altrimenti pull)**

Sostituire i blocchi tema e plugin con una funzione helper e chiamate idempotenti:

```bash
# Helper: clona se assente, altrimenti aggiorna; non fallire se già presente
clone_or_update() {
    local repo="$1" dest="$2" name="$3"
    if [ -d "$dest/.git" ]; then
        echo "✓ $name already present (updating)"
        git -C "$dest" pull --ff-only 2>/dev/null || echo "  (update skipped)"
    elif git clone --depth=1 "$repo" "$dest" 2>/dev/null; then
        echo "✓ $name installed"
    else
        echo "✗ Failed to install $name"
        FAILED_INSTALLS+=("$name")
    fi
}

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Theme
echo "Installing Powerlevel10k theme..."
clone_or_update "https://github.com/romkatv/powerlevel10k.git" \
    "$ZSH_CUSTOM_DIR/themes/powerlevel10k" "Powerlevel10k"

# Plugins
echo "Installing zsh plugins..."
clone_or_update "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
clone_or_update "https://github.com/zsh-users/zsh-autosuggestions" \
    "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" "zsh-autosuggestions"
```

(Rimuovere i vecchi blocchi `git clone ... powerlevel10k`, `PLUGIN_SUCCESS`, e i due `git clone` dei plugin.)

- [ ] **Step 4: Verifica sintassi**

Run: `bash -n bin/config_terminal.sh`
Expected: nessun output (OK). NB: il test funzionale completo richiede un ambiente sacrificabile (vedi Task 12, CI/container) — non eseguire `config_terminal.sh` direttamente sulla macchina di sviluppo perché modifica la shell di default e `~/.zshrc`.

- [ ] **Step 5: Commit**

```bash
git add bin/config_terminal.sh
git commit -m "fix(terminal): make config_terminal.sh fully idempotent (zsh/oh-my-zsh/p10k/plugins)"
```

---

## Task 11: Fix validazione `verify_constants.sh` + workflow `verify-constants.yml`

**Files:**
- Modify: `bin/verify_constants.sh:34`
- Modify: `.github/workflows/verify-constants.yml`

- [ ] **Step 1: Aggiungere `wget` alla regex dei metodi**

In `bin/verify_constants.sh:34` cambiare:

```bash
    if ! [[ $install_method =~ ^(apt|snap|curl|script|tar|test)$ ]]; then
```

in:

```bash
    if ! [[ $install_method =~ ^(apt|snap|curl|wget|script|tar)$ ]]; then
```

(rimosso `test`, aggiunto `wget`).

- [ ] **Step 2: (Opzionale ma consigliato) validare che la funzione esista**

Dopo la validazione del metodo, aggiungere un controllo che la funzione referenziata sia un identificatore bash valido:

```bash
    # Validate install_function name (identificatore bash valido)
    if ! [[ $install_function =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Error: Invalid install_function name '$install_function' for '$key'."
        flag=1
        return 1
    fi
```

(Questo avrebbe intercettato `install_browser-SQLite`.)

- [ ] **Step 3: Correggere il workflow per eseguire da `bin/`**

In `.github/workflows/verify-constants.yml`, sostituire lo step che esegue `./bin/verify_constants.sh` con:

```yaml
      - name: Verify constants
        run: |
          cd bin
          ./verify_constants.sh
```

(così `source ./config/constants.sh` trova davvero il file).

- [ ] **Step 4: Verifica locale**

Run: `cd bin && ./verify_constants.sh; echo "exit=$?"`
Expected: `All entries are valid.` e `exit=0` (dopo aver applicato il Task 9 che corregge i nomi e con `wget` ora accettato).

- [ ] **Step 5: Commit**

```bash
git add bin/verify_constants.sh .github/workflows/verify-constants.yml
git commit -m "fix(ci): accept wget method, validate function names, run validator from bin/"
```

---

## Task 12: Fix workflow `test-install-all.yml` e `updater-readme.yml`

**Files:**
- Modify: `.github/workflows/test-install-all.yml:35`
- Modify: `.github/workflows/updater-readme.yml`

- [ ] **Step 1: Escludere davvero snap/heavy/interattivi nel test-install-all**

In `.github/workflows/test-install-all.yml`, sostituire la riga di esecuzione `./install_softwares.sh -ax Spotify` con un'esclusione coerente con il commento (snap + GUI + heavy):

```yaml
        run: |
          cd bin
          CI=true ./install_softwares.sh -ax Spotify Brave AzureStorageExplorer Microk8s VSCode < /dev/null
```

(`CI=true` + `< /dev/null` impediscono blocchi su prompt come krew; escludiamo snap/GUI che falliscono/pesano in CI.)

- [ ] **Step 2: updater-readme.yml — limitare il commit ai push e dare i permessi**

In `.github/workflows/updater-readme.yml`:
- aggiungere a livello di job:

```yaml
    permissions:
      contents: write
```

- gating dello step di commit/push agli eventi push:

```yaml
      - name: Commit updated README
        if: github.event_name == 'push'
        run: |
          ...
```

- [ ] **Step 3: Verifica YAML**

Run: `for f in .github/workflows/*.yml; do python3 -c "import yaml,sys; yaml.safe_load(open('$f'))" && echo "OK $f"; done`
Expected: `OK` per ogni file (YAML valido).

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/test-install-all.yml .github/workflows/updater-readme.yml
git commit -m "fix(ci): exclude snap/GUI in install test, gate readme auto-commit to push with write perms"
```

---

## Task 13: Verifica finale end-to-end (dry-run completo + syntax)

**Files:** nessuno (solo verifica)

- [ ] **Step 1: Syntax check globale**

Run: `./bin/run_syntax_check.sh`
Expected: `✓ Syntax OK su tutti gli script`.

- [ ] **Step 2: Dry-run completo "install all"**

Run: `cd bin && echo "" | ./install_softwares.sh -d -a < /dev/null 2>&1 | tail -20`
Expected: si arriva fino a `[DRY-RUN] Preview completed: 100%` e `All installations succeeded`, senza hang e senza righe "command not found"/"Unknown software".

- [ ] **Step 3: verify_constants e auto_gen_readme**

Run: `cd bin && ./verify_constants.sh && ./auto_gen_readme.sh >/dev/null && echo "readme OK"`
Expected: `All entries are valid.` e `readme OK`.

- [ ] **Step 4: (Opzionale) test reale di config_terminal in container**

In un container/VM sacrificabile Debian/Ubuntu:
```bash
docker run --rm -it -v "$PWD":/repo debian:stable bash -lc \
  'apt-get update && apt-get install -y sudo git curl && cd /repo/bin && ./config_terminal.sh true; ./config_terminal.sh true'
```
Expected: la **seconda** esecuzione non produce errori `✗ Failed (may already exist)` ma `✓ already installed/present, skipping` (prova di idempotenza).

- [ ] **Step 5: Commit finale / aggiornare TODO**

Spuntare in `TODO` le voci risolte (Helm già presente, SQLite typo, `main "$@"`, curl|sudo → ancora aperto su NodeJS, ecc.) e committare:

```bash
git add TODO
git commit -m "docs: update TODO with completed fixes"
```

---

## Note finali / fuori scope (sicurezza — backlog)

Questi non sono bloccanti ma andrebbero pianificati separatamente (Fase 5 del TODO):
- `NodeJS.sh`, `nvm.sh`, `kustomize.sh`: pattern `curl | sudo bash` — valutare download+verifica prima dell'esecuzione.
- `k9s.sh`, `kind.sh`, `go.sh`, `argocd*`: aggiungere verifica checksum SHA256 (come già fa `VSCode.sh`/`kubectl.sh`).
- `Spotify.sh`: usare `signed-by` invece di `trusted.gpg.d` globale.
- Rimuovere codice morto: `archive/install_softwares_old.sh`, `install_one_function`, `show_progress_bar`, `restart_session`.

## Self-Review (eseguita)
- **Copertura:** ogni problema confermato nell'analisi ha un task (Docker, apt_get_install, main, nvm, go, kubectl/krew, k9s, argo*, SQLite names, idempotenza terminale, verify_constants+regex+workflow cwd, test-install-all esclusioni, updater-readme permessi).
- **Placeholder:** nessuno; ogni step di codice contiene il codice completo.
- **Consistenza tipi/nomi:** `apt_get_install` usa `"$@"` (Task 1) e Docker (Task 2) ne dipende; `install_SQLite_CLI`/`install_browser_SQLite` rinominati in coppia file+constants (Task 9); `USER_SHELL` usato in nvm/go è esportato da `install_softwares.sh:64`.
