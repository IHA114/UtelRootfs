#!/bin/sh
#
# internet.sh,v 10.08.05 2010-08-05 15:00:00
#
# usage: internet.sh
#
path_sh=`nv get path_sh`
. $path_sh/global.sh
echo "Info: internet.sh start" > $test_log
echo "Info: `date +%m-%d %H:%M:%S`" >> $test_log

genSysFiles()
{
	login=`nv get Login`
	pass=`nv get Password`
	echo "$login::0:0:Adminstrator:/:/bin/sh" > /etc/passwd
	echo "$login:x:0:$login" > /etc/group
	echo "$login:$pass" > /tmp/tmpchpw
	chpasswd < /tmp/tmpchpw
	rm -f /tmp/tmpchpw
}
user_login=`cat /etc/passwd | grep admin`
#user_login�����ڻ�Ϊ��ʱ��ִ�к���genSysFiles
[ -n "$user_login" ] || { genSysFiles;}

safe_run()
{
	ps > ${test_log}/ps.tmp
	flag=`grep -w "$1" ${test_log}/ps.tmp`
	if [ "-${flag}" = "-" ];then
		$1 &
	fi
	rm -rf ${test_log}/ps.tmp
}

#��̬nv�ÿ�
#. $path_sh/cfgnv_init.sh
pswan=`nv get pswan`
ethwan=`nv get ethwan`
wifiwan=`nv get wifiwan`
echo 0 > /proc/sys/net/ipv6/conf/$pswan"1"/accept_ra
echo 0 > /proc/sys/net/ipv6/conf/$pswan"2"/accept_ra
echo 0 > /proc/sys/net/ipv6/conf/$pswan"3"/accept_ra
echo 0 > /proc/sys/net/ipv6/conf/$pswan"4"/accept_ra
echo 0 > /proc/sys/net/ipv6/conf/$ethwan/accept_ra
echo 0 > /proc/sys/net/ipv6/conf/$wifiwan/accept_ra

#EC �������Ӹ������ֵ
echo 7248 > /proc/sys/net/nf_conntrack_max
echo 7200 > /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_established

#zte_mainctrl &

#��br_name,usblan_name�����ں�ʵ��ƽ̨��
fast_usb=`nv get fast_usb`
lan_enable=`nv get LanEnable`

#LanEnableΪ2ʱ��û��br������Ҫдbr_name
if [ "$lan_enable" != "2" ]; then
    echo $lan_if > /proc/net/br_name
fi

echo $fast_usb > /proc/net/usb_name

#br0���������dhcp
sh $path_sh/lan.sh

#������ת�����𴫸��ں�
fastnat_level=`nv get fastnat_level`
echo "Info: set fastnat_level��$fastnat_level" >> $test_log
echo $fastnat_level > /proc/net/fastnat_level

#����֧�ֿ���ת����Э��˿ںŴ����ں�
nofast_port=`nv get nofast_port`
echo "Info: set nofast_port��$nofast_port" >> $test_log
echo $nofast_port > /proc/net/nofast_port

killall -9 miniupnpd
rm -rf $path_conf/inadyn.status

#
#��ʼ��ʱһ�������ø���ģ�����ֵ��
#��Ӧ�������ļ���/etc_ro/net_debug.conf
#
while read i
do
    MYKEY=`echo $i|awk 'BEGIN{FS="="}{print $1}'`
    MYVALUE=`echo $i|awk 'BEGIN{FS="="}{print $2}'`
    echo "${MYVALUE}">/sys/module/net_ext_modul/parameters/${MYKEY}
done</etc_ro/net_debug.conf

#��¼���̱������ź�killed��
netdog -s exitsig=1

#����ں�skb�����Ϣ�����ֵ
safe_run netmonitor

#����ں˵�netlink�¼����ļ���֧���ں��Զ����¼������дflash�汾Ĭ�Ϲر�
#safe_run event_proc
