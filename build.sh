#!/usr/bin/env bash

# This script builds the HTML files from the AsciiDoc files
# to the build folder and adds an extra sitemap.

set -euo pipefail

deploy=0

# Chack arguments
if [[ "${1:-}" == "--deploy" ]]; then
  deploy=1
fi

# Gets the current operating system.
os=$(uname -s)

# Sets the src and build folder.
source_folder="src"
build_folder="build"

# Ensures that the script runs from its own folder.
if ! cd "$(dirname "$0")"; then exit 1; fi

# Checks if Asciidoctor is installed.
if ! command -v asciidoctor &>/dev/null; then
  echo "Error: The asciidoctor command is not installed. Please install it first."
  exit 1
fi

# Checks if the required Asciidoctor libraries are installed.
error=0
for gem_name in "asciidoctor-diagram" "asciidoctor-diagram-plantuml"; do
  if ! gem list -i "$gem_name" &>/dev/null; then
    echo "Error: The $gem_name gem is not installed. Please install it first."
    echo "> gem install $gem_name"
    error=1
  fi
done
if ((error == 1)); then exit 1; fi

# Checks the src folder.
if [[ ! -d "$source_folder" ]]; then
  echo "Error: Source folder '$source_folder' does not exist."
  exit 1
fi

# Checks that no HTML file exists next to an AsciiDoc file.
# Such a file would be copied to the build folder and
# overwrite the freshly generated HTML file.
conflicting_html_files=()
while IFS= read -r adoc_file; do
  html_file="${adoc_file%.adoc}.html"
  if [[ -f "${html_file}" ]]; then
    conflicting_html_files+=("$html_file")
  fi
