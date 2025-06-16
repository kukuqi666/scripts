#!/usr/bin/env bash

# The files installed by the script conform to the Filesystem Hierarchy Standard:
# https://wiki.linuxfoundation.org/lsb/fhs


JSON_PATH=${JSON_PATH:-/usr/local/etc/cpolar}


# Set this variable only if you want this script to check all the systemd unit file:
# export check_all_service_files='yes'

curl() {
  $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@"
}

systemd_cat_config() {
  if systemd-analyze --help | grep -qw 'cat-config'; then
    systemd-analyze --no-pager cat-config "$@"
    echo
  else
    echo "${aoi}~~~~~~~~~~~~~~~~"
    cat "$@" "$1".d/*
    echo "${aoi}~~~~~~~~~~~~~~~~"
    echo "${yellow}warning: ${green}The systemd version on the current operating system is too low."
    echo "${yellow}warning: ${green}Please consider to upgrade the systemd or the operating system.${reset}"
    echo
  fi
}

check_if_running_as_root() {
  # If you want to run as another user, please modify $UID to be owned by this user
  if [[ "$UID" -ne '0' ]]; then
    echo "WARNING: The user currently executing this script is not root. You may encounter the insufficient privilege error."
    read -r -p "Are you sure you want to continue? [y/n] " cont_without_been_root
    if [[ x"${cont_without_been_root:0:1}" = x'y' ]]; then
      echo "Continuing the installation with current user..."
    else
      echo "Not running with root, exiting..."
      exit 1
    fi
  fi
}



identify_the_operating_system_and_architecture() {
  if [[ "$(uname)" == 'Linux' ]]; then
    case "$(uname -m)" in
      'i386' | 'i686')
        MACHINE='386'
        ;;
      'amd64' | 'x86_64')
        MACHINE='amd64'
        ;;
      'armv5tel')
        MACHINE='arm'
        ;;
      'armv6l')
        MACHINE='arm'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm'
        ;;
      'armv7' | 'armv7l')
        MACHINE='arm'
        grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm'
        ;;
      'armv8' | 'aarch64')
        MACHINE='arm64'
        ;;
      'mips')
        MACHINE='mips'
        ;;
      'mipsle')
        MACHINE='mipsle'
        ;;
      'mips64')
        MACHINE='mips64'
        ;;
      'mips64le')
        MACHINE='mips64le'
        ;;
      'ppc64')
        MACHINE='ppc64'
        ;;
      'ppc64le')
        MACHINE='ppc64le'
        ;;
      'riscv64')
        MACHINE='riscv64'
        ;;
      's390x')
        MACHINE='s390x'
        ;;
      *)
        echo "error: The architecture is not supported."
        exit 1
        ;;
    esac
    if [[ ! -f '/etc/os-release' ]]; then
      echo "error: Don't use outdated Linux distributions."
      exit 1
    fi
    # Do not combine this judgment condition with the following judgment condition.
    ## Be aware of Linux distribution like Gentoo, which kernel supports switch between Systemd and OpenRC.
    ### Refer: https://github.com/v2fly/fhs-install-v2ray/issues/84#issuecomment-688574989
 
   if [[ -f /.dockerenv ]] || grep -q 'docker\|lxc' /proc/1/cgroup && [[ "$(type -P systemctl)" ]]; then
      true
    elif [[ -d /run/systemd/system ]] || grep -q systemd <(ls -l /sbin/init); then
      true
    else
      echo "error: Only Linux distributions using systemd are supported."
      exit 1
    fi
    if [[ "$(type -P apt)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='apt -y --no-install-recommends install'
      PACKAGE_MANAGEMENT_REMOVE='apt purge'
      package_provide_tput='ncurses-bin'
    elif [[ "$(type -P dnf)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='dnf -y install'
      PACKAGE_MANAGEMENT_REMOVE='dnf remove'
      package_provide_tput='ncurses'
    elif [[ "$(type -P yum)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='yum -y install'
      PACKAGE_MANAGEMENT_REMOVE='yum remove'
      package_provide_tput='ncurses'
    elif [[ "$(type -P zypper)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='zypper install -y --no-recommends'
      PACKAGE_MANAGEMENT_REMOVE='zypper remove'
      package_provide_tput='ncurses-utils'
    elif [[ "$(type -P pacman)" ]]; then
      PACKAGE_MANAGEMENT_INSTALL='pacman -Syu --noconfirm'
      PACKAGE_MANAGEMENT_REMOVE='pacman -Rsn'
      package_provide_tput='ncurses'
    else
      echo "error: The script does not support the package manager in this operating system."
      exit 1
    fi
  else
    echo "error: This operating system is not supported."
    exit 1
  fi
}

## Demo function for processing parameters
judgment_parameters() {
  while [[ "$#" -gt '0' ]]; do
    case "$1" in
      '--remove')
        if [[ "$#" -gt '1' ]]; then
          echo 'error: Please enter the correct parameters.'
          exit 1
        fi
        REMOVE='1'
        ;;
      '--version')
        VERSION="${2:?error: Please specify the correct version.}"
        break
        ;;
      '-c' | '--check')
        CHECK='1'
        break
        ;;
      '-f' | '--force')
        FORCE='1'
        break
        ;;
      '-h' | '--help')
        HELP='1'
        break
        ;;
      '-l' | '--local')
        LOCAL_INSTALL='1'
        LOCAL_FILE="${2:?error: Please specify the correct local file.}"
        break
        ;;
      '-p' | '--proxy')
        if [[ -z "${2:?error: Please specify the proxy server address.}" ]]; then
          exit 1
        fi
        PROXY="$2"
        shift
        ;;
      *)
        echo "$0: unknown option -- -"
        exit 1
        ;;
    esac
    shift
  done
}

install_software() {
  package_name="$1"
  file_to_detect="$2"
  type -P "$file_to_detect" > /dev/null 2>&1 && return
  if ${PACKAGE_MANAGEMENT_INSTALL} "$package_name"; then
    echo "info: $package_name is installed."
  else
    echo "error: Installation of $package_name failed, please check your network."
    exit 1
  fi
}

get_version() {
  # 0: Install or update Cpolar.
  # 1: Installed or no new version of Cpolar.
  # 2: Install the specified version of Cpolar.



  if [[ -n "$VERSION" ]]; then
    RELEASE_VERSION="${VERSION#v}"
    return 2
  fi
  # Determine the version number for Cpolar installed from a local file
  if [[ -f '/usr/local/bin/cpolar' ]]; then
    VERSION="$(/usr/local/bin/cpolar version | awk 'NR==1 {print $3}')"
    CURRENT_VERSION="$VERSION"
    if [[ "$LOCAL_INSTALL" -eq '1' ]]; then
      RELEASE_VERSION="$CURRENT_VERSION"
      return
    fi
  fi

  RELEASE_VERSION="3.3.12"

  if [[ "$RELEASE_VERSION" == "$CURRENT_VERSION" ]]; then
    return 1
  fi

  return 0


  # Get Cpolar release version number
  TMP_FILE="$(mktemp)"
  if ! curl -x "${PROXY}" -sS -H "Accept: application/vnd.github.v3+json" -o "$TMP_FILE" 'https://api.cpolar.com/v1/Updates'; then
    "rm" "$TMP_FILE"
    echo 'error: Failed to get release list, please check your network.'
    exit 1
  fi
  RELEASE_LATEST="$(sed 'y/,/\n/' "$TMP_FILE" | grep 'tag_name' | awk -F '"' '{print $4}')"
  "rm" "$TMP_FILE"
  RELEASE_VERSION="v${RELEASE_LATEST#v}"
  # Compare Cpolar version numbers
  if [[ "$RELEASE_VERSION" != "$CURRENT_VERSION" ]]; then
    RELEASE_VERSIONSION_NUMBER="${RELEASE_VERSION#v}"
    RELEASE_MAJOR_VERSION_NUMBER="${RELEASE_VERSIONSION_NUMBER%%.*}"
    RELEASE_MINOR_VERSION_NUMBER="$(echo "$RELEASE_VERSIONSION_NUMBER" | awk -F '.' '{print $2}')"
    RELEASE_MINIMUM_VERSION_NUMBER="${RELEASE_VERSIONSION_NUMBER##*.}"
    # shellcheck disable=SC2001
    CURRENT_VERSIONSION_NUMBER="$(echo "${CURRENT_VERSION#v}" | sed 's/-.*//')"
    CURRENT_MAJOR_VERSION_NUMBER="${CURRENT_VERSIONSION_NUMBER%%.*}"
    CURRENT_MINOR_VERSION_NUMBER="$(echo "$CURRENT_VERSIONSION_NUMBER" | awk -F '.' '{print $2}')"
    CURRENT_MINIMUM_VERSION_NUMBER="${CURRENT_VERSIONSION_NUMBER##*.}"
    if [[ "$RELEASE_MAJOR_VERSION_NUMBER" -gt "$CURRENT_MAJOR_VERSION_NUMBER" ]]; then
      return 0
    elif [[ "$RELEASE_MAJOR_VERSION_NUMBER" -eq "$CURRENT_MAJOR_VERSION_NUMBER" ]]; then
      if [[ "$RELEASE_MINOR_VERSION_NUMBER" -gt "$CURRENT_MINOR_VERSION_NUMBER" ]]; then
        return 0
      elif [[ "$RELEASE_MINOR_VERSION_NUMBER" -eq "$CURRENT_MINOR_VERSION_NUMBER" ]]; then
        if [[ "$RELEASE_MINIMUM_VERSION_NUMBER" -gt "$CURRENT_MINIMUM_VERSION_NUMBER" ]]; then
          return 0
        else
          return 1
        fi
      else
        return 1
      fi
    else
      return 1
    fi
  elif [[ "$RELEASE_VERSION" == "$CURRENT_VERSION" ]]; then
    return 1
  fi
}

