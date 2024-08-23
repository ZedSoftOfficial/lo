#!/bin/bash

# Function to handle 6to4 configuration
handle_six_to_four() {
    echo "Setting up 6to4..."
    # Placeholder for 6to4 configuration commands
}

# Function to handle 6to4 multi-server (1 Iran 2 outside)
handle_six_to_four_multi_iran_kharej() {
    echo "Which server is this?"
    echo "1) Iran1"
    echo "2) Iran2"
    read -p "Select an option (1 or 2): " server_role

    case $server_role in
        1)
            read -p "Enter the IP Iran1: " ipiran1
            read -p "Enter the IP Outside: " ipkharej
            read -p "Enter the IP Iran2: " ipiran2

            # Commands for Iran1 and Iran2
            commands=$(cat <<EOF
#!/bin/bash

# تنظیمات تونل برای اولین سرور ایران
ip tunnel add 6to4_To_IR1 mode sit remote $ipkharej local $ipiran1
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

# تنظیمات تونل برای دومین سرور ایران
ip tunnel add 6to4_To_IR2 mode sit remote $ipkharej local $ipiran2
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

            # Write commands to /etc/rc.local
            sudo bash -c "echo '#!/bin/bash' > /etc/rc.local"
            sudo bash -c "echo '$commands' >> /etc/rc.local"
            sudo chmod +x /etc/rc.local
            echo "Commands for 6to4 multi server (1 Iran 2 outside) have been set."
            ;;
        *)
            echo "Invalid option. Please select 1 or 2."
            return
            ;;
    esac
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
#!/bin/bash

# تنظیمات تونل برای اولین سرور ایران
ip tunnel add 6to4_To_IR1 mode sit remote $ipkharej local $ipiran1
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

# تنظیمات تونل برای دومین سرور ایران
ip tunnel add 6to4_To_IR2 mode sit remote $ipkharej local $ipiran2
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

            # Write commands to /etc/rc.local
            sudo bash -c "echo '#!/bin/bash' > /etc/rc.local"
            sudo bash -c "echo '$commands' >> /etc/rc.local"
            sudo chmod +x /etc/rc.local
            echo "Commands for 6to4 multi server (1 outside 2 Iran) have been set."
            ;;
        *)
            echo "Invalid option. Please select 1, 2, or 3."
            return
            ;;
    esac
}

# Function to handle removing tunnels
remove_tunnels() {
    echo "Removing tunnels..."
    # Add your commands to remove tunnels here
    sudo ip tunnel del 6to4_To_IR1 2>/dev/null
    sudo ip tunnel del GRE6Tun_To_IR1 2>/dev/null
    sudo ip tunnel del 6to4_To_IR2 2>/dev/null
    sudo ip tunnel del GRE6Tun_To_IR2 2>/dev/null
    sudo ip link del 6to4_To_IR1 2>/dev/null
    sudo ip link del GRE6Tun_To_IR1 2>/dev/null
    sudo ip link del 6to4_To_IR2 2>/dev/null
    sudo ip link del GRE6Tun_To_IR2 2>/dev/null
    echo "Tunnels removed."
}

# Function to enable BBR
enable_bbr() {
    echo "Enabling BBR..."
    wget --no-check-certificate -O /opt/bbr.sh https://github.com/teddysun/across/raw/master/bbr.sh
    chmod 755 /opt/bbr.sh
    /opt/bbr.sh
    echo "BBR enabled."
}

# Function to fix WhatsApp time
fix_whatsapp_time() {
    echo "Fixing WhatsApp time..."
    sudo timedatectl set-timezone Asia/Tehran
    echo "WhatsApp time fixed to Asia/Tehran timezone."
}

# Function to optimize system
optimize_system() {
    echo "Optimizing system..."
    # Sample optimization commands
    sudo sysctl -w net.ipv4.ip_forward=1
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
    echo "System optimized."
}

# Function to install x-ui
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

# Function to change nameserver
change_nameserver() {
    echo "Changing nameserver..."
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

# Function to disable IPv6
disable_ipv6() {
    echo "Disabling IPv6..."
    sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
    echo "IPv6 has been disabled."
}

# Main script execution
echo "What should I do?"
echo "1) 6to4"
echo "2) 6to4 multi server (1 Iran 2 outside)"
echo "3) 6to4 multi server (1 outside 2 Iran)"
echo "4) Remove tunnels"
echo "5) Enable BBR"
echo "6) Fix WhatsApp Time"
echo "7) Optimize"
echo "8) Install x-ui"
echo "9) Change NameServer"
echo "10) Disable IPv6"
read -p "Select an option (1, 2, 3, 4, 5, 6, 7, 8, 9, or 10): " option

case $option in
    1)
        handle_six_to_four
        ;;
    2)
        handle_six_to_four_multi_iran_kharej
        ;;
    3)
        handle_six_to_four_multi_outside_iran
        ;;
    4)
        remove_tunnels
        ;;
    5)
        enable_bbr
        ;;
    6)
        fix_whatsapp_time
        ;;
    7)
        optimize_system
        ;;
    8)
        install_x_ui
        ;;
    9)
        change_nameserver
        ;;
    10)
        disable_ipv6
        ;;
    *)
        echo "Invalid option. Please select 1, 2, 3, 4, 5, 6, 7, 8, 9, or 10."
        ;;
esac
