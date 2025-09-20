#!/bin/bash

# Function for the main script logic
run_main_script() {
    while true; do
        clear
        date +"%l:%M:%S %p" | figlet -f /usr/share/figlet/ANSI_Regular.flf
        echo "Press 'q' to quit: "

        # Use read with a timeout (-t) of 1 second
        read -t 1 -n 1 key

        if [[ "$key" == 'q' ]] || [[ "$key" == 'Q' ]]; then
            break
        fi
    done

    echo -e "\n\nBye..."
}

# Check if figlet is installed; if so, run the main script immediately
if command -v figlet &>/dev/null; then
    echo "Figlet is already installed. Running the main script..."
    run_main_script
    exit 0
fi

# If figlet is not installed, proceed with setup
echo "Figlet not found. Setting up..."

# Function to detect the package manager
detect_package_manager() {
    if command -v apt &>/dev/null; then
        echo "apt"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

# Function to install a package
install_package() {
    local package="$1"
    local package_manager
    package_manager=$(detect_package_manager)

    case "$package_manager" in
    apt)
        sudo apt update && sudo apt install -y "$package"
        ;;
    dnf)
        sudo dnf install -y "$package"
        ;;
    pacman)
        sudo pacman -Sy --noconfirm "$package"
        ;;
    *)
        echo "Error: Unsupported package manager or OS. Install $package manually."
        exit 1
        ;;
    esac
}

# Install figlet
install_package "figlet"

# Create figlet font directory if not exists
sudo mkdir -p /usr/share/figlet

# Download figlet font if not already present
if [[ ! -f /usr/share/figlet/ANSI_Regular.flf ]]; then
    if command -v wget &>/dev/null; then
        sudo wget -O /usr/share/figlet/ANSI_Regular.flf https://raw.githubusercontent.com/xero/figlet-fonts/master/ANSI%20Regular.flf
    elif command -v curl &>/dev/null; then
        sudo curl -o /usr/share/figlet/ANSI_Regular.flf https://raw.githubusercontent.com/xero/figlet-fonts/master/ANSI%20Regular.flf
    else
        echo "Error: Neither wget nor curl is installed. Installing wget..."
        install_package "wget"
        sudo wget -O /usr/share/figlet/ANSI_Regular.flf https://raw.githubusercontent.com/xero/figlet-fonts/master/ANSI%20Regular.flf
    fi
fi

# Run the main script after setup
run_main_script
