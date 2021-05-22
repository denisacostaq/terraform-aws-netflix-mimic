%{ for alias, ip in nodes }alias ${alias}='ssh -oStrictHostKeyChecking=no ubuntu@${ip}'
%{ endfor }
