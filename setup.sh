#!/bin/bash
# setup.sh - Generated cluster setup script
# This script is self-contained with all configs embedded
# Generated on: $(date)

set -e

INSTALL_NODE=true

echo "========================================="
echo "Setting up development environment..."
echo "========================================="

# ─────────────────────────────────────────
# Install System Packages
# ─────────────────────────────────────────
install_packages() {
    echo "📦 Installing system packages..."
    
    # Check if we need sudo
    if [ "$EUID" -eq 0 ]; then
        SUDO=""
        SUDO_ENV=""
    else
        SUDO="sudo"
        SUDO_ENV="sudo -E"
    fi
    
    $SUDO apt-get update -qq || true
    $SUDO apt-get remove -y --purge neovim
    $SUDO apt-get install -y --no-install-recommends \
        build-essential cmake gcc \
        curl git jq openssh-client htop tmux zip \
        software-properties-common ripgrep vim wget tar unzip \
        ca-certificates python3-dev \
        nvtop zstd
    
    # Install Neovim
    if ! command -v nvim &>/dev/null; then
        echo "📦 Installing Neovim..."
        curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.tar.gz
        $SUDO tar -C /opt -xzf nvim-linux-x86_64.tar.gz
        $SUDO ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
        rm nvim-linux-x86_64.tar.gz
    fi

    # Install TPM (Tmux Plugin Manager) and plugins
    if [ -f ~/.tmux.conf ]; then
        echo "  → Installing Tmux Plugin Manager"
        if [ ! -d ~/.tmux/plugins/tpm ]; then
            git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        fi
        # Install tmux plugins if TPM is installed
        if [ -f ~/.tmux/plugins/tpm/bin/install_plugins ]; then
            echo "  → Installing tmux plugins"
            ~/.tmux/plugins/tpm/bin/install_plugins || true
        fi
    fi
    
    # Optional: Install Node.js and pyright for code intelligence
    if [ "${INSTALL_NODE:-false}" = "true" ]; then
        echo "📦 Installing Node.js and Pyright..."
        if ! command -v node &>/dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO_ENV bash -
            $SUDO apt-get install -y nodejs
            $SUDO npm install -g pyright

            # needed for nvim
            mkdir -p ~/.local/bin
            curl -L -o /tmp/tree-sitter.gz \
                https://github.com/tree-sitter/tree-sitter/releases/download/v0.26.3/tree-sitter-linux-x64.gz
            gunzip -c /tmp/tree-sitter.gz > ~/.local/bin/tree-sitter
            chmod +x ~/.local/bin/tree-sitter
        fi
    fi

    # aws cli
    mkdir -p ~/tmp
    cd ~/tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    $SUDO ./aws/install
    cd ~
    
    # Clean up
    $SUDO apt-get clean
    $SUDO rm -rf /var/lib/apt/lists/*
}

# ─────────────────────────────────────────
# Restore Configuration Files
# ─────────────────────────────────────────
restore_configs() {
    echo "📝 Restoring configuration files..."
    
    # Create necessary directories
    mkdir -p ~/.config/nvim
    mkdir -p ~/.vim/autoload
    mkdir -p ~/.config/nvim/pack/github/start
    
    # Restore .vimrc
    if [ -n "$VIMRC_B64" ]; then
        echo "  → Restoring .vimrc"
        echo "$VIMRC_B64" | base64 -d | gunzip > ~/.vimrc || \
            echo "$VIMRC_B64" | base64 -D 2>/dev/null | gunzip > ~/.vimrc || \
            echo "Failed to decode .vimrc"
    fi
    
    # Restore .tmux.conf
    if [ -n "$TMUX_CONF_B64" ]; then
        echo "  → Restoring .tmux.conf"
        echo "$TMUX_CONF_B64" | base64 -d | gunzip > ~/.tmux.conf || \
            echo "$TMUX_CONF_B64" | base64 -D 2>/dev/null | gunzip > ~/.tmux.conf || \
            echo "Failed to decode .tmux.conf"
    fi
    
    # Restore nvim init.vim
    if [ -n "$NVIM_INIT_B64" ]; then
        echo "  → Restoring nvim init.vim"
        echo "$NVIM_INIT_B64" | base64 -d | gunzip > ~/.config/nvim/init.vim || \
            echo "$NVIM_INIT_B64" | base64 -D 2>/dev/null | gunzip > ~/.config/nvim/init.vim || \
            echo "Failed to decode init.vim"
    fi
    
    # Restore .gitconfig (optional, may want to modify)
    if [ -n "$GITCONFIG_B64" ]; then
        echo "  → Restoring git config"
        echo "$GITCONFIG_B64" | base64 -d | gunzip > ~/.gitconfig.tmp || \
            echo "$GITCONFIG_B64" | base64 -D 2>/dev/null | gunzip > ~/.gitconfig.tmp || \
            echo "Failed to decode .gitconfig"
        if [ -f ~/.gitconfig.tmp ]; then
            git config --global user.name "$(git config --file ~/.gitconfig.tmp user.name 2>/dev/null || echo 'Rishit Sheth')"
            git config --global user.email "$(git config --file ~/.gitconfig.tmp user.email 2>/dev/null || echo 'rsheth@lila.ai')"
            rm ~/.gitconfig.tmp
        fi
    fi
}

# ─────────────────────────────────────────
# Install Vim/Neovim Plugins
# ─────────────────────────────────────────
install_plugins() {
    echo "🔌 Installing editor plugins..."
    
    # Install vim-plug for Vim
    if [ -f ~/.vimrc ]; then
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        vim -Es +PlugInstall +qa || true
    fi
    
    # Install vim-plug for Neovim
    if [ -f ~/.config/nvim/init.vim ] && command -v nvim &>/dev/null; then
        curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        nvim --headless +PlugInstall +qa 2>/dev/null || true
        nvim --headless +PlugInstall +qa 2>/dev/null || true  # Run twice for first-time quirks
        
        # Install GitHub Copilot if not already present
        if [ ! -d ~/.config/nvim/pack/github/start/copilot.vim ]; then
            echo "  → Installing GitHub Copilot for Neovim"
            git clone https://github.com/github/copilot.vim \
                ~/.config/nvim/pack/github/start/copilot.vim
        fi
    fi
}
# ─────────────────────────────────────────
# Embedded Configuration Data  
# ─────────────────────────────────────────
VIMRC_B64="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"
TMUX_CONF_B64="H4sIAP4ZemkAA51XbW/bNhD+7l9xk5GpLcwoduKm89CiW1vsS4oCSYsNSIuAlimJsSSyJGXZ67rf
viP1Yklx0mAf4pC894d3x9MYIqEgFCn+SpoyY9hiNAaAxBipF0GgC8lUoZk6DkUWfC2YNlzkOpi9
mJ++mAaJKMlKME1MwojJii1xukiti5RCrUeoULGMSpCKRXwLkRIZvCFLMAL/0VGRL3m+sicjzQwR
0poAEjf8lsdykDXb2Q1ohpuKaJXbEHJ0jK2QojUK71XqvSTJ7X4orGXKDcaOCqDQPI/hH6AoSpwg
bhwDKXEjSiAJkBD88TcrcBMWSrHc3Ehqku9+JUAGApsHBGovfa9dHo2a1ZWkIaugSwVd4R3lEY8h
4imDJ2FC85hVm1SE1AGGaO5EoQCvAuxVHFsRewQlzY0l4z0+rbxUoJE1ZMSp+Dc4bgUcJiU3YdID
5bfUEKoURoS0RBSmvpzGXQT3PUl6u7S3W/d2t6OOFF5JykJDrD0gFx1S2idddkjrPulTh3TbJ719
OEdap2+bRetqWik97OAdK5XsQbfuxFF7q9DbTxKvWPO/2SASS3sryrxPfduhXrDI9KkXHeolj5MB
Ge1igdnKWlLNCLKyLUztWenKDZnIQcrWMJXZItKAwFVKNDAdUollzzMGJ4PS1YaaQlciGz4gZmLF
WlLjUi2xROdSGq4Hx1HsulShzp4PKLcFtqRoBymiMSBJoXldGrIhVXVJag5tdpj/K54dJtf1WrMt
lYV0wg1NeagHtqx58P3BKc8RuQ1NYTYgOFXgjb/lCDE2yZslNp2Sr7AvYM8ZX0fxyybeyTJ+6SD5
Mn7iWmzGMhLKgri+QDo2no6vVyyiRWq+eIfsoZN5bBI4n48Ox4tVklEM43r85xf/YUj6rPsue4X3
lGXU9ViRSeTIWdl2wxyOpvAraJ3gwm+9cJlHQ8M3mIBCrZiqIe/A4KrYvhzN01SW5XGkGAsxm0Ka
yWOh4gCN6cChxHP0wOoMmYMoVq5NEtu/iN5hK0AUUy6XgqoVWYar81n4fBZF58sALVV19BGDkTvi
8nXD4Z1FunpAXPaSvyq65FgGNuSQ5iFLwdtaxUA4kAgLxZW+TUOpeEbVDi94z7Cnts54GGoNzGts
yYbnRZERTTdsf9f+dO4f4sJ6N0Ix8EWO8I5VkROdsDS1Pb56Qhw6FUTIbG8zNEG7cg/Bj+Rac0G7
quSa+6yzkNi2wXN013Nys/lzNx54jecUGg4iNkwpvsIHx5s8qxifLT6GD7P6zxZX+uXnd9dHcnq0
gq+LK2Z38NUlL2H5hiuRZ5iv1qs3Hy4+XH58d/ke3VEFq135UbB1gZK2QO853iPQ6XSRCLFm2AY9
cK2zS+1EFDGsLWUD6uG0uPzjd78zwAzS0d/5LhnvzUNfLu35Ayr2Gf1jJVVR/E9PFEZoaJgQI4gd
J0lOM6btjAOP0P8YNx9hoUnP1zItYp5jkURcxTRNqyutG52Vs94MmW+FTjKGabfmTQpg44iwAvqS
QznHW23q1rSj+fouH1N8XVYMUpRMpTw/oE1kTG3r1Kwnme1jbLYV/hjmtqxtD+ldSz2Sf4B90Xg4
MuBYnOKYWw+SQU9Z42WgQ8Wl0UFzcKwTH2avXjVS7XkqYm9/Wc0xcX7Ug1QhwafYYTo4HuRb2QnK
cd527v+eftmQW6zwFcJXg8U7TMIM/NrCIUachGwFu0HLwecq/h6t+DKGqMrWe77B2aT7fr7BN3Lw
ghIJ3lVlGmyKLcADb4+/Xydj2SB9bF/XI9/rKt01E2hKd3Z6909n0fnk9GS+PT+bnExOru1yfmqX
36bzWb2cvJhN6t3UnUxnJ9+d1MxS52eTX87s688jbKmIJPwEZAV3skBmHnwe4Vel9Rr8GD+4wlTg
RNo85XiSFEv3idlPRpkd0gY//3zoOMB4A1zjfJbe1OeIgrN5iB3//NF/WMiRkAIPAAA="
NVIM_INIT_B64="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
H36Z4J9u+D88cN6UfkkAAA=="
GITCONFIG_B64="H4sIAP4ZemkAAxWMMQrCQBBF6+wpPqSwMgcQBDtbUbtgMSST7MDubNiZGLy9CfzmvQe/xTuKYd9d
/GRYuJ5X44qh6CTzWsmlKCZJ3IX+KJ/Q4pGYjEEjLQ7SEasOJWdWh0fGVFIqm+iMJMp2CY1SZlzx
FIvieEX2GBrOJGm31Q6+jRt92X7W7VfhD4JNth+YAAAA"
# ─────────────────────────────────────────
# Main Execution
# ────────────────────────────────────────
main() {
    echo "Environment: $(/bin/hostname)"
    echo "User: $(/usr/bin/whoami)"
    echo ""
    
    # Parse arguments
    while [ $# -gt 0 ]; do
        case $1 in
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --with-node)
                INSTALL_NODE=true
                shift
                ;;
            --configs-only)
                CONFIGS_ONLY=true
                shift
                ;;
            *)
                echo "Unknown option: $1"
                echo "Usage: $0 [--skip-packages] [--with-node] [--configs-only]"
                exit 1
                ;;
        esac
    done
    
    if [ "${CONFIGS_ONLY:-false}" = "true" ]; then
        restore_configs
        echo "✅ Configs restored successfully!"
    else
        restore_configs
        [ "${SKIP_PACKAGES:-false}" = "false" ] && install_packages
        install_plugins
        
        echo ""
        echo "========================================="
        echo "✅ Development environment setup complete!"
        echo "========================================="
        echo ""
        echo "Installed:"
        echo "  • Development tools (vim, tmux, git, etc.)"
        [ -f ~/.vimrc ] && echo "  • Vim configuration"
        [ -f ~/.tmux.conf ] && echo "  • Tmux configuration"
        [ -f ~/.config/nvim/init.vim ] && echo "  • Neovim configuration"
        echo ""
        echo "Tips:"
        echo "  • Run 'tmux' to start a tmux session"
        echo "  • Run 'nvim' to use Neovim"
        echo "  • Your original Python environment is untouched"
        echo ""
    fi
}

# Run main function
main "$@"
