PATH_FILTER="dir/file"
CHANGED_FILES=$(git diff HEAD HEAD~ --name-only)
MATCH_COUNT=0

echo "Checking for file changes..."
for FILE in $CHANGED_FILES
do
if [[ $PATH_FILTER =~ $FILE ]]; then
    echo "MATCH:  ${FILE} changed"
    MATCH_FOUND=true
    MATCH_COUNT=$(($MATCH_COUNT+1))
else
    echo "IGNORE: ${FILE} changed"
fi
done

echo "$MATCH_COUNT match(es) for filter '$PATH_FILTER' found."


