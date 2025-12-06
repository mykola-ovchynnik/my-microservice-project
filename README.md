# DevOps CI/CD Platform

**Повний CI/CD процес з моніторингом для Django застосунку**

## Опис проєкту

Цей проєкт реалізує повний CI/CD процес для Django застосунку з моніторингом та управлінням метриками:

- **Terraform** – управління інфраструктурою як код (IaC)
- **Jenkins** – Continuous Integration для збірки та публікації Docker образів
- **Argo CD** – Continuous Deployment з GitOps підходом
- **Kubernetes (EKS)** – платформа оркестрації контейнерів
- **Helm** – управління конфігураціями Kubernetes
- **RDS/Aurora** – керовані бази даних AWS (універсальний модуль)
- **Prometheus** – збір та зберігання метрик
- **Grafana** – візуалізація метрик та моніторинг

## Архітектура системи

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Developer │────│     Git     │────│   Jenkins   │────│     ECR     │
│   (commit)  │    │ Repository  │    │ (CI/Build)  │    │ (Registry)  │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                           │                                      │
                           │                                      │
                           ▼                                      ▼
                   ┌─────────────┐                        ┌─────────────┐
                   │   Argo CD   │◄───────────────────────│ Kubernetes  │
                   │  (GitOps)   │                        │    (EKS)    │
                   └─────────────┘                        └─────────────┘
                           │                                      │
                           │                                      │
                           ▼                                      ▼
                   ┌─────────────┐                        ┌─────────────┐
                   │ RDS/Aurora  │◄───────────────────────│   Django    │
                   │ PostgreSQL  │                        │ Application │
                   └─────────────┘                        └─────────────┘
                                                                  │
                                                                  │
                                                                  ▼
                   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
                   │ Prometheus  │────│   Grafana   │────│ Kubernetes  │
                   │ (Metrics)   │    │ (Dashboard) │    │ Monitoring  │
                   └─────────────┘    └─────────────┘    └─────────────┘
```

## Структура проєкту

```
📁 my-microservice-project
├── .gitignore
├── README.md
├── backend.tf                    # Налаштування S3 + DynamoDB бекенду
├── main.tf                       # Головний файл для підключення модулів
├── outputs.tf                    # Загальні виводи ресурсів
├── kubernetes-secrets.yaml       # Секрети для Jenkins (AWS credentials)
├── kubernetes-secrets.yaml.template
├── LICENSE
│
├── charts/                       # Django Helm Chart
│   └── django-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── configmap.yaml
│           ├── deployment.yaml
│           ├── hpa.yaml
│           └── service.yaml
│
└── modules/                      # Каталог з усіма модулями
    ├── s3-backend/               # Модуль для S3 та DynamoDB
    │   ├── s3.tf
    │   ├── dynamodb.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── vpc/                      # Модуль для VPC
    │   ├── vpc.tf
    │   ├── routes.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── ecr/                      # Модуль для ECR
    │   ├── ecr.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── eks/                      # Модуль для Kubernetes кластера
    │   ├── eks.tf
    │   ├── aws_ebs_csi_driver.tf
    │   ├── storage_class.tf
    │   ├── providers.tf
    │   ├── variables.tf
    │   └── ourputs.tf
    │
    ├── rds/                      # Універсальний модуль для RDS/Aurora
    │   ├── aurora.tf
    │   ├── rds.tf
    │   ├── shared.tf
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── jenkins/                  # Модуль для Jenkins
    │   ├── jenkins.tf
    │   ├── irsa.tf
    │   ├── rbac-secrets.tf
    │   ├── providers.tf
    │   ├── values.yaml
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── argo_cd/                  # Модуль для Argo CD
    │   ├── argo_cd.tf
    │   ├── providers.tf
    │   ├── values.yaml
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── charts/               # Helm-чарт для створення app'ів
    │       ├── Chart.yaml
    │       ├── values.yaml
    │       └── templates/
    │           ├── application.yaml
    │           └── repository.yaml
    │
    └── monitoring/               # Модуль для Prometheus + Grafana
        ├── monitoring.tf
        ├── providers.tf
        ├── variables.tf
        ├── outputs.tf
        └── values/
            ├── grafana-values.yaml
            └── prometheus-values.yaml
