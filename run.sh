#!/bin/bash

if [ ${#} -gt "0" ] && [ "${1}" == 'init' ] ; then
	ruby lib/radioactive.rb "qx1A5-XlEkw" "RDN4awrpPQQ" "QcIy9NiNbmo"
else
	ruby lib/radioactive.rb
fi