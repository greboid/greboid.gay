#!/bin/bash
mkdir -p /app/images
find /app -type f -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' | cat -n | while read n f; do
  ext=$(echo "$f" | awk -F '.' '{print $NF}')
  hash=$(sha1sum "$f" | awk '{print $1}')
  mv "$f" "/app/images/$hash.$ext";
done

for file in $(find "/app/images/$dir" -name '*.jpg' -o -name '*.png' -o -name '*.jpeg'); do
  cwebp -quiet -m 6 -mt -o "$file.webp" -- "$file"
done