```

## Модуль моніторингу (Prometheus + Grafana)

### Опис модуля

Модуль `monitoring` забезпечує повне розгортання системи моніторингу:

- **Prometheus** для збору та зберігання метрик
- **Grafana** для візуалізації та створення дашбордів
- **kube-state-metrics** для метрик Kubernetes кластера
- **LoadBalancer** доступ до обох сервісів
- **Persistent Storage** для збереження даних та конфігурацій
- Попередньо налаштовані дашборди для Kubernetes
- Автоматичне виявлення та моніторинг Django, Jenkins та інших сервісів

### Використання модуля

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  namespace        = "monitoring"

  # Storage configuration
  prometheus_storage_size = "20Gi"
  grafana_storage_size    = "5Gi"

  # Grafana configuration
  grafana_admin_password = "Admin12345!!"

  depends_on = [module.eks]
}
```

### Змінні модуля моніторингу

| Змінна                    | Тип      | За замовчуванням | Опис                                   |
| ------------------------- | -------- | ---------------- | -------------------------------------- |
| `cluster_name`            | `string` | -                | **Обов'язкова**: Назва EKS кластера    |
| `cluster_endpoint`        | `string` | -                | **Обов'язкова**: Endpoint EKS кластера |
| `namespace`               | `string` | `"monitoring"`   | Kubernetes namespace для моніторингу   |
| `prometheus_storage_size` | `string` | `"20Gi"`         | Розмір сховища для Prometheus          |
| `grafana_storage_size`    | `string` | `"5Gi"`          | Розмір сховища для Grafana             |
| `grafana_admin_password`  | `string` | `"admin123"`     | Пароль адміністратора Grafana          |

### Виводи модуля моніторингу

```hcl
output "prometheus_url" {
  description = "Prometheus server URL"
  value       = "http://${LoadBalancer_hostname}"
}

output "grafana_url" {
  description = "Grafana dashboard URL"
  value       = "http://${LoadBalancer_hostname}"
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}
```

## Універсальний RDS-модуль

### Опис модуля

Модуль `rds` забезпечує універсальне розгортання керованих баз даних AWS із можливістю вибору між класичною інстанцією RDS або кластером Aurora.

Підтримуються два режими роботи:

- **RDS Instance** – створюється стандартна інстанція PostgreSQL/MySQL (`use_aurora = false`)
- **Aurora Cluster** – створюється кластер Aurora з підтримкою високої доступності (`use_aurora = true`)

### Можливості модуля

Модуль автоматично створює всі необхідні ресурси для коректної роботи бази даних:

- **DB Subnet Group** – розподіл інстанцій по приватних підмережах
- **Security Group** – керування доступом до БД
- **Parameter Group** – індивідуальні параметри конфігурації
- **KMS Keys** – шифрування даних у спокої
- **Random Password** – автоматична генерація паролів

### Приклад використання модуля

#### PostgreSQL RDS Instance (Development)

```hcl
module "rds_postgres" {
  source = "./modules/rds"

  project_name = "lesson-10"
  environment  = "dev"

  use_aurora     = false
  engine         = "postgres"
  engine_version = "16.9"
  instance_class = "db.t3.micro"

  db_name         = "djangodb"
  master_username = "djangouser"
  master_password = null  # Автогенерація паролю

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_cidr_blocks = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  multi_az                = false
  storage_encrypted       = true
  backup_retention_period = 3
  deletion_protection     = false
  skip_final_snapshot     = true

  custom_db_parameters = [
    {
      name  = "max_connections"
      value = "200"
    },
    {
      name  = "checkpoint_completion_target"
      value = "0.9"
    }
  ]

  tags = {
    Project     = "lesson-10"
    Environment = "dev"
    ManagedBy   = "terraform"
    Module      = "rds"
    Purpose     = "django-database"
  }
}
```

