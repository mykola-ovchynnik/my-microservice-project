# Lesson 7 - Django Microservice with Kubernetes and Helm

Проєкт демонструє розгортання Django мікросервісу в Kubernetes кластері з використанням Helm чартів та автоматичного масштабування.

## Архітектура проєкту

### Інфраструктура (Terraform)
- **EKS кластер** - Kubernetes кластер на AWS
- **ECR репозиторій** - для зберігання Docker образів
- **VPC з підмережами** - мережева інфраструктура
- **S3 Backend** - для зберігання Terraform state

### Додаток (Django + PostgreSQL)
- **Django застосунок** - веб-додаток з PostgreSQL базою даних
- **PostgreSQL** - база даних в окремому deployment
- **Nginx** - веб-сервер (включений в Docker образ)
- **LoadBalancer** - AWS ELB для публічного доступу

### Автоматизація (Helm + HPA)
- **Helm чарт** - для розгортання всіх компонентів
- **HPA (Horizontal Pod Autoscaler)** - автоматичне масштабування 2-6 подів при CPU > 70%
- **ConfigMap** - для конфігурації середовища

## Компоненти проєкту

### 1. Django Application (`app/django/`)
- Django веб-додаток з PostgreSQL
- Docker образ з Nginx та Django
- Налаштування для Kubernetes через змінні середовища

### 2. Helm Chart (`charts/django-chart/`)
- **Deployment** - Django та PostgreSQL подів
- **Service** - LoadBalancer для Django, ClusterIP для PostgreSQL
- **HPA** - автоматичне масштабування
- **ConfigMap** - конфігурація середовища

### 3. Terraform Infrastructure (`modules/`)
- **EKS Module** - Kubernetes кластер
- **ECR Module** - репозиторій для Docker образів
- **VPC Module** - мережева інфраструктура
- **S3 Backend Module** - зберігання state файлів

## Команди для роботи з проєктом

### 1. Підготовка середовища
```bash
# Встановлення необхідних інструментів
# AWS CLI, kubectl, Helm, Docker, Terraform

# Налаштування AWS credentials
aws configure

# Перевірка підключення до AWS
aws sts get-caller-identity
```

### 2. Розгортання інфраструктури (Terraform)
```bash
# Ініціалізація Terraform
terraform init

# Перегляд плану
terraform plan

# Застосування змін
terraform apply

# Отримання вихідних даних
terraform output
```

### 3. Налаштування kubectl для EKS
```bash
# Отримання конфігурації кластера
aws eks update-kubeconfig --region eu-central-1 --name <cluster-name>

# Перевірка підключення
kubectl cluster-info
kubectl get nodes
```

### 4. Підготовка Docker образу
```bash
# Перехід в директорію додатку
cd app

# Створення .env на основі прикладу
cp .env.example .env
# Відредагуйте .env та додайте свої значення (наприклад, пароль та ALLOWED_HOSTS для production)

# Збірка образу з --no-cache
docker build --no-cache -t django-app ./django

# Тестування локально
docker run -d --name django-app-test -p 8000:8000 --env-file .env django-app
```

### 5. Завантаження образу в ECR
```bash
# Отримання URL для ECR
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-central-1.amazonaws.com

# Тегування образу для ECR
docker tag django-app:latest <account-id>.dkr.ecr.eu-central-1.amazonaws.com/lesson-7-ecr:latest

# Завантаження в ECR
docker push <account-id>.dkr.ecr.eu-central-1.amazonaws.com/lesson-7-ecr:latest
```

### 6. Оновлення Helm values.yaml
```bash
# Оновлення репозиторію образу в charts/django-chart/values.yaml
# Замініть <account-id> на ваш AWS Account ID
image:
  repository: <account-id>.dkr.ecr.eu-central-1.amazonaws.com/lesson-7-ecr
  tag: latest
```

### 7. Розгортання в Kubernetes (Helm)
```bash
# Повернення в кореневу директорію
cd ..

# Встановлення Helm чарту
helm install my-app ./charts/django-chart

# Оновлення конфігурації
helm upgrade my-app ./charts/django-chart

# Перегляд статусу
kubectl get all
kubectl get hpa
```

