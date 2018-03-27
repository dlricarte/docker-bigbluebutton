#!/bin/bash
# Little helper start script for BigBlueButton in a docker container.
# Author: Juan Luis Baptiste <juan.baptiste@gmail.com>
#set -x
# Import our environment variables from systemd
for e in $(tr "\000" "\n" < /proc/1/environ); do
        eval "export $e"
done
. /functions.sh
DEFAULT_BBB_INSTALL_DEMOS="no"

# Sleep to give the container services time to start.
sleep 10

IP=`get_ip`

if [ ! -z "$BBB_INSTALL_DEMOS" -a "$BBB_INSTALL_DEMOS" == "yes" ]; then
    echo -e "\e[92mInstalling BigBlueButton demo package...\n\e[0m"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --allow-unauthenticated bbb-demo
    [ $? -gt 0 ] && echo - "ERROR: Could not intall the demos." && exit 1
    echo -e "\e[92mDone.\e[0m\n"
fi

# ln -s /dev/stdout /var/log/bigbluebutton/bbb-web.log
# ln -s /dev/stdout /var/log/bigbluebutton/bbb-rap-worker.log

echo -e "\e[92mStarting BigBlueButton services...\e[0m"
# service redis-server start
# [ -d /var/run/bbb-apps-akka ] || install -m 755 -o bigbluebutton -g bigbluebutton -d /var/run/bbb-apps-akka
# cd /usr/share/bbb-apps-akka
# exec sudo -u bigbluebutton bin/bbb-apps-akka&

# set_var "bbb.sip.app.ip" "127.0.0.1" /usr/share/red5/webapps/sip/WEB-INF/bigbluebutton-sip.properties
# set_var "freeswitch.ip" "127.0.0.1" /usr/share/red5/webapps/sip/WEB-INF/bigbluebutton-sip.properties
#sed -i "s/<X-PRE-PROCESS cmd=\"set\" data=\"local_ip_v4=*/<\!--<X-PRE-PROCESS cmd=\"set\" data=\"local_ip_v4=/; /<X-PRE-PROCESS cmd=\"set\" data=\"local_ip_v4=*/s/\"\/>/\"\/>-->/" /opt/freeswitch/conf/vars.xml
#set_var "bind_server_ip" "${CONTAINER_IP}\"\/>" /opt/freeswitch/conf/vars.xml
#set_var "external_rtp_ip" "${CONTAINER_IP}\"\/>" /opt/freeswitch/conf/vars.xml
#set_var "external_sip_ip" "${CONTAINER_IP}\"\/>" /opt/freeswitch/conf/vars.xml
#sed -i -r "/ext-rtp-ip/s/(.*value*[=,:] *\").*/\1\$\$\{external_rtp_ip\}\"\/>/" /opt/freeswitch/conf/sip_profiles/external.xml
#sed -i -r "/ext-sip-ip/s/(.*value*[=,:] *\").*/\1\$\$\{external_sip_ip\}\"\/>/" /opt/freeswitch/conf/sip_profiles/external.xml

echo -e "\e[92mUpdating BigBlueButton IP address configuration...\e[0m"

if [ ! -z "$SERVER_NAME" ];then
    echo -e "\n\e[92mUsing $SERVER_NAME as hostname.\e[0m"
    #Add an entry to /etc/hosts pointing the container IP address
    #to $SERVER_NAME
    printf '%s\t%s\n' $IP $SERVER_NAME | cat >> /etc/hosts
    CONTAINER_IP=$IP
    IP=$SERVER_NAME
fi

#Set new hostname
bbb-conf --setip $IP
#Replace the IP address on the demo web app, it seems
#bbb-conf --setip doesn't do it
echo -e "\n\e[92mChanging IP address in demo API:\e[0m $IP"
sed -ri "s/(.*BigBlueButtonURL *= *\").*/\1http:\/\/$IP\/bigbluebutton\/\";/" /var/lib/tomcat7/webapps/demo/bbb_api_conf.jsp



# Warning: Detected the directory
#    /var/bigbluebutton/screenshare
# is not owned by red5
# Not running:  LibreOffice



#[ ! -z $SERVER_SALT ] && echo -e "\n\e[92mSetting Salt to:\e[0m $SERVER_SALT" && bbb-conf --setsecret $SERVER_SALT
#It seems that some times bbb-conf --setsecret doesn't set the secret on the demo api conf file.
#sed -ri "s/(.*salt *= *\").*/\1$SERVER_SALT\";/" /var/lib/tomcat7/webapps/demo/bbb_api_conf.jsp

#Fix permissions when using a volume container
chown -R tomcat7:tomcat7 /var/bigbluebutton

#For some reason sometimes meetings fail when started from mconf-web
#until we clean the installation
#bbb-conf --enablewebrtc
#bbb-conf --restart
# echo -e "\n\e[92mCleaning configuration...\n\e[0m"
# bbb-conf --clean

#echo -e "\n\e[92mChecking configuration...\n"
#bbb-conf --check

echo -e "\n\e[92m*******************************************\e[0m"
echo -e "\n\e[0mUse this address to access your \nBigBlueButton container:\e[92m \n\nhttp://$IP\n\e[0m"
echo -e "\n\e[0mThe container's internal IP address \nis:\e[92m $CONTAINER_IP\n\e[0m"
echo -e "\n\e[92m*******************************************\e[0m\n"

#Ugly hack: Infinite loop to maintain the container running
#while true;do sleep 100000;done
#/sbin/init
