if (( BASH_VERSINFO[0] < 4 || \
    (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 2) )); then
    echo "Bash 4.2 or later required."
    exit 1
fi
