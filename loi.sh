#!/bin/bash

echo "What should I do?"
echo "1) 6to4"
echo "2) 6to4 multi server (1 outside 2 Iran)"
echo "3) Remove tunnels"
echo "4) Enable BBR"
echo "5) Fix Whatsapp Time"
echo "6) Optimize"
echo "7) Install x-ui"
echo "8) Change NameServer"
echo "9) Disable IPv6 - After server reboot IPv6 is activated"
read -p "Select an option (1, 2, 3, 4, 5, 6, 7, 8, or 9): " server_choice

setup_rc_local() {
    FILE="/etc/rc.local"
    commands="$1"

    # Ensure the file exists and is executable, or create it if it does not
    if [ -f "$FILE" ]; then
        sudo bash -c "echo -e '#!/bin/bash\n\nexit 0' > $FILE"
    else
        echo -e '#!/bin/bash\n\nexit 0' | sudo tee "$FILE" > /dev/null
    fi
    sudo chmod +x "$FILE"

    # Add new commands above 'exit 0'
    sudo bash -c "sed -i '/exit 0/i $commands' $FILE"
    echo "Commands added to /etc/rc.local"

    # Execute the commands immediately
    eval "$commands"
    echo "Commands executed immediately."
}

# Function to handle 6to4 configuration
handle_six_to_four() {
    echo "Setting up 6to4..."
    # Placeholder for 6to4 configuration commands
}

# Function to handle 6to4 multi-server (1 outside 2 Iran)
handle_six_to_four_multi_outside_iran() {
    echo "Which server is this?"
    echo "1) Outside"
    echo "2) Iran1"
    echo "3) Iran2"
    read -p "Select an option (1, 2, or 3): " server_role

    case $server_role in
        1)
            # Outside server configuration
            read -p "Enter the IP Outside: " ipkharej1
            read -p "Enter the IP Iran1: " ipiran1
            read -p "Enter the IP Iran2: " ipiran2

            # Generate the commands for outside configuration
            commands=$(cat <<EOF
#!/bin/bash

# تنظیمات تونل برای اولین سرور ایران
ip tunnel add 6to4_To_IR1 mode sit remote \$ipkharej1 local \$ipiran1
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

# تنظیمات تونل برای دومین سرور ایران
ip tunnel add 6to4_To_IR2 mode sit remote \$ipkharej1 local \$ipiran2
ip -6 addr add 2009:480:1f10:e1f::2/64 dev 6to4_To_IR2
ip link set 6to4_To_IR2 mtu 1480
ip link set 6to4_To_IR2 up

ip -6 tunnel add GRE6Tun_To_IR2 mode ip6gre remote 2009:480:1f10:e1f::1 local 2009:480:1f10:e1f::2
ip addr add 10.10.11.2/30 dev GRE6Tun_To_IR2
ip link set GRE6Tun_To_IR2 mtu 1436
ip link set GRE6Tun_To_IR2 up

exit 0
EOF
)
            echo "$commands" | sudo tee /etc/rc.local > /dev/null
            sudo chmod +x /etc/rc.local
            echo "Commands for 6to4 multi server (Outside) have been set."
            ;;
        2|3)
            # Iran1 or Iran2 server configuration
            if [ "$server_role" -eq 2 ]; then
                ipiran1_prompt="Enter the IP Iran1"
                ipiran1_var="ipiran1"
                ipkharej_prompt="Enter the IP Outside"
                ipkharej_var="ipkharej1"
            else
                ipiran1_prompt="Enter the IP Iran2"
                ipiran1_var="ipiran2"
                ipkharej_prompt="Enter the IP Outside"
                ipkharej_var="ipkharej2"
            fi

            read -p "$ipiran1_prompt: " ipiran1
            read -p "$ipkharej_prompt: " ipkharej1
            read -p "Enter the IP Iran2: " ipiran2
            read -p "Enter the required ports (e.g., 8080,9090,6060): " ports
            port_list=$(echo "$ports" | tr ',' ' ')

            # Generate commands based on ports
            iptables_rules=""
            for port in $port_list; do
                iptables_rules+="iptables -t nat -A PREROUTING -p tcp --dport $port -j DNAT --to-destination 10.10.10.1\n"
            done

            # Commands for Iran1 or Iran2 server
            commands=$(cat <<EOF
#!/bin/bash
# Variables
ipiran1="$ipiran1"
ipkharej1="$ipkharej1"
port1="$port_list"

ip tunnel add 6to4_To_KH mode sit remote \$ipkharej1 local \$ipiran1
ip -6 addr add 2002:480:1f10:e1f::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote 2002:480:1f10:e1f::2 local 2002:480:1f10:e1f::1
ip addr add 10.10.10.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

# Enable IPv4 forwarding
sysctl net.ipv4.ip_forward=1

# IPTables rules
$iptables_rules

iptables -t nat -A POSTROUTING -j MASQUERADE

exit 0
EOF
)
            echo "$commands" | sudo tee /etc/rc.local > /dev/null
            sudo chmod +x /etc/rc.local
            echo "Commands for 6to4 multi server ($ipiran1) have been set."
            ;;
        *)
            echo "Invalid option. Please select 1, 2, or 3."
            ;;
    esac
}

