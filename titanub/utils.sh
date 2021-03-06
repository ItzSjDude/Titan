#!/bin/bash


declare -r minPVer=8
declare -r maxPVer=10

getPythonVersion() {
    local -i count=$minPVer
    local tmp
    while true; do
        tmp=$(python3.$count -V 2> /dev/null)
        [[ -n $tmp || $count -gt $maxPVer ]] && break
        count+=1
    done
    declare -gr pVer=$(sed -E 's/Python (3\.[0-9]{1,2}\.[0-9]{1,2}).*/\1/g' <<< $tmp)
}

log() {
    local text="$*"
    test ${#text} -gt 0 && test ${text::1} != '~' \
        && echo -e "[$(date +'%d-%b-%y %H:%M:%S') - INFO] - titanub - ${text#\~}"
}

quit() {
    local err="\t:: ERROR :: $1\nExiting With SIGTERM (143) ..."
    if (( getMessageCount )); then
        replyLastMessage "$err"
    else
        log "$err"
    fi
    exit 143
}

runPythonCode() {
    python${pVer%.*} -c "$1"
}

runPythonModule() {
    python${pVer%.*} -m "$@"
}

gitInit() {
    git init &> /dev/null
}

gitClone() {
    git clone "$@" &> /dev/null
}

remoteIsExist() {
    grep -q $1 < <(git remote)
}

addHeroku() {
    git remote add heroku $HEROKU_GIT_URL
}

addUpstream() {
    git remote add $UPSTREAM_REMOTE ${UPSTREAM_REPO%.git}.git
}

updateUpstream() {
    git remote rm $UPSTREAM_REMOTE && addUpstream
}

fetchUpstream() {
    git fetch $UPSTREAM_REMOTE &> /dev/null
}

fetchBranches() {
    local r_bs l_bs
    r_bs=$(grep -oP '(?<=refs/heads/)\w+' < <(git ls-remote --heads $UPSTREAM_REMOTE))
    l_bs=$(grep -oP '\w+' < <(git branch))
    for r_b in $r_bs; do
        [[ $l_bs =~ $r_b ]] || git branch $r_b $UPSTREAM_REMOTE/$r_b &> /dev/null
    done
}

updateBuffer() {
    git config http.postBuffer 524288000
}

upgradePip() {
    pip3 install -U pip &> /dev/null
}

installReq() {
    pip3 install -r $1/requirements.txt &> /dev/null
}

printLine() {
    echo '->- ->- ->- ->- ->- ->- ->- --- -<- -<- -<- -<- -<- -<- -<-'
}
