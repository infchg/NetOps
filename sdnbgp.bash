#!/bin/bash

# sdnbgp.bash    SDN Docker Quagga BGP peering demo
#
# DATE: Code 2015/12/28 + tuning submitted the following year : ! Happy 2016 !
#
# Assumptions.
# 1. virtualized with Docker (available using vbox or kvm or esx or nutanix on request)
# 2. simulate network with linux bridge (available with OVS or Neutron or private on request) 
#
# AUTHOR: M. J. Carlos / 
# EMAIL:  infchg.appspot () gmail . com. 
#
# GIT:  github SDN-docker-quagga-BGP-peering
#
# AREA:  SDN PaaS Telecom IaaS UNDP SaaS UNDPKO Missions
#
# LOG:
# 2016/1/3 improved inter-container networking with a pipe-workaround (otherwise put midonet or ovs there),
#
# for Malaga and BuenosAires' coder offices the GWs used 1.1.1.33 and 1.1.1.34/30
# currently using Tokyo and Barcelona for this demo.
# 

########## This demos needs to be run as root || whoami eq 'root' or $EUID '$(id -u)' != '0' 
if [ "$EUID" -ne 0 ]
  then echo "Please this demo run as root, e.g.  sudo ./sdnbgp.bash  "
  exit
fi
 
# 
# Nets         192.168.101.0/24             1.1.1.0/30                   192.168.1.0/24
#                    br2                        br12                     br1
#    TokyoN1  -------------------- TokyoGW ---------------- BarnaGW -------------- BarnaN1
#        .1                    .254       .2               .1     .254            .1
#  

################## two lines usefull to debug, sharing a filesystem
## -v /usr/local/sdnbgp:/usr/local/sdnbgp   removed later
## also removed /bin/sh -c "/usr/local/demo/test.sh; /usr/sbin/sshd -D"
mkdir -p /usr/local/sdnbgp && chmod 777 /usr/local/sdnbgp   #rarely used 

##################  Start Tokyo & Barna Nodes, containers
echo -e "\n---- Starting Tokyo & Barna Nodes, containers  ----\n"
export TokyoN1=$(docker run -dti --net=none -v /usr/local/sdnbgp:/usr/local/sdnbgp ubuntu:14.04 bash)
export TokyoN2=$(docker run -dti --net=none  ubuntu:14.04 bash)
export BarnaN1=$(docker run -dti --net=none  ubuntu:14.04 bash)
export BarnaN2=$(docker run -dti --net=none  ubuntu:14.04 bash)

cat <<FIN
---- the Node containers are ---- 
TokyoN1    $TokyoN1 
TokyoN2    $TokyoN2 
BarnaN1    $BarnaN1 
BarnaN2    $BarnaN2
FIN

################## 
echo -e "\n---- Building Gateway image with Quagga & BGP :  name =  ubun.quag.bgp "
  docker build -t  ubun.quag.bgp  .

##################  Creating Tokyo GW for the demo
echo  -e "\n---- Creating Tokyo GW for the demo ----\n"
echo  -e "\n--- running quagga with  --privileged=true    ---\n"
# ref vzctl set CTID --capability net_admin:on --save
# originally created --net=none  for later networking, now networking via host(as internet)
export TokyoGW=$(docker run -dti   --privileged=true   ubun.quag.bgp   )
docker exec $TokyoGW   bash -c ' rename -v s/TokyoGW\.// /etc/quagga/* && ifconfig lo:10 10.1.1.81 up  && ifconfig eth0:12 1.1.1.2 up  && cp /etc/quagga/hosts /etc'
 
##################  Creating Barna GW for the demo
echo -e "\n---- Creating Barcelona GW for the demo ----\n"
echo -e "\n--- running quagga with  --privileged=true    ----\n"
# --net=none 
export BarnaGW=$(docker run -dti    --privileged=true   ubun.quag.bgp   )
docker exec $BarnaGW   bash -c ' rename -v s/BarnaGW\.// /etc/quagga/* && ifconfig lo:10 10.1.1.34 up  && ifconfig eth0:12 1.1.1.1 up  && cp /etc/quagga/hosts /etc'
 
