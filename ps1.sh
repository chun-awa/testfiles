RESET=$(printf "\033[0m")
FG_RESET=$(printf "\033[39m")
BG_RESET=$(printf "\033[49m")

FG_RED=$(printf "\033[91m")
FG_YELLOW=$(printf "\033[93m")
FG_GREEN=$(printf "\033[92m")
FG_CYAN=$(printf "\033[96m")
FG_BLUE=$(printf "\033[94m")
FG_MAGENTA=$(printf "\033[95m")
FG_WHITE=$(printf "\033[97m")

BG_RED=$(printf "\033[101m")
BG_YELLOW=$(printf "\033[103m")
BG_GREEN=$(printf "\033[102m")
BG_CYAN=$(printf "\033[106m")
BG_BLUE=$(printf "\033[104m")
BG_MAGENTA=$(printf "\033[105m")
BG_WHITE=$(printf "\033[107m")

get_cpu_usage(){
    cpu_cores=$(echo $(awk '/cpu cores/{print $4}' /proc/cpuinfo)|cut -d ' ' -f 1)
    cpu_usage="$(ps aux | awk 'BEGIN {sum=0} {sum+=$3}; END {print sum}')"
    cpu_usage="$((${cpu_usage/\.*} / ${cpu_cores}))"
    printf "CPU ${cpu_usage}%%"
}

get_memory_usage(){
    mem_total=$(awk '/MemTotal/{print $2}' /proc/meminfo)
    mem_avail=$(awk '/MemAvailable/{print $2}' /proc/meminfo)
    mem_used=$(expr $mem_total - $mem_avail)
    mem_percent=$(expr $mem_used "*" 100 / $mem_total)
    printf "Mem $(expr $mem_used / 1024)MiB / $(expr $mem_total / 1024)MiB $mem_percent%%"
}

get_uptime(){
    uptime=$(cat /proc/uptime|cut -d ' ' -f 1)
    uptime=$((${uptime/\.*}))
    uptime=$(date -d @$uptime "+%Hh%Mm%Ss")
    printf "Uptime $uptime"
}

getexitcode(){
    printf $exitcode
}

getdate(){
    printf $(date '+%H:%M:%S')
}

leftprompt(){
    printf "\r$FG_YELLOW$(whoami)@$(hostname)$RESET $FG_CYAN$(pwd|sed "s|${HOME}|~|g")$RESET"
}

rightprompt(){
    p="$(get_cpu_usage) $(get_memory_usage) $(get_uptime) $(getexitcode) $(getdate)"
    for ((i=${#p};i<$COLUMNS;i++));do
        printf ' '
    done
    printf $FG_WHITE
    printf $BG_RED
    get_cpu_usage
    printf $BG_RESET
    printf " "
    printf $BG_MAGENTA
    get_memory_usage
    printf $BG_RESET
    printf " "
    printf $BG_BLUE
    get_uptime
    printf $BG_RESET
    printf $FG_RESET
    printf " "
    if [[ $exitcode == 0 ]];then
        printf $FG_GREEN
    else
        printf $FG_RED
    fi
    getexitcode
    printf $RESET
    printf " "
    printf $FG_WHITE
    getdate
    printf $RESET
}

prompt(){
    exitcode=$?
    rightprompt
    leftprompt
    echo
    if [[ $exitcode == 0 ]]; then
        printf "$FG_GREEN>$RESET "
    else
        printf "$FG_RED>$RESET "
    fi
}

PS1="\$(prompt)"
