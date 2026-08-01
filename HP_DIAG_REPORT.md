# HP_DIAG_REPORT

Generated: 2026-08-01T16:48:24Z (UTC)
Local:     2026-08-01T16:48:24+0000
Pwd:       /home/sg/hp-twingate-setup
User:      sg uid=1000 gid=1000

## Identity

### hostname

```text
hp
```

### uname

```text
Linux hp 7.0.0-28-generic #28-Ubuntu SMP PREEMPT_DYNAMIC Sun Jun 21 01:01:36 UTC 2026 x86_64 GNU/Linux
```

### whoami / id

```text
uid=1000(sg) gid=1000(sg) groups=1000(sg),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),100(users),101(lxd),983(docker)
```

## Addresses (all)

### hostname -I

```text
192.168.1.10 172.18.0.1 172.17.0.1 172.19.0.1 172.20.0.1 172.20.0.254 
```

### ip -br a

```text
lo               UNKNOWN        127.0.0.1/8 ::1/128 
wlo1             UP             192.168.1.10/24 metric 1024 fe80::7266:55ff:fe02:24e9/64 
br-85610a4e62c6  DOWN           172.18.0.1/16 
docker0          DOWN           172.17.0.1/16 
br-bc232ee42e68  UP             172.19.0.1/16 fe80::6b:3ff:fea9:596e/64 
veth7c9b597@if2  UP             fe80::6c77:d1ff:fef2:5d8a/64 
br-0c43ec10c987  UP             172.20.0.1/16 172.20.0.254/16 fe80::4866:92ff:fef7:9582/64 
veth8a930c7@if2  UP             fe80::30e1:48ff:feb6:74d5/64 
```

### ip -4 addr

```text
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: wlo1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    inet 192.168.1.10/24 metric 1024 brd 192.168.1.255 scope global dynamic wlo1
       valid_lft 60038sec preferred_lft 60038sec
3: br-85610a4e62c6: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    inet 172.18.0.1/16 brd 172.18.255.255 scope global br-85610a4e62c6
       valid_lft forever preferred_lft forever
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
5: br-bc232ee42e68: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    inet 172.19.0.1/16 brd 172.19.255.255 scope global br-bc232ee42e68
       valid_lft forever preferred_lft forever
7: br-0c43ec10c987: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    inet 172.20.0.1/16 brd 172.20.255.255 scope global br-0c43ec10c987
       valid_lft forever preferred_lft forever
    inet 172.20.0.254/16 scope global secondary br-0c43ec10c987
       valid_lft forever preferred_lft forever
```

## Routes

### ip route

```text
default via 192.168.1.1 dev wlo1 proto dhcp src 192.168.1.10 metric 1024 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
172.18.0.0/16 dev br-85610a4e62c6 proto kernel scope link src 172.18.0.1 linkdown 
172.19.0.0/16 dev br-bc232ee42e68 proto kernel scope link src 172.19.0.1 
172.20.0.0/16 dev br-0c43ec10c987 proto kernel scope link src 172.20.0.1 
192.168.1.0/24 dev wlo1 proto kernel scope link src 192.168.1.10 metric 1024 
192.168.1.1 dev wlo1 proto dhcp scope link src 192.168.1.10 metric 1024 
```

### default route

```text
default via 192.168.1.1 dev wlo1 proto dhcp src 192.168.1.10 metric 1024 
```

## DNS

### resolvectl

```text
Global
         Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
  resolv.conf mode: stub

Link 2 (wlo1)
    Current Scopes: DNS
         Protocols: +DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 192.168.1.1
       DNS Servers: 192.168.1.1 2401:4900:50:9::7dd 2401:4900:50:9::7bb
     Default Route: yes

Link 3 (br-85610a4e62c6)
    Current Scopes: none
         Protocols: -DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
     Default Route: no

Link 4 (docker0)
    Current Scopes: none
         Protocols: -DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
     Default Route: no

Link 5 (br-bc232ee42e68)
    Current Scopes: none
         Protocols: -DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
     Default Route: no

Link 6 (veth7c9b597)
    Current Scopes: none
         Protocols: -DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
     Default Route: no

Link 7 (br-0c43ec10c987)
    Current Scopes: none
         Protocols: -DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
     Default Route: no

Link 8 (veth8a930c7)
    Current Scopes: none
         Protocols: -DefaultRoute -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
     Default Route: no
```

