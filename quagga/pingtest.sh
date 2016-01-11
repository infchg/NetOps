
ip ad

PONG=' -c2 -W1  ' # ping only 2 twice and dont wait more than 1 secs

echo 'pinging Tokyo nodes and lo pp interfaces'
ping TokyoGW  $PONG
ping TokyoGW-lo  $PONG
ping TokyoGW-pp  $PONG
ping TokyoN1  $PONG
ping TokyoN2  $PONG



echo 'pinging Barcelona nodes and lo pp interfaces'
ping BarnaGW  $PONG
ping BarnaGW-lo  $PONG
ping BarnaGW-pp  $PONG
ping BarnaN1  $PONG
ping BarnaN2  $PONG