done < <(find "$source_folder" -type f -name "*.adoc" -not -name "*.inc.adoc")
if ((${#conflicting_html_files[@]} > 0)); then
  echo "Error: These HTML files conflict with the generated files. Please delete them:"
  printf '%s\n' "${conflicting_html_files[@]}"
  exit 1
fi

# Cleans or creates the build folder.
printf "Clean '%s' folder: " "$build_folder"
mkdir -p "$build_folder"
if [[ -d "$build_folder" ]]; then
  find "$build_folder" -mindepth 1 -maxdepth 1 -exec rm -rf {} \;
else
  echo "Error: Build folder '${build_folder}' does not exist or cannot be created."
  exit 1
fi
echo "done"

# Generates the HTML files from the AsciiDoc files
# in the src folder to the build folder.
echo "Generate HTML files:"
# Main documents
attributes=(-a toc=left)
required_libs=(-r asciidoctor-diagram)
find "$source_folder" \
  -maxdepth 1 \
  -type f -name "*.adoc" -not -name "*.inc.adoc" \
  -exec echo "  {}" \; \
  -exec asciidoctor "${attributes[@]}" "${required_libs[@]}" -D "$build_folder" {} \;
# Special subfolders
attributes=(-a toc=auto)
for special_subfolder in "faq" "install-and-config"; do
  find "${source_folder}/${special_subfolder}" \
    -type f -name "*.adoc" -not -name "*.inc.adoc" \
    -exec echo "  {}" \; \
    -exec asciidoctor "${attributes[@]}" "${required_libs[@]}" -D "${build_folder}/${special_subfolder}" {} \;
done
echo "done"

# Adds an extra sitemap to the HTML files in 'build' folder:
search='<li><a href="#sitemap"><span class="icon"><i class="fa fa-sitemap"><\/i><\/span> Seitenübersicht<\/a><\/li>'
replace='\
  <li id="extra-sitemap-sh"><span style="color: #7a2518"><br \/><span class="icon"><i class="fa fa-sitemap"><\/i><\/span> Seitenübersicht<\/span><\/li>\
  <li><a href="index.html">Einführung<\/a><\/li>\
  <li><a href="install-and-config\/index.html" target="_blank" rel="noopener noreferrer"><span class="icon"><i class="fa fa-sticky-note-o"><\/i><\/span> Installation \&amp; Konfiguration<\/a><\/li>\
  <li><a href="faq\/index.html" target="_blank" rel="noopener noreferrer"><span class="icon"><i class="fa fa-sticky-note-o"><\/i><\/span> FAQ \&amp; Tipps<\/a><\/li>\
  <li><span style="color: #ccc;"><span class="icon"><i class="fa fa-sticky-note-o"><\/i><\/span> Notizen<\/span><\/li>\
  <li><a href="project-work.html"><span class="icon"><i class="fa fa-sticky-note-o"><\/i><\/span> Hinweise Projektarbeit<\/a><\/li>\
  <li><span style="color: #7a2518"><br \/><span class="icon"><i class="fa fa-sitemap"><\/i><\/span> Praktika - SE I<\/span><\/li>\
  <li><a href="01-basics.html">Teil 1 - Grundlagen<\/a><\/li>\
  <li><a href="02-git-branching.html">Teil 2 - Parallel arbeiten<\/a><\/li>\
  <li><a href="03-teamwork.html">Teil 3 - Teamarbeit und Konflikte<\/a><\/li>\
  <li><a href="04-issues-projects.html">Teil 4 - Aufgabenmanagement<\/a><\/li>\
  <li><a href="05-diagrams.html">Teil 5 - Diagramme<\/a><\/li>\
  <li><a href="06-code-review.html">Teil 6 - Code-Review und Integration<\/a><\/li>\
  <li><span style="color: #7a2518"><br \/><span class="icon"><i class="fa fa-sitemap"><\/i><\/span> Praktika - SE II<\/span><\/li>\
  <li><a href="07-git-advanced.html">Teil 7 - Git Advanced<\/a><\/li>\
  <li><a href="08-github-actions.html">Teil 8 - GitHub Actions<\/a><\/li>\
'
printf "Add extra sitemap: "
if [[ "$os" == "Darwin" ]]; then
  find "$build_folder" -type f -name "*.html" -exec sed -i '' "s/${search}/${replace}/g" {} \; #macOS
else
  find "$build_folder" -type f -name "*.html" -exec sed -i "s/${search}/${replace}/g" {} \; #Linux
fi
grep -q 'id="extra-sitemap-sh"' "$build_folder/index.html" || {
  echo "Error: sitemap replacement failed"
  exit 1
}
echo "done"

# Adds a preview warning if in 'next' branch.
git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [[ "$git_branch" == "next" ]]; then
  search='<div id="header">'
  style='position: fixed;padding: 15px;background-color: rgba(255,244,0,.9);right: -130px;top: 15px;z-index: 1000;width: 400px;text-align: center;transform: rotate(35deg);border: 3px dashed #e00;'
  link='<a href="\/praktika\/se\/git-docs-collab\/" style="font-size: 10px;">Come to the productive side!<\/a>'
  replace="<div id=\"cz_preview_warning\" style=\"${style}\">PREVIEW<br \/>${link}<\/div>${search}"
  printf "Add preview warning: "
  if [[ "$os" == "Darwin" ]]; then
    find "$build_folder" -type f -name "*.html" -exec sed -i '' "s/${search}/${replace}/g" {} \; #macOS
  else
    find "$build_folder" -type f -name "*.html" -exec sed -i "s/${search}/${replace}/g" {} \; #Linux
  fi
  echo "done"
fi

# Copies additional folders and files to the build folder.
printf "Copy additional files: "
find "$source_folder" \
  -mindepth 1 -maxdepth 1 \
  -not \( -name "*.adoc" -o -name "*docinfo*" -o -name ".*" -o -name "plantuml" -o -name "faq" -o -name "install-and-config" \) \
  -exec cp -r {} "${build_folder}/" \;
find "${source_folder}/faq" \
  -mindepth 1 -maxdepth 1 \
  -not \( -name "*.adoc" -o -name "*docinfo*" -o -name ".*" -o -name "plantuml" \) \
  -exec cp -r {} "${build_folder}/faq/" \;
find "${source_folder}/install-and-config" \
  -mindepth 1 -maxdepth 1 \
  -not \( -name "*.adoc" -o -name "*docinfo*" -o -name ".*" -o -name "plantuml" \) \
  -exec cp -r {} "${build_folder}/install-and-config/" \;
echo "done"

# Runs the deploy script if needed.
if ((deploy == 1)); then
  ./deploy.sh
fi
