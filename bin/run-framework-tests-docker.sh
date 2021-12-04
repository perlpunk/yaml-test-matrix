#!/bin/ash

#set -x

if [[ ! -d /yaml-test-suite-data ]]; then
    echo "/yaml-test-suite-data needed"
    exit 1
fi

view="$1"

cd /yaml-test-suite-data

if [[ ! -d /matrix/tmp ]]; then
    echo "/matrix/tmp does not exist"
    exit 1
fi

runview() {
    local id=$1 subid=$2
    input=$id
    name=$id
    [[ -n "$subid" ]] && name="$id:$subid"
    [[ -n "$subid" ]] && input=$subid
    echo -n "Running $name   "$'\r'
    # echo "timeout 3 $view < $id/in.yaml > /matrix/tmp/$id.error 2>&1"
    touch /matrix/tmp/$name.error
    timeout 3 $view < $input/in.yaml > /matrix/tmp/$name.stdout 2>/matrix/tmp/$name.stderr
    if [[ $? -eq 0 ]]; then
        rm /matrix/tmp/$name.error
    fi
    [[ -f core ]] && rm core
}

echo "Running tests in docker..."
for id in [A-Z0-9]*
#for id in 229Q
do
    if [[ -f $id/in.yaml ]]; then
        runview $id ""
    else
        cd $id
        for subid in [0-9][0-9]*; do
            runview $id $subid
        done
        cd ..
    fi
done
echo "Done           "

