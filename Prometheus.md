# Prometheus+grafana+alertmanager

[TOC]



## <u>文档标识</u>

| 文档名称 | Prometheus+grafana+alertmanager |
| -------- | ------------------------------- |
| 版本号   | <V1.0.0>                        |

## <u>文档修订历史</u>

| 版本   | 日期     | 描述   | 文档所有者 |
| ------ | -------- | ------ | ---------- |
| V1.0.0 | 2023.1.3 | create | 杨丝雨     |
|        |          |        |            |
|        |          |        |            |

## <u>端口说明</u>

| 端口 | 作用                 | remarks |
| ---- | -------------------- | ------- |
| 9090 | prometheus默认端口   |         |
| 3000 | grafana默认端口      |         |
| 9093 | alertmanager默认端口 |         |

## <u>配置文件介绍</u>

| 文件名           | 描述                          |
| ---------------- | ----------------------------- |
| prometheus.yml   | Prometheus的主配置⽂件        |
| grafana.ini      | 配置 smtp服务器，配置发件邮箱 |
| alertmanager.yml | alertmanager主配置文件        |
|                  |                               |

## <u>相关文档参考</u>

[prometheus+grafana+alertmanager 安装配置文档]: https://blog.51cto.com/mageedu/2568334
[官方文档地址]: https://prometheus.io/docs/introduction/overview/
[github项目下载地址]: https://github.com/prometheus/prometheus
[grafana程序下载地址]: https://grafana.com/grafana/download
[grafana dashboard 下载地址]: https://grafana.com/grafana/download/
[alertmanager文档地址]: https://prometheus.io/docs/alerting/latest/configuration/
[alertmanager下载地址]: https://github.com/prometheus/alertmanager



## Prometheus简介

------

​			Prometheus受启发于Google的Brogmon监控系统（相似的Kubernetes是从Google的Brog系统演变而来），从2012年开始由前Google工程师在Soundcloud以开源软件的形式进行研发，并且于2015年早期对外发布早期版本。2016年5月继Kubernetes之后成为第二个正式加入CNCF基金会的项目，同年6月正式发布1.0版本。2017年底发布了基于全新存储层的2.0版本，能更好地与容器平台、云平台配合。

------

### Prometheus架构图

