#!/bin/bash
# fix-yaml-lint.sh
# Automatische Behebung häufiger YAML-Lint-Probleme

set -e

echo "🔧 Behebe YAML-Lint-Probleme..."

# Funktion zum Beheben von trailing spaces
fix_trailing_spaces() {
    local file="$1"
    echo "  Entferne trailing spaces in $file"
    sed -i 's/[[:space:]]*$//' "$file"
}

# Funktion zum Hinzufügen von document-start
fix_document_start() {
    local file="$1"
    if ! head -1 "$file" | grep -q "^---"; then
        echo "  Füge document-start zu $file hinzu"
        sed -i '1i ---' "$file"
    fi
}

# Funktion zum Hinzufügen von newline am Ende
fix_end_of_file() {
    local file="$1"
    if [ -n "$(tail -c1 "$file")" ]; then
        echo "  Füge newline am Ende von $file hinzu"
        echo "" >> "$file"
    fi
}

# Funktion zum Korrigieren der Einrückung
fix_indentation() {
    local file="$1"
    echo "  Korrigiere Einrückung in $file"
    # Verwende yq für saubere YAML-Formatierung (falls verfügbar)
    if command -v yq > /dev/null 2>&1; then
        yq eval '.' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
    fi
}

# Liste der zu korrigierenden Dateien
yaml_files=(
    ".github/workflows/build-and-publish.yml"
    ".github/workflows/release.yml"
    ".github/workflows/yaml-lint.yml"
    "docker-compose.yml"
    ".yamllint"
)

# Prüfe ob Dateien existieren und korrigiere sie
for file in "${yaml_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "🔧 Bearbeite $file..."
        
        # Korrigiere häufige Probleme
        fix_trailing_spaces "$file"
        fix_document_start "$file"
        fix_end_of_file "$file"
        
        echo "  ✅ $file korrigiert"
    else
        echo "  ⚠️ $file nicht gefunden, überspringe..."
    fi
done

echo ""
echo "✅ YAML-Lint-Korrekturen abgeschlossen!"
echo ""
echo "🔍 Teste die Korrekturen:"
echo "  yamllint .github/workflows/"
echo "  yamllint docker-compose.yml"
echo ""
echo "📝 Committe die Änderungen:"
echo "  git add ."
echo "  git commit -m '🔧 Fix YAML lint issues - add document start, remove trailing spaces'"
echo "  git push origin main"