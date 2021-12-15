#!/bin/bash

GITLEAKS_BIN="$2"
INPUT_CONFIG_PATH="$1"
CONFIG=""

if [ -f "$INPUT_CONFIG_PATH" ]; then
  echo -e "\nFound config in $INPUT_CONFIG_PATH"
  CONFIG=" --config-path=$INPUT_CONFIG_PATH"
else
  echo -e "\nConfig not found in $INPUT_CONFIG_PATH... using default"  
fi

chmod +x $GITLEAKS_BIN

echo -e "\nrunning gitleaks $($GITLEAKS_BIN --version) ...\n"

echo '[]' > gitleaks.json
EXIT_CODE=3

if [ "$GITHUB_EVENT_NAME" = "push" -o "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]; then
  GITLEAKS=$($GITLEAKS_BIN --debug --path=$GITHUB_WORKSPACE --report="gitleaks.json" --format=JSON --leaks-exit-code=2 --verbose --redact $CONFIG)
  EXIT_CODE=$?
elif [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
  git --git-dir="$GITHUB_WORKSPACE/.git" log --pretty=format:"%H" remotes/origin/$GITHUB_BASE_REF.. >commit_list.txt
  cat commit_list.txt
  GITLEAKS=$($GITLEAKS_BIN --debug --path=$GITHUB_WORKSPACE --report="gitleaks.json" --format=JSON --leaks-exit-code=2 --verbose --redact --commits-file=commit_list.txt $CONFIG)
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