![Prometheus介绍和高可用方案简介-开源基础软件社区](https://dl-harmonyos.51cto.com/images/202206/926e8f472e5ed7714108254c9261fc20f642a9.jpg)

### Prometheus 特点

**作为新一代的监控框架，Prometheus 具有以下特点：**

1、多维数据模型：由度量名称和键值对标识的时间序列数据

2、PromSQL：一种灵活的查询语言，可以利用多维数据完成复杂的查询

3、不依赖分布式存储，单个服务器节点可直接工作

4、基于HTTP的pull方式采集时间序列数据

5、推送时间序列数据通过PushGateway组件支持

6、通过服务发现或静态配置发现目标

7、多种图形模式及仪表盘支持（grafana）

8、适用于以机器为中心的监控以及高度动态面向服务架构的监控

### Prometheus 组织架构

- Prometheus Server：用于收集指标和存储时间序列数据，并提供查询接口

- client Library：客户端库（例如Go，Python，Java等），为需要监控的服务产生相应的/metrics并暴露给Prometheus Server。目前已经有很多的软件原生就支持Prometheus，提供/metrics，可以直接使用。对于像操作系统已经不提供/metrics，可以使用exporter，或者自己开发exporter来提供/metrics服务。

- push gateway：主要用于临时性的 jobs。由于这类 jobs 存在时间较短，可能在 Prometheus 来 pull 之前就消失了。对此Jobs定时将指标push到pushgateway，再由Prometheus Server从Pushgateway上pull。

**这种方式主要用于服务层面的 metrics：**

- exporter：用于暴露已有的第三方服务的 metrics 给 Prometheus。
- alertmanager：从 Prometheus server 端接收到 alerts 后，会进行去除重复数据，分组，并路由到对收的接受方式，发出报警。常见的接收方式有：电子邮件，pagerduty，OpsGenie, webhook 等。

- Web UI：Prometheus内置一个简单的Web控制台，可以查询指标，查看配置信息或者Service Discovery等，实际工作中，查看指标或者创建仪表盘通常使用Grafana，Prometheus作为Grafana的数据源；

> **注：**大多数 Prometheus 组件都是用 Go 编写的，因此很容易构建和部署为静态的二进制文件。

### prometheus与常见监控系统比较

#### Prometheus vs Zabbix

- Zabbix 使用的是 C 和 PHP, Prometheus 使用 Golang, 整体而言 Prometheus 运行速度更快一点。
- Zabbix 属于传统主机监控，主要用于物理主机，交换机，网络等监控，Prometheus 不仅适用主机监控，还适用于 Cloud, SaaS, Openstack，Container 监控。
- Zabbix 在传统主机监控方面，有更丰富的插件。
- Zabbix 可以在 WebGui 中配置很多事情，但是 Prometheus 需要手动修改文件配置。

#### Prometheus vs Graphite

- [Graphite](http://graphite.readthedocs.io/en/latest/overview.html) 功能较少，它专注于两件事，存储时序数据， 可视化数据，其他功能需要安装相关插件，而 Prometheus 属于一站式，提供告警和趋势分析的常见功能，它提供更强的数据存储和查询能力。
- 在水平扩展方案以及数据存储周期上，Graphite 做的更好。

#### Prometheus vs InfluxDB

- [InfluxDB](https://www.influxdata.com/) 是一个开源的时序数据库，主要用于存储数据，如果想搭建监控告警系统， 需要依赖其他系统。
- InfluxDB 在存储水平扩展以及高可用方面做的更好, 毕竟核心是数据库。

#### Prometheus vs OpenTSDB

- [OpenTSDB](http://opentsdb.net/) 是一个分布式时序数据库，它依赖 Hadoop 和 HBase，能存储更长久数据， 如果你系统已经运行了 Hadoop 和 HBase, 它是个不错的选择。
- 如果想搭建监控告警系统，OpenTSDB 需要依赖其他系统。

#### Prometheus vs Nagios

- [Nagios](https://www.nagios.org/) 数据不支持自定义 Labels, 不支持查询，告警也不支持去噪，分组, 没有数据存储，如果想查询历史状态，需要安装插件。
- Nagios 是上世纪 90 年代的监控系统，比较适合小集群或静态系统的监控，显然 Nagios 太古老了，很多特性都没有，相比之下Prometheus 要优秀很多。

#### Prometheus vs Sensu

- [Sensu](https://sensuapp.org/) 广义上讲是 Nagios 的升级版本，它解决了很多 Nagios 的问题，如果你对 Nagios 很熟悉，使用 Sensu 是个不错的选择。
- Sensu 依赖 RabbitMQ 和 Redis，数据存储上扩展性更好。

#### 总结

- Prometheus 属于一站式监控告警平台，依赖少，功能齐全。
- Prometheus 支持对云或容器的监控，其他系统主要对主机监控。
- Prometheus 数据查询语句表现力更强大，内置更强大的统计函数。
- Prometheus 在数据存储扩展性以及持久性上没有 InfluxDB，OpenTSDB，Sensu 好。

## Grafana简介

------

​			[Grafana](https://grafana.com/) 是一个监控仪表系统，它是由 Grafana Labs 公司开源的的一个系统监测工具，它可以大大帮助我们简化监控的复杂度，我们只需要提供需要监控的数据，它就可以帮助生成各种可视化仪表，同时它还有报警功能，可以在系统出现问题时发出通知。

------

### Grafana特点

 ①可视化：快速和灵活的客户端图形具有多种选项。面板插件为许多不同的方式可视化指标和日志。
 ②报警：可视化地为最重要的指标定义警报规则。Grafana将持续评估它们，并发送通知。
 ③通知：警报更改状态时，它会发出通知。接收电子邮件通知。
 ④动态仪表盘：使用模板变量创建动态和可重用的仪表板，这些模板变量作为下拉菜单出现在仪表板顶部。
 ⑤混合数据源：在同一个图中混合不同的数据源!可以根据每个查询指定数据源。这甚至适用于自定义数据源。
 ⑥注释：注释来自不同数据源图表。将鼠标悬停在事件上可以显示完整的事件元数据和标记。
 ⑦过滤器：过滤器允许您动态创建新的键/值过滤器，这些过滤器将自动应用于使用该数据源的所有查询。

### Grafana基本概念

#### 数据源（Data Source）

对于Grafana而言，Prometheus这类为其提供数据的对象均称为数据源（Data Source）。目前，Grafana官方提供了对：Graphite, InfluxDB, OpenTSDB, Prometheus, Elasticsearch, CloudWatch的支持。对于Grafana管理员而言，只需要将这些对象以数据源的形式添加到Grafana中，Grafana便可以轻松的实现对这些数据的可视化工作。

#### 仪表盘（Dashboard）

通过数据源定义好可视化的数据来源之后，对于用户而言最重要的事情就是实现数据的可视化。在Grafana中，我们通过Dashboard来组织和管理我们的数据可视化图表：

![img](https://2584451478-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-LBdoxo9EmQ0bJP2BuUi%2F-LRX7f16nDH_eSWU4Szc%2F-LRX7gzvWm8jDHg4S9fc%2Fdashboard-components.png?generation=1542465969279644&alt=media)

如上所示，在一个Dashboard中一个最基本的可视化单元为一个**Panel（面板）**，Panel通过如趋势图，热力图的形式展示可视化数据。 并且在Dashboard中每一个Panel是一个完全独立的部分，通过Panel的**Query Editor（查询编辑器）**我们可以为每一个Panel自己查询的数据源以及数据查询方式，例如，如果以Prometheus作为数据源，那在Query Editor中，我们实际上使用的是PromQL，而Panel则会负责从特定的Prometheus中查询出相应的数据，并且将其可视化。由于每个Panel是完全独立的，因此在一个Dashboard中，往往可能会包含来自多个Data Source的数据。

Grafana通过插件的形式提供了多种Panel的实现，常用的如：Graph Panel，Heatmap Panel，SingleStat Panel以及Table Panel等。用户还可通过插件安装更多类型的Panel面板。

除了Panel以外，在Dashboard页面中，我们还可以定义一个**Row（行）**，来组织和管理一组相关的Panel。

除了Panel, Row这些对象以外，Grafana还允许用户为Dashboard定义**Templating variables（模板参数）**，从而实现可以与用户动态交互的Dashboard页面。同时Grafana通过JSON数据结构管理了整个Dasboard的定义，因此这些Dashboard也是非常方便进行共享的。Grafana还专门为Dashboard提供了一个共享服务：https://grafana.com/dashboards，通过该服务用户可以轻松实现Dashboard的共享，同时我们也能快速的从中找到我们希望的Dashboard实现，并导入到自己的Grafana中。

#### 组织和用户

作为一个通用可视化工具，Grafana除了提供灵活的可视化定制能力以外，还提供了面向企业的组织级管理能力。在Grafana中Dashboard是属于一个**Organization（组织）**，通过Organization，可以在更大规模上使用Grafana，例如对于一个企业而言，我们可以创建多个Organization，其中**User（用户）**可以属于一个或多个不同的Organization。 并且在不同的Organization下，可以为User赋予不同的权限。 从而可以有效的根据企业的组织架构定义整个管理模型。

## Alertmanager简介

------

​		**Alertmanager 主要用于接收 Prometheus 发送的告警信息，它支持丰富的告警通知渠道**，而且很容易做到告警信息进行去重，降噪，分组等，是一款前卫的告警通知系统。

![img](https://img2018.cnblogs.com/blog/1183448/201908/1183448-20190802165437616-1426983122.png)

------

### Alertmanager核心概念

#### 分组

分组将类似性质的警报分类为单个通知。当许多系统同时发生故障并且可能同时触发数百到数千个警报时，这在较大的中断期间尤其有用。

示例：当发生网络分区故障时，集群中正在运行数十个或数百个服务实例。您的一半服务实例无法再访问数据库。Prometheus 中的警报规则被配置为在每个服务实例无法与数据库通信时发送警报。因此，数百个警报被发送到 Alertmanager。

作为用户，您只想获得一个页面，同时仍然能够准确查看哪些服务实例受到影响。因此，可以将 Alertmanager 配置为按集群和警报名称对警报进行分组，以便它发送单个紧凑通知。

警报分组、分组通知的时间以及这些通知的接收者由配置文件中的路由树进行配置。

#### 抑制

抑制是一个概念，如果某些其他警报已经触发，则抑制某些警报的通知。

示例：发出警报，通知无法访问整个集群。如果该特定警报正在触发，Alertmanager 可以配置为静音与该集群相关的所有其他警报。这可以防止收到与实际问题无关的数百或数千个触发警报的通知。

通过 Alertmanager 的配置文件进行配置。

#### 静默

静默是在给定时间内简单地将警报静音的直接方法。静默是基于匹配器配置的，就像路由树一样。检查传入警报是否与活动静默的所有相等或正则表达式匹配器匹配。如果他们这样做，则不会发送该警报的通知。

静默是在 Alertmanager 的 Web 界面中配置的。

#### 客户行为

Alertmanager对其客户端的行为有特殊要求。这些仅与不使用 Prometheus 发送警报的高级用例相关。

#### 高可用性

Alertmanager 支持配置以创建集群以实现高可用性。这可以使用–cluster-*标志进行配置。

重要的是不要在 Prometheus 及其警报管理器之间负载平衡流量，而是将 Prometheus 指向所有警报管理器的列表。



## Prometheus安装

------

- 创建运行prometheus server进程的系统用户，并为其创建家目录/var/lib/prometheus 作为数据存储目录

```shell
useradd -r -m -d /var/lib/prometheus prometheus
```

- 创建数据目录并授权

```shell
mkdir -p /data/prometheus
chown -R prometheus.prometheus /data/prometheus
```

- 下载并安装prometheus server

```shell
wget https://github.com/prometheus/prometheus/releases/download/v2.41.0/prometheus-2.41.0.linux-amd64.tar.gz
tar -xf prometheus-2.41.0.linux-amd64.tar.gz -C /usr/local/
ln -sv /usr/local/prometheus-2.41.0.linux-amd64 /usr/local/prometheus
```

- 创建unit file，让systemd 管理prometheus

```shell
cat >> /usr/lib/systemd/system/prometheus.service << EOF
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
```

- 设置开机自启并启动prometheus

```shell
systemctl enable prometheus.service
systemctl start prometheus.service
```



## Grafana安装

------

- 下载并安装

```shell
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-9.3.2-1.x86_64.rpm
yum -y install grafana-enterprise-9.3.2-1.x86_64.rpm
```

- 启动grafana

```shell
systemctl enable grafana-server.service
systemctl restart grafana-server.service
```



## Alertmanager安装

------

- 创建数据目录并授权

```shell
mkdir -p /data/alertmanager
chown -R prometheus.prometheus /data/alertmanager
```

- 下载并安装

```shell
tar -xf alertmanager-0.25.0-rc.2.linux-amd64.tar.gz -C /usr/local/
ln -sv /usr/local/alertmanager-0.25.0-rc.2.linux-amd64/ /usr/local/alertmanager >& /dev/null
chown -R prometheus.prometheus /usr/local/alertmanager
```

- 创建unit file，让systemd 管理alertmanager

```shell
cat >> /usr/lib/systemd/system/alertmanager.service << EOF
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
```

- 启动

```shell
systemctl enable alertmanager.service
systemctl start alertmanager.service
```



## <u>附录：Alertmanager配置文件详解</u>

```yaml
global:
  # 经过此时间后，如果尚未更新告警，则将告警声明为已恢复。(即prometheus没有向alertmanager发送告警了)
  resolve_timeout: 5m
  # 配置发送邮件信息
  smtp_smarthost: 'smtp.qq.com:465'
  smtp_from: '742899387@qq.com'
  smtp_auth_username: '742899387@qq.com'
  smtp_auth_password: 'password'
  smtp_require_tls: false
 
# 读取告警通知模板的目录。
templates: 
- '/etc/alertmanager/template/*.tmpl'
 
# 所有报警都会进入到这个根路由下，可以根据根路由下的子路由设置报警分发策略
route:
  # 先解释一下分组，分组就是将多条告警信息聚合成一条发送，这样就不会收到连续的报警了。
  # 将传入的告警按标签分组(标签在prometheus中的rules中定义)，例如：
  # 接收到的告警信息里面有许多具有cluster=A 和 alertname=LatencyHigh的标签，这些个告警将被分为一个组。
  #
  # 如果不想使用分组，可以这样写group_by: [...]
  group_by: ['alertname', 'cluster', 'service']
 
  # 第一组告警发送通知需要等待的时间，这种方式可以确保有足够的时间为同一分组获取多个告警，然后一起触发这个告警信息。
  group_wait: 30s
 
  # 发送第一个告警后，等待"group_interval"发送一组新告警。
  group_interval: 5m
 
  # 分组内发送相同告警的时间间隔。这里的配置是每3小时发送告警到分组中。举个例子：收到告警后，一个分组被创建，等待5分钟发送组内告警，如果后续组内的告警信息相同,这些告警会在3小时后发送，但是3小时内这些告警不会被发送。
  repeat_interval: 3h 
 
  # 这里先说一下，告警发送是需要指定接收器的，接收器在receivers中配置，接收器可以是email、webhook、pagerduty、wechat等等。一个接收器可以有多种发送方式。
  # 指定默认的接收器
  receiver: team-X-mails
 
  
  # 下面配置的是子路由，子路由的属性继承于根路由(即上面的配置)，在子路由中可以覆盖根路由的配置
 
  # 下面是子路由的配置
  routes:
  # 使用正则的方式匹配告警标签
  - match_re:
      # 这里可以匹配出标签含有service=foo1或service=foo2或service=baz的告警
      service: ^(foo1|foo2|baz)$
    # 指定接收器为team-X-mails
    receiver: team-X-mails
    # 这里配置的是子路由的子路由，当满足父路由的的匹配时，这条子路由会进一步匹配出severity=critical的告警，并使用team-X-pager接收器发送告警，没有匹配到的告警会由父路由进行处理。
    routes:
    - match:
        severity: critical
      receiver: team-X-pager
 
  # 这里也是一条子路由，会匹配出标签含有service=files的告警，并使用team-Y-mails接收器发送告警
  - match:
      service: files
    receiver: team-Y-mails
    # 这里配置的是子路由的子路由，当满足父路由的的匹配时，这条子路由会进一步匹配出severity=critical的告警，并使用team-Y-pager接收器发送告警，没有匹配到的会由父路由进行处理。
    routes:
    - match:
        severity: critical
      receiver: team-Y-pager
 
  # 该路由处理来自数据库服务的所有警报。如果没有团队来处理，则默认为数据库团队。
  - match:
      # 首先匹配标签service=database
      service: database
    # 指定接收器
    receiver: team-DB-pager
    # 根据受影响的数据库对告警进行分组
    group_by: [alertname, cluster, database]
    routes:
    - match:
        owner: team-X
      receiver: team-X-pager
      # 告警是否继续匹配后续的同级路由节点，默认false，下面如果也可以匹配成功，会向两种接收器都发送告警信息(猜测。。。)
      continue: true
    - match:
        owner: team-Y
      receiver: team-Y-pager
 
 
# 下面是关于inhibit(抑制)的配置，先说一下抑制是什么：抑制规则允许在另一个警报正在触发的情况下使一组告警静音。其实可以理解为告警依赖。比如一台数据库服务器掉电了，会导致db监控告警、网络告警等等，可以配置抑制规则如果服务器本身down了，那么其他的报警就不会被发送出来。
 
inhibit_rules:
#下面配置的含义：当有多条告警在告警组里时，并且他们的标签alertname,cluster,service都相等，如果severity: 'critical'的告警产生了，那么就会抑制severity: 'warning'的告警。
- source_match:  # 源告警(我理解是根据这个报警来抑制target_match中匹配的告警)
    severity: 'critical' # 标签匹配满足severity=critical的告警作为源告警
  target_match:  # 目标告警(被抑制的告警)
    severity: 'warning'  # 告警必须满足标签匹配severity=warning才会被抑制。
  equal: ['alertname', 'cluster', 'service']  # 必须在源告警和目标告警中具有相等值的标签才能使抑制生效。(即源告警和目标告警中这三个标签的值相等'alertname', 'cluster', 'service')
 
 
# 下面配置的是接收器
receivers:
# 接收器的名称、通过邮件的方式发送、
- name: 'team-X-mails'
  email_configs:
    # 发送给哪些人
  - to: 'team-X+alerts@example.org'
    # 是否通知已解决的警报
    send_resolved: true
 
# 接收器的名称、通过邮件和pagerduty的方式发送、发送给哪些人，指定pagerduty的service_key
- name: 'team-X-pager'
  email_configs:
  - to: 'team-X+alerts-critical@example.org'
  pagerduty_configs:
  - service_key: <team-X-key>
 
# 接收器的名称、通过邮件的方式发送、发送给哪些人
- name: 'team-Y-mails'
  email_configs:
  - to: 'team-Y+alerts@example.org'
 
# 接收器的名称、通过pagerduty的方式发送、指定pagerduty的service_key
- name: 'team-Y-pager'
  pagerduty_configs:
  - service_key: <team-Y-key>
 
# 一个接收器配置多种发送方式
- name: 'ops'
  webhook_configs:
  - url: 'http://prometheus-webhook-dingtalk.kube-ops.svc.cluster.local:8060/dingtalk/webhook1/send'
    send_resolved: true
  email_configs:
  - to: '742899387@qq.com'
    send_resolved: true
  - to: 'soulchild@soulchild.cn'
    send_resolved: true
```



## <u>附录：Prometheus配置文件</u>

- Prometheus的主配置⽂件为prometheus.yml

它主要由global、rule_files、scrape_configs、alerting、remote_write和remote_read⼏个配置段组成：

```yaml
- global：全局配置段；

 - rule_files：指定告警规则文件的路径

 - scrape_configs：
  	scrape配置集合，⽤于定义监控的⽬标对象（target）的集合，以及描述如何抓取 （scrape）相关指标数据的配置参数；
  	通常，每个scrape配置对应于⼀个单独的作业（job），
  	⽽每个targets可通过静态配置（static_configs）直接给出定义，也可基于Prometheus⽀持的服务发现机制进 ⾏⾃动配置；
 - job_name: 'nodes'
 static_configs: 	# 静态指定，targets中的 host:port/metrics 将会作为metrics抓取对象
 - targets: ['localhost:9100']
 - targets: ['172.20.94.1:9100']
 - job_name: 'docker_host'
  file_sd_configs: 	# 基于文件的服务发现，文件中（yml 和json 格式）定义的host:port/metrics将会成为抓取对象
 - files:
  - ./sd_files/docker_host.yml
refresh_interval: 30s
```

- alertmanager_configs：

可由Prometheus使⽤的Alertmanager实例的集合，以及如何同这些Alertmanager交互的配置参数；

每个Alertmanager可通过静态配置（static_configs）直接给出定义， 也可基于Prometheus⽀持的服务发现机制进⾏⾃动配置；

- remote_write：

```
配置“远程写”机制，Prometheus需要将数据保存于外部的存储系统（例如InfluxDB）时 定义此配置段，
随后Prometheus将样本数据通过HTTP协议发送给由URL指定适配器(Adaptor)；
```

- remote_read：

```
配置“远程读”机制，Prometheus将接收到的查询请求交给由URL指定适配器 （Adpater）执⾏，
Adapter将请求条件转换为远程存储服务中的查询请求，并将获取的响应数据转换为Prometheus可⽤的格式；
```

监控及告警规则配置文件：*.yml

定义监控规则

需要在主配置文件rule_files: 中指定才会生效

```yaml
 rule_files:

- "test_rules.yml"  # 指定配置告警规则的文件路径
```

- 服务发现定义文件：支持yaml 和 json 两种格式

- 也是需要在主配置文件中定义

```yaml
 file_sd_configs:
	- files:
		- ./sd_files/http.yml
		refresh_interval: 30s
```

**prometheus web-gui**

- web页面访问地址：  http://ip:port 如： http://10.10.11.40:9090/
- alerts： 查看告警规则
- graph： 查询收集到的指标数据，并提供简单的绘图
- status： prometheus运行时配置已经监听主机相关信息
- 详情自行查看web-gui页面

## <u>附录：Prometheus常用的高可用方案</u>

![Prometheus介绍和高可用方案简介-开源基础软件社区](https://dl-harmonyos.51cto.com/images/202206/c7cb7410755177bd5c6349c199088ee39f8a7d.jpg)

![Prometheus介绍和高可用方案简介-开源基础软件社区](https://dl-harmonyos.51cto.com/images/202206/8438d3002a95504a27407232ff1a452bece54c.png)

![Prometheus介绍和高可用方案简介-开源基础软件社区](https://dl-harmonyos.51cto.com/images/202206/85d26053931999f0950009a9dd6625866c8b31.jpg)

![Prometheus介绍和高可用方案简介-开源基础软件社区](https://dl-harmonyos.51cto.com/images/202206/486f3f919431a113d03141049149fa083e0c64.png)