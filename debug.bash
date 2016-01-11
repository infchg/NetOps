#!/bin/bash
echo "THIS debug BGP logs in every quaga image !!! "
echo "USE with care if you have hundreds of quag images !! "
if [ "$EUID" -ne 0 ]
  then echo "Please this demo run as root, e.g.  sudo ./sdnbgp.bash  "
  exit
fi

# this automation can me moved to ansible whenever if number of nodes becomes much higher


 docker ps |grep quag | awk '{print $1}'| xargs -n1 -I^ docker exec ^ bash -c 'hostname && netstat -nr && tail  /var/log/quagga/bgpd.log '

 docker ps |grep quag | awk '{print $1}'| xargs -n1 -I^ docker exec ^  vtysh -c 'sh ip bgp' 


echo "checking neigboors 1.1.1.1 and 2 in each GW, should complain for himself and succeed for the neighboor"
 docker ps |grep quag | awk '{print $1}'| xargs -n1 -I^ docker exec ^ vtysh -c 'sh ip bgp neig 10.1.1.1' 
 docker ps |grep quag | awk '{print $1}'| xargs -n1 -I^ docker exec ^ vtysh -c 'sh ip bgp neig 10.1.1.2' 

echo "checking BGP learned routes in each GW"  
 docker ps |grep quag | awk '{print $1}'| xargs -n1 -I^ docker exec ^ vtysh -c 'sh ip rou bgp ' 


echo -e "\n---- Test: Ping Tokyo and Barna from Tokyo N2 - to compare with the non-pinging baseline ----\n"

PONG=' -c2 -W1  ' # ping only 2 twice and dont wait more than 1 secs
 docker exec $TokyoN2 ping 192.168.101.1    $PONG
 docker exec $TokyoN2 ping 192.168.101.2   $PONG
 docker exec $TokyoN2 ping 192.168.1.2  $PONG
 docker exec $TokyoN2 ping 192.168.1.1   $PONG




exit 
#example output for debugging: 
#  two cases below
## TBL-2  a case where BGP advertised network was mistaken, 
## TBL-1  in the case below a config file was missing : hence the log was not there and bgp daemon was not running


Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG        0 0          0 eth0
1.0.0.0         0.0.0.0         255.0.0.0       U         0 0          0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 eth0
192.168.1.0     0.0.0.0         255.255.255.0   U         0 0          0 eth1
2016/01/05 13:08:54 BGP: %NOTIFICATION: received from neighbor 1.1.1.1 2/2 (OPEN Message Error/Bad Peer AS) 2 bytes fe 0a
2016/01/05 13:11:28 BGP: %NOTIFICATION: sent to neighbor 1.1.1.1 2/2 (OPEN Message Error/Bad Peer AS) 2 bytes fe 0a
2016/01/05 13:11:28 BGP: Notification sent to neighbor 1.1.1.1: shutdown
2016/01/05 13:11:28 BGP: %NOTIFICATION: received from neighbor 1.1.1.1 2/2 (OPEN Message Error/Bad Peer AS) 2 bytes fe 0a
2016/01/05 13:13:26 BGP: %NOTIFICATION: sent to neighbor 1.1.1.1 2/2 (OPEN Message Error/Bad Peer AS) 2 bytes fe 0a
2016/01/05 13:13:26 BGP: Notification sent to neighbor 1.1.1.1: shutdown
2016/01/05 13:13:26 BGP: %NOTIFICATION: received from neighbor 1.1.1.1 2/2 (OPEN Message Error/Bad Peer AS) 2 bytes fe 0a
2016/01/05 13:14:37 BGP: %NOTIFICATION: sent to neighbor 1.1.1.1 2/2 (OPEN Message Error/Bad Peer AS) 2 bytes fe 0a
2016/01/05 13:14:37 BGP: Notification sent to neighbor 1.1.1.1: shutdown
2016/01/05 13:14:37 BGP: %NOTIFICATION: received from neighbor 1.1.1.1 2/2 (OPEN Message Error/Bad Peer AS) 2 bytes fe 0a


Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG        0 0          0 eth0
1.0.0.0         0.0.0.0         255.0.0.0       U         0 0          0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 eth0
192.168.101.0   0.0.0.0         255.255.255.0   U         0 0          0 eth1
tail: cannot open '/var/log/quagga/bgpd.log' for reading: No such file or directory

----> 


## TBL-2  in the case below the BGP advertised network was mistaken, 



b0cc23460d77
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG        0 0          0 eth0
1.0.0.0         0.0.0.0         255.0.0.0       U         0 0          0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 eth0
192.168.1.0     0.0.0.0         255.255.255.0   U         0 0          0 eth1
2016/01/05 14:09:03 BGP: BGPd 0.99.22.4 starting: vty@2605, bgp@<all>:179
2016/01/05 14:09:06 BGP: stream_read_try: read failed on fd 12: Connection reset by peer
2016/01/05 14:09:06 BGP: 1.1.1.2 [Error] bgp_read_packet error: Connection reset by peer
2016/01/05 14:09:07 BGP: %ADJCHANGE: neighbor 1.1.1.2 Up
811a643f4168
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         172.17.0.1      0.0.0.0         UG        0 0          0 eth0
1.0.0.0         0.0.0.0         255.0.0.0       U         0 0          0 eth0
172.17.0.0      0.0.0.0         255.255.0.0     U         0 0          0 eth0
192.168.101.0   0.0.0.0         255.255.255.0   U         0 0          0 eth1
2016/01/05 14:09:00 BGP: BGPd 0.99.22.4 starting: vty@2605, bgp@<all>:179
2016/01/05 14:09:07 BGP: %ADJCHANGE: neighbor 1.1.1.1 Up
BGP table version is 0, local router ID is 10.1.1.34
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, R Removed
Origin codes: i - IGP, e - EGP, ? - incomplete

   Network          Next Hop            Metric LocPrf Weight Path
*  192.168.1.0      1.1.1.2                  0             0 65081 i
*>                  0.0.0.0                  0         32768 i

Total number of prefixes 1
BGP table version is 0, local router ID is 10.1.1.81
Status codes: s suppressed, d damped, h history, * valid, > best, i - internal,
              r RIB-failure, S Stale, R Removed
Origin codes: i - IGP, e - EGP, ? - incomplete

   Network          Next Hop            Metric LocPrf Weight Path
*  192.168.1.0      1.1.1.1                  0             0 65034 i
*>                  0.0.0.0                  0         32768 i

Total number of prefixes 1
