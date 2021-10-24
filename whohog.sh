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
    if [ -d "$item" ] ; then
        du -h -sb "$item" | sed -E 's/\s+/,/g' >> "$out_unsorted"
    fi

done

# sort directories in descending order by bytes
sort -t, -r -nk1 "$out_unsorted" > "$out_sorted"

# '/' needs to be converted to '\/' in order to be regular expression friendly
target="$(echo "$target" | sed 's|/|\\/|g')"
# df provised the number of 1024 byte units being used
fs_1k_blocks="$(df | sed -n "/${target}$/p" | awk '{print $2}')"
# multiply the number of 1024 byte units by 1024 to get the number of bytes
fs_total="$(( $fs_1k_blocks * 1024 ))"

# bytes used by dirs
all_dir_totals=0
# bytes per gb
bytes_per_gb=1073741824

# table header
echo "                 Dir     Gigabytes       Percent        Bytes"
echo " --------------------------------------------------------------------"

# directory statistics
while read -r line; do

    # get directory name
    name="$(echo "$line" | awk 'BEGIN{FS=","} {printf("%s", $2)}')"
    # bytes used by the directory
    used="$(echo "$line" | awk 'BEGIN{FS=","} {printf("%s", $1)}')"
    # keep track of bytes used by all directories
    all_dir_totals="$(($all_dir_totals + $used))"
    # percentage of fs space being used by the directory
    percentage="$(echo "scale=10;$used/$fs_total*100" | bc -l)"
    # gb being used by the directory
    gb="$(echo "scale=4;$used/$bytes_per_gb" | bc -l)"

    # print directory data
    printf "%20s    %12f    %10f    %15d\n" "$name" "$gb" "$percentage" "$used"

done < "$out_sorted"

# overall statistics
echo ""
percent_accounted="$(echo "scale=10;$all_dir_totals/$fs_total*100" | bc -l )"
percent_missing="$(echo "scale=10;100-$percent_accounted" | bc -l )"
gb_dir="$(echo "scale=4;$all_dir_totals/$bytes_per_gb" | bc -l)"
gb_fs="$(echo "scale=4;$fs_total/$bytes_per_gb" | bc -l)"
echo " Gigabytes accounted for: $gb_dir of $gb_fs"
echo " Bytes accounted for:     $all_dir_totals of $fs_total"
echo " Percent accounted for:   $percent_accounted"
echo " Percent unaccounted for: $percent_missing"
echo ""

# clean up
rm "$out_unsorted"
rm "$out_sorted"