### Основні змінні модуля RDS

| Змінна                    | Тип            | За замовчуванням | Опис                                                            |
| ------------------------- | -------------- | ---------------- | --------------------------------------------------------------- |
| `project_name`            | `string`       | `"lesson-10"`    | Назва проєкту (префікс для ресурсів)                            |
| `environment`             | `string`       | `"dev"`          | Середовище: dev, staging, prod                                  |
| `use_aurora`              | `bool`         | `false`          | **Ключова змінна**: true → Aurora Cluster, false → RDS Instance |
| `engine`                  | `string`       | `"postgres"`     | Двигун БД: "postgres" або "mysql"                               |
| `engine_version`          | `string`       | `"16.9"`         | Версія двигуна БД                                               |
| `instance_class`          | `string`       | `"db.t3.micro"`  | Клас інстансу БД                                                |
| `db_name`                 | `string`       | `"djangodb"`     | Назва бази даних                                                |
| `master_username`         | `string`       | `"djangouser"`   | Ім'я головного користувача                                      |
| `master_password`         | `string`       | `null`           | Пароль (якщо null → автогенерація)                              |
| `vpc_id`                  | `string`       | –                | **Обов'язкова**: ID VPC                                         |
| `subnet_ids`              | `list(string)` | –                | **Обов'язкова**: список приватних підмереж                      |
| `allowed_cidr_blocks`     | `list(string)` | `[]`             | CIDR-блоки з доступом до БД                                     |
| `storage_encrypted`       | `bool`         | `true`           | Увімкнути шифрування сховища                                    |
| `backup_retention_period` | `number`       | `3`              | Період зберігання бекапів (у днях)                              |
| `deletion_protection`     | `bool`         | `false`          | Захист від видалення ресурсу                                    |
| `skip_final_snapshot`     | `bool`         | `true`           | Пропустити фінальний snapshot при видаленні                     |

## Створювана інфраструктура

### AWS Ресурси

- **Amazon EKS Cluster** – версія Kubernetes 1.32
- **EC2 Node Group** – інстанси t3.medium (2-6 нод) з автомасштабуванням
- **VPC** – з публічними (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24) та приватними підмережами (10.0.4.0/24, 10.0.5.0/24, 10.0.6.0/24)
- **Amazon ECR Repository** – для зберігання Docker-образів
- **Amazon RDS PostgreSQL** – керована база даних для Django застосунку
- **S3 Bucket** – бекенд для зберігання Terraform state (`mykolaovchynnik-terraform-state-lesson-9`)
- **DynamoDB Table** – для state locking (`terraform-locks`)
- **IAM Roles & Policies** – права доступу для всіх сервісів
- **EBS CSI Driver** – підтримка persistent volumes у Kubernetes
- **LoadBalancer Services** – для зовнішнього доступу до сервісів

### Kubernetes Ресурси

- **Jenkins** – CI-сервер із підтримкою Kaniko для збірки Docker-образів
- **Argo CD** – GitOps-підхід для автоматизованого деплойменту
- **Django Application** – розгортання застосунку з HPA автомасштабуванням (2-6 реплік)
- **Prometheus** – збір метрик з кластера, Jenkins, Django
- **Grafana** – візуалізація з попередньо налаштованими дашбордами
- **kube-state-metrics** – метрики стану Kubernetes
- **LoadBalancer Services** – зовнішній доступ до всіх сервісів
- **Persistent Volumes** – збереження даних для Jenkins, Prometheus, Grafana

## Передумови

### Встановлені інструменти

