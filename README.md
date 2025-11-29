# DevOps CI/CD

**CI/CD Platform з Jenkins + Argo CD + Terraform + RDS**

## Опис проєкту

Проєкт реалізує повний CI/CD-процес для Django-застосунку з використанням сучасних DevOps-практик та інструментів:

- **Terraform** – інфраструктура як код (IaC) для створення та управління хмарними ресурсами
- **Jenkins** – система Continuous Integration для автоматизованої збірки та публікації Docker-образів
- **Argo CD** – інструмент Continuous Deployment, що забезпечує GitOps-підхід до доставки застосунку
- **Kubernetes (EKS)** – платформа оркестрації контейнерів для масштабованого розгортання
- **Helm** – управління конфігураціями Kubernetes через чарт-пакети
- **RDS/Aurora** – інтеграція з керованою базою даних AWS

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
```

## Структура проєкту

Проєкт організовано за модульним підходом: інфраструктура та сервіси винесені в окремі Terraform-модулі, а для Kubernetes-застосунків використовується Helm.

```
my-microservice-project/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів
├── outputs.tf               # Загальні виводи ресурсів
├── kubernetes-secrets.yaml  # Секрети для Jenkins (AWS credentials)
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf
│   │   ├── dynamodb.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf
│   │   ├── routes.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   ├── eks/                 # Модуль для Kubernetes кластера
│   │   ├── eks.tf
│   │   ├── aws_ebs_csi_driver.tf
│   │   ├── storage_class.tf
│   │   ├── variables.tf
│   │   ├── providers.tf
│   │   └── outputs.tf
│   │
│   ├── jenkins/             # Модуль для Jenkins
│   │   ├── jenkins.tf
│   │   ├── irsa.tf
│   │   ├── rbac-secrets.tf
│   │   ├── providers.tf
│   │   ├── variables.tf
│   │   ├── values.yaml
│   │   └── outputs.tf
│   │
│   ├── rds/                 # Універсальний модуль для RDS/Aurora
│   │   ├── aurora.tf
│   │   ├── rds.tf
│   │   ├── shared.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
│   └── argo_cd/             # Модуль для Argo CD
│       ├── argo_cd.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── values.yaml
│       ├── outputs.tf
│       └── charts/          # Helm chart для Argo CD Applications
│           ├── Chart.yaml
│           ├── values.yaml
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
│
├── charts/                  # Django Helm Chart
│   └── django-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── configmap.yaml
│           ├── hpa.yaml
│           └── _helpers.tpl
│
└── README.md               # Документація проєкту
```

## Універсальний RDS-модуль

### Опис

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

Таким чином, модуль є універсальним рішенням для швидкого й безпечного налаштування баз даних у AWS.

### Приклад використання модуля

#### PostgreSQL RDS Instance (Development)

```hcl
module "rds_postgres_dev" {
  source = "./modules/rds"

  # Основні параметри
  project_name = "lesson-10"
  environment  = "dev"

  # Тип БД – стандартний RDS Instance
  use_aurora     = false
  engine         = "postgres"
  engine_version = "16.9"
  instance_class = "db.t3.micro"

  # Конфігурація бази даних
  db_name         = "djangodb"
  master_username = "djangouser"
  master_password = null  # Автогенерація паролю

  # Мережа та доступи
  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  # Налаштування для development-середовища
  multi_az                = false
  storage_encrypted       = true
  backup_retention_period = 3
  deletion_protection     = false
  skip_final_snapshot     = true

  # Кастомні параметри PostgreSQL
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
  }
}
```

#### Aurora PostgreSQL Cluster (Production)

```hcl
module "rds_aurora_prod" {
  source = "./modules/rds"

  # Основні параметри
  project_name = "my-project"
  environment  = "prod"

  # Тип БД – Aurora Cluster
  use_aurora     = true
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.r5.large"

  # Конфігурація бази даних
  db_name         = "proddb"
  master_username = "admin"
  master_password = var.db_password  # Use secure variable

