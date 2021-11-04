#!/bin/bash

INPUT_CONFIG_PATH="$1"
CONFIG=""

if [ -f "$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH" ]; then
  CONFIG=" --config-path=$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH"
fi

echo -e "\nrunning gitleaks $(gitleaks --version) ...\n"

OUTPUT_RESULT=[]
if [ "$GITHUB_EVENT_NAME" = "push" -o "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]
then
  OUTPUT_RESULT=[$(gitleaks --path=$GITHUB_WORKSPACE --leaks-exit-code=0 --quiet --redact $CONFIG | paste -s -d ',')]
elif [ "$GITHUB_EVENT_NAME" = "pull_request" ]
then 
  git --git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/$GITHUB_BASE_REF... > commit_list.txt
  OUTPUT_RESULT=[$(gitleaks --path=$GITHUB_WORKSPACE --leaks-exit-code=0 --quiet --redact --commits-file=commit_list.txt $CONFIG | paste -s -d ',')]
fi

if [ "$OUTPUT_RESULT" != "[]" ]
then
  GITLEAKS_RESULT=$(echo -e "\e[31mGitleaks encountered leaks:")
  EXITCODE=1
else
  GITLEAKS_RESULT=$(echo -e "\e[32mYour code is good to go!")
  EXITCODE=0
fi

echo -e "$GITLEAKS_RESULT\n"
echo -e "$OUTPUT_RESULT\n"
echo -e "Maintaining gitleaks takes a lot of work so consider sponsoring it or donate:\n\e[36mhttps://github.com/sponsors/zricethezav\n\e[36mhttps://www.paypal.me/zricethezav\n"

echo "::set-output name=exitcode::$EXITCODE"
echo "::set-output name=result::$OUTPUT_RESULT"
