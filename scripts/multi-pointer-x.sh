#!/bin/bash

havesecondary=$( xinput list | grep "master pointer" -c )
primary=$( xinput list | grep "master pointer" -m 1 | awk '{ gsub("id=", "", $5); print $5 }' )
if [ "$havesecondary" -lt 2 ]
then
  xinput create-master "mymaster"
fi

secondary=$( xinput list | grep "master pointer" | awk 'NR==2 { gsub("id=", "", $(NF-3)); print $(NF-3) }' )

tp=$( xinput list | grep "Touchpad" | awk '{ v gsub("id=", "", $(NF-3)); print $(NF-3) }' )

echo "have=$havesecondary prim=$primary sec=$secondary tp=$tp"

order=$( xinput list | awk '{gsub("id=", "", $(NF-3)); print NR, $(NF-3)}' )

tpnum=$( echo "$order" | grep " $tp" | awk '{ print $1 }' )

if [ "$tpnum" -lt 10 ]
then
  # at original node
  xinput reattach $tp $secondary
else
  # restore to orig
  xinput reattach $tp $primary
fi


