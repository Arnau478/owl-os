FILES=$(find src/**)
FILE_COUNT=$(ls $FILES | wc -l)
LINES=$(cat $FILES 2>/dev/null | wc -l)
echo "Files: $FILE_COUNT"
echo "Lines: $LINES"
