#!/bin/bash

set -euo pipefail

SRC_TMP_FILE=$1
DST_CP_FILE_TO=$2
SOLR_HOST=$3
SOLR_COLLECTION_NAME=$4
DECOMPOUND_DST_CP_FILE_TO=$5
TARGET_SYSTEM=$6
REPLACE_RULES_SRC_TMP_FILE=$7
REPLACE_RULES_DST_CP_FILE_TO=$8

if grep -q -i -E '^https?://' <<<$SOLR_HOST; then
  SOLR_BASE_URL=$SOLR_HOST
else
  SOLR_BASE_URL=http://$SOLR_HOST/solr
fi

echo "In smui2solrcloud.sh - script deploying rules to querqy api"
echo "^-- SRC_TMP_FILE = $SRC_TMP_FILE"
echo "^-- DST_CP_FILE_TO = $DST_CP_FILE_TO"
echo "^-- SOLR_BASE_URL = $SOLR_BASE_URL"
echo "^-- SOLR_COLLECTION_NAME: $SOLR_COLLECTION_NAME"
echo "^-- DECOMPOUND_DST_CP_FILE_TO = $DECOMPOUND_DST_CP_FILE_TO"
echo "^-- TARGET_SYSTEM = $TARGET_SYSTEM"
echo "^-- REPLACE_RULES_SRC_TMP_FILE = $REPLACE_RULES_SRC_TMP_FILE"
echo "^-- REPLACE_RULES_DST_CP_FILE_TO = $REPLACE_RULES_DST_CP_FILE_TO"


# DEPLOYMENT
#####

echo "^-- Perform rules.txt deployment (decompound-rules.txt eventually)"

echo "^-- ... rules.txt"
python3 ./conf/push_common_rules.py $SRC_TMP_FILE "$SOLR_BASE_URL/$SOLR_COLLECTION_NAME/querqy/rewriter/$DST_CP_FILE_TO"
if [ $? -ne 0 ]; then
  exit 16
fi

echo "^-- ... replace-rules.txt"
if ! [[ $REPLACE_RULES_SRC_TMP_FILE == "NONE" && $REPLACE_RULES_DST_CP_FILE_TO == "NONE" ]]
then
    python3 /smui/conf/push_replace.py $REPLACE_RULES_SRC_TMP_FILE "$SOLR_BASE_URL/$SOLR_COLLECTION_NAME/querqy/rewriter/$REPLACE_RULES_DST_CP_FILE_TO"
fi

# all ok
echo "smui2solrcloud.sh - ok"
exit 0
