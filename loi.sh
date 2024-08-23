#!/bin/bash

echo "What should I do?"
echo "1) 6to4"
echo "2) Remove tunnels"
echo "3) Enable BBR"
echo "4) Fix Whatsapp Time"
echo "5) Optimize"
echo "6) Install x-ui"
echo "7) Change NameServer"
echo "8) Disable IPv6 - After server reboot IPv6 is activated"
echo "9) 6to4 multi server (1 outside 2 Iran)"
read -p "Select an option (1-9): " server_choice

setup_rc_local() {
    FILE="/etc/rc.local"
    commands="$1"

    if [ -f "$FILE" ]; then
        sudo bash -c "echo -e '#! /bin/bash\n\nexit 0' > $FILE"
    else
        echo -e '#! /bin/bash\n\nexit 0' | sudo tee "$FILE" > /dev/null
    fi
    sudo chmod +x "$FILE"

    sudo bash -c "sed -i '/exit 0/i $commands' $FILE"
    echo "Commands added to /etc/rc.local"

    eval "$commands"
    echo "Commands executed immediately."
}

handle_six_to_four() {
    echo "Handling 6to4 configuration..."
    # کدهای مربوط به پیکربندی 6to4
}

remove_tunnels() {
    echo "Removing tunnels..."
    # کدهای مربوط به حذف تونل‌ها
}

enable_bbr() {
    wget --no-check-certificate -O /opt/bbr.sh https://github.com/teddysun/across/raw/master/bbr.sh
    chmod 755 /opt/bbr.sh
    /opt/bbr.sh
    echo "BBR optimization enabled."
}

fix_whatsapp_time() {
    echo "Fixing Whatsapp time..."
    # کدهای مربوط به تنظیم زمان واتساپ
}

optimize() {
    echo "Optimizing system..."
    # کدهای مربوط به بهینه‌سازی سیستم
}

install_x_ui() {
    echo "Installing x-ui..."
    # کدهای مربوط به نصب x-ui
}

change_nameserver() {
    echo "Changing NameServer..."
    # کدهای مربوط به تغییر NameServer
}

disable_ipv6() {
    echo "Disabling IPv6..."
    # کدهای مربوط به غیرفعال کردن IPv6
}

handle_six_to_four_multi_server() {
    echo "Which server is this?"
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
        echo "Configuration for Outside server executed."

    elif [ "$server_option" -eq 2 ]; then
        read -p "Enter the IP Outside: " ipkharej1
        read -p "Enter the IP Iran1: " ipiran1
        read -p "Enter the ports (comma separated, e.g., 443,8080): " ports
        IFS=',' read -r -a port_array <<< "$ports"

        commands=$(cat <<EOF
ip tunnel add 6to4_To_KH mode sit remote $ipkharej1 local $ipiran1
ip -6 addr add 2002:480:1f10:e1f::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote 2002:480:1f10:e1f::2 local 2002:480:1f10:e1f::1
ip addr add 10.10.10.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

sysctl net.ipv4.ip_forward=1
EOF
        )
        for i in "${!port_array[@]}"; do
            commands+="\niptables -t nat -A PREROUTING -p tcp --dport ${port_array[$i]} -j DNAT --to-destination 10.10.10.1"
        done
        commands+="\niptables -t nat -A POSTROUTING -j MASQUERADE"

        setup_rc_local "$commands"
        echo "Configuration for Iran1 server executed."

    elif [ "$server_option" -eq 3 ]; then
        read -p "Enter the IP Outside: " ipkharej1
        read -p "Enter the IP Iran2: " ipiran2
        read -p "Enter the ports (comma separated, e.g., 443,8080): " ports
        IFS=',' read -r -a port_array <<< "$ports"

        commands=$(cat <<EOF
ip tunnel add 6to4_To_KH mode sit remote $ipkharej1 local $ipiran2
ip -6 addr add 2009:480:1f10:e1f::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote 2009:480:1f10:e1f::2 local 2009:480:1f10:e1f::1
ip addr add 10.10.11.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

sysctl net.ipv4.ip_forward=1
EOF
        )
        for i in "${!port_array[@]}"; do
            commands+="\niptables -t nat -A PREROUTING -p tcp --dport ${port_array[$i]} -j DNAT --to-destination 10.10.11.1"
        done
        commands+="\niptables -t nat -A POSTROUTING -j MASQUERADE"

        setup_rc_local "$commands"
        echo "Configuration for Iran2 server executed."

    else
        echo "Invalid server option selected. Exiting."
        exit 1
    fi
}

case $server_choice in
    1)
        handle_six_to_four
        ;;
    2)
        remove_tunnels
        ;;
    3)
        enable_bbr
        ;;
    4)
        fix_whatsapp_time
        ;;
    5)
        optimize
        ;;
    6)
        install_x_ui
        ;;
    7)
        change_nameserver
        ;;
    8)
        disable_ipv6
        ;;
    9)
        handle_six_to_four_multi_server
        ;;
    *)
        echo "Invalid option. Please select a number between 1 and 9."
        ;;
esac
