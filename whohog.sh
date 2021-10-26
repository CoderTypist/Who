#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "Please specify the mount location of the file system"
    exit -1
fi

echo ""
target="$1"
out_unsorted="data_usage_unsorted.txt"
out_sorted="data_usage_sorted.txt"
echo -n "" > "$out_unsorted"
echo -n "" > "$out_sorted"

# loop over items in the current directory
for item in $(ls); do

    # find the size of each directory
    if [ -d "$item" -o -f "$item" ] ; then

        # convert du output to be comma delimited
        du -h -sb "$item" | sed -E 's/\s+/,/g' >> "$out_unsorted"
    fi
done

# sort directories in descending order by bytes
sort -t, -r -nk1 "$out_unsorted" > "$out_sorted"

# '/' needs to be converted to '\/' in order to be regular expression friendly
target="$(echo "$target" | sed 's|/|\\/|g')"

# df provides the number of 1024 byte units being used
fs_1k_blocks="$(df | sed -n "/${target}$/p" | awk '{print $2}')"

# get the percent of the fs that is in use
fs_percent_used="$(df | sed -n "/${target}$/p" | awk '{print $5}')"
# remove the '%' at the end
fs_percent_used="${fs_percent_used:0:${#fs_percent_used}-1}"

# multiply the number of 1024 byte units by 1024 to get the number of bytes
fs_total="$(( $fs_1k_blocks * 1024 ))"

# bytes used by items
byte_total=0
# bytes per gb, where 1GB=1024*1024*1024
bytes_per_gb=1073741824

# table header
echo "       Gigabytes       Percent                   Bytes    Owner             Item"
echo " ----------------------------------------------------------------------------------------------------"

# item statistics
while read -r line; do

    # get item name
    name="$(echo "$line" | awk 'BEGIN{FS=","} {printf("%s", $2)}')"

    # bytes used by the item
    bytes="$(echo "$line" | awk 'BEGIN{FS=","} {printf("%s", $1)}')"

    # keep track of bytes used by all items
    byte_total="$(($byte_total + $bytes))"

    # owner
    owner="$(ls -la | sed -n "/$name$/p" | awk '{print $3}')"

    # percentage of fs space being used by items
    percentage="$(echo "scale=10;$bytes/$fs_total*100" | bc -l)"

    # gb being used by the items
    gb="$(echo "scale=4;$bytes/$bytes_per_gb" | bc -l)"

    item_type=""
    if [ -d "$name" ] ; then
        item_type="D"
    elif [ -f "$name" ] ; then
        item_type="F"
    else
        # this should never happen
        item_type="?"
    fi

    # print directory data
    printf "%16f    %10f    %20d    %-14s    %s: %s\n" "$gb" "$percentage" "$bytes" "$owner" "$item_type" "$name"

done < "$out_sorted"

# overall statistics
echo ""

fs_percent_accounted="$(echo "scale=10;$byte_total/$fs_total*100" | bc -l )"
fs_percent_missing="$(echo "scale=10;$fs_percent_used-$fs_percent_accounted" | bc -l )"
fs_free="$((100-$fs_percent_used))"

gb_dir="$(echo "scale=4;$byte_total/$bytes_per_gb" | bc -l)"
gb_fs="$(echo "scale=4;$fs_total/$bytes_per_gb" | bc -l)"

echo " GB accounted for:    $gb_dir of $gb_fs"
echo " Bytes accounted for: $byte_total of $fs_total"
printf " Percent accounted for:   %.2f%%\n" "$fs_percent_accounted"
printf " Percent unaccounted for: %.2f%%\n" "$fs_percent_missing"
echo " Free storage: ${fs_free}%"
echo ""

# clean up
rm "$out_unsorted"
rm "$out_sorted"
