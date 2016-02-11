#!/bin/bash

if [ ${#} -gt "0" ] && [ "${1}" == 'init' ] ; then
	ruby lib/radioactive.rb "YQHsXMglC9A" "QcIy9NiNbmo" "e-ORhEE9VVg"
else
	ruby lib/radioactive.rb
fi