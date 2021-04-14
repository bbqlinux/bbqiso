#!/usr/bin/bash

set -e -u

iso_name=bbqlinux
iso_label="BBQLINUX"
iso_version=$(date +%Y.%m.%d)
iso_publisher="BBQLinux <http://www.bbqlinux.org>"
iso_application="BBQLinux Live/Rescue DVD"
desktop_env=cinnamon
install_dir=bbqlinux
work_dir=work
out_dir=out
gpg_key=

verbose=""
pacman_conf=${work_dir}/pacman.conf
script_path=$(readlink -f ${0%/*})

umask 0022

_usage ()
{
    echo "usage ${0} [options]"
    echo
    echo " General options:"
    echo "    -N <iso_name>             Set an iso filename (prefix)"
    echo "                               Default: ${iso_name}"
    echo "    -V <iso_version>          Set an iso version (in filename)"
    echo "                               Default: ${iso_version}"
    echo "    -L <iso_label>            Set an iso label (disk label)"
    echo "                               Default: ${iso_label}"
    echo "    -P <publisher>            Set a publisher for the disk"
    echo "                               Default: '${iso_publisher}'"
    echo "    -A <application>          Set an application name for the disk"
    echo "                               Default: '${iso_application}'"
    echo "    -E <desktop_env>          Set desktop environment"
    echo "                               Default: ${desktop_env}"
    echo "    -D <install_dir>          Set an install_dir (directory inside iso)"
    echo "                               Default: ${install_dir}"
    echo "    -w <work_dir>             Set the working directory"
    echo "                               Default: ${work_dir}"
    echo "    -o <out_dir>              Set the output directory"
    echo "                               Default: ${out_dir}"
    echo "    -v                        Enable verbose output"
    echo "    -h                        This help message"
    exit ${1}
}

# Helper function to run make_*() only one time per architecture.
run_once() {
    if [[ ! -e ${work_dir}/build.${1} ]]; then
        $1
        touch ${work_dir}/build.${1}
    fi
}

# Setup custom pacman.conf with current cache directories.
make_pacman_conf() {
    local _cache_dirs
    _cache_dirs=($(pacman -v 2>&1 | grep '^Cache Dirs:' | sed 's/Cache Dirs:\s*//g'))
    sed -r "s|^#?\\s*CacheDir.+|CacheDir = $(echo -n ${_cache_dirs[@]})|g" ${script_path}/pacman.x86_64.conf > ${work_dir}/pacman.conf
}

# Base installation, plus needed packages (airootfs)
make_basefs() {
    bbqmkiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" init
    bbqmkiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -p "haveged intel-ucode amd-ucode memtest86+ mkinitcpio-nfs-utils nbd zsh efitools" install
}

# Additional packages (airootfs)
make_packages() {
    bbqmkiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -p "$(grep -h -v ^# ${script_path}/packages.x86_64)" install
}

# Desktop Environment
make_desktop_env() {
    case "${desktop_env}" in
    "cinnamon" | "gnome" | "mate" | "plasma" | "xfce4")
        bbqmkiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -p "bbqlinux-desktop-${desktop_env}" install
        ;;
    *)
        bbqmkiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -p "bbqlinux-desktop-cinnamon" install
        ;;
    esac
}

# Needed packages for x86_64 EFI boot
make_packages_efi() {
    bbqmkiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -p "efitools" install
}

