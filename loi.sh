#!/bin/bash

echo "What should I do?"
echo "1) 6to4"
echo "2) 6to4 multi server (1 Outside 2 Iran)"
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

    # Ensure the file exists and is executable, or create and set it to exit 0
    if [ ! -f "$FILE" ]; then
        echo -e '#!/bin/bash\n\nexit 0' | sudo tee "$FILE" > /dev/null
    fi

    # Remove any existing 'exit 0'
    sudo sed -i '/^exit 0$/d' "$FILE"

    # Add new commands to the file
    echo "$commands" | sudo tee -a "$FILE" > /dev/null

    # Ensure 'exit 0' is at the end of the file with a preceding blank line
    echo -e "\nexit 0" | sudo tee -a "$FILE" > /dev/null

    sudo chmod +x "$FILE"
    echo "Commands added to /etc/rc.local"
    echo "Commands executed immediately."
    eval "$commands"
}

fix_whatsapp_time() {
    commands="sudo timedatectl set-timezone Asia/Tehran"
    setup_rc_local "$commands"
    echo "Whatsapp time fixed to Asia/Tehran timezone."
}

optimize() {
    USER_CONF="/etc/systemd/user.conf"
    SYSTEM_CONF="/etc/systemd/system.conf"
    LIMITS_CONF="/etc/security/limits.conf"
    SYSCTL_CONF="/etc/sysctl.d/local.conf"
    TEMP_USER_CONF=$(mktemp)
    TEMP_SYSTEM_CONF=$(mktemp)

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

    add_line_if_not_exists "$USER_CONF" "DefaultLimitNOFILE=1024000" "$TEMP_USER_CONF"
    add_line_if_not_exists "$SYSTEM_CONF" "DefaultLimitNOFILE=1024000" "$TEMP_SYSTEM_CONF"

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

    cat <<EOF | sudo tee "$SYSCTL_CONF"
# max open files
fs.file-max = 1024000
EOF
    echo "Added sysctl settings to $SYSCTL_CONF"

    sudo sysctl --system
    echo "Sysctl changes applied."
}

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

handle_six_to_four() {
    echo "Choose the type of server:"
    echo "1) Outside"
    echo "2) Iran1"
    echo "3) Iran2"
    read -p "Select an option (1 or 2): " six_to_four_choice

    if [ "$six_to_four_choice" -eq 1 ]; then
        read -p "Enter the IP outside: " ipkharej
        read -p "Enter the IP Iran: " ipiran

        commands=$(cat <<EOF
ip tunnel add 6to4_To_IR mode sit remote $ipiran local $ipkharej
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR
ip link set 6to4_To_IR mtu 1480
ip link set 6to4_To_IR up

ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR
ip link set GRE6Tun_To_IR mtu 1436
ip link set GRE6Tun_To_IR up
EOF
)

        setup_rc_local "$commands"
        echo "Commands executed for the outside server."

    elif [ "$six_to_four_choice" -eq 2 ]; then
        read -p "Enter the IP Iran: " ipiran
        read -p "Enter the IP outside: " ipkharej

        commands=$(cat <<EOF
ip tunnel add 6to4_To_KH mode sit remote $ipkharej local $ipiran
ip -6 addr add 2002:480:1f10:e1f::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote 2002:480:1f10:e1f::2 local 2002:480:1f10:e1f::1
ip addr add 10.10.10.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

sysctl net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 10.10.10.1
iptables -t nat -A PREROUTING -j DNAT --to-destination 10.10.10.2
iptables -t nat -A POSTROUTING -j MASQUERADE
EOF
)

        setup_rc_local "$commands"
        echo "Commands executed for the Iran server."

    else
        echo "Invalid option. Please select 1 or 2."
    fi
}

handle_six_to_four_multi_server() {
    echo "1) Outside"
    echo "2) Iran1"
    echo "3) Iran2"
    read -p "Select an option (1, 2, or 3): " server_option

    if [ "$server_option" -eq 1 ]; then
        read -p "Enter the IP Outside: " ipkharej1
        read -p "Enter the IP Iran1: " ipiran1
        read -p "Enter the IP Iran2: " ipiran2

        commands=$(cat <<EOF
ip tunnel add 6to4_To_IR1 mode sit remote $ipiran1 local $ipkharej1
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

ip tunnel add 6to4_To_IR2 mode sit remote $ipiran2 local $ipkharej1
ip -6 addr add 2009:480:1f10:e1f::2/64 dev 6to4_To_IR2
ip link set 6to4_To_IR2 mtu 1480
ip link set 6to4_To_IR2 up

ip -6 tunnel add GRE6Tun_To_IR2 mode ip6gre remote 2009:480:1f10:e1f::1 local 2009:480:1f10:e1f::2
ip addr add 10.10.11.2/30 dev GRE6Tun_To_IR2
ip link set GRE6Tun_To_IR2 mtu 1436
ip link set GRE6Tun_To_IR2 up
EOF
)

        setup_rc_local "$commands"
        echo "Commands executed for multi-server setup."

    elif [ "$server_option" -eq 2 ]; then
        echo "Multi-server setup for Iran1 is not yet implemented."

    elif [ "$server_option" -eq 3]; then
        echo "Multi-server setup for Iran2 is not yet implemented."

    else
        echo "Invalid option. Please select 1, 2, or 3."
    fi
}

remove_tunnels() {
    commands=$(cat <<EOF
ip tunnel del 6to4_To_IR1
ip tunnel del GRE6Tun_To_IR1
ip tunnel del 6to4_To_IR2
ip tunnel del GRE6Tun_To_IR2
EOF
)

    setup_rc_local "$commands"
    echo "Tunnels removed."
}

enable_bbr() {
    commands=$(cat <<EOF
echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
sysctl -p
EOF
)

    setup_rc_local "$commands"
    echo "BBR enabled."
}

change_nameserver() {
    commands=$(cat <<EOF
sed -i 's/^nameserver.*/nameserver 1.1.1.1/' /etc/resolv.conf
EOF
)

    setup_rc_local "$commands"
    echo "Nameserver changed to 1.1.1.1."
}

case "$server_choice" in
    1)
        handle_six_to_four
        ;;
    2)
        handle_six_to_four_multi_server
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
        echo "Invalid option. Please select a number between 1 and 9."
        ;;
esac
