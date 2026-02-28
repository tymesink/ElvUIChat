#!/bin/bash
# Auto-increment the patch version in ElvUIChat.toc on every commit.
# Format: major.patch (e.g. 1.0 -> 1.1 -> 1.2)

TOC="source/ElvUIChat/ElvUIChat.toc"

# Read current version
current=$(grep -oP '(?<=## Version: )\S+' "$TOC")
if [ -z "$current" ]; then
    echo "pre-commit: could not read version from $TOC"
    exit 1
fi

major=$(echo "$current" | cut -d. -f1)
patch=$(echo "$current" | cut -d. -f2)

# Increment patch
new_patch=$((patch + 1))
new_version="${major}.${new_patch}"

# Write back
sed -i "s/## Version: ${current}/## Version: ${new_version}/" "$TOC"

echo "pre-commit: version bumped ${current} -> ${new_version}"

# Stage the updated TOC
git add "$TOC"
