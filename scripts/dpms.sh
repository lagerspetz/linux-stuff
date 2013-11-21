#!/bin/bash
standby=0
suspend=0
off=0

#sleep 10
cmd="xset dpms"
$cmd "${standby}" "${suspend}" "${off}"
synclient TapButton1=1
#synclient TapButton2=3
synclient TapButton3=2
synclient HorizTwoFingerScroll=1
