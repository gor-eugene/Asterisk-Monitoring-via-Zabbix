#!/bin/bash

# sip_status.sh  - generate sipstatus.html to include in zabbix screen

HTMLFILE='/var/www/html/sipstatus.html'
FONT="<font color=black face='verdana, arial, helvetica, sans-serif' size='2' />"
/bin/echo "<html><body><table>" >> $HTMLFILE

# place that wherever you want

# number of offline extensions --- show peers
#UserParameter=asterisk.extensions_offline,sudo -u zabbix sudo asterisk -rx "sip show peers" | grep -v trunk | grep -v --text -i "sip peers" | grep -v Forceport | grep UNKNOW | wc -l
/usr/sbin/asterisk -rx "sip show peers" | \
/bin/grep -E -v --text -i 'trunk-|sip peers|Forcerport' | \
/bin/gawk '{print $1,$8}' | \
/bin/sed 's/\/.* / /' | \
while LINE= read -r line; do
        SIPNUMBER=`/bin/echo $line | /bin/gawk '{print $1}'`
        SIPNAME=`/usr/sbin/asterisk -rx "database show" | /bin/grep AMPUSER | /bin/grep cidname | /bin/grep $SIPNUMBER | /usr/bin/tr '/' ' ' | /bin/sed 's/AMPUSER.* ://'`
        SIPSTATUS=`/bin/echo $line | /bin/gawk '{if ($2 == "OK") print "ONLINE"; else print "OFFLINE"}'`
        if [ $SIPSTATUS == 'OFFLINE' ]; then
                COLOR='#FFBBBB'
        fi
        if [ $SIPSTATUS == 'ONLINE' ]; then
                COLOR='BBFFBB'
        fi

        /bin/echo "<tr><td bgcolor=$COLOR>" $FONT $SIPNUMBER "</td><td bgcolor=$COLOR>" $FONT $SIPNAME "</td><td bgcolor=$COLOR>" $FONT $SIPSTATUS "</td></tr>" >> $HTMLFILE
done

# number of offline extensions --- dongle show devices
# asterisk -rx "dongle show devices" | grep "Not\|not" | awk '{print $1,$3,$4}'
/usr/sbin/asterisk -rx "dongle show devices" | \
/bin/grep "Not\|not" | \
/bin/gawk '{print $1,$3,$4}' | \
while LINE= read -r line; do
        GSMNUM=`/bin/echo $line | /bin/gawk '{print $1}'`
        GSMSTATE=`/bin/echo $line | /bin/gawk '{if ($2 = "Not connec") print ("GSM " $1 " not connected"); else print "All GSM is work"}'`
        if [ $GSMSTATE != 'All GSM is work']; then
                COLOR='#FFBBBB'
        fi
        if [ $GSMSTATE == 'All GSM is work']; then
                COLOR='#BBFFBB'
        fi
        /bin/echo/ "<tr><td bgcolor=$color>" $FONT $GSMNUM "</td><td bgcolor=$COLOR>" $FONT $GSMSTATE "</td></tr>" >> $HTMLFILE
done

# total number of trunks ---- sip show registry
# asterisk -rx "sip show registry" | grep -v "registrations" | grep -v "Reg.Time" | gawk 'END{print NR}'
# UserParameter=asterisk.trunks_total,sudo -u zabbix sudo asterisk -rx "sip show registry" | grep -v "registrations" | grep -v "Reg.Time" | wc -l
/usr/sbin/asterisk -rx "sip show registry" | \
/bin/grep -v 'registrations\|Reg.Time' | \
/bin/gawk 'END{print NR}' | \
while LINE= read -r line; do
        TNOT=`/bin/echo $line | /bin/gawk '{print "Total numbers of trnks: ", $1}'`
        if [ $TNOT == 0 ]; then 
                COLOR='#FFBBBB'
        fi
        if [ $TNOT != 0 ]; then 
                COLOR='#BBFFBB'
        fi
        /bin/echo/ "<tr><td bgcolor=$COLOR>" $FONT $TNOT "</td></tr>" >> $HTMLFILE
done

