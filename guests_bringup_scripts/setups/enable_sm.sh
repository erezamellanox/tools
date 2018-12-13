sshpass -p 3tango ssh root@dev-h-vrt-009-010 <<'ENDSSH'
systemctl enable opensm
ENDSSH

sshpass -p 3tango ssh root@dev-h-vrt-009-011 <<'ENDSSH'
systemctl enable opensm
ENDSSH

sshpass -p 3tango ssh root@dev-h-vrt-009-012 <<'ENDSSH'
systemctl enable opensm
ENDSSH

sshpass -p 3tango ssh root@dev-h-vrt-009-014 <<'ENDSSH'
systemctl enable opensm
ENDSSH
