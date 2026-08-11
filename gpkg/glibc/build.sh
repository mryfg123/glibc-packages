TERMUX_PKG_HOMEPAGE=https://www.gnu.org/software/libc/
TERMUX_PKG_DESCRIPTION="GNU C Library"
TERMUX_PKG_LICENSE="GPL-3.0, LGPL-3.0"
TERMUX_PKG_MAINTAINER="@termux-pacman"
TERMUX_PKG_VERSION=2.43
TERMUX_PKG_REVISION=1
TERMUX_PKG_SRCURL=https://ftp.gnu.org/gnu/libc/glibc-$TERMUX_PKG_VERSION.tar.xz
TERMUX_PKG_SHA256=d9c86c6b5dbddb43a3e08270c5844fc5177d19442cf5b8df4be7c07cd5fa3831
TERMUX_PKG_DEPENDS="linux-api-headers-glibc"
TERMUX_PKG_RECOMMENDS="glibc-runner"
TERMUX_PKG_NO_STATICSPLIT=true
TERMUX_PKG_CONFFILES="glibc/etc/gai.conf, glibc/etc/locale.gen"

termux_step_pre_configure() {
	if [ "$TERMUX_PACKAGE_LIBRARY" != "glibc" ]; then
		termux_error_exit "Compilation is only possible based on glibc"
	fi

	# disabling clone3 function
	rm ${TERMUX_PKG_SRCDIR}/sysdeps/unix/sysv/linux/*/clone3.S
	# disabling editing of `ldd` script for x86_64 arch
	rm ${TERMUX_PKG_SRCDIR}/sysdeps/unix/sysv/linux/x86_64/configure*

	# installing special scripts for correct operation of system calls
	cp ${TERMUX_PKG_BUILDER_DIR}/{shm{at,ctl,dt,get}.c,mprotect.c,syscall.c,fakesyscall*.h,fake_epoll_pwait2.c,setfs{u,g}id.c} \
		${TERMUX_PKG_SRCDIR}/sysdeps/unix/sysv/linux/ #*

	# installing and configuring scripts for parsing users/groups according to the android standard
	cp ${TERMUX_PKG_BUILDER_DIR}/{android_passwd_group.*,android_system_user_ids.h} \
		${TERMUX_PKG_SRCDIR}/nss/
	bash ${TERMUX_PKG_BUILDER_DIR}/gen-android-ids.sh ${TERMUX_BASE_DIR} \
		${TERMUX_PKG_SRCDIR}/nss/android_ids.h \
		${TERMUX_PKG_BUILDER_DIR}/android_system_user_ids.h

	# installing a syslog script that can work with the android log system
	cp ${TERMUX_PKG_BUILDER_DIR}/syslog.c ${TERMUX_PKG_SRCDIR}/misc/

	# installing shmem-android scripts for system V shared memory emulation
	cp ${TERMUX_PKG_BUILDER_DIR}/shmem-android.* ${TERMUX_PKG_SRCDIR}/sysvipc/

	# `fakesyscall.json` - json file that stores a list of unsupported syscalls for Termux in keys,
	# the name of which indicates the fakesyscall function and how it will be launched
	# = Syntax ==
	# {
	#   "fakesyscall_1()": [
	#     "syscall_1",
	#     "syscall_2"
	#   ],
	#   "fakesyscall_2(a0, a1, a2, a3, a4, a5)": [
	#     "syscall_3",
	#     "syscall_4"
	#   ]
	# }
	# == Rules ===
	# - The name syscall and the name of the function fakesyscall must not be repeated
	# - Specify the syscall name without the leading `__NR_` prefix
	# ============
	for i in aarch64 arm i386 x86_64/64; do
		mv ${TERMUX_PKG_SRCDIR}/sysdeps/unix/sysv/linux/${i///*/}/syscall.S \
			${TERMUX_PKG_SRCDIR}/sysdeps/unix/sysv/linux/${i///*/}/syscallS.S
		local header_disabled_syscall="${TERMUX_PKG_SRCDIR}/sysdeps/unix/sysv/linux/${i}/disabled-syscall.h"
		{
			for j in $(jq -r '.[] | .[]' ${TERMUX_PKG_BUILDER_DIR}/fakesyscall.json); do
				grep "#define __NR_${j} " ${TERMUX_PKG_SRCDIR}/sysdeps/unix/sysv/linux/${i}/arch-syscall.h || true
				sed -i "/#define __NR_${j} /d" ${TERMUX_PKG_SRCDIR}/sysdeps/unix/sysv/linux/${i}/arch-syscall.h
			done
		} >> $header_disabled_syscall
		{
			echo -e "\n#define DISABLED_SYSCALL_WITH_FAKESYSCALL \\"
			local IFS=$'\n'
			for j in $(jq -r '. | keys | .[]' ${TERMUX_PKG_BUILDER_DIR}/fakesyscall.json); do
				local need_return=false
				for z in $(jq -r '."'${j}'" | .[]' ${TERMUX_PKG_BUILDER_DIR}/fakesyscall.json); do
					if grep -q "^#define __NR_${z} " $header_disabled_syscall; then
						echo -e "\tcase __NR_${z}: \\"
						need_return=true
					elif [[ ${z} =~ ^[0-9]+$ ]]; then
						echo -e "\tcase ${z}: \\"
						need_return=true
					fi
				done
				[ "${need_return}" = "true" ] && echo -e "\t\treturn ${j}; \\"
			done
			unset IFS
		} >> $header_disabled_syscall
		sed -i '$ s| \\||' $header_disabled_syscall
	done

	# replacing some hard paths that may not exist in some device
	for i in /dev/stderr:/proc/self/fd/2 \
		/dev/stdin:/proc/self/fd/0 \
		/dev/stdout:/proc/self/fd/1; do
		for j in $(grep -s -r -l ${i%%:*} ${TERMUX_PKG_SRCDIR}); do
			sed -i "s|${i%%:*}|${i//*:}|g" ${j}
		done
	done

	# adding revision to glibc version
	sed -i "s/${TERMUX_PKG_VERSION}/${TERMUX_PKG_FULLVERSION_FOR_PACMAN}/" ${TERMUX_PKG_SRCDIR}/version.h

	# specifying the current release (use only when developing glibc)
	#sed -i "s/stable/dev.$(git -C ${TERMUX_PKG_BUILDER_DIR} rev-parse --short HEAD).$(date +%Y%m%d%H%M%S)/" ${TERMUX_PKG_SRCDIR}/version.h
}