# Function to handle Remove Tunnels
remove_tunnels() {
    echo "Removing tunnels..."
    sudo ip tunnel del 6to4_To_IR1 2>/dev/null
    sudo ip tunnel del GRE6Tun_To_IR1 2>/dev/null
    sudo ip tunnel del 6to4_To_IR2 2>/dev/null
    sudo ip tunnel del GRE6Tun_To_IR2 2>/dev/null
    sudo ip link del 6to4_To_IR1 2>/dev/null
    sudo ip link del GRE6Tun_To_IR1 2>/dev/null
    sudo ip link del 6to4_To_IR2 2>/dev/null
    sudo ip link del GRE6Tun_To_IR2 2>/dev/null

    # Clear /etc/rc.local
    echo -e '#!/bin/bash\n\nexit 0' | sudo tee /etc/rc.local > /dev/null
    echo "Tunnels removed and /etc/rc.local cleared."
}

# Function to handle Enable BBR
enable_bbr() {
    wget --no-check-certificate -O /opt/bbr.sh https://github.com/teddysun/across/raw/master/bbr.sh
    chmod 755 /opt/bbr.sh
    /opt/bbr.sh
    echo "BBR optimization enabled."
}

# Function to handle Fix Whatsapp Time
fix_whatsapp_time() {
    commands="sudo timedatectl set-timezone Asia/Tehran"
    setup_rc_local "$commands"
    echo "Whatsapp time fixed to Asia/Tehran timezone."
}

# Function to handle Optimize
optimize() {
    USER_CONF="/etc/systemd/user.conf"
    SYSTEM_CONF="/etc/systemd/system.conf"
    sudo sed -i 's/#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=65535/' $USER_CONF $SYSTEM_CONF
    sudo systemctl daemon-reload
    echo "System optimized."
}

# Function to handle Install x-ui
install_x_ui() {
    wget -O x-ui.sh https://raw.githubusercontent.com/x-ui/x-ui/master/install.sh
    chmod +x x-ui.sh
    ./x-ui.sh
    echo "x-ui installed."
}

# Function to handle Change NameServer
change_nameserver() {
    read -p "Enter the new nameserver: " nameserver
    file="/etc/resolv.conf"
    if [ -f "$file" ]; then
        sudo bash -c "echo 'nameserver $nameserver' > $file"
        echo "Nameserver updated."
    else
        echo "$file does not exist."
    fi
}

# Function to handle Disable IPv6
disable_ipv6() {
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
    echo "IPv6 has been disabled."
}

# Execute the selected option
case $server_choice in
    1)
        handle_six_to_four
        ;;
    2)
        handle_six_to_four_multi_outside_iran
        ;;
    3)
        remove_tunnels
        ;;
    4)
        enable_bbr
        ;;
    5)
        fix_whatsapp_time
        ;;
    6)
        optimize
        ;;
    7)
        install_x_ui
        ;;
    8)
        change_nameserver
        ;;
    9)
        disable_ipv6
        ;;
    *)
        echo "Invalid option. Please select 1, 2, 3, 4, 5, 6, 7, 8, or 9."
        ;;
esac