1. **AWS CLI** – з налаштованими credentials
2. **Terraform** – версія >= 1.0
3. **kubectl** – для керування Kubernetes-кластером
4. **Helm 3** – для роботи з charts
5. **Git** – для роботи з репозиторіями

### AWS Permissions

Повні права для:

- **EKS** – повний доступ
- **EC2** – повний доступ
- **IAM** – створення ролей і політик
- **S3 та DynamoDB** – повні права
- **ECR** – повний доступ
- **RDS** – повний доступ
- **ELB** – повні права (для LoadBalancers)

## Покрокова інструкція виконання фінального проєкту

### Технічні вимоги

- **Інфраструктура**: AWS з використанням Terraform
- **Компоненти**: VPC, EKS, RDS, ECR, Jenkins, Argo CD, Prometheus, Grafana

### Етапи виконання

#### 1. Підготовка середовища

**Налаштування AWS CLI:**

```bash
# Налаштуйте AWS CLI
aws configure

# Перевірте підключення
aws sts get-caller-identity
```

**Ініціалізація Terraform:**

```bash
# Клонуйте репозиторій
git clone https://github.com/mykola-ovchynnik/my-microservice-project.git
cd my-microservice-project

# Переключіться на final-project гілку
git checkout final-project

# Ініціалізуйте Terraform
terraform init

# Перевірте всі необхідні змінні та параметри
terraform validate
terraform plan
```

#### 2. Розгортання інфраструктури

**Виконати команду розгортання:**

```bash
# Розгорніть повну інфраструктуру (20-30 хвилин)
terraform apply

# Підтвердіть розгортання: yes
```

**Налаштування kubectl:**

```bash
# Налаштуйте доступ до EKS кластера
aws eks update-kubeconfig --region eu-central-1 --name lesson-9-eks-cluster

# Перевірте підключення
kubectl get nodes
```

**Перевірити стан ресурсів:**

```bash
# Перевірити Jenkins
kubectl get all -n jenkins

# Перевірити Argo CD
kubectl get all -n argocd

# Перевірити Prometheus та Grafana
kubectl get all -n monitoring

# Перевірити всі LoadBalancer сервіси
kubectl get svc --all-namespaces | grep LoadBalancer
```

#### 3. Перевірка доступності

**Рекомендований підхід - LoadBalancer URLs:**

```bash
# Отримати всі URLs сервісів
terraform output deployment_instructions

# Або окремо кожен сервіс:
echo "Jenkins: $(terraform output -raw jenkins_url)"
echo "Argo CD: $(terraform output -raw argocd_server_url)"
echo "Prometheus: $(terraform output -raw prometheus_url)"
echo "Grafana: $(terraform output -raw grafana_url)"
```

**Альтернативний підхід - Port-forwarding (якщо LoadBalancer недоступний):**

Jenkins:

```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
# Відкрийте: http://localhost:8080
```

Argo CD:

```bash
kubectl port-forward svc/argocd-server 8081:443 -n argocd
# Відкрийте: https://localhost:8081
```

Grafana:

```bash
kubectl port-forward svc/grafana 3000:80 -n monitoring
# Відкрийте: http://localhost:3000
```

Prometheus:

```bash
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
# Відкрийте: http://localhost:9090
```

#### 4. Моніторинг та перевірка метрик

**Рекомендований підхід - Grafana LoadBalancer:**

1. Відкрийте Grafana через LoadBalancer URL
2. Login: `admin` / `Admin12345!!`
3. Перевірте попередньо налаштовані дашборди:
   - **Kubernetes Overview Dashboard** (ID: 15757)
   - **Kubernetes Pods Dashboard** (ID: 15760)
   - **Prometheus Stats** (ID: 2)

**Prometheus перевірка:**

1. Відкрийте Prometheus через LoadBalancer URL
2. Перевірте метрики:
   - `up` – Статус всіх цілей моніторингу
   - `kube_node_info` – Інформація про ноди
   - `kube_pod_info` – Інформація про поди
   - `django_app` – метрики Django застосунку (якщо розгорнутий)

