#!/bin/bash

clear

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "لطفا با root اجرا کنید."
        exit 1
    fi
}

update_server() {
    apt update && apt upgrade -y
}

install_certbot() {
    if ! command -v certbot &>/dev/null; then
        echo "Certbot نصب نیست، در حال نصب..."
        apt-get update
        apt-get install certbot -y
    fi

    read -p "دامنه را وارد کنید: " DOMAIN

    certbot certonly --standalone \
        --agree-tos \
        --register-unsafely-without-email \
        -d "$DOMAIN"
}

check_port() {
    read -p "شماره پورت را وارد کنید: " PORT
    sudo lsof -i :"$PORT"
}

install_3xui() {
    read -p "نسخه خاص میخواهید؟ (y/n): " VER

    if [[ "$VER" =~ ^[Yy]$ ]]; then
        read -p "نسخه را وارد کنید (مثال: v2.8.11): " VERSION
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) "$VERSION"
    else
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    fi
}

run_benchmark() {
    wget -qO- bench.sh | bash
}

run_nload() {
    if ! command -v nload &>/dev/null; then
        echo "در حال نصب nload..."
        apt update
        apt install nload -y
    fi

    nload -u M
}

transfer_file() {
    echo "انتقال فایل بین دو سرور"

    read -p "مسیر فایل: " FILE
    read -p "IP سرور مقصد: " DEST_IP
    read -p "نام کاربری مقصد: " DEST_USER
    read -p "مسیر مقصد: " DEST_PATH

    scp "$FILE" "${DEST_USER}@${DEST_IP}:${DEST_PATH}"
}

check_root

while true; do
    clear
    echo "=============================="
    echo "      Server Tools Menu"
    echo "=============================="
    echo "1) آپدیت سرور"
    echo "2) دریافت SSL"
    echo "3) مشاهده پورت درگیر"
    echo "4) نصب 3X-UI"
    echo "5) تست بنچمارک"
    echo "6) مشاهده مصرف پهنا باند"
    echo "7) انتقال فایل بین سرورها"
    echo "0) خروج"
    echo "=============================="

    read -p "انتخاب: " CHOICE

    case $CHOICE in
        1) update_server ;;
        2) install_certbot ;;
        3) check_port ;;
        4) install_3xui ;;
        5) run_benchmark ;;
        6) run_nload ;;
        7) transfer_file ;;
        0) exit 0 ;;
        *) echo "گزینه نامعتبر" ;;
    esac

    read -p "برای ادامه Enter بزنید..."
done