  # Мережа та доступи
  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.node_security_group_id]

  # Aurora-specific параметри
  aurora_replica_count = 2

  # Налаштування для production-середовища
  multi_az                = true
  storage_encrypted       = true
  backup_retention_period = 30
  deletion_protection     = true
  skip_final_snapshot     = false

  # Моніторинг і оптимізація
  performance_insights_enabled = true
  monitoring_interval          = 60

  # Кастомні параметри
  custom_db_parameters = [
    {
      name  = "max_connections"
      value = "1000"
    },
    {
      name  = "work_mem"
      value = "32768"  # 32MB in KB
    }
  ]

  tags = {
    Project     = "my-project"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

### Основні змінні модуля

| Змінна                       | Тип            | За замовчуванням | Опис                                                            |
| ---------------------------- | -------------- | ---------------- | --------------------------------------------------------------- |
| `project_name`               | `string`       | `"lesson-10"`    | Назва проєкту (префікс для ресурсів)                            |
| `environment`                | `string`       | `"dev"`          | Середовище: dev, staging, prod                                  |
| `use_aurora`                 | `bool`         | `false`          | **Ключова змінна**: true → Aurora Cluster, false → RDS Instance |
| `engine`                     | `string`       | `"postgres"`     | Двигун БД: "postgres" або "mysql"                               |
| `engine_version`             | `string`       | `"13.7"`         | Версія двигуна БД                                               |
| `instance_class`             | `string`       | `"db.t3.micro"`  | Клас інстансу БД                                                |
| `multi_az`                   | `bool`         | `false`          | Увімкнути Multi-AZ                                              |
| `db_name`                    | `string`       | `"djangodb"`     | Назва бази даних                                                |
| `master_username`            | `string`       | `"admin"`        | Ім'я головного користувача                                      |
| `master_password`            | `string`       | `null`           | Пароль (якщо null → автогенерація)                              |
| `vpc_id`                     | `string`       | –                | **Обов'язкова**: ID VPC                                         |
| `subnet_ids`                 | `list(string)` | –                | **Обов'язкова**: список приватних підмереж                      |
| `allowed_cidr_blocks`        | `list(string)` | `[]`             | CIDR-блоки з доступом до БД                                     |
| `allowed_security_group_ids` | `list(string)` | `[]`             | Security Group ID з доступом до БД                              |
| `storage_encrypted`          | `bool`         | `true`           | Увімкнути шифрування сховища                                    |
| `backup_retention_period`    | `number`       | `7`              | Період зберігання бекапів (у днях)                              |
| `deletion_protection`        | `bool`         | `false`          | Захист від видалення ресурсу                                    |
| `skip_final_snapshot`        | `bool`         | `true`           | Пропустити фінальний snapshot при видаленні                     |
| `custom_db_parameters`       | `list(object)` | `[]`             | Список кастомних параметрів БД                                  |

### Як змінити тип БД, engine та клас інстансу

#### 1. Зміна типу БД (RDS ↔ Aurora)

```hcl
# RDS Instance
module "my_database" {
  source     = "./modules/rds"
  use_aurora = false  # Використовувати RDS Instance
  # ...
}

# Aurora Cluster
module "my_database" {
  source     = "./modules/rds"
  use_aurora = true   # Використовувати Aurora Cluster
  # ...
}
```

#### 2. Зміна engine (PostgreSQL ↔ MySQL)

```hcl
# PostgreSQL RDS
module "my_database" {
  source         = "./modules/rds"
  engine         = "postgres"
  engine_version = "16.9"
  # ...
}

# MySQL RDS
module "my_database" {
  source         = "./modules/rds"
  engine         = "mysql"
  engine_version = "8.0.35"
  # ...
}
```

#### 3. Зміна класу інстансу

```hcl
# Development (мінімальні витрати)
instance_class = "db.t3.micro"    # 2 vCPU, 1 GB RAM

# Staging (баланс ціна/продуктивність)
instance_class = "db.t3.medium"   # 2 vCPU, 4 GB RAM

# Production (висока продуктивність)
instance_class = "db.r5.xlarge"   # 4 vCPU, 32 GB RAM
```

## Створювана інфраструктура

Інфраструктура будується повністю автоматизовано за допомогою Terraform і включає як хмарні ресурси AWS, так і сервіси в Kubernetes-кластері.

### AWS Ресурси

- **Amazon EKS Cluster** (версія Kubernetes 1.32)
- **EC2 Node Group** – інстанси t3.medium, автоматичне масштабування (2–6 нод)
- **VPC** – з публічними та приватними підмережами
- **Amazon ECR Repository** – для зберігання Docker-образів
- **Amazon RDS / Aurora PostgreSQL** – керована база даних для Django-застосунку
- **S3 Bucket** – бекенд для зберігання Terraform state
- **DynamoDB Table** – використовується для state locking
- **IAM Roles & Policies** – права доступу для всіх сервісів
- **EBS CSI Driver** – підтримка persistent volumes у Kubernetes

### Kubernetes Ресурси

- **Jenkins** – CI-сервер із підтримкою Kaniko для збірки Docker-образів
- **Argo CD** – GitOps-підхід для автоматизованого деплойменту
- **Django Application** – розгортання застосунку з autoscaling (HPA)
- **LoadBalancer Services** – зовнішній доступ до застосунків
- **Persistent Volumes** – збереження даних Jenkins

## Передумови

Перед запуском необхідно встановити та налаштувати інструменти, а також мати відповідні AWS-права доступу.

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

## Покрокове розгортання

**Крок 1: Підготовка AWS Credentials**

```bash
# Налаштуйте AWS CLI
aws configure

# Отримайте ваш AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"
```

**Крок 2: Підготовка секретів**

```bash
# Кодування AWS credentials в base64
echo -n "YOUR_AWS_ACCESS_KEY_ID" | base64
echo -n "YOUR_AWS_SECRET_ACCESS_KEY" | base64

# Створіть GitHub Personal Access Token і закодуйте
echo -n "YOUR_GITHUB_TOKEN" | base64
```

- Оновіть файл `kubernetes-secrets.yaml` вашими закодованими значеннями:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: jenkins
type: Opaque
data:
  aws-access-key-id: <BASE64_ENCODED_ACCESS_KEY>
  aws-secret-access-key: <BASE64_ENCODED_SECRET_KEY>
---
apiVersion: v1
kind: Secret
metadata:
  name: github-token
  namespace: jenkins
type: Opaque
data:
  token: <BASE64_ENCODED_GITHUB_TOKEN>
```

**Крок 3: Розгортання інфраструктури**

```bash
# Ініціалізація Terraform
terraform init

# Перегляд планованих змін
terraform plan

# Розгортання інфраструктури
terraform apply
```

**Крок 4: Налаштування kubectl**

```bash
# Налаштування доступу до EKS кластера
aws eks update-kubeconfig --region eu-central-1 --name lesson-9-eks-cluster

# Перевірка підключення
kubectl get nodes
kubectl get namespaces
```

**Крок 5: Застосування секретів**

```bash
# Застосування AWS credentials та GitHub token
kubectl apply -f kubernetes-secrets.yaml

# Перевірка створення секретів
kubectl get secrets -n jenkins
```

**Крок 6: Налаштування Django для роботи з базою даних**

```bash
# Отримання конфігурації БД для Django
terraform output django_database_config

# Створення Kubernetes ConfigMap для Django
kubectl create configmap django-db-config \
  --from-literal=DATABASE_ENGINE=django.db.backends.postgresql \
  --from-literal=DATABASE_NAME=$(terraform output -raw db_name) \
  --from-literal=DATABASE_USER=$(terraform output -raw db_username) \
  --from-literal=DATABASE_HOST=$(terraform output -raw db_endpoint | cut -d: -f1) \
  --from-literal=DATABASE_PORT=$(terraform output -raw db_port) \
  --namespace=django-app

# Створення Kubernetes Secret з паролем БД
kubectl create secret generic django-db-secret \
  --from-literal=DATABASE_PASSWORD="$(terraform output -raw master_password)" \
  --namespace=django-app
```

**Крок 7: Доступ до сервісів**

```bash
# Отримання URLs та паролів
terraform output deployment_instructions

# Отримання паролів окремо
terraform output jenkins_admin_password
terraform output argocd_admin_password
terraform output master_password
```

## Налаштування CI/CD Pipeline

### 1. Налаштування Jenkins

**Доступ до Jenkins UI:**

```bash
# Отримати URL Jenkins
terraform output jenkins_url
```

**Логін в Jenkins:**

- Username: admin
- Password: `terraform output jenkins_admin_password`

**Створення Pipeline Job:**

- New Item → Pipeline
- Pipeline script from SCM
- Git Repository: https://github.com/YOUR_USERNAME/YOUR_REPO.git
- Branch: lesson-8-9
- Script Path: Jenkinsfile

**Налаштування Credentials:**

- Manage Jenkins → Credentials
- Додайте GitHub token з ID: github-token

### 2. Налаштування Argo CD

**Доступ до Argo CD UI:**

```bash
# Отримати URL Argo CD
terraform output argocd_server_url
```

**Логін в Argo CD:**

- Username: admin
- Password: `terraform output argocd_admin_password`

**Перевірка Applications:**

- Argo CD автоматично створить Application для Django
- Перевірте статус синхронізації

## Процес CI/CD

### Continuous Integration (Jenkins)

- **Тригер**: Push у гілку lesson-8-9
- **Збірка**: Kaniko збирає Docker-образ з Django-кодом
- **Публікація**: Образ публікується в ECR з тегом build number
- **Оновлення**: Jenkins оновлює values.yaml у гілці infra-repo
- **Commit**: Зміни комітяться назад у Git-репозиторій

### Continuous Deployment (Argo CD)

- **Моніторинг**: Argo CD відстежує зміни в гілці infra-repo
- **Синхронізація**: Автоматично застосовує зміни в Kubernetes
- **Деплой**: Новий Docker-образ розгортається в кластері
- **Підключення до БД**: Django застосунок підключається до PostgreSQL/Aurora
- **Масштабування**: HPA автоматично масштабує поди за навантаженням

## Робота з базою даних

### Підключення до PostgreSQL

```bash
# Отримання connection string
terraform output connection_string

# Підключення через psql
psql "$(terraform output -raw connection_string)"

# Або окремими параметрами
psql -h $(terraform output -raw db_endpoint | cut -d: -f1) \
     -p $(terraform output -raw db_port) \
     -U $(terraform output -raw db_username) \
     -d $(terraform output -raw db_name)
```

### Django міграції

```bash
# В Django контейнері виконайте
python manage.py migrate
python manage.py createsuperuser
```

## Моніторинг та логування

### Перевірка статусу

```bash
# Jenkins pods
kubectl get pods -n jenkins

# Argo CD pods
kubectl get pods -n argocd

# Django application
kubectl get pods -n django-app

# Перевірка підключення до БД
kubectl logs -f deployment/django-app -n django-app | grep -i database

# Services та їх external IPs
kubectl get services --all-namespaces
```

### Логи

```bash
# Jenkins logs
kubectl logs -f deployment/jenkins -n jenkins

# Argo CD logs
kubectl logs -f deployment/argocd-server -n argocd

# Django application logs
kubectl logs -f deployment/django-app -n django-app
```

### Моніторинг бази даних

```bash
# PostgreSQL статус
aws rds describe-db-instances --db-instance-identifier lesson-10-dev-db --region eu-central-1

# CloudWatch метрики
aws logs describe-log-groups --log-group-name-prefix "/aws/rds/instance/lesson-10-dev-db" --region eu-central-1

# Performance Insights (якщо увімкнено)
aws pi get-resource-metrics --service-type RDS --identifier db-XXX --region eu-central-1
```

### Метрики

```bash
# Node metrics
kubectl top nodes

# Pod metrics
kubectl top pods --all-namespaces

# HPA status
kubectl get hpa -n django-app

# Database connections in Django
kubectl exec -it deployment/django-app -n django-app -- python manage.py dbshell --command="SELECT count(*) FROM pg_stat_activity;"
```

## Автоматичне масштабування

Django-застосунок налаштований з HorizontalPodAutoscaler:

- Мінімум подів: 2
- Максимум подів: 6
- Поріг CPU: 70%
- Метрики: CPU utilization

```bash
# Моніторинг автомасштабування
kubectl describe hpa django-app -n django-app
watch kubectl get hpa -n django-app
```

## Безпека

### Реалізовані заходи:

- **RBAC**: Роль-базований контроль доступу для всіх сервісів
- **Service Accounts**: Окремі service accounts для Jenkins та Argo CD
- **Secrets Management**: AWS credentials та GitHub tokens в Kubernetes secrets
- **Database Security**: RDS в приватних підмережах, Security Groups, шифрування
- **Network Policies**: Ізоляція мережевого трафіку
- **Image Scanning**: ECR автоматично сканує образи на вразливості

### Рекомендації для production:

- Використовуйте AWS Secrets Manager замість Kubernetes secrets
- Увімкніть Pod Security Standards
- Налаштуйте Network Policies для строгої ізоляції
- Використовуйте private ECR endpoints
- Увімкніть RDS encryption at rest та in transit
- Налаштуйте RDS backup та point-in-time recovery
- Використовуйте RDS Proxy для connection pooling

## Troubleshooting

### Django не може підключитися до БД

```bash
# Перевірити конфігурацію БД
kubectl get configmap django-db-config -n django-app -o yaml
kubectl get secret django-db-secret -n django-app -o yaml

# Перевірити security groups
terraform output security_group_id

# Тестувати підключення з pods
kubectl exec -it deployment/django-app -n django-app -- python manage.py dbshell

# Перевірити RDS статус
aws rds describe-db-instances --db-instance-identifier lesson-10-dev-db --region eu-central-1 --query 'DBInstances[0].DBInstanceStatus'
```

### RDS Parameter Group помилки

```bash
# Перевірити існуючі parameter groups
aws rds describe-db-parameter-groups --region eu-central-1

# Видалити конфліктний parameter group
aws rds delete-db-parameter-group --db-parameter-group-name lesson-10-dev-db-params --region eu-central-1

# Імпортувати існуючий в Terraform state
terraform import module.rds_postgres.aws_db_parameter_group.main[0] lesson-10-dev-db-params
```

### Відновлення БД з backup

```bash
# Список доступних snapshots
aws rds describe-db-snapshots --db-instance-identifier lesson-10-dev-db --region eu-central-1

# Відновлення з автоматичного backup
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier lesson-10-dev-db-restored \
  --db-snapshot-identifier rds:lesson-10-dev-db-2025-01-18-03-00 \
  --region eu-central-1

# Point-in-time recovery
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier lesson-10-dev-db \
  --target-db-instance-identifier lesson-10-dev-db-restored \
  --restore-time 2025-01-18T10:00:00.000Z \
  --region eu-central-1
```

## Очищення ресурсів

**ВАЖЛИВО**: Для уникнення непередбачуваних витрат завжди видаляйте ресурси після тестування.

```bash
# Видалення Helm releases
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
helm uninstall django-app -n django-app

# Видалення Terraform інфраструктури
terraform destroy

# Форсоване видалення RDS (якщо Terraform destroy не спрацював)
aws rds delete-db-instance --db-instance-identifier lesson-10-dev-db --skip-final-snapshot --region eu-central-1

# Видалення Aurora cluster
aws rds delete-db-cluster --db-cluster-identifier lesson-10-dev-aurora-cluster --skip-final-snapshot --region eu-central-1

# Підтвердження видалення в AWS Console
# Перевірити: EKS, EC2, LoadBalancers, NAT Gateways, RDS
```

### Швидка перевірка видалення ресурсів

```bash
# Перевірити що все видалено
echo "=== EKS Clusters ==="
aws eks list-clusters --region eu-central-1

echo "=== RDS Instances ==="
aws rds describe-db-instances --region eu-central-1 --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus]'

echo "=== Aurora Clusters ==="
aws rds describe-db-clusters --region eu-central-1 --query 'DBClusters[*].[DBClusterIdentifier,Status]'

echo "=== Load Balancers ==="
aws elbv2 describe-load-balancers --region eu-central-1 --query 'LoadBalancers[*].[LoadBalancerName,State.Code]'

echo "=== NAT Gateways ==="
aws ec2 describe-nat-gateways --region eu-central-1 --query 'NatGateways[?State!=`deleted`].[NatGatewayId,State]'
```
