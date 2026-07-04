kernel=$(uname -m && uname -sr)
echo $kernel
kernel=${kernel//$'\n'/ }
echo $kernel
kernel=$(uname -a | cut -f 3- -d ' ')
echo $kernel
