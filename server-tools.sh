#!/bin/bash

# ==========================================
# Colors and Styling
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ==========================================
# Helper Functions
# ==========================================
print_info() { echo -e "${CYAN}[ℹ] $1${NC}"; }
print_success() { echo -e "${GREEN}[✔] $1${NC}"; }
print_warning() { echo -e "${YELLOW}[⚠] $1${NC}"; }
print_error() { echo -e "${RED}[✖] $1${NC}"; }

pause() {
    echo
    read -p "Press [Enter] to return to the menu..."
}

# ==========================================
# Core Functions
# ==========================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

update_server() {
    print_info "Updating package list and upgrading system..."
    apt update && apt upgrade -y
    print_success "Server updated successfully."
}

install_certbot() {
    if ! command -v certbot &>/dev/null; then
        print_info "Certbot is not installed. Installing now..."
        apt-get update && apt-get install certbot -y
    fi

    echo -e "${YELLOW}Enter your domain name (e.g., example.com):${NC} "
    read -r DOMAIN

    if [ -z "$DOMAIN" ]; then
        print_error "Domain cannot be empty!"
        return
    fi

    print_info "Requesting SSL certificate for $DOMAIN..."
    certbot certonly --standalone \
        --agree-tos \
        --register-unsafely-without-email \
        -d "$DOMAIN"
    
    if [ $? -eq 0 ]; then
        print_success "SSL Certificate generated for $DOMAIN"
    else
        print_error "Failed to generate SSL certificate."
    fi
}

check_port() {
    if ! command -v lsof &>/dev/null; then
        print_info "Installing lsof..."
        apt install lsof -y > /dev/null 2>&1
    fi

    echo -e "${YELLOW}Enter port number to check:${NC} "
    read -r PORT
    
    print_info "Checking port $PORT..."
    OUTPUT=$(lsof -i :"$PORT")
    
    if [ -z "$OUTPUT" ]; then
        print_success "Port $PORT is free and not in use."
    else
        print_warning "Port $PORT is currently in use:"
        echo "$OUTPUT"
    fi
}

install_3xui() {
    echo -e "${YELLOW}Do you want a specific version of 3X-UI? (y/n):${NC} "
    read -r ANSWER

    if [[ "$ANSWER" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Enter version (e.g., v2.8.11):${NC} "
        read -r VERSION
        print_info "Installing 3X-UI version $VERSION..."
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) "$VERSION"
    else
        print_info "Installing the latest version of 3X-UI..."
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
    fi
}

run_benchmark() {
    print_info "Starting Server Benchmark..."
    wget -qO- bench.sh | bash
}

run_nload() {
    if ! command -v nload &>/dev/null; then
        print_info "Installing nload..."
        apt update && apt install nload -y
    fi
    print_info "Starting nload. Press 'Ctrl+C' to exit the monitor."
    sleep 2
    nload -u M
}

transfer_file() {
    print_info "File Transfer Setup (SCP)"

    read -p "1. Enter source file path (e.g., /root/file.zip): " FILE
    if [ ! -f "$FILE" ]; then
        print_error "File does not exist!"
        return
    fi

    read -p "2. Enter destination server IP: " DEST_IP
    read -p "3. Enter destination username (default: root): " DEST_USER
    DEST_USER=${DEST_USER:-root}
    read -p "4. Enter destination path (default: /root/): " DEST_PATH
    DEST_PATH=${DEST_PATH:-/root/}

    print_info "Starting transfer..."
    scp "$FILE" "${DEST_USER}@${DEST_IP}:${DEST_PATH}"
    
    if [ $? -eq 0 ]; then
        print_success "File transferred successfully."
    else
        print_error "File transfer failed."
    fi
}

manage_firewall() {
    if ! command -v ufw &>/dev/null; then
        print_info "UFW is not installed. Installing..."
        apt update && apt install ufw -y
    fi

    clear
    echo -e "${CYAN}${BOLD}============================================${NC}"
    echo -e "             FIREWALL MANAGEMENT            "
    echo -e "${CYAN}${BOLD}============================================${NC}"
    echo -e " 1) Check Firewall Status"
    echo -e " 2) Enable Firewall (Turn ON)"
    echo -e " 3) Disable Firewall (Turn OFF)"
    echo -e " 0) Back to Main Menu"
    echo -e "${CYAN}--------------------------------------------${NC}"
    echo -e "${YELLOW}Select an option [0-3]:${NC} \c"
    read -r FW_CHOICE

    case $FW_CHOICE in
        1)
            print_info "Current Firewall Status:"
            ufw status verbose
            ;;
        2)
            print_warning "Enabling firewall. Allowing SSH (Port 22) automatically to prevent disconnection..."
            ufw allow 22/tcp > /dev/null 2>&1
            echo "y" | ufw enable
            print_success "Firewall has been enabled successfully."
            ;;
        3)
            print_info "Disabling firewall..."
            ufw disable
            print_success "Firewall has been disabled."
            ;;
        0)
            return
            ;;
        *)
            print_error "Invalid option."
            ;;
    esac
}