download_cpolar() {
  DOWNLOAD_LINK="http://www.cpolar.com/static/downloads/releases/$RELEASE_VERSION/cpolar-stable-linux-$MACHINE.zip"
  echo "Downloading Cpolar archive: $DOWNLOAD_LINK"
  if ! curl -x "${PROXY}" -R -H 'Cache-Control: no-cache' -o "$ZIP_FILE" "$DOWNLOAD_LINK"; then
    echo 'error: Download failed! Please check your network or try again.'
    return 1
  fi


  # echo "Downloading verification file for Cpolar archive: $DOWNLOAD_LINK.dgst"
  # if ! curl -x "${PROXY}" -sSR -H 'Cache-Control: no-cache' -o "$ZIP_FILE.dgst" "$DOWNLOAD_LINK.dgst"; then
  #   echo 'error: Download failed! Please check your network or try again.'
  #   return 1
  # fi

  # if [[ "$(cat "$ZIP_FILE".dgst)" == 'Not Found' ]]; then
  #   echo 'error: This version does not support verification. Please replace with another version.'
  #   return 1
  # fi

  # Verification of Cpolar archive

  # for LISTSUM in 'md5' 'sha1' 'sha256' 'sha512'; do
  #   SUM="$(${LISTSUM}sum "$ZIP_FILE" | sed 's/ .*//')"
  #   CHECKSUM="$(grep ${LISTSUM^^} "$ZIP_FILE".dgst | grep "$SUM" -o -a | uniq)"
  #   if [[ "$SUM" != "$CHECKSUM" ]]; then
  #     echo 'error: Check failed! Please check your network or try again.'
  #     return 1
  #   fi
  # done
}

