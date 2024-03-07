old_extension=$1
new_extension=$2
if [ -z "$old_extension" ] || [ -z "$new_extension" ]; then
  echo "Usage: ./script.sh <old_extension> <new_extension>"
  exit 1
fi

for file in *.$old_extension; do
  mv "$file" "${file%.$old_extension}.$new_extension"
done
