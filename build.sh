. properties.sh
packjson="modrinth.index.json"

echo "{
    \"formatVersion\": 1,
    \"game\": \"minecraft\",
    \"versionId\": \"$version\",
    \"name\": \"$name\",
    \"files\": [
        " > $packjson
while read line
do 
    modId="$(echo $line | sed 's/[/].*//')"
    fileId="$(echo $line | sed 's/.*[/]//')"
    file="$(curl "https://api.curse.tools/v1/cf/mods/$modId/files" 2>/dev/null)"
    downloadUrl="$(echo $file | jq "first(.data[] | select(.id | contains($fileId))).downloadUrl")"
    fileSize="$(echo $file | jq "first(.data[] | select(.id | contains($fileId))).fileLength")"
    fileName="$(echo $file | jq "first(.data[] | select(.id | contains($fileId))).fileName" | tr -d '"')"
    sha1="$(echo $file | jq "first(.data[] | select(.id | contains($fileId))).hashes[] | select(.algo | contains(1)).value")"
    echo "        {
            \"path\": \"mods/$fileName\",
            \"hashes\": {
                \"sha1\": $sha1
            },
            \"env\": {
                \"client\": \"required\",
                \"server\": \"required\"
            },
            \"downloads\": [
                $downloadUrl
            ],
            \"fileSize\": $fileSize
        }," >> $packjson
done < "$cffiles"
while read line
do
    file="$(curl "https://api.modrinth.com/v2/version/$line" 2>/dev/null)"
    #echo $file
    modId="$(echo $file | jq ".project_id" | tr -d '"')"
    project="$(curl "https://api.modrinth.com/v2/project/$modId" 2>/dev/null)"
    downloadUrl="$(echo $file | jq "first(.files[]).url")"
    fileSize="$(echo $file | jq "first(.files[]).size")"
    fileName="$(echo $file | jq "first(.files[]).filename" | tr -d '"')"
    sha1="$(echo $file | jq "first(.files[]).hashes.sha1")"
    sha512="$(echo $file | jq "first(.files[]).hashes.sha512")"
    client="$(echo $project | jq ".client_side")"
    server="$(echo $project | jq ".server_side")"
    echo "        {
            \"path\": \"mods/$fileName\",
            \"hashes\": {
                \"sha1\": $sha1,
                \"sha512\": $sha512
            },
            \"env\": {
                \"client\": $client,
                \"server\": $server
            },
            \"downloads\": [
                $downloadUrl
            ],
            \"fileSize\": $fileSize
        }," >> $packjson
done < "$mrfiles"

#while read line
#do 
#    modId="$(echo $line | sed 's/[|].*//')"
#    fileId="$(echo $line | sed 's/.*[|]//')"
#    file="$(curl "https://api.github.com/repos/$modId/releases/assets/$fileId" 2>/dev/null)"
#    downloadUrl="$(echo $file | jq ".browser_download_url")"
#    fileSize="$(echo $file | jq ".size")"
#    fileName="$(echo $file | jq ".name" | tr -d '"')"
#    echo $downloadUrl
#    sha1="$(curl "$(echo $downloadUrl | tr -d '"')" | sha1sum)"
#    echo "        {
#            \"path\": \"mods/$fileName\",
#            \"hashes\": {
#                \"sha1\": \"$sha1\"
#            },
#            \"env\": {
#                \"client\": \"required\",
#                \"server\": \"required\"
#            },
#            \"downloads\": [
#                $downloadUrl
#            ],
#            \"fileSize\": $fileSize
#        }," >> $packjson
#done < "$ghfiles"

sed -i '$s/.$//' $packjson

echo "
    ],
    \"dependencies\": {
        \"$loader\": \"$loaderversion\",
        \"minecraft\": \"$mcversion\"
    }
}" >> $packjson

zip "$name" $packjson
zip "$name" $config
cp "$options" options.txt
zip "$name" options.txt
rm $packjson
rm options.txt
mv "$name.zip" ".out/$name.mrpack"
