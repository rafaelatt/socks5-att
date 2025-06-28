#!/bin/bash

DANTE_CONF="/etc/danted.conf"
LOG_FILE="/var/log/danted.log"

install_dante() {
    echo "[+] Installing Dante Server..."
    apt update
    apt install -y dante-server

    echo -n "Nhập interface lắng nghe (vd: eth0 hoặc 0.0.0.0): "
    read iface

    echo -n "Nhập port SOCKS5 (vd: 1080): "
    read port

    cat > $DANTE_CONF <<EOF
logoutput: $LOG_FILE
internal: $iface port = $port
external: $iface

method: username none
user.notprivileged: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
    command: bind connect udpassociate
}
EOF

    touch $LOG_FILE
    systemctl enable danted
    systemctl restart danted
    echo "[+] Dante SOCKS5 đã khởi động trên $iface:$port"
}

add_user() {
    echo -n "Nhập username: "
    read user
    id "$user" &>/dev/null && echo "[-] User đã tồn tại." && return
    sudo useradd -M -s /usr/sbin/nologin "$user"
    echo "Nhập mật khẩu cho $user:"
    sudo passwd "$user"
    echo "[+] User $user đã được thêm."
}

delete_user() {
    echo -n "Nhập username cần xoá: "
    read user
    id "$user" &>/dev/null || { echo "[-] User không tồn tại."; return; }
    sudo userdel "$user"
    echo "[+] User $user đã được xoá."
}

show_log() {
    echo "[+] Hiển thị log SOCKS5:"
    tail -n 30 $LOG_FILE
}

main_menu() {
    while true; do
        echo ""
        echo "========= SOCKS5 Proxy Menu ========="
        echo "1. Cài đặt Dante SOCKS5 Server"
        echo "2. Thêm user"
        echo "3. Xoá user"
        echo "4. Xem log kết nối"
        echo "0. Thoát"
        echo "====================================="
        read -p "Chọn tuỳ chọn: " choice
        case $choice in
            1) install_dante ;;
            2) add_user ;;
            3) delete_user ;;
            4) show_log ;;
            0) exit 0 ;;
            *) echo "[-] Lựa chọn không hợp lệ." ;;
        esac
    done
}

main_menu
