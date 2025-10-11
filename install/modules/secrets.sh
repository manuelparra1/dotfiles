#!/usr/bin/env bash
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  printf "\033[1;31m[ERROR]\033[0m This script is a module and is not meant to be run directly.\n"
  printf "Please execute the main installer script:\n"
  printf "  ./install_dotfiles.sh\n"
  exit 1
fi
set -euo pipefail
# requires common.sh sourced by parent

banner "Secrets Management (sops)"

# --- Install Dependencies ---
install_deps() {
  local missing=()
  have sops || missing+=("sops")
  have age || missing+=("age")

  if [[ ${#missing[@]} -gt 0 ]]; then
    say "Attempting to install missing dependencies: ${missing[*]}"
    # pkg_install is defined in common.sh
    pkg_install "${missing[@]}"
  else
    say "sops and age are already installed."
  fi
}

# --- Guide User for Key Placement ---
setup_age_key() {
  local key_file="${HOME}/.config/sops/age/keys.txt"
  if [[ -f "$key_file" ]]; then
    say "Age key file already exists at ${key_file}. Skipping setup."
    return 0
  fi

  say "Setting up sops for decryption..."
  do_run mkdir -p "$(dirname "$key_file")"

  echo
  warn "ACTION REQUIRED: You need to place your age private key in the following file:"
  printf "  \033[1;37m%s\033[0m\n" "$key_file"
  echo
  echo "This key is the one you saved to your USB drive. It starts with 'AGE-SECRET-KEY-1...'."
  echo "The script is paused. Please copy the key into that file now."
  echo

  # Loop until the user confirms the key is in place
  while true;
  do
    read -r -p "Have you placed the key file? (y/n): " ans
    case "$ans" in
      [yY]*)
        if [[ -f "$key_file" && -s "$key_file" ]]; then
          say "Key file found. Proceeding."
          break
        else
          warn "Key file not found or is empty. Please make sure it's correctly placed."
        fi
        ;;
      [nN]*)
        warn "Skipping decryption. You can run the secrets module again later."
        return 1
        ;;
      *)
        echo "Invalid input. Please enter 'y' or 'n'."
        ;;
    esac
  done
}

# --- Decrypt and Source ---
decrypt_secrets() {
  local encrypted_file="${REPO_ROOT}/secrets.yaml"
  local decrypted_file="${HOME}/.secrets.env"

  if [[ ! -f "$encrypted_file" ]]; then
    warn "No 'secrets.yaml' file found in the repository. Skipping."
    return 1
  fi

  say "Decrypting secrets to ${decrypted_file}"
  if do_run "sops --decrypt '$encrypted_file' > '$decrypted_file'"; then
    # Add to .gitignore if not already there to prevent accidental commits
    local gitignore="${HOME}/.gitignore"
    if ! grep -q ".secrets.env" "$gitignore" 2>/dev/null;
    then
      do_run "echo '.secrets.env' >> '$gitignore'"
    fi
    say "Decryption successful. The secrets will be available in your next shell session."
  else
    die "Decryption failed. Please check your age key and file permissions."
  fi
}

# --- Main module execution ---
install_deps
if setup_age_key; then
  decrypt_secrets
fi
say "Secrets module complete."
