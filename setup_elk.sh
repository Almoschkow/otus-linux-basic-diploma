#!/bin/bash

# Скрипт установки и настройки ELK-стека (Elasticsearch, Logstash, Kibana)

set -e  # Прерываем скрипт при ошибке

# Определим IP-адрес хоста
# HOST_IP=$(ip -o -4 addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -n1)

### === 1. Elasticsearch ===
echo "[+] Настройка Elasticsearch..."
sudo tee /etc/elasticsearch/elasticsearch.yml > /dev/null <<EOF
network.host: 0.0.0.0
http.port: 9200

cluster.name: elk-cluster
node.name: elk-node
discovery.type: single-node

path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch

# Отключаем X-Pack Security
xpack.security.enabled: false
xpack.security.transport.ssl.enabled: false
xpack.security.http.ssl.enabled: false
EOF

sudo systemctl daemon-reexec
sudo systemctl enable elasticsearch
sudo systemctl restart elasticsearch
sleep 5

# Проверка Elasticsearch
if curl -s http://localhost:9200 >/dev/null; then
  # echo "[✓] Elasticsearch работает на http://$HOST_IP:9200" 
  echo "[✓] Elasticsearch работает на http://192.168.56.107:9200"
else
  echo "[!] Elasticsearch не отвечает. Проверьте журнал: journalctl -u elasticsearch"
fi

### === 2. Kibana ===
echo "[+] Настройка Kibana..."
sudo tee /etc/kibana/kibana.yml > /dev/null <<EOF
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
EOF

sudo systemctl enable kibana
sudo systemctl restart kibana
sleep 5

if curl -s http://localhost:5601 >/dev/null; then
  # echo "[✓] Kibana работает на http://$HOST_IP:5601"
  echo "[✓] Kibana работает на http://192.168.56.107:5601"
else
  echo "[!] Kibana не отвечает. Проверьте журнал: journalctl -u kibana"
fi

### === 3. Logstash ===
echo "[+] Настройка Logstash..."
sudo mkdir -p /etc/logstash/conf.d

sudo tee /etc/logstash/conf.d/logstash-nginx-es.conf > /dev/null <<EOF
input {
    beats {
        port => 5400
    }
}

filter {
 grok {
   match => [ "message" , "%{COMBINEDAPACHELOG}+%{GREEDYDATA:extra_fields}"]
   overwrite => [ "message" ]
 }
 mutate {
   convert => ["response", "integer"]
   convert => ["bytes", "integer"]
   convert => ["responsetime", "float"]
 }
 date {
   match => [ "timestamp" , "dd/MMM/YYYY:HH:mm:ss Z" ]
   remove_field => [ "timestamp" ]
 }
 useragent {
   source => "agent"
 }
}

output {
 elasticsearch {
   hosts => ["http://localhost:9200"]
   index => "weblogs-%{+YYYY.MM.dd}"
   document_type => "nginx_logs"
 }
 stdout { codec => rubydebug }
}
EOF

sudo systemctl enable logstash
sudo systemctl restart logstash

# Проверка состояния Logstash
if systemctl is-active --quiet logstash; then
  echo "[✓] Logstash настроен и работает. Слушает порт 5400 для логов от Filebeat"
else
  echo "[!] Logstash не запущен. Проверьте журнал: journalctl -u logstash"
fi

# Финальное сообщение
# echo "[✓] ELK-стек настроен. Перейдите в Kibana: http://$HOST_IP:5601"
echo "[✓] ELK-стек настроен. Перейдите в Kibana: http://192.168.56.107:5601"
