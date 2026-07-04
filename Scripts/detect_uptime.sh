uptime=$(</proc/uptime)
echo $uptime
uptime=${uptime//.*}
echo $uptime
