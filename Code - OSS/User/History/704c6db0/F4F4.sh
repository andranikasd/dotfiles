# ─── Directory navigation ───
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias cd-='cd -'

# ─── Listing & search ───
alias ll='ls -lh --group-directories-first --color=auto'
alias la='ls -lah --group-directories-first --color=auto'
alias lsd='ls -lh --group-directories-first --color=auto | grep "^d"'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# ─── Files & disk ───
alias df='df -h'
alias du='du -h'
alias dus='du -sh *'
alias free='free -h'
alias cpv='rsync -ah --info=progress2'   # Copy with progress
alias rmrf='rm -rf --one-file-system'    # Safe-ish rm -rf

# ─── Compression ───
alias untar='tar -xvf'
alias untgz='tar -xzvf'
alias untbz2='tar -xjvf'
alias untxz='tar -xJvf'
alias targz='tar -czvf'
alias tarbz2='tar -cjvf'
alias tarxz='tar -cJvf'

# ─── System info & monitoring ───
alias cls='clear'
alias please='sudo $(fc -ln -1)'
alias h='history'
alias cpuinfo='lscpu'
alias meminfo='free -h'
alias ports='ss -tuln'
alias myip='curl -s ifconfig.me'
alias topcpu='ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head'
alias topmem='ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head'