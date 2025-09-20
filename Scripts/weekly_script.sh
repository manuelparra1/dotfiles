while IFS= read -r file; do
  cp "$file" ./WK22-Update/ 
done < ./wk_22.txt