#### 5. Перевірка стану метрик в Grafana Dashboard

1. **Увійдіть в Grafana** з паролем `Admin12345!!`

2. **Перейдіть до Dashboards** → Browse

3. **Перевірте дашборди:**

   - **Kubernetes Overview** – загальна інформація про кластер
   - **Kubernetes Pods** – метрики подів
   - **Prometheus Stats** – статистика самого Prometheus

4. **Перевірте, що дані надходять:**
   - Графіки показують актуальні дані
   - Метрики оновлюються в реальному часі
   - Немає помилок у збору даних

## Результати розгортання

### Успішно розгорнуті компоненти

- ✅ **EKS Cluster**: Kubernetes кластер з 2 worker нодами
- ✅ **VPC**: Мережева інфраструктура з публічними та приватними підмережами
- ✅ **RDS PostgreSQL**: База даних для Django застосунків
- ✅ **ECR**: Container registry
- ✅ **Jenkins**: CI/CD платформа з LoadBalancer доступом
- ✅ **Argo CD**: GitOps deployment з web UI
- ✅ **Prometheus**: Збір та зберігання метрик з кластера
- ✅ **Grafana**: Візуалізація метрик з попередньо налаштованими дашбордами

### Доступ до сервісів

**Всі сервіси доступні через LoadBalancer URLs (рекомендовано):**

- Зовнішній доступ з будь-якого місця
- Не потребує kubectl підключення
- Професійний production-ready підхід
- Можна ділитися URL з командою

**Port-forwarding (альтернатива):**

- Локальний доступ для діагностики
- Потребує активне kubectl підключення
- Корисно для troubleshooting

## Налаштування CI/CD Pipeline

### 1. Налаштування Jenkins

**Доступ до Jenkins UI:**

```bash
# Отримати URL та credentials
terraform output jenkins_url
terraform output jenkins_admin_user
terraform output jenkins_admin_password
```

**Логін в Jenkins:**

- Username: `admin`
- Password: використайте команду `terraform output jenkins_admin_password`

**Створення Pipeline Job:**

1. New Item → Pipeline
2. Pipeline script from SCM
3. Git Repository: `https://github.com/YOUR_USERNAME/YOUR_REPO.git`
4. Branch: `final-project`
5. Script Path: `Jenkinsfile`

**Налаштування Credentials:**

- Manage Jenkins → Credentials
- Додайте GitHub token з ID: `github-token`
- AWS credentials вже налаштовані через IRSA

### 2. Налаштування Argo CD

**Доступ до Argo CD UI:**

```bash
# Отримати URL та пароль
terraform output argocd_server_url
terraform output argocd_admin_password
```

**Логін в Argo CD:**

- Username: `admin`
- Password: використайте команду `terraform output argocd_admin_password`

**Перевірка Applications:**

- Argo CD автоматично створює Application для Django
- Перевірте статус синхронізації
- Моніторинг деплойментів в real-time

### 3. Налаштування моніторингу

**Grafana Dashboard:**

```bash
# Отримати URL та пароль
terraform output grafana_url
# Password: Admin12345!!
```

**Вже налаштовані можливості:**

- Prometheus як джерело даних
- Автоматичне оновлення метрик
- 3 попередньо встановлені дашборди
- Моніторинг Django, Jenkins, Kubernetes

## Процес CI/CD

### Continuous Integration (Jenkins)

1. **Тригер**: Push у гілку `lesson-4`
2. **Збірка**: Kaniko збирає Docker-образ з Django-кодом
3. **Публікація**: Образ публікується в ECR з тегом build number
4. **Оновлення**: Jenkins оновлює `values.yaml`
5. **Commit**: Зміни комітяться назад у Git-репозиторій

### Continuous Deployment (Argo CD)