cat <<FIN
---- the Gateway containers are ---- 
TokyoGW    $TokyoGW   
BarnaGW    $BarnaGW 
FIN
 
 

# Use 3rd-party app (pipework bridge or mido or ovs ...) to network the containers 
echo  -e "\n---- networking tokyo in the Tokyo subnet 192.168.101.0 ----\n"
pierrecdn/pipework.sh br2 $TokyoN1 192.168.101.1/24 192.168.101.255 192.168.101.254

pierrecdn/pipework.sh br2 $TokyoN2 192.168.101.2/24 192.168.101.255 192.168.101.254

pierrecdn/pipework.sh br2 $TokyoGW 192.168.101.254/24 192.168.101.255 172.0.0.1 #gw to internet/host


################## Test
echo -e "\n---- Test: Ping Tokyo local net but not Barna - baseline to compare with peering ----\n"

 docker exec $TokyoN2 ping 192.168.101.1 -c2 -W2
 docker exec $TokyoN2 ping 192.168.101.2 -c2 -W2
 docker exec $TokyoN2 ping 192.168.101.254 -c2 -W2
 docker exec $TokyoN2 ping 192.168.1.254 -c2 -W2


# Use 3rd-party app (pipework bridge or mido or ovs ...) to network the containers 
echo -e "\n---- networking Barcelona in the Barcelona subnet 192.168.1.0/24 ----\n"
pierrecdn/pipework.sh br1 $BarnaN1 192.168.1.1/24 192.168.1.255 192.168.1.254

pierrecdn/pipework.sh br1 $BarnaN2 192.168.1.2/24 192.168.1.255 192.168.1.254

pierrecdn/pipework.sh br1 $BarnaGW 192.168.1.254/24 192.168.1.255  172.0.0.1  #gw to internet/host


################## Test
echo -e "\n---- Test:  Barna net Pingable but Tokyo unreacheable- baseline to compare with peering ----\n"

 docker exec $BarnaN2 ping 192.168.101.1   -A -c2 -W2
 docker exec $BarnaN2 ping 192.168.1.1   -A -c2 -W2
 docker exec $BarnaN2 ping 192.168.101.2   -A  -c2 -W2
 docker exec $BarnaN2 ping 192.168.1.2   -A -c2 -W2
 
# Use 3rd-party app (pipework bridge or mido or ovs ...) to network the containers 
echo -e "\n---- networking point to point link between Gateways   1.1.1.0/30 ----\n"
 
#  cannot use pipework until  the change proposed 30dec was implemented .. tbd
#pierrecdn/pipework.sh br12 $BarnaGW 1.1.1.1/24 1.1.1.3 1.1.1.2  
#pierrecdn/pipework.sh br12 $TokyoGW 1.1.1.2/24 1.1.1.3 1.1.1.2     #intentionally wrong route

# instead : just use connectivity via the internet (in this case host docker0)

#the most elegant is a GRE tunnel
 docker exec $TokyoGW  lsmod | grep gre
# ip_gre                 22432  0
#gre                    12989  1 ip_gre

# to create a GRE tunnel between two interfaces with the following IP addresses.
#    Host A: 172.17.0.2  
#   Host B: 172.17.0.3
#On host A,  the following command.
# sudo ip tunnel add gre0 mode gre remote 172.17.0.3 local 172.17.0.2 ttl 255
# sudo ip link set gre0 up
# sudo ip addr add 1.1.1.1/24 dev gre0 

 docker exec $TokyoGW  ping -c2 -W2 1.1.1.2 
  docker exec $TokyoGW  ping -c2 -W2 1.1.1.1  


##################  Starting Tokyo GW for BGP
echo -e "\n---- Starting Tokyo GW for BGP ----\n"
 docker exec $TokyoGW   /etc/init.d/quagga restart 
 
################## Test
echo -e "\n---- Test: without connectivity - baseline to compare with peering ----\n"
 docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip bgp sum' 
 docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip bgp neig' 
  docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip rou  ' 
  docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip rou bgp' 
  docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip bgp neig 1.1.1.2' 
#% No such neighbor
  docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip bgp neig 10.1.1.34' 
