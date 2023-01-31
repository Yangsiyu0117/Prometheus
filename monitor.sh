#!/bin/bash
# date : 2023.1.3
# Use：Centos 7 or openEuler
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
node_exporter=node_exporter-1.5.0.linux-amd64.tar.gz
webhook_dingtalk=prometheus-webhook-dingtalk-2.1.0.linux-amd64.tar.gz

wget_software() {
	yum -y install wget >&/dev/null
	if [ ! -f $workdir/${prometheus_package} ]; then
		wget https://github.com/prometheus/prometheus/releases/download/v2.41.0/${prometheus_package} >&/dev/null
	fi
	if [ ! -f $workdir/${grafana_package} ]; then
		wget https://dl.grafana.com/enterprise/release/${grafana_package} >&/dev/null
	fi
	if [ ! -f $workdir/${alertmanager_packge} ]; then
		wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0-rc.2/${alertmanager_packge} >&/dev/null
	fi
	if [ ! -f $workdir/${node_exporter} ]; then
		wget https://github.com/prometheus/node_exporter/releases/download/v1.5.0/${node_exporter} >&/dev/null
	fi
	if [ ! -f $workdir/${webhook_dingtalk} ]; then
		wget https://github.com/timonwong/prometheus-webhook-dingtalk/releases/download/v2.1.0/${webhook_dingtalk} >&/dev/null
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
	systemctl enable node_exporter.service >&/dev/null
	systemctl start node_exporter.service >&/dev/null
	proc=node_exporter
	write_header
	run_ok
	systemctl enable prometheus-webhook-dingtalk.service >&/dev/null
	systemctl start prometheus-webhook-dingtalk.service >&/dev/null
	proc=prometheus-webhook-dingtalk
	write_header
	run_ok
}

docker_install() {
	yum -y install docker-ce docker-compose-plugin
	docker_tar=docker_monitor.tar.gz
	mkdir -p /home/prom/prometheus/data
	mkdir -p /home/prom/grafana
	mkdir /data
	tar xf $workdir/$docker_tar -C /data/
	docker compose -f /data/monitor/docker-compose.yml up -d
	docker compose ps
}

install_node_exporter() {
	tar xf $workdir/$node_exporter -C /usr/local/
	ln -sv /usr/local/node_exporter-1.5.0.linux-amd64/ /usr/local/node_exporter >&/dev/null
	chown -R prometheus.prometheus /usr/local/node_exporter
	cat >>/usr/lib/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter

[Service]
ExecStart=/usr/local/node_exporter/node_exporter --web.listen-address=:9100  --collector.filesystem  --collector.netdev  --collector.cpu  --collector.diskstats  --collector.mdadm  --collector.loadavg  --collector.time  --collector.uname  --collector.logind


[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
}

install_webhool_dingtalk() {
	mkdir -p /usr/local/prometheus/wehook/
	tar -xf $workdir/$webhook_dingtalk -C /usr/local/prometheus/wehook/prometheus-webhook-dingtalk-2.1.0.linux-amd64
	mv /usr/local/prometheus/wehook/prometheus-webhook-dingtalk-2.1.0.linux-amd64 /usr/local/prometheus/wehook/dingtalk
	cat >>/usr/lib/systemd/system/prometheus-webhook-dingtalk.service <<EOF
[Unit]
Description=Alertmanager for prometheus

[Service]
Restart=always
User=prometheus
ExecStart=/usr/local/prometheus/wehook/dingtalkprometheus-webhook-dingtalk --config.file=/usr/local/prometheus/wehook/dingtalk/config.yml
ExecReload=/bin/kill -HUP $MAINPID
TimeoutStopSec=20s
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF
	systemctl daemon-reload
}

bak_configfile() {
	cp /usr/local/prometheus/prometheus.yml /usr/local/prometheus/prometheus.yml.bak
	cp /usr/local/alertmanager/alertmanager.yml /usr/local/alertmanager/alertmanager.yml.bak
	cp /usr/local/prometheus/wehook/dingtalk/config.example.yml /usr/local/prometheus/wehook/dingtalk/config.yml
	echo "" >/usr/local/prometheus/wehook/dingtalk/config.yml
	mkdir -p /usr/local/prometheus/wehook/dingtalk/templates
	mkdir -p /usr/local/prometheus/rules
}

configure_files() {
	cat >>/usr/local/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets: ["127.0.0.1:9093"]

rule_files:
   - /usr/local/prometheus/rules/node.yaml

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "node"
    static_configs:
      - targets: ["127.0.0.1:9100"]
EOF
	mkdir -p /usr/local/prometheus/rules/
	cp $workdir/node.yaml /usr/local/prometheus/rules/
	cat >>/usr/local/alertmanager/alertmanager.yml <<EOF
global:
  resolve_timeout: 30s

route:
  group_by: ['alertname']
  group_wait: 60s
  group_interval: 3m
  receiver: 'dev'

receivers:
- name: 'dev'
  webhook_configs:
  - send_resolved: true
    url: http://127.0.0.1:8060/dingtalk/dev/send

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'job', 'instance']
EOF
	cat >>/usr/local/prometheus/wehook/dingtalk/config.yml <<EOF
targets:
  dev:
    url: https://oapi.dingtalk.com/robot/send?access_token=2e7a57d2731720053f60143741a1b806b3d4bc89ab142dfedd06947f8c572893
    secret: SECdfaaa917475bc01443d237fb2299c917c2bdfdfc96dbd9596f1c853ca4ff8196
    message:
      title: '{{ template "ding.link.title" . }}'
      text: '{{ template "ding.link.content" . }}'
templates:
  - /usr/local/prometheus/wehook/dingtalk/templates/default.tmpl
EOF
	cp %workdir/default.tmpl /usr/local/prometheus/wehook/dingtalk/templates/
}

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
			read -p "Plsease choose installation method（docker or normal）： " method
			case word in
			normal)
				network
				if [[ $? == 1 ]]; then
					#statements
					wget_software
					Useradd
					create_dir
					install_prometheus
					install_grafana
					install_alertmanager
					install_node_exporter
					install_webhool_dingtalk
				else
					Useradd
					create_dir
					install_prometheus
					install_grafana
					install_alertmanager
					install_node_exporter
					install_webhool_dingtalk
				fi
				;;
			docker)
				network
				if [[ $? == 1 ]]; then
					docker_install
				else
					show_str_Red "--------------------------------------------"
					show_str_Red "|                  警告！！！              |"
					show_str_Red "|    检查到当前网络不可用，请选择normal安装     |"
					show_str_Red "--------------------------------------------"
					exit 0
				fi
				;;

			esac
			#运行的主程序

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
