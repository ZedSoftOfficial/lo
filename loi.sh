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
    if [ ! -f "$FILE" ]; then
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
            read -p "Enter the required ports (e.g., 8080,9090,6060): " ports
            port_list=$(echo "$ports" | tr ',' ' ')

            # Generate the commands for outside configuration
            commands=$(cat <<EOF
#!/bin/bash

# تنظیمات تونل برای اولین سرور ایران
ip tunnel add 6to4_To_IR1 mode sit remote $ipkharej1 local $ipiran1
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

# تنظیمات تونل برای دومین سرور ایران
ip tunnel add 6to4_To_IR2 mode sit remote $ipkharej1 local $ipiran2
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
                ipiran="$ipiran1"
                ip_remote="$ipkharej1"
                ip_local="2002:480:1f10:e1f::1"
                ip_gre_local="10.10.10.1"
            else
                ipiran="$ipiran2"
                ip_remote="$ipkharej1"
                ip_local="2009:480:1f10:e1f::1"
                ip_gre_local="10.10.11.1"
            fi

            read -p "Enter the IP $ipiran: " ipiran_value
            read -p "Enter the IP Outside: " ipkharej1
            read -p "Enter the IP Iran2: " ipiran2
            read -p "Enter the required ports (e.g., 8080,9090,6060): " ports
            port_list=$(echo "$ports" | tr ',' ' ')

            # Generate commands for Iran1 or Iran2 configuration
            commands=$(cat <<EOF
#!/bin/bash
# Variables
ipiran="$ipiran_value"
ipkharej1="$ipkharej1"
port_list="$port_list"

ip tunnel add 6to4_To_KH mode sit remote \$ipkharej1 local \$ipiran
ip -6 addr add $ip_local/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote $ip_local local $ip_gre_local
ip addr add 10.10.10.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

# Enable IPv4 forwarding
sysctl net.ipv4.ip_forward=1

# IPTables rules
EOF
)
            for port in $port_list; do
                commands+=$(printf "iptables -t nat -A PREROUTING -p tcp --dport %s -j DNAT --to-destination 10.10.10.1\n" "$port")
            done

            commands+=$(cat <<EOF
iptables -t nat -A POSTROUTING -j MASQUERADE

exit 0
EOF
)
            echo "$commands" | sudo tee /etc/rc.local > /dev/null
            sudo chmod +x /etc/rc.local
            echo "Commands for 6to4 multi server ($ipiran_value) have been set."
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
    LIMITS_CONF="/etc/security/limits.conf"
    SYSCTL_CONF="/etc/sysctl.d/local.conf"
    TEMP_USER_CONF=$(mktemp)
    TEMP_SYSTEM_CONF=$(mktemp)

    # Function to add line if not exists
    add_line_if_not_exists() {
        local file="$1"
        local line="$2"
        local temp_file="$3"

        if [ -f "$file" ]; then
            cp "$file" "$temp_file"
            if ! grep -q "$line" "$file"; then
                sed -i '/^\[Manager\]/a '"$line" "$temp_file"
                sudo mv "$temp_file" "$file"
                echo "Added '$line' to $file"
            else
                echo "The line '$line' already exists in $file"
                rm "$temp_file"
            fi
        else
            echo "$file does not exist."
            rm "$temp_file"
        fi
    }

    # Optimize user.conf
    add_line_if_not_exists "$USER_CONF" "DefaultLimitNOFILE=1024000" "$TEMP_USER_CONF"

    # Optimize system.conf
    add_line_if_not_exists "$SYSTEM_CONF" "DefaultLimitNOFILE=1024000" "$TEMP_SYSTEM_CONF"

    # Optimize limits.conf
    if [ -f "$LIMITS_CONF" ]; then
        cat <<EOF | sudo tee -a "$LIMITS_CONF"
* hard nofile 1024000
* soft nofile 1024000
root hard nofile 1024000
root soft nofile 1024000
EOF
        echo "Added limits to $LIMITS_CONF"
    else
        echo "$LIMITS_CONF does not exist."
    fi

    # Optimize sysctl.d/local.conf
    cat <<EOF | sudo tee "$SYSCTL_CONF"
# max open files
fs.file-max = 1024000
EOF
    echo "Added sysctl settings to $SYSCTL_CONF"

    # Apply sysctl changes
    sudo sysctl --system
    echo "Sysctl changes applied."
}

# Function to install x-ui
install_x_ui() {
    echo "Choose the version of x-ui to install:"
    echo "1) alireza"
    echo "2) MHSanaei"
    read -p "Select an option (1 or 2): " xui_choice

    if [ "$xui_choice" -eq 1 ]; then
        bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
        echo "alireza version of x-ui installed."
    elif [ "$xui_choice" -eq 2 ]; then
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
        echo "MHSanaei version of x-ui installed."
    else
        echo "Invalid option. Please select 1 or 2."
    fi
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
    commands=$(cat <<EOF
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
EOF
)

    setup_rc_local "$commands"
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
