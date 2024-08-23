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

    # Ensure the file exists and is executable, or empty it if it already exists
    if [ -f "$FILE" ]; then
        sudo bash -c "echo -e '#! /bin/bash\n\nexit 0' > $FILE"
    else
        echo -e '#! /bin/bash\n\nexit 0' | sudo tee "$FILE" > /dev/null
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
            read -p "Enter the IP Outside: " ipkharej
            read -p "Enter the IP Iran1: " ipiran1
            read -p "Enter the IP Iran2: " ipiran2

            # Commands for Outside server
            commands=$(cat <<EOF
ip tunnel add 6to4_To_IR1 mode sit remote $ipkharej local $ipiran1
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local $ipiran1
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

ip tunnel add 6to4_To_IR2 mode sit remote $ipkharej local $ipiran2
ip -6 addr add 2009:480:1f10:e1f::2/64 dev 6to4_To_IR2
ip link set 6to4_To_IR2 mtu 1480
ip link set 6to4_To_IR2 up

ip -6 tunnel add GRE6Tun_To_IR2 mode ip6gre remote 2009:480:1f10:e1f::1 local $ipiran2
ip addr add 10.10.11.2/30 dev GRE6Tun_To_IR2
ip link set GRE6Tun_To_IR2 mtu 1436
ip link set GRE6Tun_To_IR2 up

exit 0
EOF
)

            # Write commands to /etc/rc.local
            sudo bash -c "echo '#!/bin/bash' > /etc/rc.local"
            sudo bash -c "echo '$commands' >> /etc/rc.local"
            sudo chmod +x /etc/rc.local
            echo "Commands for 6to4 multi server (1 outside) have been set."
            ;;
        2)
            read -p "Enter the IP Iran1: " ipiran1
            read -p "Enter the IP Outside: " ipkharej
            read -p "Enter the IP Iran2: " ipiran2

            # Commands for Iran1 and Iran2
            commands=$(cat <<EOF
ip tunnel add 6to4_To_IR1 mode sit remote $ipkharej local $ipiran1
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local $ipiran1
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

ip tunnel add 6to4_To_IR2 mode sit remote $ipkharej local $ipiran2
ip -6 addr add 2009:480:1f10:e1f::2/64 dev 6to4_To_IR2
ip link set 6to4_To_IR2 mtu 1480
ip link set 6to4_To_IR2 up

ip -6 tunnel add GRE6Tun_To_IR2 mode ip6gre remote 2009:480:1f10:e1f::1 local $ipiran2
ip addr add 10.10.11.2/30 dev GRE6Tun_To_IR2
ip link set GRE6Tun_To_IR2 mtu 1436
ip link set GRE6Tun_To_IR2 up

exit 0
EOF
)

            # Write commands to /etc/rc.local
            sudo bash -c "echo '#!/bin/bash' > /etc/rc.local"
            sudo bash -c "echo '$commands' >> /etc/rc.local"
            sudo chmod +x /etc/rc.local
            echo "Commands for 6to4 multi server (1 Iran 2 outside) have been set."
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
    echo -e '#! /bin/bash\n\nexit 0' | sudo tee /etc/rc.local > /dev/null
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

    add_line_if_not_exists() {
        local file="$1"
        local line="$2"
        local temp_file="$3"

        if [ -f "$file" ]; then
            cp "$file" "$temp_file"
            if ! grep -q "$line" "$file"; then
                sed -i '/^\[Manager\]/a '"$line" "$temp_file"
                sudo mv "$temp_file" "$file"
                echo "Added '$line' to $file."
            else
                echo "'$line' already exists in $file."
            fi
        fi
    }

    add_line_if_not_exists "$USER_CONF" "DefaultLimitNOFILE=65536" "$TEMP_USER_CONF"
    add_line_if_not_exists "$SYSTEM_CONF" "DefaultLimitNOFILE=65536" "$TEMP_SYSTEM_CONF"

    sudo sysctl -w net.ipv4.ip_forward=1
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
    echo "System optimized."
}

# Function to handle Install x-ui
install_x_ui() {
    echo "Installing x-ui..."
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
        echo "Invalid choice for x-ui version."
    fi
}

# Function to handle Change NameServer
change_nameserver() {
    read -p "Enter the file to change nameserver (e.g., /etc/resolv.conf): " file
    if [ -f "$file" ]; then
        sudo cp "$file" "$file.bak"
        sudo sed -i '/^nameserver /d' "$file"
        echo -e "nameserver 8.8.8.8\nnameserver 1.1.1.1" | sudo tee -a "$file" > /dev/null
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
