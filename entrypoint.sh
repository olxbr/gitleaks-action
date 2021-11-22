#!/bin/bash

INPUT_CONFIG_PATH="$1"
CONFIG=""

if [ -f "$INPUT_CONFIG_PATH" ]; then
  echo -e "\nFound config in $INPUT_CONFIG_PATH"
  CONFIG=" --config-path=$INPUT_CONFIG_PATH"
else
  echo -e "\nConfig not found in $INPUT_CONFIG_PATH... using default"  
fi

wget -q https://github.com/zricethezav/gitleaks/releases/download/v8.0.0/gitleaks_8.0.0_linux_x64.tar.gz
tar -xf gitleaks_8.0.0_linux_x64.tar.gz
chmod +x gitleaks
rm -rf gitleaks_8.0.0_linux_x64.tar.gz

echo -e "\nrunning gitleaks version $(./gitleaks version) ...\n"

echo '[]' > gitleaks.json
EXIT_CODE=3

if [ "$GITHUB_EVENT_NAME" = "push" -o "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]; then
  GITLEAKS=$(./gitleaks detect --source "$GITHUB_WORKSPACE" --report-path "gitleaks.json" --report-format JSON --exit-code 2 --redact --config "$CONFIG")
  EXIT_CODE=$?
elif [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
  git --git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/$GITHUB_BASE_REF... >commit_list.txt
  GITLEAKS=$(./gitleaks detect --source "$GITHUB_WORKSPACE" --report-path "gitleaks.json" --report-format JSON --exit-code 2 --redact --commits-file=commit_list.txt --config "$CONFIG")
  EXIT_CODE=$?
fi

case $EXIT_CODE in
0) echo -e "Your code is good to go!\n\n" ;;
1) echo -e "Gitleaks execution fail!\n\n" ;;
2) echo -e "Gitleaks encountered leaks!\n\n$(cat gitleaks.json)\n\n" ;;
3) echo -e "Gitleaks not executed!\n\n" ;;
*) echo -e "Exit code was $EXIT_CODE\n\n" ;;
esac

echo "::set-output name=exit_code::$EXIT_CODE"
echo "::set-output name=result::$(jq -c . < gitleaks.json | sed 's/\x27/`/g')"

rm -rf gitleaks gitleaks.json
