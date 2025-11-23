# DevOps CI/CD

## Вивчення Helm — Lesson 7

## Опис проєкту

Проєкт демонструє повний цикл розгортання Django-застосунку у Kubernetes-кластері на базі AWS, із використанням Terraform для керування інфраструктурою та Helm для деплойменту застосунку.

Інфраструктура включає створення EKS-кластеру, приватного репозиторію ECR для зберігання Docker-образів, AWS EBS CSI Driver для persistent storage та розгортання Helm-чарту, що забезпечує масштабування та конфігурацію сервісу.

## Структура проєкту

```
my-microservice-project/
│
├── main.tf                  # Основний Terraform-файл для підключення модулів
├── backend.tf               # Конфігурація бекенду (S3 + DynamoDB) для Terraform state
├── outputs.tf               # Глобальні вихідні дані інфраструктури
│
├── modules/                 # Каталог інфраструктурних модулів
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакету
│   │   ├── dynamodb.tf      # Створення таблиці DynamoDB
│   │   ├── variables.tf     # Змінні модуля
│   │   └── outputs.tf       # Вихідні дані
│   │
│   ├── vpc/                 # Модуль для створення VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж та Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутів та NAT Gateway
│   │   ├── variables.tf     # Змінні модуля
│   │   └── outputs.tf       # Вихідні дані
│   │
│   ├── ecr/                 # Модуль для ECR-репозиторію
│   │   ├── ecr.tf           # Створення приватного ECR з lifecycle policy
│   │   ├── variables.tf     # Змінні модуля
│   │   └── outputs.tf       # URL репозиторію
│   │
│   └── eks/                 # Модуль для створення EKS-кластеру
│       ├── eks.tf           # Створення EKS, Node Groups, EBS CSI Driver
│       ├── variables.tf     # Змінні модуля
│       └── outputs.tf       # Параметри кластера
│
├── app/                     # Django-застосунок
│   ├── Dockerfile           # Docker-образ для Django
│   ├── entrypoint.sh        # Скрипт ініціалізації (міграції, collectstatic)
│   ├── requirements.txt     # Python-залежності (Django, psycopg2, whitenoise)
│   ├── manage.py            # Django management
│   └── project/             # Django проєкт
│       ├── settings.py      # Налаштування (включаючи WhiteNoise)
│       ├── urls.py          # URL маршрути
│       ├── static/          # Статичні файли
│       └── templates/       # HTML шаблони
│
├── charts/                  # Helm-чарти
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml    # Deployment для Django-застосунку
│       │   ├── service.yaml       # LoadBalancer Service
│       │   ├── configmap.yaml     # Змінні середовища
│       │   ├── hpa.yaml           # Horizontal Pod Autoscaler
│       │   ├── postgres.yaml      # PostgreSQL Deployment, Service, PVC
│       │   └── _helpers.tpl       # Допоміжні шаблони Helm
│       ├── Chart.yaml             # Метадані чарта
│       └── values.yaml            # Конфігураційні значення
│
└── README.md                # Документація
```

## Створена інфраструктура

### AWS-ресурси

- **EKS-кластер**
- **EC2 Node Group** (t3.medium, масштабування 2–6 нод)
- **VPC** з публічними та приватними підмережами
- **NAT Gateway** в кожній AZ для приватних підмереж
- **ECR** для зберігання Docker-образів
- **S3** для Terraform state
- **DynamoDB** для блокування state
- **IAM-ролі та політики** для EKS, Node Groups, та EBS CSI Driver
- **EBS CSI Driver** для динамічного створення Persistent Volumes
- **OIDC Provider** для EKS Service Accounts

### Kubernetes-ресурси

- **Deployment** для Django-застосунку (2 репліки)
- **Deployment** для PostgreSQL (1 репліка)
- **LoadBalancer Service** для зовнішнього доступу до Django
- **ClusterIP Service** для внутрішнього доступу до PostgreSQL
- **ConfigMap** зі змінними середовища
- **PersistentVolumeClaim** (10Gi) для PostgreSQL на AWS EBS
- **HorizontalPodAutoscaler** для автоматичного масштабування (2-6 подів при CPU > 70%)
- **StorageClass** (gp2) для EBS volumes

## Перед початком роботи

Необхідно встановити та налаштувати:

- **AWS CLI** (з коректно налаштованими обліковими даними)
- **Terraform** (версія ≥ 1.0)
- **kubectl**
- **Helm 3**
- **Docker**

## Інструкція з розгортання

### 1. Підготовка інфраструктури

```bash
# Ініціалізація Terraform
terraform init

# Перевірка плану змін
terraform plan

# Створення інфраструктури
terraform apply
```

