<h1 align="center">Итоговый проект курса Linux Basic</a> 
<h3 align="center">Аварийное восстановления веб-инфраструктуры с балансировкой, репликацией баз данных, мониторингом и централизованным логированием</h3>
<h4 align="center">Цель: Демонстрация автоматического восстановления инфраструктуры</h4>
<h5 align="center">Описание: Установка и настройка веб-сервера на базе Nginx и Apache, установка БД на базе Mysql с репликацией и системой бекапов, развертывание мониторинга на базе Prometheus и Grafana, и централизованный сбор логирования на базе Elasticsearch</h5>
  
> Итоговый проект выполнен на дистрибутиве Ubuntu 22.04

[![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)](https://nginx.org/ru/)
[![Apache](https://img.shields.io/badge/apache-%23D42029.svg?style=for-the-badge&logo=apache&logoColor=white)](https://www.apache.org)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![MySQL](https://img.shields.io/badge/mysql-4479A1.svg?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com)
[![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=Prometheus&logoColor=white)](https://prometheus.io)
[![Grafana](https://img.shields.io/badge/grafana-%23F46800.svg?style=for-the-badge&logo=grafana&logoColor=white)](https://grafana.com)
[![Elasticsearch](https://img.shields.io/badge/elasticsearch-%230377CC.svg?style=for-the-badge&logo=elasticsearch&logoColor=white)](https://www.elastic.co/elasticsearch)
![Bash Script](https://img.shields.io/badge/bash_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

<h2 aligh="left">Оглавление</h2>

1. [Список исполняемых файлов](#Описание-исполняемых-файлов)
2. [Предварительные условия](#Предварительные-условия)
3. [Проверка работоспособности](#Проверка-работоспособности)
4. [Хосты и их IP-адреса](#Хосты-и-их-ip-адреса)

<h3 align="left">Описание исполняемых файлов</h3>

Исполняемый файл | Описание
--- | --- 
set_ip_nginx.sh | Установка статичного IP-адреса для хоста nginx, запрет переотпределение на динамический адрес при запуске
set_ip_apache1.sh | Установка статичного IP-адреса для хоста apache1, запрет переотпределение на динамический адрес при запуске
set_ip_apache2.sh | Установка статичного IP-адреса для хоста apache2, запрет переотпределение на динамический адрес при запуске
set_ip_mysql-master.sh | Установка статичного IP-адреса для хоста mysql-master, запрет переотпределение на динамический адрес при запуске
set_ip_mysql-slave.sh | Установка статичного IP-адреса для хоста mysql-slave, запрет переотпределение на динамический адрес при запуске
set_ip_monitoring.sh | Установка статичного IP-адреса для хоста monitoring, запрет переотпределение на динамический адрес при запуске
set_ip_elk.sh | Установка статичного IP-адреса для хоста elk, запрет переотпределение на динамический адрес при запуске
setup_iptables.sh | Установка правил iptables для портов сервисов
bootstrap.sh | Централизованный запуск установочных и конфигурационных скриптов всех сервисов через выбор роли
setup_apache1.sh | Установка и настройка сервиса apache2 на хосте apache1
setup_apache2.sh |Установка и настройка сервиса apache2 на хосте apache2
setup_nginx.sh | Установка и настройка сервиса nginx с балансировкой, устанавливается на хосте nginx
setup_mysql-master.sh |Установка и настройка сервиса mysql на хосте mysql-master. Создание пользователя репликации, настройка master, включение бинарных логов, подготовка параметров для slave
setup_mysql-slave.sh | Установка и настройка сервиса mysql на хосте mysql-slave. Получение параметров репликации, настройка slave, запуск репликации и проверка статуса
setup_elk.sh | Установка и настройка сервисов ELK-стека (Elasticsearch, Logstash, Kibana) на хосте elk
setup_node_exporter.sh | Установка и настройка node_exporter на nginx, apache1 и apache2 для сбора системных метрик и отображению в Prometheus
setup_filebeat.sh | Установка и настройка Filebeat на nginx хосте для сбора и передачи логов сервиса nginx в централизованную систему логирования logstash
setup_prometheus.sh |Установка и настройка prometheus на monitoring хосте
setup_grafana.sh | Установка и настройка grafana на monitoring хосте
create_backup.sh | Создание резервной копии базы данных и отправка в git-репозиторий
restore_backup.sh | Восстановление базы данных из резервной копии из git-репозитория


<h3 align="left">Предварительные условия</h3>
<h5 aligh="left">1. Предустановленные пакеты</h5>
  
  * Хост Nginx: nginx, node_exporter, filebeat, git, iptables-persistent
  * Хосты Apache: Apache2, node_exporter, iptables-persistent
  * Хосты Mysql: mysql-server-8.0, git, iptables-persistent
  * Хост мониторинга: 
    * prometheus-2.46.0 
    * grafana_10.0.3
    * iptables-persistent
    * git
  * Хост ELK:
    * elasticsearch-8.9.1
    * kibana-8.9.1
    * logstash-8.9.1
    * default-jdk
    * iptables-persistent
    * git
  
  <h5 aligh="left">2. Требования к железу</h5>
  
  * RAM: 2GB (4GB для кластера ELK)
  * Space: 20GB (40GB для кластера ELK)

<h3 align="left">Проверка работоспособности</h3>
  
  * [Веб-сервер](https://192.168.68.53)
  * [Prometheus](https://192.168.68.60:9090)
  * [Grafana](https://192.168.68.60:3000) 
  * [Kibana](https://192.168.68.60:5601) 

<h3 aligh=left">Хосты и их IP адреса</h3>

  * nginx: 192.168.68.53
  * apache1: 192.168.68.55
  * apache2: 192.168.68.57
  * mysql-master: 192.168.68.58
  * mysql-slave: 192.168.68.59
  * monitoring: 192.168.68.60
  * elk: 192.168.68.61
