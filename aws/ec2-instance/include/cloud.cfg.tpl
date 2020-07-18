#cloud-config
# vim: syntax=yaml
locale: ${locale}
timezone: ${timezone}

package_upgrade: true
%{ if create_ssm_agent == true ~}
packages:
    - https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
%{ endif ~}

write_files:
    - path: /etc/environment
      content: |
        LC_ALL=en_US.UTF-8
%{ if ecs_cluster_name != null }
    - path: /etc/ecs/ecs.config
      content: |
        ECS_CLUSTER=${ecs_cluster_name}
%{ endif ~}

%{ if create_nat == true ~}
bootcmd:
    - [ sh, -c, "echo 1 > /proc/sys/net/ipv4/ip_forward; echo 655361 > /proc/sys/net/netfilter/nf_conntrack_max" ]
%{ for src_cidr in nat_src_cidrs ~}
    - [ iptables, -t, nat, -I, POSTROUTING, -s, ${src_cidr}, -d, ${nat_dst_cidr}, -j, MASQUERADE ]
%{ endfor ~}
%{ endif ~}
