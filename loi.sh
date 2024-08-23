#!/bin/bash

# نمایش منوی اصلی
echo "Select an option:"
echo "1) 6to4 multi server (1 outside 2 Iran)"
read -p "Select an option (1): " main_option

# اگر کاربر گزینه 1 را انتخاب کرد، ادامه دهید
if [ "$main_option" -eq 1 ]; then
    echo "Which server is this?"
    echo "1) Outside"
    echo "2) Iran1"
    echo "3) Iran2"
    read -p "Select an option (1, 2, or 3): " server_option

    if [ "$server_option" -eq 1 ]; then
        # برای سرور Outside
        read -p "Enter the IP Outside: " ipkharej1
        read -p "Enter the IP Iran1: " ipiran1
        read -p "Enter the IP Iran2: " ipiran2

        # ایجاد محتوای جدید برای فایل rc.local
        cat <<EOL > /etc/rc.local
#!/bin/bash

# تنظیمات تونل برای اولین سرور ایران
ip tunnel add 6to4_To_IR1 mode sit remote $ipiran1 local $ipkharej1
ip -6 addr add 2002:480:1f10:e1f::2/64 dev 6to4_To_IR1
ip link set 6to4_To_IR1 mtu 1480
ip link set 6to4_To_IR1 up

ip -6 tunnel add GRE6Tun_To_IR1 mode ip6gre remote 2002:480:1f10:e1f::1 local 2002:480:1f10:e1f::2
ip addr add 10.10.10.2/30 dev GRE6Tun_To_IR1
ip link set GRE6Tun_To_IR1 mtu 1436
ip link set GRE6Tun_To_IR1 up

# تنظیمات تونل برای دومین سرور ایران
ip tunnel add 6to4_To_IR2 mode sit remote $ipiran2 local $ipkharej1
ip -6 addr add 2009:480:1f10:e1f::2/64 dev 6to4_To_IR2
ip link set 6to4_To_IR2 mtu 1480
ip link set 6to4_To_IR2 up

ip -6 tunnel add GRE6Tun_To_IR2 mode ip6gre remote 2009:480:1f10:e1f::1 local 2009:480:1f10:e1f::2
ip addr add 10.10.11.2/30 dev GRE6Tun_To_IR2
ip link set GRE6Tun_To_IR2 mtu 1436
ip link set GRE6Tun_To_IR2 up

exit 0
EOL

        chmod +x /etc/rc.local
        echo "Configuration for Outside saved to /etc/rc.local and the file has been made executable."

    elif [ "$server_option" -eq 2 ]; then
        # برای سرور Iran1
        read -p "Enter the IP Outside: " ipkharej1
        read -p "Enter the IP Iran1: " ipiran1

        # گرفتن پورت‌ها
        read -p "Enter the ports (comma separated, e.g., 443,8080): " ports
        IFS=',' read -r -a port_array <<< "$ports"

        # ایجاد محتوای جدید برای فایل rc.local
        cat <<EOL > /etc/rc.local
#!/bin/bash

ip tunnel add 6to4_To_KH mode sit remote $ipkharej1 local $ipiran1
ip -6 addr add 2002:480:1f10:e1f::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote 2002:480:1f10:e1f::2 local 2002:480:1f10:e1f::1
ip addr add 10.10.10.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up

# فعال کردن فورواردینگ IPv4
sysctl net.ipv4.ip_forward=1
EOL

        # اضافه کردن قوانین iptables بر اساس تعداد پورت‌ها
        for i in "${!port_array[@]}"; do
            if [ "$i" -eq 0 ]; then
                echo "iptables -t nat -A PREROUTING -p tcp --dport ${port_array[$i]} -j DNAT --to-destination 10.10.10.1" >> /etc/rc.local
            else
                echo "iptables -t nat -A PREROUTING -p tcp --dport ${port_array[$i]} -j DNAT --to-destination 10.10.10.1" >> /etc/rc.local
            fi
        done

        # اضافه کردن دستور POSTROUTING و خروج
        cat <<EOL >> /etc/rc.local
iptables -t nat -A POSTROUTING -j MASQUERADE 

exit 0
EOL

        chmod +x /etc/rc.local
        echo "Configuration for Iran1 saved to /etc/rc.local and the file has been made executable."

    else
        echo "Invalid server option selected. Exiting."
        exit 1
    fi
else
    echo "Invalid main option selected. Exiting."
    exit 1
fi