## SSH host keys (fingerprints)

### ed25519 host key

```text
== /etc/ssh/ssh_host_ed25519_key.pub ==
256 SHA256:0sgqaJxH2YXgZna9i7jv/peR7g86zDKhFc4tgMmHS5U root@hp (ED25519)
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIlGoFKbwQAROogeqTcRBQGTONCTEiG4rEnWSWth/0nu root@hp
== /etc/ssh/ssh_host_rsa_key.pub ==
3072 SHA256:QG6mhg/1ZKnU0BsMuJ3GEvhEI9dIavMGiM9FilZZzng root@hp (RSA)
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCh6rB9HN5rQuqn7a9PWaHmMbkbILkVDDEi41IaS+U5Ghgx0sbOFfEXckFJQeqMBDa0JBSeMZGxn5By5dO8s4zHs0HYgmJqRbxh9SWnrEzps3V3L1AVAS2v/Q85uR//bT0RaoLt79T4btiOdgZK/PGL/ev2MetLREwHQDQeNL6/M6PJ/0r7HtpBkAp5gPWwfvCJI9EJyzO6Ga5z+mmMYlG3aJNMaQyt0ZUQDSiw5YHtPBCkcnIFYgsd1xmB6DchaRSHQVYw+66Dg2l14+JxKPQsMDc16/TDKF0RM9KuEtANBcTmCogctfNfic/rNlonEFV0YECrbecMQsOJVc8XE2ki9i0PrEPXYL5B4UM3SRm4mBcP882UVBMYusWPBjHrhpZPQWWfL+0QbMhG5GBvmD9V4RKlXJz2hymSBufgqUcVLCX0u988f3ZqpdDF6b78vKQWvWzqA1Bzk5eoXgtAQDXP5UiNyHDoYFcwMhCj3mUJkHn+UWe1Pm9kWQx7RXSThfc= root@hp
== /etc/ssh/ssh_host_ecdsa_key.pub ==
256 SHA256:l3Uh3lrFo5QPAP1Bu+USDEILzVpHnTKeJ0iWXDegqyg root@hp (ECDSA)
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHnNtyJ1GSGz78x+s7NRFFvNGydbblJwIltR2kIOmvLIAxFkxh7zBe+YqzCC95hrhpfdoscKRq+0gyri7rcIudw= root@hp
```

## sshd service

### systemctl ssh/sshd

