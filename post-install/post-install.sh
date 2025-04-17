#!/usr/bin/env bash
#
# A post installation script for Linux hosts.
#
# Four spaces for indentation.
# No lines exceeding 79 characters.
#
# vim configuration based off the .vimrc at:
#   - https://github.com/nathanielhix/dot_files/blob/main/.vimrc

function main() {
    # Verify that we have the appropriate permissions.
    if (( EUID != 0 )); then
        echo -e "You must be root to execute this script."
        exit 1
    fi

    # Set common variables
    user_name="svc-admin"
    ssh_group="ssh-users"

    # Declare arrays

    declare -a family_debian
    declare -a family_rhel

    # Arrays of known distribution names.
    # Distribution names need to match the ID field in /etc/os-release.
    # If there are spaces, substitute '_'.
    # TODO: Iterate through list of arrays, instead of explicitely calling each
    # one. Bash namerefs may work here.
    # https://www.gnu.org/software/bash/manual/html_node/Shell-Parameters.html

    family_debian=(
        debian
        ubuntu
    )

    family_rhel=(
        rocky
        centos
        almalinux
    )

    os_release=$(get_os)

    if [[ "${family_debian[*]}" =~ "$os_release"( |$) ]]; then
        configure_debian
    elif [[ "${family_rhel[*]}" =~ "$os_release"( |$) ]]; then
        configure_rhel
    else
        echo -e "OS family unknown."
        exit 1
    fi
}


function get_os() {
    # Declare arrays

    declare -a files_release

    # Supported release files

    files_release=(
        /etc/os-release
    )

    # Iterate through release files, and try to extract the distribution name.
    # Strip the string ID= from the distribution name.
    # Strip double quotes from the distribution name.

    for x in "${files_release[@]}"; do
        if [[ -f "$x" ]]; then
            while read line; do
                if [[ "$line" =~ ^ID= ]]; then
                    distro_name="${line#ID=}"
                    distro_name="${distro_name//\"}"
                    break
                fi
            done < "$x"
        fi
        [[ "$distro_name" ]] && break
    done

    # Return the distro name, or a failure string.

    if [[ "$distro_name" ]]; then
        echo -e "$distro_name"
    else
        echo -e "unknown_distro"
    fi
}


function configure_rhel() {
    packages=(
        bind-utils
        open-vm-tools
        openssh-server
        openssh-clients
        python39
        vim-enhanced
    )

    # Update existing software.
    yum upgrade -y

    # Install some packages.
    yum install -y "${packages[@]}"

    # Add the administrative user.
    if ! id "$user_name" &>/dev/null; then
        adduser "$user_name"
        passwd "$user_name"
    else
        echo -e "User $user_name already exists. Proceeding."
    fi

    # Add the ssh-users group and add svc-admin to it.
    if ! getent group "$ssh_group"; then
        groupadd "$ssh_group"
    fi

    # Get groups
    readarray -t group_memberships < <(id "$user_name" --name --groups)

    if [[ ! "${group_memberships[*]}" =~ "$ssh_group"( |$) ]]; then
        usermod -aG "$ssh_group" "$user_name"
    fi

    # Disable SELinux
    # SELinux should be configured correctly with contexts.
    selinux_status=$(sestatus | awk '/^Mode from config:/ {print $NF}')
    if [[ "$selinux_status" == enforcing ]]; then
        echo -e "Setting SELinux mode to permissive."
        sed -i '/^SELINUX=/s/enforcing/permissive/' /etc/selinux/config

        unset selinux_status
        selinux_status=$(sestatus | awk '/^Mode from config/ {print $NF}')

        if [[ "$selinux_status" == permissive ]]; then
            echo -e "Successfully set SELinux to permissive. Please reboot."
        fi
    else
        echo -e "SELinux is not enforcing."
    fi
}


function configure_debian() {
    echo -e "${FUNCNAME[0]} not implemented yet."
}


# Execute the script
main