decompression() {
  if ! unzip -q "$1" -d "$TMP_DIRECTORY"; then
    echo 'error: Cpolar decompression failed.'
    "rm" -r "$TMP_DIRECTORY"
    echo "removed: $TMP_DIRECTORY"
    exit 1
  fi
  echo "info: Extract the Cpolar package to $TMP_DIRECTORY and prepare it for installation."
  

  mkdir -p "$TMP_DIRECTORY/systemd/system"
  mkdir -p "$TMP_DIRECTORY/config"

  #wget -O "$TMP_DIRECTORY/config/cpolar.demo.yml" https://www.cpolar.com/static/downloads/cpolar.demo.yml
 
  DOWNLOAD_CONFIG_LINK="http://www.cpolar.com/static/downloads/cpolar.demo.yml" 
  echo "Downloading Cpolar demo config file: $DOWNLOAD_CONFIG_LINK"
  if ! curl -x "${PROXY}" -R -H 'Cache-Control: no-cache' -o "$TMP_DIRECTORY/config/cpolar.demo.yml"  "$DOWNLOAD_CONFIG_LINK"; then
    echo 'error: Download failed! Please check your network or try again.'
    return 1
  fi

  DOWNLOAD_SERVICE_CONFIG_LINK="http://www.cpolar.com/static/downloads/cpolar.service"
  echo "Downloading Cpolar service config file: $DOWNLOAD_SERVICE_CONFIG_LINK"
  if ! curl -x "${PROXY}" -R -H 'Cache-Control: no-cache' -o "$TMP_DIRECTORY/systemd/system/cpolar.service"  "$DOWNLOAD_SERVICE_CONFIG_LINK"; then
    echo 'error: Download failed! Please check your network or try again.'
    return 1
  fi

  DOWNLOAD_SERVICE_AT_CONFIG_LINK="http://www.cpolar.com/static/downloads/cpolar@.service"
  echo "Downloading Cpolar service@ config file: $DOWNLOAD_SERVICE_AT_CONFIG_LINK"
  if ! curl -x "${PROXY}" -R -H 'Cache-Control: no-cache' -o "$TMP_DIRECTORY/systemd/system/cpolar@.service"  "$DOWNLOAD_SERVICE_AT_CONFIG_LINK"; then
    echo 'error: Download failed! Please check your network or try again.'
    return 1
  fi
}

