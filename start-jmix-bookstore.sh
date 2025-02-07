#!/bin/bash

# Проверка наличия утилиты Yandex Cloud CLI
yc --version >/dev/null 2>&1 || { echo "Yandex Cloud CLI не установлен. Установите его и повторите попытку."; exit 1; }

# Конфигурация
VM_NAME="bookstore"
NETWORK_NAME="nick-network"
SUBNET_NAME="nick-subnet"
ZONE="ru-central1-a"
IMAGE_ID="fd8bpal18cm4kprpjc2m"
SSH_KEY_NAME="nick_ssh_key"
USER="ipiris"

# Создание SSH-ключей
ssh-keygen -t rsa -b 2048 -f $SSH_KEY_NAME -N "" || { echo "Ошибка при создании SSH-ключей."; exit 1; }

# Создание временного файла cloud-init
CLOUD_INIT_FILE=$(mktemp)

cat <<EOF > $CLOUD_INIT_FILE
#cloud-config
users:
  - name: $USER
    ssh-authorized-keys:
      - $(cat ${SSH_KEY_NAME}.pub)
    groups: sudo
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
EOF

# Создание облачной сети и подсети
yc vpc network create --name $NETWORK_NAME
yc vpc subnet create \
  --name $SUBNET_NAME \
  --zone $ZONE \
  --range 192.168.0.0/24 \
  --network-name $NETWORK_NAME

# Создание виртуальной машины
yc compute instance create \
  --name $VM_NAME \
  --zone $ZONE \
  --platform "standard-v3" \
  --cores 2 \
  --memory 4 \
  --create-boot-disk size=20,type=network-ssd,image-id=$IMAGE_ID \
  --network-interface subnet-name=$SUBNET_NAME,nat-ip-version=ipv4 \
  --metadata-from-file user-data=$CLOUD_INIT_FILE

rm -f $CLOUD_INIT_FILE

# Получение внешнего IP-адреса
EXTERNAL_IP=$(yc compute instance get --name $VM_NAME --format json | jq -r '.network_interfaces[0].primary_v4_address.one_to_one_nat.address')

# Установка Docker на виртуальной машине
ssh -o StrictHostKeyChecking=no -i $SSH_KEY_NAME $USER@$EXTERNAL_IP << EOF
sudo snap install docker
sudo systemctl daemon-reload
sudo systemctl enable snap.docker.dockerd.service
sudo systemctl start snap.docker.dockerd.service
sudo systemctl restart snap.docker.dockerd.service
sleep 10
sudo docker run -d --restart=always -p 80:8080 jmix/jmix-bookstore
EOF

# Вывод информации для подключения
echo "Подключение к виртуальной машине по SSH:"
echo "ssh -i $SSH_KEY_NAME $USER@$EXTERNAL_IP"

echo "Открытие веб-приложения:"
echo "http://$EXTERNAL_IP"
