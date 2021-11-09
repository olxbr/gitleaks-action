#!/bin/bash

INPUT_CONFIG_PATH="$1"
CONFIG=""

if [ -f "$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH" ]; then
  CONFIG=" --config-path=$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH"
fi

GITLEAKS_VERSION=$(curl -s https://api.github.com/repos/zricethezav/gitleaks/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")') && wget -q https://github.com/zricethezav/gitleaks/releases/download/$GITLEAKS_VERSION/gitleaks-linux-amd64
mv gitleaks-linux-amd64 gitleaks
chmod +x gitleaks

echo -e "\nrunning gitleaks $(./gitleaks --version) ...\n"

echo '[]' > gitleaks.json
EXIT_CODE=3

if [ "$GITHUB_EVENT_NAME" = "push" -o "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]; then
  GITLEAKS=$(./gitleaks --path=$GITHUB_WORKSPACE --report="gitleaks.json" --format=JSON --leaks-exit-code=2 --quiet --redact $CONFIG)
  EXIT_CODE=$?
elif [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
  git --git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/$GITHUB_BASE_REF... >commit_list.txt
  GITLEAKS=$(./gitleaks --path=$GITHUB_WORKSPACE --report="gitleaks.json" --format=JSON --leaks-exit-code=2 --quiet --redact --commits-file=commit_list.txt $CONFIG)
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