# Copy mkinitcpio archiso hooks and build initramfs (airootfs)
make_setup_mkinitcpio() {
    local _hook
    mkdir -p ${work_dir}/x86_64/airootfs/etc/initcpio/hooks
    mkdir -p ${work_dir}/x86_64/airootfs/etc/initcpio/install
    for _hook in archiso archiso_shutdown archiso_pxe_common archiso_pxe_nbd archiso_pxe_http archiso_pxe_nfs archiso_loop_mnt; do
        cp /usr/lib/initcpio/hooks/${_hook} ${work_dir}/x86_64/airootfs/etc/initcpio/hooks
        cp /usr/lib/initcpio/install/${_hook} ${work_dir}/x86_64/airootfs/etc/initcpio/install
    done
    sed -i "s|/usr/lib/initcpio/|/etc/initcpio/|g" ${work_dir}/x86_64/airootfs/etc/initcpio/install/archiso_shutdown
    cp /usr/lib/initcpio/install/archiso_kms ${work_dir}/x86_64/airootfs/etc/initcpio/install
    cp /usr/lib/initcpio/archiso_shutdown ${work_dir}/x86_64/airootfs/etc/initcpio
    cp ${script_path}/mkinitcpio.conf ${work_dir}/x86_64/airootfs/etc/mkinitcpio-archiso.conf
    gnupg_fd=
    if [[ ${gpg_key} ]]; then
      gpg --export ${gpg_key} >${work_dir}/gpgkey
      exec 17<>${work_dir}/gpgkey
    fi
    ARCHISO_GNUPG_FD=${gpg_key:+17} bbqmkiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -r 'mkinitcpio -c /etc/mkinitcpio-archiso.conf -k /boot/vmlinuz-linux -g /boot/archiso.img' run
    if [[ ${gpg_key} ]]; then
      exec 17<&-
    fi
}

# Customize installation (airootfs)
make_customize_airootfs() {
    cp -af ${script_path}/airootfs ${work_dir}/x86_64

    mv ${work_dir}/x86_64/airootfs/etc/pacman.x86_64.conf ${work_dir}/x86_64/airootfs/etc/pacman.conf

    wget -O ${work_dir}/x86_64/airootfs/etc/pacman.d/mirrorlist 'https://www.archlinux.org/mirrorlist/?country=all&protocol=http&use_mirror_status=on'

    lynx -dump -nolist 'https://wiki.archlinux.org/index.php/Installation_Guide?action=render' >> ${work_dir}/x86_64/airootfs/root/install.txt

    bbqmkiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -r '/root/customize_airootfs.sh' run
    rm ${work_dir}/x86_64/airootfs/root/customize_airootfs.sh
    
    bbqmkiso ${verbose} -w "${work_dir}/x86_64" -C "${work_dir}/pacman.conf" -D "${install_dir}" -r "python /root/customize_airootfs.py --desktop_env ${desktop_env}" run
    rm ${work_dir}/x86_64/airootfs/root/customize_airootfs.py
}

# Prepare kernel/initramfs ${install_dir}/boot/
make_boot() {
    mkdir -p ${work_dir}/iso/${install_dir}/boot/x86_64
    cp ${work_dir}/x86_64/airootfs/boot/archiso.img ${work_dir}/iso/${install_dir}/boot/x86_64/archiso.img
    cp ${work_dir}/x86_64/airootfs/boot/vmlinuz-linux ${work_dir}/iso/${install_dir}/boot/x86_64/vmlinuz

    cp ${work_dir}/x86_64/airootfs/boot/intel-ucode.img ${work_dir}/iso/${install_dir}/boot/intel_ucode.img
    cp ${work_dir}/x86_64/airootfs/usr/share/licenses/intel-ucode/LICENSE ${work_dir}/iso/${install_dir}/boot/intel_ucode.LICENSE

    cp ${work_dir}/x86_64/airootfs/boot/amd-ucode.img ${work_dir}/iso/${install_dir}/boot/amd_ucode.img
    cp ${work_dir}/x86_64/airootfs/usr/share/licenses/amd-ucode/LICENSE ${work_dir}/iso/${install_dir}/boot/amd_ucode.LICENSE
}

# Add other aditional/extra files to ${install_dir}/boot/
make_boot_extra() {
    cp ${work_dir}/x86_64/airootfs/boot/memtest86+/memtest.bin ${work_dir}/iso/${install_dir}/boot/memtest
    cp ${work_dir}/x86_64/airootfs/usr/share/licenses/common/GPL2/license.txt ${work_dir}/iso/${install_dir}/boot/memtest.COPYING
}