install_file() {
  NAME="$1"
  if [[ "$NAME" == 'cpolar' ]]; then
    install -m 755 "${TMP_DIRECTORY}/$NAME" "/usr/local/bin/$NAME"
    ln -s "/usr/local/bin/$NAME" "/usr/bin/$NAME"
  # elif [[ "$NAME" == 'geoip.dat' ]] || [[ "$NAME" == 'geosite.dat' ]]; then
  #   install -m 644 "${TMP_DIRECTORY}/$NAME" "${DAT_PATH}/$NAME"

  fi
}

install_cpolar() {
  # Install Cpolar binary to /usr/local/bin/ and $DAT_PATH
  install_file cpolar
  # install -d "$DAT_PATH"
  # If the file exists, geoip.dat and geosite.dat will not be installed or updated
  # if [[ ! -f "${DAT_PATH}/.undat" ]]; then
  #   install_file geoip.dat
  #   install_file geosite.dat
  # fi

  # Install Cpolar configuration file to $JSON_PATH
  # shellcheck disable=SC2153

   if [[ ! -f "$JSON_PATH/cpolar.yml" ]]; then
     install -d  "$JSON_PATH"
     # echo "" > "${JSON_PATH}/cpolar.yml"
     install -m 666  "${TMP_DIRECTORY}/config/cpolar.demo.yml" "${JSON_PATH}/cpolar.yml" 
     CONFIG_NEW='1'
   fi

  # Install Cpolar configuration file to $JSONS_PATH
  # if [[ -n "$JSONS_PATH" ]] && [[ ! -d "$JSONS_PATH" ]]; then
  #   install -d "$JSONS_PATH"
  #   for BASE in 00_log 01_api 02_dns 03_routing 04_policy 05_inbounds 06_outbounds 07_transport 08_stats 09_reverse; do
  #     echo '{}' > "${JSONS_PATH}/${BASE}.json"
  #   done
  #   CONFDIR='1'
  # fi

  # Used to store Cpolar log files
  if [[ ! -d '/var/log/cpolar/' ]]; then
    if id nobody | grep -qw 'nogroup'; then
      install -d -m 700 -o nobody -g nogroup /var/log/cpolar/
      install -m 644 -o nobody -g nogroup /dev/null /var/log/cpolar/access.log
      install -m 644 -o nobody -g nogroup /dev/null /var/log/cpolar/error.log
    else
      install -d -m 700 -o nobody -g nobody /var/log/cpolar/
      install -m 644 -o nobody -g nobody /dev/null /var/log/cpolar/access.log
      install -m 644 -o nobody -g nobody /dev/null /var/log/cpolar/error.log
    fi
    LOG='1'
  fi
}

