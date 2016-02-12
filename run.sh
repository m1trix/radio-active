#!/bin/bash

if [ ${#} -gt "0" ] && [ "${1}" == 'init' ] ; then
	ruby app.rb "RDN4awrpPQQ" "QcIy9NiNbmo" "My2FRPA3Gf8"
else
	ruby app.rb
fi