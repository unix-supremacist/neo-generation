. properties.sh
 
rm $mrfiles
while read line
do 
    file="$(curl "https://api.modrinth.com/v2/project/$line/version" 2>/dev/null | jq "first(.[] | select(.game_versions[] | contains(\"$mcversion\"))).id" | tr -d '"')"
    echo "$file" >> $mrfiles
done < $mrmods

rm $cffiles
while read line
do 
    file="$(curl "https://api.curse.tools/v1/cf/mods/$line/files" 2>/dev/null | jq "first(.data[] | select(.sortableGameVersions[].gameVersion | contains(\"$mcversion\"))).id")"
    echo "$line/$file" >> $cffiles
done < $cfmods

rm $ghfiles
while read line
do 
    file="$(curl "https://api.github.com/repos/$line/releases" 2>/dev/null | jq ".[].assets[]
    | select(.name | contains(\"dev\") | not)
    | select(.name | contains(\"source\") | not)
    | select(.name | contains(\"src\") | not)
    .id")"
    echo "$line|$file" >> $ghfiles
done < $ghmods