install_startup_service_file() {
  install -m 644 "${TMP_DIRECTORY}/systemd/system/cpolar.service" /etc/systemd/system/cpolar.service
  install -m 644 "${TMP_DIRECTORY}/systemd/system/cpolar@.service" /etc/systemd/system/cpolar@.service
  mkdir -p '/etc/systemd/system/cpolar.service.d'
  mkdir -p '/etc/systemd/system/cpolar@.service.d/'

  "rm" '/etc/systemd/system/cpolar.service.d/10-donot_touch_multi_conf.conf' \
      '/etc/systemd/system/cpolar@.service.d/10-donot_touch_multi_conf.conf'
#  echo "# In case you have a good reason to do so, duplicate this file in the same directory and make your customizes there.
## Or all changes you made will be lost!  # Refer: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
#[Service]
#ExecStart=
#ExecStart=/usr/local/bin/cpolar start-all -daemon=on -config=${JSON_PATH}/cpolar.yml -log=/var/log/cpolar/access.log" > \
#      '/etc/systemd/system/cpolar.service.d/10-donot_touch_single_conf.conf'
#    echo "# In case you have a good reason to do so, duplicate this file in the same directory and make your customizes there.
## Or all changes you made will be lost!  # Refer: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
#[Service]
#ExecStart=
#ExecStart=/usr/local/bin/cpolar start-all -daemon=on -config=${JSON_PATH}/%i.yml -log=/var/log/cpolar/access.log" > \
#      '/etc/systemd/system/cpolar@.service.d/10-donot_touch_single_conf.conf'
  

  echo "info: Systemd service files have been installed successfully!"
  echo "${yellow}warning: ${green}The following are the actual parameters for the cpolar service startup."
  echo "${yellow}warning: ${green}Please make sure the configuration file path is correctly set.${reset}"
  systemd_cat_config /etc/systemd/system/cpolar.service
  # shellcheck disable=SC2154
  if [[ x"${check_all_service_files:0:1}" = x'y' ]]; then
    echo
    echo
    systemd_cat_config /etc/systemd/system/cpolar@.service
  fi
  systemctl daemon-reload
  SYSTEMD='1'
}

start_cpolar() {
  if [[ -f '/etc/systemd/system/cpolar.service' ]]; then
    if systemctl start "${CPOLAR_CUSTOMIZE:-cpolar}"; then
      echo 'info: Start the Cpolar service.'
    else
      echo 'error: Failed to start Cpolar service.'
      exit 1
    fi
  fi
}

stop_cpolar() {
  CPOLAR_CUSTOMIZE="$(systemctl list-units | grep 'cpolar@' | awk -F ' ' '{print $1}')"
  if [[ -z "$CPOLAR_CUSTOMIZE" ]]; then
    local cpolar_daemon_to_stop='cpolar.service'
  else
    local cpolar_daemon_to_stop="$CPOLAR_CUSTOMIZE"
  fi
  if ! systemctl stop "$cpolar_daemon_to_stop"; then
    echo 'error: Stopping the Cpolar service failed.'
    exit 1
  fi
  echo 'info: Stop the Cpolar service.'
}

