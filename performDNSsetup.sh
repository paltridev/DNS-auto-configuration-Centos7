#! /bin/bash

echo "


       ********************************************
       *  DNS CONFIGURATION BY TRIDEV 		  *
       *                                          *
       ********************************************
"

yum install bind -y 
yum install bind-utils -y

echo "Enter IP of virtual Machine"
read ip

echo ""
sed -i 's|	listen-on port 53 { 127.0.0.1; };|	listen-on port 53 { 127.0.0.1;'$ip'; };|g' /etc/named.conf #search and replace line

sed -i 's|	listen-on-v6 port 53 { ::1; };|#	listen-on-v6 port 53 { ::1; };|g' /etc/named.conf #search and replace line

echo "Enter IP netmask of virtual Machine (IP address with last byte being 0 with /24. i.e 192.168.100.0/24 )"
read ipNetmask

sed -i 's|	allow-query     { localhost; };|	allow-query     { localhost;'$ipNetmask'; };|g' /etc/named.conf #search and replace line

echo "Enter domain name you want to configure"
read domainName

sed -i '58 a	zone "'$domainName'" IN {' /etc/named.conf
sed -i '59 a\	type master;' /etc/named.conf
sed -i '60 a\	file "forward.zone";' /etc/named.conf
sed -i '61 a\	allow-update {none; };' /etc/named.conf    
sed -i '62 a	};' /etc/named.conf
sed -i '63 a\	' /etc/named.conf

echo ""
echo "Enter ip address in reverse order (i.e. 192.168.100.2 = 100.168.192 )"
read reverseIp

sed -i '64 a	zone "'$reverseIp'.in-addr.arpa" IN {' /etc/named.conf
sed -i '65 a\	type master;' /etc/named.conf
sed -i '66 a\	file "reverse.zone";' /etc/named.conf
sed -i '67 a\	allow-update {none; };' /etc/named.conf    
sed -i '68 a	};' /etc/named.conf
sed -i '69 a\	' /etc/named.conf

echo ""
echo " named.conf configured "

if [ -f /var/named/forward.zone ]
then
	echo "" 
	echo "file exist"
else
	touch /var/named/forward.zone
	echo ""
	echo " forward.zone created "
fi

if [ -f /var/named/reverse.zone ]
then
	echo "" 
	echo "file exist"
else
	touch /var/named/reverse.zone
	echo ""
	echo " reverse.zone created "
fi

sed -i '1 a	$TTL 86400' /var/named/forward.zone
sed -i '2 a	@	IN SOA	dns.'$domainName'. root.'$domainName'. (' /var/named/forward.zone
sed -i '3 a\	2019111400	;Serial' /var/named/forward.zone
sed -i '4 a\	3600	;Refresh' /var/named/forward.zone
sed -i '5 a\	1800	;Retry' /var/named/forward.zone
sed -i '6 a\	604800	;Expire' /var/named/forward.zone
sed -i '7 a\	86400	) ;Minimum TTL' /var/named/forward.zone
sed -i '8 a\	' /var/named/forward.zone

sed -i '9 a	@	IN NS	dns.'$domainName'.' /var/named/forward.zone
sed -i '10 a	@	IN A	'$ip'' /var/named/forward.zone
sed -i '11 a\	' /var/named/forward.zone
sed -i '12 a	dns	IN A	'$ip'' /var/named/forward.zone
sed -i '13 a	www	IN CNAME	dns' /var/named/forward.zone
echo ""
echo "forward.zone configured"
echo ""
echo ""
echo "enter last byte number of IP address ( i.e for 192.168.100.50 it is 50 )"
read lastByte

sed -i '1 a	$TTL 86400' /var/named/reverse.zone
sed -i '2 a	@	IN SOA	dns.'$domainName'. root.'$domainName'. (' /var/named/reverse.zone
sed -i '3 a\	2019111400	;Serial' /var/named/reverse.zone
sed -i '4 a\	3600	;Refresh' /var/named/reverse.zone
sed -i '5 a\	1800	;Retry' /var/named/reverse.zone
sed -i '6 a\	604800	;Expire' /var/named/reverse.zone
sed -i '7 a\	86400	) ;Minimum TTL' /var/named/reverse.zone
sed -i '8 a\	' /var/named/reverse.zone

sed -i '9 a	@	IN NS	dns.'$domainName'.' /var/named/reverse.zone
sed -i '10 a	@	IN PTR	'$domainName'.' /var/named/reverse.zone
sed -i '11 a	dns	IN A	'$ip'' /var/named/reverse.zone
sed -i '12 a	www	IN A	'$ip'' /var/named/reverse.zone
sed -i '13 a	'$lastByte'	IN PTR	dns.'$domainName'.' /var/named/reverse.zone
sed -i '14 a	'$lastByte'	IN PTR	www.'$domainName'.' /var/named/reverse.zone
echo ""
echo "reverse.zone configured"
echo ""

chgrp named /var/named/forward.zone
chgrp named /var/named/reverse.zone

sed -i 's|#Listen 12.34.56.78:80|Listen '$ip':80|g' /etc/httpd/conf/httpd.conf

sed -i 's|Listen 80|#Listen 80|g' /etc/httpd/conf/httpd.conf
sed -i 's|ServerAdmin root@localhost|ServerAdmin root@'$domainName'|g' /etc/httpd/conf/httpd.conf
sed -i 's|#ServerName www.example.com:80|ServerName www.'$domainName':80|g' /etc/httpd/conf/httpd.conf

echo "IP Configuration done in /etc/httpd/conf/httpd.conf"
echo ""

sed -i 's|search localdomain||g' /etc/resolv.conf #search and replace line
sed -i '1 a	domain '$domainName'' /etc/resolv.conf
sed -i '2 a	search '$domainName'' /etc/resolv.conf
sed -i '3 a	nameserver '$ip'' /etc/resolv.conf
sed -i '4 a	nameserver 127.0.0.1' /etc/resolv.conf

echo "resolv Configuration done in /etc/resolv.conf"
echo ""

service httpd stop
service named stop
service httpd start
service named start

echo "


       ********************************************
       *  DNS CONFIGURATION DONE		  *
       *                                          *
       ********************************************
"

