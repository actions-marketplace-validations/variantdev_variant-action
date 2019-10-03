#!/bin/sh
set -e

cat << EOS > $HOME/.netrc
machine github.com
login ${GITHUB_ACTOR}
password ${GITHUB_TOKEN}
EOS

git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --global user.name "${GITHUB_ACTOR}"

cd "${VARIANT_WORKING_DIR:-.}"

set +e
OUTPUT=$(sh -c "variant $*" 2>&1)
SUCCESS=$?
echo "$OUTPUT"
set -e

if [ $SUCCESS -eq 0 ]; then
    exit 0
fi

if [ "$VARIANT_COMMENT" = "1" ] || [ "$VARIANT_COMMENT" = "false" ]; then
    exit $SUCCESS
fi

VARIANT_NAME=${variant:-variant}

COMMENT="#### \`$VARIANT_NAME $*\` Failed
\`\`\`
$OUTPUT
\`\`\`"
PAYLOAD=$(echo '{}' | jq --arg body "$COMMENT" '.body = $body')
COMMENTS_URL=$(cat /github/workflow/event.json | jq -r .pull_request.comments_url)
curl -s -S -H "Authorization: token $GITHUB_TOKEN" --header "Content-Type: application/json" --data "$PAYLOAD" "$COMMENTS_URL" > /dev/null || true

exit $SUCCESS