termux_step_configure() {
	echo "slibdir=/data/data/com.linux.term/files/linux/lib" > configparms
	echo "rtlddir=/data/data/com.linux.term/files/linux/lib" >> configparms
	echo "sbindir=/data/data/com.linux.term/files/linux/bin" >> configparms
	echo "rootsbindir=/data/data/com.linux.term/files/linux/bin" >> configparms

	local _configure_flags=()
	case $TERMUX_ARCH in
		"aarch64") _configure_flags+=(--enable-memory-tagging --enable-fortify-source);;
		"arm"|"i686") _configure_flags+=(--enable-fortify-source);;
		"x86_64") _configure_flags+=(--enable-cet);;
	esac

	# 新增：禁用 ldconfig 和 localedef（避免 Android 环境下的断言错误）
	_configure_flags+=(--disable-ldconfig --disable-localedef)

	local _pkgversion="GNU libc for Android"
	if [ -n "${TERMUX_APP_PACKAGE-}" ]; then
		_pkgversion+="/${TERMUX_APP_PACKAGE}"
	fi

	CFLAGS="${CFLAGS/-Wp,-D_FORTIFY_SOURCE=2 / }"
	CFLAGS="${CFLAGS/-Werror / }"
	export TERMUX_ARCH TERMUX_REAL_ARCH
	if [ "$TERMUX_ARCH" != "$TERMUX_REAL_ARCH" ]; then
		CFLAGS+=" -DMULTILIB_GLIBC"
	fi
	${TERMUX_PKG_SRCDIR}/configure \
		--prefix=/data/data/com.linux.term/files/linux \
		--libdir=/data/data/com.linux.term/files/linux/lib \
		--libexecdir=/data/data/com.linux.term/files/linux/libexec \
		--includedir=/data/data/com.linux.term/files/linux/include \
		--host=$TERMUX_HOST_PLATFORM \
		--build=$TERMUX_HOST_PLATFORM \
		--target=$TERMUX_HOST_PLATFORM \
		--with-bugurl=https://github.com/termux-pacman/glibc-packages/issues \
		--with-pkgversion="${_pkgversion}" \
		--enable-bind-now \
		--enable-fortify-source \
		--disable-multi-arch \
		--enable-stack-protector=strong \
		--enable-systemtap \
		--disable-nscd \
		--disable-profile \
		--disable-werror \
		--disable-default-pie \
		"${_configure_flags[@]}"
}

termux_step_make() {
	make -O
	if [ "$TERMUX_ARCH" = "$TERMUX_REAL_ARCH" ]; then
		make info
	fi
}

# 辅助函数：编译 libsyscall_without_fsc.so（修改为安装到 DESTDIR）
termux_glibc_make_syscall_without_fsc() {
	local libname="libsyscall_without_fsc.so"
	echo "Compiling '${libname}'..."
	${CC} ${TERMUX_PKG_BUILDER_DIR}/syscall.c -o ${DESTDIR}/data/data/com.linux.term/files/linux/lib/${libname} \
		-shared -DWITHOUT_FAKESYSCALL
	echo "DONE"
}

