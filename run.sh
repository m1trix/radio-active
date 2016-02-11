#!/bin/bash

if [ ${#} -gt "0" ] && [ "${1}" == 'init' ] ; then
	ruby lib/radioactive.rb "RDN4awrpPQQ" "QcIy9NiNbmo" "My2FRPA3Gf8"
else
	ruby lib/radioactive.rb
fi