### 8. Отримання LoadBalancer URL та оновлення ALLOWED_HOSTS
```bash
# Отримання ELB URL
kubectl get svc my-app-django

# Оновлення ALLOWED_HOSTS в values.yaml з отриманим ELB domain
# Потім оновлення Helm release
helm upgrade my-app ./charts/django-chart
```

### 9. Перевірка роботи
```bash
# Статус подів
kubectl get pods

# Перевірка всіх ресурсів
kubectl get all

# Логи Django
kubectl logs my-app-django-<pod-name>

# Доступ до додатку
kubectl get svc my-app-django

# Тестування додатку
curl http://<elb-domain>

# Перевірка HPA
kubectl get hpa
kubectl describe hpa my-app-django-hpa

# Перевірка ConfigMap
kubectl get configmap my-app-config -o yaml
```

### 10. Тестування масштабування
```bash
# Створення навантаження для тестування HPA
kubectl run load-generator --image=busybox --rm -it --restart=Never -- sh -c "while true; do wget -qO- http://my-app-django; sleep 0.1; done"

# Моніторинг масштабування
kubectl get hpa -w
```

## Конфігурація

### Environment Variables (ConfigMap)
```yaml
config:
  POSTGRES_HOST: my-app-postgres
  POSTGRES_PORT: "5432"
  POSTGRES_USER: django_user
  POSTGRES_DB: django_db
  POSTGRES_PASSWORD: pass9764gd
  ALLOWED_HOSTS: "<your-elb-domain>"
```

### HPA Configuration
- **Мінімум подів:** 2
- **Максимум подів:** 6
- **CPU поріг:** 70%
- **Тип метрики:** CPU Utilization

### Resource Limits
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Структура проєкту

```
my-microservice-project/
├── app/
│   ├── django/                 # Django додаток
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── my_app/
│   ├── nginx/                  # Nginx конфігурація
│   └── docker-compose.yml
├── charts/
│   └── django-chart/           # Helm чарт
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── hpa.yaml
│       │   ├── configmap.yaml
│       │   ├── postgres-deployment.yaml
│       │   └── postgres-service.yaml
│       ├── Chart.yaml
│       └── values.yaml
├── modules/                    # Terraform модулі
│   ├── eks/
│   ├── ecr/
│   ├── vpc/
│   └── s3-backend/
├── main.tf
├── backend.tf
└── outputs.tf
```

## Вимоги

### Програмне забезпечення
- Terraform >= 1.0
- AWS CLI
- kubectl
- Helm >= 3.0
- Docker

### AWS Ресурси
- EKS кластер (t3.medium nodes, min 2 nodes)
- ECR репозиторій
- VPC з підмережами
- S3 бакет для state
- DynamoDB таблиця для блокування

## Безпека

- **Шифрування** - всі ресурси мають шифрування
- **Приватні підмережі** - для баз даних
- **Security Groups** - налаштовані для EKS
- **IAM ролі** - мінімальні права доступу
- **Secrets** - паролі в ConfigMap (для production використовуйте Kubernetes Secrets)

## Моніторинг та масштабування

### HPA (Horizontal Pod Autoscaler)
- Автоматичне масштабування на основі CPU використання
- Мінімум 2 подів для високої доступності
- Максимум 6 подів для обмеження ресурсів

### LoadBalancer
- AWS ELB для публічного доступу
- Автоматичне розподілення навантаження між подами
- Health checks для перевірки доступності

## Troubleshooting

### Проблеми з підключенням до бази даних
```bash
# Перевірка статусу PostgreSQL
kubectl get pods -l app=my-app-postgres

# Логи PostgreSQL
kubectl logs my-app-postgres-<pod-name>

# Перевірка ConfigMap
kubectl get configmap my-app-config -o yaml
```

### Проблеми з HPA
```bash
# Статус HPA
kubectl get hpa

# Детальна інформація
kubectl describe hpa my-app-django-hpa
```

### Проблеми з LoadBalancer
```bash
# Перевірка сервісів
kubectl get svc

# Тестування з'єднання
curl http://<elb-domain>
```