check_update() {
  if [[ -f '/etc/systemd/system/cpolar.service' ]]; then
    get_version
    local get_ver_exit_code=$?
    if [[ "$get_ver_exit_code" -eq '0' ]]; then
      echo "info: Found the latest release of Cpolar $RELEASE_VERSION . (Current release: $CURRENT_VERSION)"
    elif [[ "$get_ver_exit_code" -eq '1' ]]; then
      echo "info: No new version. The current version of Cpolar is v$CURRENT_VERSION ."
    fi
    exit 0
  else
    echo 'error: Cpolar is not installed.'
    exit 1
  fi
}

remove_cpolar() {
  if systemctl list-unit-files | grep -qw 'cpolar'; then
    if [[ -n "$(pidof cpolar)" ]]; then
      stop_cpolar
      systemctl disable cpolar
    fi
    if ! ("rm" -rf '/usr/local/bin/cpolar' \
      '/usr/bin/cpolar' \
      '/etc/systemd/system/cpolar.service' \
      '/etc/systemd/system/cpolar@.service' \
      '/etc/systemd/system/cpolar.service.d' \
      '/etc/systemd/system/cpolar@.service.d'); then
      echo 'error: Failed to remove Cpolar.'
      exit 1
    else
      echo 'removed: /usr/local/bin/cpolar'
      echo 'removed: /usr/bin/cpolar'
      echo 'removed: /etc/systemd/system/cpolar.service'
      echo 'removed: /etc/systemd/system/cpolar@.service'
      echo 'removed: /etc/systemd/system/cpolar.service.d'
      echo 'removed: /etc/systemd/system/cpolar@.service.d'
      echo 'Please execute the command: systemctl disable cpolar'
      echo "You may need to execute a command to remove dependent software: $PACKAGE_MANAGEMENT_REMOVE curl unzip"
      echo 'info: Cpolar has been removed.'
      echo 'info: If necessary, manually delete the configuration and log files.'
      exit 0
    fi
  else
    echo 'error: Cpolar is not installed.'
    exit 1
  fi
}

# Explanation of parameters in the script
show_help() {
  echo "usage: $0 [--remove | --version number | -c | -f | -h | -l | -p]"
  echo '  [-p address] [--version number | -c | -f]'
  echo '  --remove        Remove Cpolar'
  echo '  --version       Install the specified version of Cpolar, e.g., --version v4.18.0'
  echo '  -c, --check     Check if Cpolar can be updated'
  echo '  -f, --force     Force installation of the latest version of Cpolar'
  echo '  -h, --help      Show help'
  echo '  -l, --local     Install Cpolar from a local file'
  echo '  -p, --proxy     Download through a proxy server, e.g., -p http://127.0.0.1:8118 or -p socks5://127.0.0.1:1080'
  exit 0
}

