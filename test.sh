#!/bin/bash

if [ ${#} == "0" ] ; then
    if ! bundle "exec" "rake" "tests" ; then
        exit 1
    fi
fi

for test in ${@} ; do
    if ! bundle "exec" "rake" "test:${test}" ; then
        exit 1
    fi
done