```text
active
disabled
active
alias
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; disabled; preset: enabled)
     Active: active (running) since Sat 2026-08-01 10:20:10 UTC; 6h ago
 Invocation: 0b7f025b439c4cdd80aab7def4bb4add
TriggeredBy: ● ssh.socket
       Docs: man:sshd(8)
             man:sshd_config(5)
   Main PID: 41529 (sshd)
      Tasks: 1 (limit: 30909)
     Memory: 2.7M (peak: 9.4M)
        CPU: 1.359s
     CGroup: /system.slice/ssh.service
             └─41529 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Aug 01 15:16:51 hp sshd-session[193302]: pam_unix(sshd:session): session opened for user sg(uid=1000) by sg(uid=0)
Aug 01 15:25:34 hp sshd-session[198289]: Connection closed by 172.20.0.2 port 35852
Aug 01 15:25:34 hp sshd-session[198290]: Connection closed by 172.20.0.2 port 35866 [preauth]
Aug 01 15:25:53 hp sshd-session[198406]: Connection closed by 172.20.0.2 port 45822
Aug 01 15:25:53 hp sshd-session[198425]: Connection closed by 172.20.0.2 port 45824 [preauth]
Aug 01 15:48:53 hp sshd-session[210164]: Connection closed by 192.168.1.10 port 34146
Aug 01 15:50:03 hp sshd-session[214367]: Connection closed by 172.20.0.3 port 40475
Aug 01 15:50:48 hp sshd-session[215213]: Connection closed by 172.20.0.3 port 37417
Aug 01 16:06:19 hp sshd-session[222848]: Connection closed by 172.20.0.2 port 60726
Aug 01 16:06:22 hp sshd-session[222996]: Connection closed by 172.20.0.2 port 50774 [preauth]
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; disabled; preset: enabled)
     Active: active (running) since Sat 2026-08-01 10:20:10 UTC; 6h ago
 Invocation: 0b7f025b439c4cdd80aab7def4bb4add
TriggeredBy: ● ssh.socket
       Docs: man:sshd(8)
             man:sshd_config(5)
   Main PID: 41529 (sshd)
      Tasks: 1 (limit: 30909)
     Memory: 2.7M (peak: 9.4M)
        CPU: 1.359s
     CGroup: /system.slice/ssh.service
             └─41529 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

Aug 01 15:16:51 hp sshd-session[193302]: pam_unix(sshd:session): session opened for user sg(uid=1000) by sg(uid=0)
Aug 01 15:25:34 hp sshd-session[198289]: Connection closed by 172.20.0.2 port 35852
Aug 01 15:25:34 hp sshd-session[198290]: Connection closed by 172.20.0.2 port 35866 [preauth]
Aug 01 15:25:53 hp sshd-session[198406]: Connection closed by 172.20.0.2 port 45822
Aug 01 15:25:53 hp sshd-session[198425]: Connection closed by 172.20.0.2 port 45824 [preauth]
Aug 01 15:48:53 hp sshd-session[210164]: Connection closed by 192.168.1.10 port 34146
Aug 01 15:50:03 hp sshd-session[214367]: Connection closed by 172.20.0.3 port 40475
Aug 01 15:50:48 hp sshd-session[215213]: Connection closed by 172.20.0.3 port 37417
Aug 01 16:06:19 hp sshd-session[222848]: Connection closed by 172.20.0.2 port 60726
Aug 01 16:06:22 hp sshd-session[222996]: Connection closed by 172.20.0.2 port 50774 [preauth]
```

## Listeners (22 / ssh)

### ss -lntp

```text
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      4096      127.0.0.54:53        0.0.0.0:*          
LISTEN 0      4096         0.0.0.0:22        0.0.0.0:*          
LISTEN 0      4096   127.0.0.53%lo:53        0.0.0.0:*          
LISTEN 0      4096         0.0.0.0:5433      0.0.0.0:*          
LISTEN 0      4096            [::]:22           [::]:*          
LISTEN 0      4096            [::]:5433         [::]:*          
```

### grep :22

```text
LISTEN 0      4096         0.0.0.0:22        0.0.0.0:*          
LISTEN 0      4096            [::]:22           [::]:*          
```

## sshd_config (relevant)

### sshd -T (effective)

```text
(sshd -T failed — need sudo?)
```

### config files

```text
```

## Firewall

### ufw

```text
(ufw n/a)
```

### iptables INPUT

```text
```

### nft

```text
```

## Local TCP self-tests (must show success for SSH path)

### nc/bash /dev/tcp checks

```text
127.0.0.1:22 OPEN (nc)
172.17.0.1:22 OPEN (nc)
172.18.0.1:22 OPEN (nc)
172.19.0.1:22 OPEN (nc)
172.20.0.1:22 OPEN (nc)
172.20.0.2:22 closed/fail (nc)
172.20.0.254:22 OPEN (nc)
192.168.1.10:22 OPEN (nc)
```

## SSH banner locally (first line)

### banners

```text
127.0.0.1: SSH-2.0-OpenSSH_10.2p1 Ubuntu-2ubuntu3.5
172.20.0.254: SSH-2.0-OpenSSH_10.2p1 Ubuntu-2ubuntu3.5
172.20.0.1: SSH-2.0-OpenSSH_10.2p1 Ubuntu-2ubuntu3.5
172.20.0.2: ```

## Users / sg

### id sg

```text
uid=1000(sg) gid=1000(sg) groups=1000(sg),4(adm),24(cdrom),27(sudo),30(dip),46(plugdev),100(users),101(lxd),983(docker)
```