main() {
  check_if_running_as_root
  identify_the_operating_system_and_architecture
  judgment_parameters "$@"

  install_software "$package_provide_tput" 'tput'
  # red=$(tput setaf 1)
  yellow=$(tput setaf 3)
  green=$(tput setaf 2)
  aoi=$(tput setaf 6)
  reset=$(tput sgr0)

  # Parameter information
  [[ "$HELP" -eq '1' ]] && show_help
  [[ "$CHECK" -eq '1' ]] && check_update
  [[ "$REMOVE" -eq '1' ]] && remove_cpolar

  # Two very important variables
  TMP_DIRECTORY="$(mktemp -d)"
  ZIP_FILE="${TMP_DIRECTORY}/cpolar-linux-$MACHINE.zip"

  # Install Cpolar from a local file, but still need to make sure the network is available
  if [[ "$LOCAL_INSTALL" -eq '1' ]]; then
    echo 'warn: Install Cpolar from a local file, but still need to make sure the network is available.'
    echo -n 'warn: Please make sure the file is valid because we cannot confirm it. (Press any key) ...'
    read -r
    install_software 'unzip' 'unzip'
    decompression "$LOCAL_FILE"
  else
    # Normal way
    install_software 'curl' 'curl'
    get_version
    NUMBER="$?"
    if [[ "$NUMBER" -eq '0' ]] || [[ "$FORCE" -eq '1' ]] || [[ "$NUMBER" -eq 2 ]]; then
      echo "info: Installing Cpolar $RELEASE_VERSION for $(uname -m)"
      download_cpolar
      if [[ "$?" -eq '1' ]]; then
        "rm" -r "$TMP_DIRECTORY"
        echo "removed: $TMP_DIRECTORY"
        exit 1
      fi
      install_software 'unzip' 'unzip'
      decompression "$ZIP_FILE"
    elif [[ "$NUMBER" -eq '1' ]]; then
      echo "info: No new version. The current version of Cpolar is v$CURRENT_VERSION ."
      exit 0
    fi
  fi

  # Determine if Cpolar is running
  if systemctl list-unit-files | grep -qw 'cpolar'; then
    if [[ -n "$(pidof cpolar)" ]]; then
      stop_cpolar
      CPOLOR_RUNNING='1'
    fi
  fi
  install_cpolar
  install_startup_service_file
  echo 'installed: /usr/local/bin/cpolar'
  echo 'installed link: /usr/bin/cpolar'
  # If the file exists, the content output of installing or updating geoip.dat and geosite.dat will not be displayed
  # if [[ ! -f "${DAT_PATH}/.undat" ]]; then
  #   echo "installed: ${DAT_PATH}/geoip.dat"
  #   echo "installed: ${DAT_PATH}/geosite.dat"
  # fi
  if [[ "$CONFIG_NEW" -eq '1' ]]; then
    echo "installed: ${JSON_PATH}/cpolar.yml"
  fi
  # if [[ "$CONFDIR" -eq '1' ]]; then
  #   echo "installed: ${JSON_PATH}/00_log.json"
  #   echo "installed: ${JSON_PATH}/01_api.json"
  #   echo "installed: ${JSON_PATH}/02_dns.json"
  #   echo "installed: ${JSON_PATH}/03_routing.json"
  #   echo "installed: ${JSON_PATH}/04_policy.json"
  #   echo "installed: ${JSON_PATH}/05_inbounds.json"
  #   echo "installed: ${JSON_PATH}/06_outbounds.json"
  #   echo "installed: ${JSON_PATH}/07_transport.json"
  #   echo "installed: ${JSON_PATH}/08_stats.json"
  #   echo "installed: ${JSON_PATH}/09_reverse.json"
  # fi
  if [[ "$LOG" -eq '1' ]]; then
    echo 'installed: /var/log/cpolar/'
    echo 'installed: /var/log/cpolar/access.log'
    echo 'installed: /var/log/cpolar/error.log'
  fi
  if [[ "$SYSTEMD" -eq '1' ]]; then
    echo 'installed: /etc/systemd/system/cpolar.service'
    echo 'installed: /etc/systemd/system/cpolar@.service'
  fi
  "rm" -r "$TMP_DIRECTORY"
  echo "removed: $TMP_DIRECTORY"
  if [[ "$LOCAL_INSTALL" -eq '1' ]]; then
    get_version
  fi
  echo "info: Cpolar $RELEASE_VERSION is installed."
  echo "You may need to execute a command to remove dependent software: $PACKAGE_MANAGEMENT_REMOVE curl unzip"
  if [[ "$CPOLOR_RUNNING" -eq '1' ]]; then
    start_cpolar
  else
    echo 'Please execute the command: systemctl enable cpolar; systemctl start cpolar'
  fi
}

main "$@"