install_pasarguard() {
    clear
    echo -e "${CYAN}${BOLD}============================================${NC}"
    echo -e "             PASARGUARD INSTALLER           "
    echo -e "${CYAN}${BOLD}============================================${NC}"
    echo -e " 1) Install PasarGuard Panel (MySQL)"
    echo -e " 2) Install PasarGuard Node"
    echo -e " 0) Back to Main Menu"
    echo -e "${CYAN}--------------------------------------------${NC}"
    echo -e "${YELLOW}Select an option [0-2]:${NC} \c"
    read -r PG_CHOICE

    case $PG_CHOICE in
        1)
            print_info "Installing PasarGuard Panel (MySQL)..."
            sudo bash -c "$(curl -fsSL https://github.com/PasarGuard/scripts/raw/main/pasarguard.sh)" @ install --database mysql
            print_success "Panel installation process completed."
            ;;
        2)
            print_info "Installing PasarGuard Node..."
            sudo bash -c "$(curl -sL https://github.com/PasarGuard/scripts/raw/main/pg-node.sh)" @ install
            print_success "Node installation process completed."
            ;;
        0)
            return
            ;;
        *)
            print_error "Invalid option."
            ;;
    esac
}

install_mtproxy() {
    print_info "Installing Telegram Proxy (MTProto)..."
    curl -L -o mtp_install.sh https://git.io/fj5ru && bash mtp_install.sh
    if [ $? -eq 0 ]; then
        print_success "Telegram Proxy installation script executed successfully."
    else
        print_error "Failed to install Telegram Proxy."
    fi
}

check_port_users() {
    # Check if netstat (net-tools) is installed
    if ! command -v netstat &>/dev/null; then
        print_info "netstat is not installed. Installing net-tools..."
        apt update && apt install net-tools -y > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            print_success "net-tools installed successfully."
        else
            print_error "Failed to install net-tools. Please check your internet connection."
            return
        fi
    fi

    echo -e "${YELLOW}Enter the port number to check connected users:${NC} \c"
    read -r PORT

    if [ -z "$PORT" ]; then
        print_error "Port cannot be empty!"
        return
    fi

    print_info "Counting unique IP connections on port $PORT..."
    USER_COUNT=$(netstat -anp 2>/dev/null | grep ":$PORT" | awk '{print $5}' | cut -d: -f1 | sort | uniq | wc -l)
    
    # Optional: Removing empty line matches if there are any
    if [ "$USER_COUNT" -gt 0 ]; then
        print_success "Total unique users on port $PORT: ${BOLD}$USER_COUNT${NC}"
    else
        print_warning "No active connections found on port $PORT."
    fi
}

# ==========================================
# Main Menu
# ==========================================
check_root

while true; do
    clear
    # System Info Header
    OS_INFO=$(cat /etc/os-release | grep -w "PRETTY_NAME" | cut -d "=" -f 2 | tr -d '"')
    IP_ADDR=$(hostname -I | awk '{print $1}')
    
    echo -e "${CYAN}${BOLD}============================================${NC}"
    echo -e "         ${BOLD}SERVER TOOLS MANAGER v1.3${NC}"
    echo -e "${CYAN}${BOLD}============================================${NC}"
    echo -e " ${GREEN}OS:${NC} $OS_INFO"
    echo -e " ${GREEN}IP:${NC} $IP_ADDR"
    echo -e "${CYAN}--------------------------------------------${NC}"
    echo -e "  ${BOLD}[1]${NC} Update Server"
    echo -e "  ${BOLD}[2]${NC} Generate SSL Certificate (Certbot)"
    echo -e "  ${BOLD}[3]${NC} Check Port Usage"
    echo -e "  ${BOLD}[4]${NC} Install 3X-UI Panel"
    echo -e "  ${BOLD}[5]${NC} Run Server Benchmark"
    echo -e "  ${BOLD}[6]${NC} Monitor Bandwidth (nload)"
    echo -e "  ${BOLD}[7]${NC} Transfer Files (SCP)"
    echo -e "  ${BOLD}[8]${NC} Manage Firewall (UFW)"
    echo -e "  ${BOLD}[9]${NC} Install PasarGuard (Panel / Node)"
    echo -e "  ${BOLD}[10]${NC} Install Telegram Proxy (MTProto) ${YELLOW}[NEW]${NC}"
    echo -e "  ${BOLD}[11]${NC} Check Active Users on Port ${YELLOW}[NEW]${NC}"
    echo -e "${CYAN}--------------------------------------------${NC}"
    echo -e "  ${RED}[0] Exit${NC}"
    echo -e "${CYAN}============================================${NC}"

    echo -e "${YELLOW}Select an option [0-11]:${NC} \c"
    read -r CHOICE

    echo "" # Empty line for better readability

    case $CHOICE in
        1) update_server ;;
        2) install_certbot ;;
        3) check_port ;;
        4) install_3xui ;;
        5) run_benchmark ;;
        6) run_nload ;;
        7) transfer_file ;;
        8) manage_firewall ;;
        9) install_pasarguard ;;
        10) install_mtproxy ;;
        11) check_port_users ;;
        0) print_success "Exiting. Have a great day!"; exit 0 ;;
        *) print_error "Invalid option. Please try again." ;;
    esac

    pause
done
