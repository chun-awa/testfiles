PS1="\[\033[95m\]\A\[\033[00m\] \
\[\033[96m\]\u@\h\[\033[00m\] \
\[\033[93m\]\w\[\033[00m\]\
\`exitcode=\$?;[ \$exitcode -eq 0 ]||echo \"\033[91m\] [\$exitcode]\033[0m\]\"\` \
> "