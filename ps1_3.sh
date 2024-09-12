RESET=$(printf "\033[0m")

RED=$(printf "\033[91m")
YELLOW=$(printf "\033[93m")
GREEN=$(printf "\033[92m")
CYAN=$(printf "\033[96m")
BLUE=$(printf "\033[94m")
MAGENTA=$(printf "\033[95m")
WHITE=$(printf "\033[97m")

prompt(){
	exitcode=$?
	printf $MAGENTA	
	printf $(date '+%H:%M')
	printf " "
	printf $WHITE
	printf $(tty)
	printf " "
	printf $CYAN
	printf $(whoami)
	printf "@"
	printf $(hostname)
	printf " "
        printf $YELLOW
	printf $(pwd)
	printf $RESET
	printf " > "	
}

PS1="\$(prompt)"
