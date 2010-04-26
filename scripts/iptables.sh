#!/bin/bash
# http://wiki.archlinux.org/index.php/Simple_stateful_firewall_HOWTO
#
# Set Up:
/etc/rc.d/iptables restart # Restart FW to try to catch module problems.
iptables -F                # Flush chains.
iptables -X                # Delete rules.
iptables -P INPUT DROP     # Block any incoming traffic.
iptables -P FORWARD DROP   # Same with the traversing one.
iptables -P OUTPUT ACCEPT  # We know what we do.
# We Rule:
iptables -A INPUT -i lo -j ACCEPT # Allow loopback.
iptables -A INPUT ! -i lo -m state --state ESTABLISHED,RELATED -j ACCEPT # Stateful rule.
iptables -A INPUT ! -i lo -p tcp --syn -m state --state NEW -m multiport --dports 22,6600 -j ACCEPT # New TCP traffic we'll allow.
iptables -A INPUT -j LOG -m limit --limit 3/s --limit-burst 8 --log-prefix "DROP " # Log the rest.
# Make the rules static:
/etc/rc.d/iptables save     # Save rules.
/etc/rc.d/iptables restart  # Restart FW.
iptables -vL --line-numbers # Print Rules.
exit 0                      # Exit gracefully.