echo -e "\n---- Test:  Tokyo GW pings Barna GW ----\n"
docker exec  $TokyoGW   ping 1.1.1.1 -c2

 
##################  Starting Barcelona GW for BGP peering
echo -e "\n---- Starting Barcelona GW for BGP peering ----\n"
 docker exec $BarnaGW   /etc/init.d/quagga restart 
 
################## give 1 sec ESTABLISH BGP PEERING
echo -e "\n---- give 1 sec to ESTABLISH BGP PEERING ----\n" 
 sleep 2
 
################## Test
echo -e "\n---- Test: now Tokyo should show connectivity and see peering ----\n"
 docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip bgp sum' 
 docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip bgp neig' 
  docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip rou  ' 
  docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip rou bgp' 
  docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip bgp neig 1.1.1.1' 
#% No such neighbor
  docker exec $TokyoGW   /usr/bin/vtysh -c 'sh ip bgp neig 10.1.1.34' 
echo -e "\n---- Test:  Tokyo GW pings Barna GW ----\n"
docker exec  $TokyoGW   ping 1.1.1.1 -c2
 
 ################## Test Barn
echo -e "\n---- Test: now Barna with connectivity -  to see peering ----\n"
 docker exec $BarnaGW   /usr/bin/vtysh -c 'sh ip bgp sum' 
 docker exec $BarnaGW   /usr/bin/vtysh -c 'sh ip bgp neig' 
  docker exec $BarnaGW   /usr/bin/vtysh -c 'sh ip rou  ' 
  docker exec $BarnaGW   /usr/bin/vtysh -c 'sh ip rou bgp' 
  docker exec $BarnaGW   /usr/bin/vtysh -c 'sh ip bgp neig 1.1.1.2' 
#% No such neighbor
  docker exec $BarnaGW   /usr/bin/vtysh -c 'sh ip bgp neig 10.1.1.81' 
echo -e "\n---- Test:  Tokyo GW pings Barna GW ----\n"
docker exec  $BarnaGW   ping 1.1.1.2 -c2
 
 
 
################## Test
echo -e "\n---- Test: Ping Tokyo local net AND Barna TOO - after BGP peering ----\n"

 docker exec $TokyoN2 ping 192.168.101.1 -c2 -W2
 docker exec $TokyoN2 ping 192.168.101.2 -c2 -W2
 docker exec $TokyoN2 ping 192.168.1.1 -c2 -W2
 docker exec $TokyoN2 ping 192.168.1.2 -c2  -W2

 
################## Test
echo -e "\n---- Test: Ping every one from BarnaGW   ----\n"

 docker exec $BarnaGW sh /etc/quagga/pingtest.sh  

###### TO Continue your test the containers are:  
cat <<FIN
---- TO Continue your test the containers are ---- 
TokyoN1    $TokyoN1 
TokyoN2    $TokyoN2 
BarnaN1    $BarnaN1 
BarnaN2    $BarnaN2
TokyoGW    $TokyoGW   
BarnaGW    $BarnaGW 

YOU SHOULD SEE ABOVE PEERING AS BGP router identifier 10.1.1.81, local AS number 65081
 SEE Peers 1, using 4560 bytes of memory
 SEE Neighbor        V    AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
 SEE 1.1.1.1         4 65034       0       1        0    0    0 never    Active     
 SEE in the LOGS 2016/01/05 14:28:40 BGP: %ADJCHANGE: neighbor 1.1.1.2 Up
 DO sh ip bgp neig 1.1.1.1' 
 SEE  BGP neighbor is 1.1.1.1, remote AS 65034, local AS 65081, external link
 SEE  Description: neighboor Barna
 SEE   BGP version 4, remote router ID 10.1.1.34
 SEE   BGP state = Established, up for 00:25:54
 DO 'sh ip rou bgp '  
 SEE B>* 192.168.101.0/24 [150/0] via 1.1.1.2, eth0, 00:29:50
 DO 'sh ip rou bgp '  in Tokyo GW  
 SEE B>* 192.168.1.0/24 [150/0] via 1.1.1.1, eth0, 00:29:50
 
 NOW YOU CAN ALSO RUN
   sudo ./debug.sh
 IN ORDER TO SEE MORE TESTS
   
FIN


