#!/bin/bash
# date : 2023.1.3
# Use：Centos 7
# Install prometheus+grafana+alertmanager

#骚气颜色
show_str_Black() {
	echo -e "\033[30m $1 \033[0m"
}
show_str_Red() {
	echo -e "\033[31m $1 \033[0m"
}
show_str_Green() {
	echo -e "\033[32m $1 \033[0m"
}
show_str_Yellow() {
	echo -e "\033[33m $1 \033[0m"
}
show_str_Blue() {
	echo -e "\033[34m $1 \033[0m"
}
show_str_Purple() {
	echo -e "\033[35m $1 \033[0m"
}
show_str_SkyBlue() {
	echo -e "\033[36m $1 \033[0m"
}
show_str_White() {
	echo -e "\033[37m $1 \033[0m"
}

function network() {
	#超时时间
	local timeout=1

	#目标网站
	local target=www.baidu.com

	#获取响应状态码
	local ret_code=$(curl -I -s --connect-timeout ${timeout} ${target} -w %{http_code} | tail -n1)

	if [ "x$ret_code" = "x200" ]; then
		#网络畅通
		return 1
	else
		#网络不畅通
		return 0
	fi

	return 0
}

workdir=$(
	cd $(dirname $0)
	pwd
)
prometheus_package=prometheus-2.41.0.linux-amd64.tar.gz
grafana_package=grafana-enterprise-9.3.2-1.x86_64.rpm
alertmanager_packge=alertmanager-0.25.0-rc.2.linux-amd64.tar.gz

wget_software() {
	yum -y install wget >&/dev/null
	if [ ! -f ${prometheus_package} ]; then
		wget https://github.com/prometheus/prometheus/releases/download/v2.41.0/${prometheus_package} >&/dev/null
	fi
	if [ ! -f ${grafana_package} ]; then
		wget https://dl.grafana.com/enterprise/release/${grafana_package} >&/dev/null
	fi
	if [ ! -f ${alertmanager_packge} ]; then
		cd /root/
		wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0-rc.2/${alertmanager_packge} >&/dev/null
	fi
}

###
### Install prometheus+grafana+alertmanager
###
### Usage:
###   bash monitor.sh -h
### Options:
###  h  -h --help    Show this message.
###  install   install prometheus+grafana+alertmanager
###  remove    remove prometheus+grafana+alertmanager
### Versiom:
### 	prometheus:2.41.0
###	grafana:9.3.2-1
###	alertmanager:0.25.0

help() {
	sed -rn 's/^### ?//;T;p' "$0"
}

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "h" ]]; then
	help
	exit 1
fi

Useradd() {
	user=prometheus
	egrep "^$user" /etc/passwd >&/dev/null
	if [ $? -ne 0 ]; then
		useradd -r -m -d /var/lib/$user $user
	fi
}

function write_header() {
	show_str_Red "**********************************************************************************"
	show_str_Yellow "                                  ${proc}"
	show_str_Red "**********************************************************************************"
}

function run_ok() {
	echo -e "\033[42;31m SUCCESS \033[0m"
}

create_dir() {
	mkdir -p /data/prometheus
	mkdir -p /data/alertmanager
	chown -R prometheus.prometheus /data/prometheus
	chown -R prometheus.prometheus /data/alertmanager
}

install_prometheus() {
	tar -xf $workdir/${prometheus_package} -C /usr/local/
	ln -sv /usr/local/prometheus-2.41.0.linux-amd64 /usr/local/prometheus >&/dev/null
	cat >>/usr/lib/systemd/system/prometheus.service <<EOF
[Unit]
Description=The Prometheus 2 monitoring system and time series database.
Documentation=https://prometheus.io
After=network.target
[Service]
EnvironmentFile=-/etc/sysconfig/prometheus
User=prometheus
ExecStart=/usr/local/prometheus/prometheus \
--storage.tsdb.path=/data/prometheus \
--config.file=/usr/local/prometheus/prometheus.yml \
--web.listen-address=0.0.0.0:9090 \
--web.external-url= \$PROM_EXTRA_ARGS
Restart=on-failure
StartLimitInterval=1
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
}

install_grafana() {
	yum -y install ${grafana_package} >&/dev/null
}

install_alertmanager() {
	tar -xf $workdir/${alertmanager_packge} -C /usr/local/
	ln -sv /usr/local/alertmanager-0.25.0-rc.2.linux-amd64/ /usr/local/alertmanager >&/dev/null
	chown -R prometheus.prometheus /usr/local/alertmanager
	cat >>/usr/lib/systemd/system/alertmanager.service <<EOF
[Unit]
Description=Alertmanager for prometheus

[Service]
Restart=always
User=prometheus
ExecStart=/usr/local/alertmanager/alertmanager --config.file=/usr/local/alertmanager/alertmanager.yml --storage.path=/data/alertmanager
ExecReload=/bin/kill -HUP \$MAINPID
TimeoutStopSec=20s
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
}

