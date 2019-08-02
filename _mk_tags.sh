#!/bin/bash

while read -r TAG
do
	echo "Tag: $TAG"
	SLUG=$(echo "$TAG" | tr ' A-Z' '-a-z')
	FILE="_tag/$SLUG.md"

	echo "---" > $FILE
	echo "tag: $TAG" >> $FILE
	echo "permalink: /tag/$SLUG/" >> $FILE
	echo "---" >> $FILE
done <<< $(find _posts/ -name '*.md' -exec sed -n '/^---/,/^---/p' {} \; | sed -n '/^tags:/,/^---/s/^- \(.*\)/\1/p' | sort -u)