# Fetch packages for offline installation
make_pkgcache() {
    for pkg in $(grep -h -v ^# ${script_path}/pkgcache.x86_64)
    do
        rm -f /var/cache/pacman/pkg/${pkg}-*
        # Get the download link from pacman
        pkg_path=$(pacman -Sp ${pkg})
        # Download the package
        wget -P ${work_dir}/x86_64/airootfs/var/cache/pacman/pkg ${pkg_path}
        # Download the signature file
        wget -P ${work_dir}/x86_64/airootfs/var/cache/pacman/pkg ${pkg_path}.sig
    done
}

# Prepare /${install_dir}/boot/syslinux
make_syslinux() {
    _uname_r=$(file -b ${work_dir}/x86_64/airootfs/boot/vmlinuz-linux| awk 'f{print;f=0} /version/{f=1}' RS=' ')
    mkdir -p ${work_dir}/iso/${install_dir}/boot/syslinux
    for _cfg in ${script_path}/syslinux/*.cfg; do
        sed "s|%ARCHISO_LABEL%|${iso_label}|g;
             s|%INSTALL_DIR%|${install_dir}|g" ${_cfg} > ${work_dir}/iso/${install_dir}/boot/syslinux/${_cfg##*/}
    done
    cp ${script_path}/syslinux/splash.png ${work_dir}/iso/${install_dir}/boot/syslinux
    cp ${work_dir}/x86_64/airootfs/usr/lib/syslinux/bios/*.c32 ${work_dir}/iso/${install_dir}/boot/syslinux
    cp ${work_dir}/x86_64/airootfs/usr/lib/syslinux/bios/lpxelinux.0 ${work_dir}/iso/${install_dir}/boot/syslinux
    cp ${work_dir}/x86_64/airootfs/usr/lib/syslinux/bios/memdisk ${work_dir}/iso/${install_dir}/boot/syslinux
    mkdir -p ${work_dir}/iso/${install_dir}/boot/syslinux/hdt
    gzip -c -9 ${work_dir}/x86_64/airootfs/usr/share/hwdata/pci.ids > ${work_dir}/iso/${install_dir}/boot/syslinux/hdt/pciids.gz
    gzip -c -9 ${work_dir}/x86_64/airootfs/usr/lib/modules/${_uname_r}/modules.alias > ${work_dir}/iso/${install_dir}/boot/syslinux/hdt/modalias.gz
}

# Prepare /isolinux
make_isolinux() {
    mkdir -p ${work_dir}/iso/isolinux
    sed "s|%INSTALL_DIR%|${install_dir}|g" ${script_path}/isolinux/isolinux.cfg > ${work_dir}/iso/isolinux/isolinux.cfg
    cp ${work_dir}/x86_64/airootfs/usr/lib/syslinux/bios/isolinux.bin ${work_dir}/iso/isolinux/
    cp ${work_dir}/x86_64/airootfs/usr/lib/syslinux/bios/isohdpfx.bin ${work_dir}/iso/isolinux/
    cp ${work_dir}/x86_64/airootfs/usr/lib/syslinux/bios/ldlinux.c32 ${work_dir}/iso/isolinux/
}

# Prepare /EFI
make_efi() {
    mkdir -p ${work_dir}/iso/EFI/boot
    cp ${work_dir}/x86_64/airootfs/usr/share/efitools/efi/PreLoader.efi ${work_dir}/iso/EFI/boot/bootx64.efi
    cp ${work_dir}/x86_64/airootfs/usr/share/efitools/efi/HashTool.efi ${work_dir}/iso/EFI/boot/

    cp ${work_dir}/x86_64/airootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi ${work_dir}/iso/EFI/boot/loader.efi

    mkdir -p ${work_dir}/iso/loader/entries
    cp ${script_path}/efiboot/loader/loader.conf ${work_dir}/iso/loader/
    cp ${script_path}/efiboot/loader/entries/uefi-shell-v2-x86_64.conf ${work_dir}/iso/loader/entries/
    cp ${script_path}/efiboot/loader/entries/uefi-shell-v1-x86_64.conf ${work_dir}/iso/loader/entries/

    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%INSTALL_DIR%|${install_dir}|g" \
        ${script_path}/efiboot/loader/entries/archiso-x86_64-usb.conf > ${work_dir}/iso/loader/entries/archiso-x86_64.conf

    # EFI Shell 2.0 for UEFI 2.3+
    curl -o ${work_dir}/iso/EFI/shellx64_v2.efi https://raw.githubusercontent.com/tianocore/edk2/master/ShellBinPkg/UefiShell/X64/Shell.efi
    # EFI Shell 1.0 for non UEFI 2.3+
    curl -o ${work_dir}/iso/EFI/shellx64_v1.efi https://raw.githubusercontent.com/tianocore/edk2/UDK2018/EdkShellBinPkg/FullShell/X64/Shell_Full.efi
}

# Prepare efiboot.img::/EFI for "El Torito" EFI boot mode
make_efiboot() {

    # Path definitions
    P_VMLINUZ="${work_dir}/iso/${install_dir}/boot/x86_64/vmlinuz"
    P_ARCHISO="${work_dir}/iso/${install_dir}/boot/x86_64/archiso.img"
    P_INTEL_UCODE="${work_dir}/iso/${install_dir}/boot/intel_ucode.img"
    P_AMD_UCODE="${work_dir}/iso/${install_dir}/boot/amd_ucode.img"
    P_PRELOADER="${work_dir}/x86_64/airootfs/usr/share/efitools/efi/PreLoader.efi"
    P_HASHTOOL="${work_dir}/x86_64/airootfs/usr/share/efitools/efi/HashTool.efi"
    P_SYSTEMD_BOOT="${work_dir}/x86_64/airootfs/usr/lib/systemd/boot/efi/systemd-bootx64.efi"
    P_LOADER_CONF="${script_path}/efiboot/loader/loader.conf"
    P_UEFI_SHELL_V1="${work_dir}/iso/EFI/shellx64_v1.efi"
    P_UEFI_SHELL_V1_CONF="${script_path}/efiboot/loader/entries/uefi-shell-v2-x86_64.conf"
    P_UEFI_SHELL_V2="${work_dir}/iso/EFI/shellx64_v2.efi"
    P_UEFI_SHELL_V2_CONF="${script_path}/efiboot/loader/entries/uefi-shell-v1-x86_64.conf"

    # Calculate efiboot size
    efiboot_size=$(( $(wc -c < "$P_VMLINUZ") \
                     + $(wc -c < "$P_ARCHISO") \
                     + $(wc -c < "$P_INTEL_UCODE") \
                     + $(wc -c < "$P_AMD_UCODE") \
                     + $(wc -c < "${P_PRELOADER}") \
                     + $(wc -c < "${P_HASHTOOL}") \
                     + $(wc -c < "${P_SYSTEMD_BOOT}") \
                     + $(wc -c < "${P_LOADER_CONF}") \
                     + $(wc -c < "${P_UEFI_SHELL_V1}") \
                     + $(wc -c < "${P_UEFI_SHELL_V1_CONF}") \
                     + $(wc -c < "${P_UEFI_SHELL_V2}") \
                     + $(wc -c < "${P_UEFI_SHELL_V2_CONF}") ))

    efiboot_size=$(( ${efiboot_size} / 1024 / 1024 )) # Convert to M
    efiboot_size=$(( ${efiboot_size} +  (${efiboot_size} * 0,2) ))"M"
    echo "EFIBOOT SIZE: ${efiboot_size}"

    mkdir -p ${work_dir}/iso/EFI/archiso
    truncate -s ${efiboot_size} ${work_dir}/iso/EFI/archiso/efiboot.img
    mkfs.fat -n ARCHISO_EFI ${work_dir}/iso/EFI/archiso/efiboot.img

    mkdir -p ${work_dir}/efiboot
    mount ${work_dir}/iso/EFI/archiso/efiboot.img ${work_dir}/efiboot

    mkdir -p ${work_dir}/efiboot/EFI/archiso
    cp ${P_VMLINUZ} ${work_dir}/efiboot/EFI/archiso/vmlinuz.efi
    cp ${P_ARCHISO} ${work_dir}/efiboot/EFI/archiso/archiso.img
    
    cp ${P_INTEL_UCODE} ${work_dir}/efiboot/EFI/archiso/intel_ucode.img
    cp ${P_AMD_UCODE} ${work_dir}/efiboot/EFI/archiso/amd_ucode.img

    mkdir -p ${work_dir}/efiboot/EFI/boot
    cp ${P_PRELOADER} ${work_dir}/efiboot/EFI/boot/bootx64.efi
    cp ${P_HASHTOOL} ${work_dir}/efiboot/EFI/boot/

    cp ${P_SYSTEMD_BOOT} ${work_dir}/efiboot/EFI/boot/loader.efi

    mkdir -p ${work_dir}/efiboot/loader/entries
    cp ${P_LOADER_CONF} ${work_dir}/efiboot/loader/
    cp ${P_UEFI_SHELL_V2_CONF} ${work_dir}/efiboot/loader/entries/
    cp ${P_UEFI_SHELL_V2_CONF} ${work_dir}/efiboot/loader/entries/

    sed "s|%ARCHISO_LABEL%|${iso_label}|g;
         s|%INSTALL_DIR%|${install_dir}|g" \
        ${script_path}/efiboot/loader/entries/archiso-x86_64-cd.conf > ${work_dir}/efiboot/loader/entries/archiso-x86_64.conf

    cp ${P_UEFI_SHELL_V2} ${work_dir}/efiboot/EFI/
    cp ${P_UEFI_SHELL_V1} ${work_dir}/efiboot/EFI/

    umount -d ${work_dir}/efiboot
}

# Build airootfs filesystem image
make_prepare() {
    cp -a -l -f ${work_dir}/x86_64/airootfs ${work_dir}
    bbqmkiso ${verbose} -w "${work_dir}" -D "${install_dir}" pkglist
    bbqmkiso ${verbose} -w "${work_dir}" -D "${install_dir}" ${gpg_key:+-g ${gpg_key}} prepare
    rm -rf ${work_dir}/airootfs
}

# Build ISO
make_iso() {
    bbqmkiso ${verbose} -w "${work_dir}" -D "${install_dir}" -L "${iso_label}" -P "${iso_publisher}" -A "${iso_application}" -o "${out_dir}" iso "${iso_name}-${iso_version}-x86_64-${desktop_env}.iso"
}

if [[ ${EUID} -ne 0 ]]; then
    echo "This script must be run as root."
    _usage 1
fi

if [[ x86_64 != x86_64 ]]; then
    echo "This script needs to be run on x86_64"
    _usage 1
fi

while getopts 'N:V:L:P:A:E:D:w:o:g:vh' arg; do
    case "${arg}" in
        N) iso_name="${OPTARG}" ;;
        V) iso_version="${OPTARG}" ;;
        L) iso_label="${OPTARG}" ;;
        P) iso_publisher="${OPTARG}" ;;
        A) iso_application="${OPTARG}" ;;
        E) desktop_env="${OPTARG}";;
        D) install_dir="${OPTARG}" ;;
        w) work_dir="${OPTARG}" ;;
        o) out_dir="${OPTARG}" ;;
        g) gpg_key="${OPTARG}" ;;
        v) verbose="-v" ;;
        h) _usage 0 ;;
        *)
           echo "Invalid argument '${arg}'"
           _usage 1
           ;;
    esac
done

echo "------------------------------------"
echo " BBQLINUX Configuration             "
echo "------------------------------------"
echo " Arch: x86_64                  "
echo " Desktop Environment: ${desktop_env}"
echo "------------------------------------"

sleep 3

mkdir -p ${work_dir}

run_once make_pacman_conf
run_once make_basefs
run_once make_packages

sleep 5

if mount | grep ${work_dir}/x86_64/airootfs/dev > /dev/null; then
    umount ${work_dir}/x86_64/airootfs/dev
fi

if mount | grep ${work_dir}/x86_64/airootfs > /dev/null; then
    umount ${work_dir}/x86_64/airootfs
fi

run_once make_desktop_env
run_once make_packages_efi
run_once make_setup_mkinitcpio
run_once make_customize_airootfs
run_once make_boot
run_once make_boot_extra
run_once make_pkgcache
run_once make_syslinux
run_once make_isolinux
run_once make_efi
run_once make_efiboot
run_once make_prepare
run_once make_iso

# Remount pts with correct mode
mount -o remount,gid=5,mode=620 /dev/pts