termux_step_make_install() {
	# 关键：设置 DESTDIR 指向打包目录
	export DESTDIR="${TERMUX_PKG_MASSAGEDIR}"

	# 确保打包目录的顶级目录存在
	mkdir -p ${DESTDIR}${TERMUX_PREFIX}

	# 删除目标目录中的旧 gnu 头文件（在 DESTDIR 内操作）
	rm -fr ${DESTDIR}${TERMUX__PREFIX__INCLUDE_DIR}/gnu

	# 设备上构建的特殊处理（也使用 DESTDIR）
	if [ "$TERMUX_ON_DEVICE_BUILD" = "true" ]; then
		# 如果设备上构建，先安装库文件到 DESTDIR
		local glibc_dir="${TERMUX_PKG_TMPDIR}/glibc/"
		mkdir -p ${glibc_dir}
		make DESTDIR=${glibc_dir} elf/ldso_install install-lib
		cp -r ${TERMUX_PKG_BUILDDIR}/libc.so ${glibc_dir}//data/data/com.linux.term/files/linux/lib/libc.so.6
		# 拷贝到 DESTDIR
		cp -r ${glibc_dir}//data/data/com.linux.term/files/linux/lib/* ${DESTDIR}/data/data/com.linux.term/files/linux/lib/
	fi

	# 主要安装：make install 会安装到 DESTDIR
	make install

	# 删除安装后生成的不必要文件（在 DESTDIR 内）
	rm -f ${DESTDIR}${TERMUX_PREFIX}/etc/ld.so.cache
	rm -f ${DESTDIR}${TERMUX_PREFIX}/bin/{tzselect,zdump,zic}

	# 安装 nscd 配置文件
	install -dm755 ${DESTDIR}/data/data/com.linux.term/files/linux/lib/tmpfiles.d
	install -m644 ${TERMUX_PKG_SRCDIR}/nscd/nscd.conf ${DESTDIR}${TERMUX_PREFIX}/etc/nscd.conf
	install -m644 ${TERMUX_PKG_SRCDIR}/nscd/nscd.tmpfiles ${DESTDIR}/data/data/com.linux.term/files/linux/lib/tmpfiles.d/nscd.conf
	install -m644 ${TERMUX_PKG_SRCDIR}/posix/gai.conf ${DESTDIR}${TERMUX_PREFIX}/etc/gai.conf

	# 安装 locale-gen 脚本并替换其中的占位符
	install -m755 ${TERMUX_PKG_BUILDER_DIR}/locale-gen ${DESTDIR}${TERMUX_PREFIX}/bin
	sed -i "s|@TERMUX_PREFIX@|${TERMUX_PREFIX}|g; s|@TERMUX_PREFIX_CLASSICAL@|${TERMUX_PREFIX_CLASSICAL}|g" \
		${DESTDIR}${TERMUX_PREFIX}/bin/locale-gen

	# 安装 locale.gen
	install -m644 ${TERMUX_PKG_BUILDER_DIR}/locale.gen.txt ${DESTDIR}${TERMUX_PREFIX}/etc/locale.gen
	sed -e '1,3d' -e 's|/| |g' -e 's|\\| |g' -e 's|^|#|g' \
		${TERMUX_PKG_SRCDIR}/localedata/SUPPORTED >> ${DESTDIR}${TERMUX_PREFIX}/etc/locale.gen

	# 安装 SUPPORTED 文件
	sed -e '1,3d' -e 's|/| |g' -e 's| \\||g' \
		${TERMUX_PKG_SRCDIR}/localedata/SUPPORTED > ${DESTDIR}${TERMUX_PREFIX}/share/i18n/SUPPORTED

	# 安装 locale 数据（make 会尊重 DESTDIR）
	install -dm755 ${DESTDIR}/data/data/com.linux.term/files/linux/lib/locale
	make -C ${TERMUX_PKG_SRCDIR}/localedata objdir=${TERMUX_PKG_BUILDDIR} \
		SUPPORTED-LOCALES="C.UTF-8/UTF-8 en_US.UTF-8/UTF-8" install-locale-files

	# 删除 locale.gen 中的 C.UTF-8 行（在 DESTDIR 内操作）
	sed -i '/#C\.UTF-8 /d' ${DESTDIR}${TERMUX_PREFIX}/etc/locale.gen

	# 安装 systemtap 头文件
	install -Dm644 ${TERMUX_PKG_BUILDER_DIR}/sdt.h ${DESTDIR}${TERMUX__PREFIX__INCLUDE_DIR}/sys/sdt.h
	install -Dm644 ${TERMUX_PKG_BUILDER_DIR}/sdt-config.h ${DESTDIR}${TERMUX__PREFIX__INCLUDE_DIR}/sys/sdt-config.h

	# 创建 ld.so 软链接（在 DESTDIR 内）
	ln -sfr ${DESTDIR}${PATH_DYNAMIC_LINKER} ${DESTDIR}${TERMUX_PREFIX}/bin/ld.so
	ln -sfr ${DESTDIR}${PATH_DYNAMIC_LINKER} ${DESTDIR}/data/data/com.linux.term/files/linux/lib/ld.so

	# 编译并安装 libsyscall_without_fsc.so（已修改为安装到 DESTDIR）
	termux_glibc_make_syscall_without_fsc

	# 调试输出：列出打包目录内容，便于确认
	echo "=== 打包目录内容 ($DESTDIR) ==="
	ls -laR ${DESTDIR}${TERMUX_PREFIX} | head -100 || true
	echo "================================"
}