### sg authorized_keys

```text
== /home/sg/.ssh/authorized_keys ==
2 /home/sg/.ssh/authorized_keys
256 SHA256:+lviAnMRUI5tKTuiY1M8RWln41IgEisMPnvrPi+eteE codex-brain-vostro (ED25519)
256 SHA256:D/nrWY5njy9+eoNcfJw0w+H96j2lykJPIbOiKTVtOcw ssearchitout@gmail.com (ED25519)
== /home/sg/.ssh/authorized_keys ==
2 /home/sg/.ssh/authorized_keys
256 SHA256:+lviAnMRUI5tKTuiY1M8RWln41IgEisMPnvrPi+eteE codex-brain-vostro (ED25519)
256 SHA256:D/nrWY5njy9+eoNcfJw0w+H96j2lykJPIbOiKTVtOcw ssearchitout@gmail.com (ED25519)
```

## Docker / odd interfaces

### docker

```text
NAMES                   PORTS
lifeos-twingate-1       
creepy-brain            
creepy-brain-postgres   0.0.0.0:5433->5432/tcp, [::]:5433->5432/tcp
```

### 172.17 bridge

```text
br-85610a4e62c6  DOWN           172.18.0.1/16 
docker0          DOWN           172.17.0.1/16 
br-bc232ee42e68  UP             172.19.0.1/16 fe80::6b:3ff:fea9:596e/64 
br-0c43ec10c987  UP             172.20.0.1/16 172.20.0.254/16 fe80::4866:92ff:fef7:9582/64 
```

## Connectivity toward gateway / connector hints

### ping gateway

```text
gateway=192.168.1.1
PING 192.168.1.1 (192.168.1.1) 56(84) bytes of data.
64 bytes from 192.168.1.1: icmp_seq=1 ttl=64 time=18.0 ms
64 bytes from 192.168.1.1: icmp_seq=2 ttl=64 time=10.2 ms

--- 192.168.1.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 10.214/14.099/17.984/3.885 ms
```

### ping 172.20.0.2 (connector historically)

```text
PING 172.20.0.2 (172.20.0.2) 56(84) bytes of data.
64 bytes from 172.20.0.2: icmp_seq=1 ttl=64 time=0.083 ms
64 bytes from 172.20.0.2: icmp_seq=2 ttl=64 time=0.100 ms

--- 172.20.0.2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1047ms
rtt min/avg/max/mdev = 0.083/0.091/0.100/0.008 ms
```

### ping 172.21.0.2 (connector peer seen from Mac)

```text
PING 172.21.0.2 (172.21.0.2) 56(84) bytes of data.

--- 172.21.0.2 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1015ms

```

## Netplan / NM snippets

### netplan files

```text
total 16
drwxr-xr-x   2 root root 4096 Jul  4 17:11 .
drwxr-xr-x 120 root root 4096 Jul 28 06:36 ..
-rw-------   1 root root  288 Jul  4 16:53 00-installer-config.yaml
-rw-r--r--   1 root root  128 Jul  4 17:11 50-cloud-init.yaml
---- /etc/netplan/00-installer-config.yaml ----
---- /etc/netplan/50-cloud-init.yaml ----
network:
  version: 2
  wifis:
    wlo1:
      dhcp4: true
      access-points:
        "Goel":
          password: "goel1234"

```

### nmcli

```text
```

## Summary block (machine-parsed)

```text
hostname=hp
user=sg
ips=192.168.1.10,172.18.0.1,172.17.0.1,172.19.0.1,172.20.0.1,172.20.0.254,
sshd_active=active
listen22=LISTEN 0      4096         0.0.0.0:22        0.0.0.0:*          |LISTEN 0      4096            [::]:22           [::]:*          |
ed25519_fingerprint=SHA256:0sgqaJxH2YXgZna9i7jv/peR7g86zDKhFc4tgMmHS5U
has_172_20_0_1=1
has_172_20_0_254=1
has_172_20_0_2=1
has_172_17_0_1=1
```

=== END HP_DIAG_REPORT ===