1. **Моніторинг**: Argo CD відстежує зміни
2. **Синхронізація**: Автоматично застосовує зміни в Kubernetes
3. **Деплой**: Новий Docker-образ розгортається в кластері
4. **Підключення до БД**: Django застосунок підключається до PostgreSQL
5. **Масштабування**: HPA автоматично масштабує поди за навантаженням (2-6 реплік при 70% CPU)

## Моніторинг та логування

### Перевірка статусу всіх компонентів

```bash
# Загальний статус кластера
kubectl get nodes
kubectl get pods --all-namespaces

# Статус моніторингу
kubectl get pods -n monitoring
kubectl get svc -n monitoring

# Статус CI/CD
kubectl get pods -n jenkins
kubectl get pods -n argocd

# LoadBalancer статус
kubectl get svc --all-namespaces | grep LoadBalancer
```

### Логи системи

```bash
# Jenkins logs
kubectl logs -f deployment/jenkins -n jenkins

# Argo CD logs
kubectl logs -f deployment/argocd-server -n argocd

# Prometheus logs
kubectl logs -f deployment/prometheus-server -n monitoring

# Grafana logs
kubectl logs -f deployment/grafana -n monitoring

# Django application logs (якщо розгорнутий)
kubectl logs -f deployment/django-app -n django-app
```

### Метрики та моніторинг

```bash
# Node metrics
kubectl top nodes

# Pod metrics
kubectl top pods --all-namespaces

# HPA status
kubectl get hpa -n django-app

# Prometheus targets
curl -s http://$(kubectl get svc prometheus-server -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'
```

## Робота з базою даних

### Підключення до PostgreSQL

```bash
# Отримання connection string
terraform output postgres_connection_string

# Отримання параметрів окремо
terraform output postgres_db_endpoint
terraform output postgres_db_name
terraform output postgres_db_username
terraform output postgres_db_password

# Підключення через psql
psql -h $(terraform output -raw postgres_db_endpoint | cut -d: -f1) \
     -p $(terraform output -raw postgres_db_port) \
     -U $(terraform output -raw postgres_db_username) \
     -d $(terraform output -raw postgres_db_name)
```

### Django конфігурація БД

```bash
# Створити namespace для Django
kubectl create namespace django-app

# Створити ConfigMap з налаштуваннями БД
kubectl create configmap django-db-config \
  --from-literal=DATABASE_ENGINE=django.db.backends.postgresql \
  --from-literal=DATABASE_NAME=$(terraform output -raw postgres_db_name) \
  --from-literal=DATABASE_USER=$(terraform output -raw postgres_db_username) \
  --from-literal=DATABASE_HOST=$(terraform output -raw postgres_db_endpoint | cut -d: -f1) \
  --from-literal=DATABASE_PORT=$(terraform output -raw postgres_db_port) \
  --namespace=django-app

# Створити Secret з паролем БД
kubectl create secret generic django-db-secret \
  --from-literal=DATABASE_PASSWORD="$(terraform output -raw postgres_db_password)" \
  --namespace=django-app
```

## Автоматичне масштабування

### HPA для Django застосунку

Django-застосунок налаштований з HorizontalPodAutoscaler:

- **Мінімум подів**: 2
- **Максимум подів**: 6
- **Поріг CPU**: 70%
- **Метрики**: CPU utilization

```bash
# Моніторинг автомасштабування
kubectl describe hpa django-app -n django-app

# Real-time моніторинг
watch kubectl get hpa -n django-app

# Перегляд поточних реплік
kubectl get deployment django-app -n django-app
```

### EKS Node Autoscaling

- **Мінімум нод**: 2
- **Максимум нод**: 6
- **Instance type**: t3.medium

## Безпека

### Реалізовані заходи

