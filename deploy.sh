#!/usr/bin/env bash
# Deploy do site via FTP.
#
# Uso:
#   ./deploy.sh              -> sobe arquivos modificados + novos (segundo o git)
#   ./deploy.sh index.html   -> sobe somente os arquivos passados como argumento
#   ./deploy.sh --all        -> sobe todos os arquivos publicáveis da raiz + assets/
#
# Credenciais ficam em .env (gitignored).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [[ ! -f .env ]]; then
  echo "Erro: arquivo .env não encontrado. Copie .env.example para .env e preencha." >&2
  exit 1
fi

# Carrega .env sem exportar pro ambiente do shell.
set -a; source .env; set +a

: "${FTP_HOST:?FTP_HOST não definido em .env}"
: "${FTP_USER:?FTP_USER não definido em .env}"
: "${FTP_PASS:?FTP_PASS não definido em .env}"
: "${FTP_REMOTE_DIR:?FTP_REMOTE_DIR não definido em .env}"
FTP_PORT="${FTP_PORT:-21}"

# Monta a lista de arquivos a subir.
files=()

if [[ $# -gt 0 ]]; then
  if [[ "$1" == "--all" ]]; then
    # Tudo da raiz (html/txt/xml) + assets recursivo.
    while IFS= read -r f; do files+=("$f"); done < <(
      find . -maxdepth 1 -type f \( -name "*.html" -o -name "*.txt" -o -name "*.xml" \) | sed 's|^\./||'
      find assets -type f 2>/dev/null || true
    )
  else
    files=("$@")
  fi
else
  # Detecta modificados + novos via git (rastreados ou não).
  while IFS= read -r line; do
    # Formato porcelain: "XY path". Pega tudo depois dos 3 primeiros chars.
    status="${line:0:2}"
    path="${line:3}"
    # Ignora deletados (D) — FTP não vai remover automaticamente.
    [[ "$status" == " D" || "$status" == "D " ]] && continue
    # Ignora arquivos fora de publicação.
    case "$path" in
      .env|.env.example|deploy.sh|.gitignore|*.md|.claude/*|.playwright-mcp/*|preview-*) continue ;;
    esac
    files+=("$path")
  done < <(git status --porcelain)
fi

if [[ ${#files[@]} -eq 0 ]]; then
  echo "Nada para subir. (Tudo limpo segundo o git, ou só arquivos ignorados.)"
  exit 0
fi

echo "Servidor:   ftp://$FTP_HOST:$FTP_PORT$FTP_REMOTE_DIR"
echo "Arquivos:   ${#files[@]}"
for f in "${files[@]}"; do echo "  - $f"; done
echo

fail=0
for f in "${files[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "  ! pulando $f (não é arquivo)"
    continue
  fi
  printf "  -> %-40s " "$f"
  code=$(curl -s --connect-timeout 30 --ftp-create-dirs \
    -T "$f" "ftp://$FTP_HOST:$FTP_PORT$FTP_REMOTE_DIR/$f" \
    --user "$FTP_USER:$FTP_PASS" \
    -w "%{http_code}" -o /dev/null) || code="ERR"
  if [[ "$code" == "226" || "$code" == "250" ]]; then
    echo "ok"
  else
    echo "FALHOU (code=$code)"
    fail=$((fail + 1))
  fi
done

echo
if [[ $fail -eq 0 ]]; then
  echo "Deploy concluído com sucesso."
else
  echo "Deploy terminou com $fail falha(s)." >&2
  exit 1
fi