**Примітка:** При першому запуску Terraform backend буде локальним. Після створення S3 та DynamoDB, розкоментуйте конфігурацію в `backend.tf` та виконайте `terraform init -migrate-state` для міграції стану в S3.

### 2. Налаштування kubectl

```bash
# Підключення до EKS-кластеру
aws eks update-kubeconfig --region eu-central-1 --name lesson-7-eks-cluster

# Перевірка доступу
kubectl get nodes

# Перевірка що StorageClass створено автоматично
kubectl get storageclass
```

### 3. Підготовка Docker-образу

```bash
# Перехід в директорію додатку
cd app

# Збірка образу без кешу
docker build --no-cache -t lesson-7-django-app .

# Логін у ECR
aws ecr get-login-password --region eu-central-1 \
  | docker login --username AWS --password-stdin account_id.dkr.ecr.eu-central-1.amazonaws.com

# Тегування
docker tag lesson-7-django-app:latest account_id.dkr.ecr.eu-central-1.amazonaws.com/lesson-7-django-app:latest

# Завантаження
docker push account_id.dkr.ecr.eu-central-1.amazonaws.com/lesson-7-django-app:latest

# Повернення в кореневу директорію
cd ..
```

**Примітка:** Замініть `account_id` на ваш AWS Account ID.

### 5. Деплоймент застосунку через Helm

```bash
# Встановлення Helm-чарта
helm install django-app ./charts/django-app

# Перевірка статусу
helm status django-app
kubectl get all
```

## Доступ до застосунку

```bash
# Отримання зовнішнього IP LoadBalancer
kubectl get service django-app

# Очікування (2–5 хв) на присвоєння IP
kubectl get service django-app -w

# Тестування
curl http://EXTERNAL-IP/
```

**Приклад URL:**

```
http://a3fad1ef8b2d9431188d8d8361b0d441-1126342473.eu-central-1.elb.amazonaws.com
```

## Корисні команди

### Управління Helm

```bash
# Список встановлених релізів
helm list

# Оновлення конфігурації
helm upgrade django-app ./charts/django-app

# Видалення релізу
helm uninstall django-app

# Перегляд значень
helm get values django-app
```

### Моніторинг Kubernetes

```bash
# Статус подів
kubectl get pods -o wide

# Логи Django
kubectl logs deployment/django-app

# Логи з real-time
kubectl logs -f deployment/django-app

# Статус HPA
kubectl get hpa
kubectl describe hpa django-app

# Перевірка ConfigMap
kubectl get configmap
kubectl describe configmap django-app-config

# Перевірка PVC та PV
kubectl get pvc
kubectl get pv

# Детальна інформація про поди
kubectl describe pod <pod-name>
```

### Робота з подами

```bash
# Виконання команди в поді
kubectl exec deployment/django-app -- sh -c "ls -la /app/staticfiles/"

# Інтерактивний shell в поді
kubectl exec -it deployment/django-app -- sh

# Копіювання файлів з поду
kubectl cp <pod-name>:/app/staticfiles/logo.png ./logo.png

# Перезапуск deployment
kubectl rollout restart deployment/django-app

# Статус rollout
kubectl rollout status deployment/django-app
```

## Архітектура рішення

### Мережева топологія

- **VPC**: 10.0.0.0/16
- **Публічні підмережі**: 3 AZ (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
- **Приватні підмережі**: 3 AZ (10.0.4.0/24, 10.0.5.0/24, 10.0.6.0/24)
- **NAT Gateway**: По одному в кожній AZ для приватних підмереж
- **EKS Worker Nodes**: Розташовані в приватних підмережах

### Компоненти застосунку

1. **Django App (2 pods)**

   - Обслуговує HTTP запити
   - Підключається до PostgreSQL через Service
   - Статичні файли обслуговуються через WhiteNoise
   - Init container перевіряє доступність PostgreSQL

2. **PostgreSQL (1 pod)**

   - Використовує Persistent Volume (10Gi EBS)
   - ClusterIP Service для внутрішнього доступу
   - Дані зберігаються на `/var/lib/postgresql/data`

3. **LoadBalancer Service**

   - AWS ELB для публічного доступу
   - Маршрутизація трафіку на порт 8000 Django pods
   - Health checks на `/health/` endpoint

4. **HPA (Auto-scaling)**
   - Моніторинг CPU usage
   - Автоматичне масштабування 2-6 pods
   - Target: 70% CPU utilization

**Увага:** При виконанні `terraform destroy` будуть видалені всі AWS ресурси, включаючи EKS кластер, VPC, ECR репозиторій, S3 bucket та DynamoDB таблицю.