start_software() {
	systemctl enable prometheus.service >&/dev/null
	systemctl start prometheus.service >&/dev/null
	proc=prometheus
	write_header
	run_ok
	systemctl enable grafana-server.service >&/dev/null
	systemctl restart grafana-server.service >&/dev/null
	proc=grafana
	write_header
	run_ok
	systemctl enable alertmanager.service >&/dev/null
	systemctl start alertmanager.service >&/dev/null
	proc=alertmanager
	write_header
	run_ok
}

# docker_install(){

# }

remove() {
	uninstall_date=$(date +"%Y-%m-%d-%H%M%S")
	trash=/tmp/trash/$uninstall_date
	mkdir -p $trash
	systemctl disable prometheus.service >&/dev/null
	systemctl stop prometheus.service >&/dev/null
	systemctl disable grafana-server.service >&/dev/null
	systemctl stop grafana-server.service >&/dev/null
	systemctl disable alertmanager.service >&/dev/null
	systemctl stop alertmanager.service >&/dev/null
	mv /usr/lib/systemd/system/prometheus.service $trash >&/dev/null
	mv /usr/lib/systemd/system/alertmanager.service $trash >&/dev/null
	if [ -d /usr/local/prometheus ]; then
		rm -rf /usr/local/prometheus
		mv /usr/local/prometheus* $trash
		mv /data/prometheus $trash
	fi
	if [ -d /usr/local/alertmanager ]; then
		rm -rf /usr/local/alertmanager
		mv /usr/local/alertmanager* $trash
		mv /data/alertmanager $trash
	fi
	yum -y remove grafana-enterprise-9.3.2-1.x86_64 >&/dev/null
	mv ${grafana_package} ${prometheus_package} ${alertmanager_packge} $trash >&/dev/null
}

case $1 in
install)
	if [ $(ps -ef | grep prometheus | grep -v grep | wc -l) -eq 0 ] && [ $(ps -ef | grep alertmanager | grep -v grep | wc -l) -eq 0 ] && [ $(ps -ef | grep grafana-server | grep -v grep | wc -l) -eq 0 ]; then
		trap 'onCtrlC' INT
		function onCtrlC() {
			#捕获CTRL+C，当脚本被ctrl+c的形式终止时同时终止程序的后台进程
			kill -9 ${do_sth_pid} ${progress_pid}
			echo
			echo 'Ctrl+C is captured'
			exit 1
		}

		do_sth() {
			#运行的主程序
			network
			if [[ $? == 1 ]]; then
				#statements
				wget_software
				Useradd
				create_dir
				install_prometheus
				install_grafana
				install_alertmanager
			else

				Useradd
				create_dir
				install_prometheus
				install_grafana
				install_alertmanager
			fi

		}

		progress() {
			#进度条程序
			local main_pid=$1
			local length=20
			local ratio=1
			while [ "$(ps -p ${main_pid} | wc -l)" -ne "1" ]; do
				mark='>'
				progress_bar=
				for i in $(seq 1 "${length}"); do
					if [ "$i" -gt "${ratio}" ]; then
						mark='-'
					fi
					progress_bar="${progress_bar}${mark}"
				done
				printf "Progress: ${progress_bar}\r"
				ratio=$((ratio + 1))
				#ratio=`expr ${ratio} + 1`
				if [ "${ratio}" -gt "${length}" ]; then
					ratio=1
				fi
				sleep 0.1
			done
		}

		do_sth &
		do_sth_pid=$(jobs -p | tail -1)

		progress "${do_sth_pid}" &
		progress_pid=$(jobs -p | tail -1)

		wait "${do_sth_pid}"
		printf "Progress: done                \n"

		start_software
	else
		show_str_Red "--------------------------------------------"
		show_str_Red "|                  警告！！！              |"
		show_str_Red "|    mirror process already exists！      |"
		show_str_Red "--------------------------------------------"
		exit 0
	fi
	;;
remove)
	remove
	;;
*)
	show_str_Red "----------------------------------"
	show_str_Red "|            警告！！！            |"
	show_str_Red "|    请 输 入 正 确 的 选 项       |"
	show_str_Red "----------------------------------"
	for i in $(seq -w 3 -1 1); do
		echo -ne "\b\b$i"
		sleep 1
	done
	;;
esac