- ✅ **VPC Isolation**: Приватні підмережі для БД та робочих нод
- ✅ **Security Groups**: Обмежений доступ до RDS тільки з EKS підмереж
- ✅ **IRSA**: IAM Roles for Service Accounts для Jenkins ECR доступу
- ✅ **Encryption at Rest**: S3, RDS, EBS volumes
- ✅ **Secrets Management**: Kubernetes Secrets для sensitive data
- ✅ **ECR Image Scanning**: Автоматичне сканування на вразливості
- ✅ **RBAC**: Role-Based Access Control для всіх сервісів
- ✅ **Network Policies**: Ізоляція мережевого трафіку

### Рекомендації для production

1. Використовуйте AWS Secrets Manager замість Kubernetes secrets
2. Увімкніть Pod Security Standards
3. Налаштуйте Network Policies для строгої ізоляції
4. Використовуйте private ECR endpoints
5. Увімкніть RDS Multi-AZ для високої доступності
6. Налаштуйте automated backups для RDS
7. Використовуйте RDS Proxy для connection pooling
8. Увімкніть CloudTrail та GuardDuty
9. Налаштуйте AWS WAF для LoadBalancers
10. Використовуйте KMS для управління ключами шифрування

## Troubleshooting

### Jenkins не може push в ECR

```bash
# Перевірити IRSA role
kubectl describe sa jenkins-admin -n jenkins

# Перевірити IAM role
aws iam get-role --role-name lesson-9-eks-cluster-jenkins-ecr-role

# Перевірити ECR permissions
aws ecr describe-repositories --region eu-central-1
```

### Prometheus не збирає метрики

```bash
# Перевірити статус Prometheus targets
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
# Відкрийте: http://localhost:9090/targets

# Перевірити ConfigMap
kubectl get configmap prometheus-extra-config -n monitoring -o yaml

# Перевірити logs
kubectl logs -f deployment/prometheus-server -n monitoring
```

### Grafana не показує дані

```bash
# Перевірити datasource connection
kubectl exec -it deployment/grafana -n monitoring -- wget -O- http://prometheus-server.monitoring.svc.cluster.local

# Перевірити Grafana logs
kubectl logs -f deployment/grafana -n monitoring

# Перевірити що Prometheus працює
kubectl get pods -n monitoring | grep prometheus
```

### Django не може підключитися до БД

```bash
# Перевірити конфігурацію БД
kubectl get configmap django-db-config -n django-app -o yaml
kubectl get secret django-db-secret -n django-app -o yaml

# Перевірити security groups
terraform output postgres_security_group_id

# Тестувати підключення з pod
kubectl run -it --rm debug --image=postgres:16 --restart=Never -- \
  psql -h $(terraform output -raw postgres_db_endpoint | cut -d: -f1) \
       -U $(terraform output -raw postgres_db_username) \
       -d $(terraform output -raw postgres_db_name)

# Перевірити RDS статус
aws rds describe-db-instances \
  --db-instance-identifier lesson-10-dev-db \
  --region eu-central-1 \
  --query 'DBInstances[0].DBInstanceStatus'
```

## Очищення ресурсів

**ВАЖЛИВО**: Для уникнення непередбачуваних витрат завжди видаляйте ресурси після тестування.

```bash
# Видалення Helm releases (опціонально)
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring

# Видалення Terraform інфраструктури
terraform destroy

# Підтвердження: yes
```

### Швидка перевірка видалення ресурсів

```bash
# Перевірити що все видалено
echo "=== EKS Clusters ==="
aws eks list-clusters --region eu-central-1

echo "=== RDS Instances ==="
aws rds describe-db-instances --region eu-central-1 \
  --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]'

echo "=== Load Balancers ==="
aws elbv2 describe-load-balancers --region eu-central-1 \
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code]'

echo "=== NAT Gateways ==="
aws ec2 describe-nat-gateways --region eu-central-1 \
  --query 'NatGateways[?State!=`deleted`].[NatGatewayId,State]'

echo "=== S3 Buckets ==="
aws s3 ls | grep mykolaovchynnik-terraform-state
```
