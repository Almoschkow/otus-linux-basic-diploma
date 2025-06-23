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
4. [Чек-лист выполнения](#Чек-лист-выполнения)

<h3 align="left">Описание исполняемых файлов</h3>

Исполняемый файл | Описание
--- | --- 
1 | test
1 | test
1 | test
1 | test
1 | test
1 | test
1 | test

<h3 align="left">Предварительные условия</h3>
<h5 aligh="left">1. Предустановленные пакеты</h5>
  
  * Хост Nginx: nginx
  * Хосты Apache: Apache2
  * Хосты Mysql: mysql-server-8.0
  * Хост мониторинга: 
    * prometheus-2.46.0 
    * node_exporter-1.6.1
    * grafana_10.0.3
  * Хост ELK:
    * elasticsearch-8.9.1
    * filebeat-8.9.1
    * heartbeat-8.9.1
    * kibana-8.9.1
    * logstash-8.9.1
    * metricbeat-8.9.1
    * packetbeat-8.9.1
  
  <h5 aligh="left">2. Требования к железу</h5>
  
  * RAM: 2GB (4GB для кластера ELK)
  * Space: 20GB

<h3 align="left">Проверка работоспособности</h3>
  
  * Веб-сервер: 
  * Prometheus:
  * Grafana:
  * Elasticsearch:

<h3 aligh=left">Чек-лист выполнения</h3>

  * Установка веб-сервера
  * Настройка балансировки
  * Установка Mysql
  * Настройка репликации БД
  * Подготовка бекапа
  * Бекап данных
  * Установка Prometheus
  * Установка Grafana
  * Настройка сбора метрик
  * Настройка визуализации метрик в Grafana
  * Установка ELK кластера
  * Настройка логирования и сбор логов
  * Настройка визуализации логирования в Elasticsearch