# number of registered trunks
#asterisk -rx "sip show registry" | grep -v "registrations" | grep -v "Reg.Time" | grep Registered | gawk 'END{print NR}'
/usr/sbin/asterisk -rx "sip show registry" | \
/bin/grep -v "registrations" | \
/bin/grep -v "Reg.Time" | \
/bin/grep 'Registered' | \
/bin/gawk 'END{print NR}' | \
while LINE= read -r line; do
        NORT=`/bin/echo $line | /bin/gawk '{print "Total numbers of registered trunks: ", $1}'`
        if [ $NORT == 0 ]; then 
                COLOR='#FFBBBB'
        fi
        if [ $NORT != 0 ]; then 
                COLOR='#BBFFBB'
        fi
        /bin/echo/ "<tr><td bgcolor=$COLOR>" $FONT $NORT "</td></tr>" >> $HTMLFILE
done

# number of offline trunks
#UserParameter=asterisk.trunks_offline,sudo -u zabbix sudo asterisk -rx "sip show registry" | grep -v "registrations" | grep -v "Reg.Time" | grep -v Registered | wc -l
/usr/sbin/asterisk -rx "sip show registry" | \
/bin/grep -v "registrations" | \
/bin/grep -v "Reg.Time" | \
/bin/grep -v 'Registered' | \
/bin/gawk '{print $1, $3, $5" "$6}' | \
while LINE= read -r line; do
        HOST=`/bin/echo $line | /bin/gawk '{print $1}'`
        USERNAME=`/bin/echo $line | /bin/gawk '{print $2}'`
        STATE=`/bin/echo $line | /bin/gawk '{print $3" "$4}'`
        HSTATE=`/bin/gawk '{if ($STATE == "No Authentication") print ("On host ", $HOST, " user ", $USERNAME, " ", $STATE); else print "All OK"}'`
        TOTAL=`/bin/gawk 'END{print "Total number of offline trunks: ", NR}'`
        if [ $STATE == "No Authentication" ]; then
                COLOR='#FFBBBB'
        fi
        if [ $STATE == "Registered" ]; then
                COLOR='#BBFFBB'
        fi
        /bin/echo "<tr><td bgcolor=$COLOR>" $FONT $HSTATE "</td></tr>" >> $HTMLFILE
        /bin/echo "<tr><td bgcolor=$COLOR>" $FONT $TOTAL "</td></tr>" >> $HTMLFILE
done

# number of active calls
#UserParameter=asterisk.active_calls,sudo -u zabbix sudo asterisk -rvvvvvx 'core show channels'| grep --text -i 'active call'| cut -d ' ' -f1
/usr/sbin/asterisk -rvvvvvx 'core show channels' | \
/bin/grep --text -i 'active call' | \
/bin/cut -d ' ' -f1 | \
while LINE= read -r line; do
        NOAC=`/bin/echo $line | /bin/gawk '{print $1}'`
        NOACA=`/bin/echo $line | /bin/gawk '{if ($1 > 0) print ("We have some active calls: ", $NOAC, " total"); else print "Something went wrong, no active calls!"}'`
        if [ $NOAC == 0 ]; then
                COLOR='#FFBBBB'
        fi
        if [ $NOAC != 0 ]; then
                COLOR='#BBFFBB'
        fi
        /bin/echo "<tr><td bgcolor=$COLOR>" $FONT $NOACA "</td></tr>" >> $HTMLFILE
done

# number of seconds since last asterisk start
#UserParameter=asterisk.uptime,sudo -u zabbix sudo asterisk -rx "core show uptime seconds" | grep --text -i "System uptime:" | gawk '{print $3}'
/usr/sbin/asterisk -rx "core show uptime seconds" | \
/bin/grep --text -i "System uptime:" | \
/bin/gawk '{print $3}' | \
while LINE= read -r line; do
        UPTIMES=`/bin/echo $line | /bin/gawk '{print $1}'`
        TUPTIMES=`/bin/echo $line | /bin/gawk '{if ($1 == 0) print ("Something went wrong, system uptime = ", $UPTIMES, " seconds"); else print ("All good, system uptime = ", $UPTIMES, "seconds")}'`
        if [ $UPTIMES == 0  ]; then
                COLOR='#FFBBBB'
        fi
        if [ $UPTIMES > 0 ]; then
                COLOR='#BBFFBB'
        fi
        /bin/echo "<tr><td bgcolor=$COLOR>" $FONT $TUPTIMES "</td></tr>" >> $HTMLFILE
done

/bin/echo "</table></body></html>" >> $HTMLFILE
