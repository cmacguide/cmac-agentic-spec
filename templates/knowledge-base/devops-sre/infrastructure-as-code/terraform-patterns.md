# Infrastructure as Code Patterns - Terraform & Azure Bicep

Este guia apresenta padrões, boas práticas e estruturas para implementação de Infrastructure as Code usando Terraform e Azure Bicep, focando em modularidade, reutilização e manutenibilidade.

## 🎯 Choosing the Right Tool

### **Terraform**

- **Multi-cloud**: AWS, Azure, GCP, Kubernetes
- **Mature ecosystem**: Vasto provider ecosystem
- **State management**: Controle explícito do estado
- **Use case**: Ambientes multi-cloud, infraestrutura complexa

### **Azure Bicep**

- **Azure-native**: Integração nativa com ARM
- **Simplified syntax**: Mais limpo que JSON templates
- **No state management**: ARM gerencia o estado
- **Use case**: Projetos exclusivamente Azure

---

## 🏗️ Terraform Best Practices

### **Module Organization**

Structure Terraform code in reusable modules with clear boundaries:

```hcl
# ✅ Good - Organized module structure
# modules/web-service/main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Input variables with clear descriptions
variable "service_name" {
  description = "Name of the web service"
  type        = string
  validation {
    condition     = length(var.service_name) > 0
    error_message = "Service name cannot be empty."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_config" {
  description = "Configuration for EC2 instances"
  type = object({
    instance_type = string
    min_size      = number
    max_size      = number
    desired_size  = number
  })
  default = {
    instance_type = "t3.micro"
    min_size      = 1
    max_size      = 3
    desired_size  = 2
  }
}

# Local values for computed resources
locals {
  common_tags = {
    Service     = var.service_name
    Environment = var.environment
    ManagedBy   = "terraform"
    CreatedAt   = timestamp()
  }

  name_prefix = "${var.service_name}-${var.environment}"
}

# Application Load Balancer
resource "aws_lb" "web_service" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-alb"
    Type = "LoadBalancer"
  })
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web_service" {
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.web_service.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.instance_config.min_size
  max_size         = var.instance_config.max_size
  desired_capacity = var.instance_config.desired_size

  launch_template {
    id      = aws_launch_template.web_service.id
    version = "$Latest"
  }

  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup       = 300
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-instance"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Output values for other modules to use
output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.web_service.dns_name
}

output "security_group_id" {
  description = "ID of the web service security group"
  value       = aws_security_group.web_service.id
}
```

### **Environment-Specific Configuration**

Use environment-specific variable files and consistent naming:

```hcl
# environments/prod/terraform.tfvars
service_name = "user-api"
environment  = "prod"

instance_config = {
  instance_type = "t3.medium"
  min_size      = 2
  max_size      = 10
  desired_size  = 4
}

database_config = {
  instance_class    = "db.r5.large"
  allocated_storage = 100
  multi_az         = true
  backup_retention = 7
}

monitoring_config = {
  enable_detailed_monitoring = true
  log_retention_days        = 30
  alert_email              = "devops@company.com"
}

# environments/dev/terraform.tfvars
service_name = "user-api"
environment  = "dev"

instance_config = {
  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 2
  desired_size  = 1
}

database_config = {
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  multi_az         = false
  backup_retention = 1
}

monitoring_config = {
  enable_detailed_monitoring = false
  log_retention_days        = 7
  alert_email              = "dev-team@company.com"
}
```

---

## 🔐 Security and Compliance Patterns

### **Security Group Management**

Define security groups with clear, minimal permissions:

```hcl
# ✅ Good - Explicit, minimal security group rules
resource "aws_security_group" "web_service" {
  name_prefix = "${local.name_prefix}-web-"
  vpc_id      = var.vpc_id

  description = "Security group for ${var.service_name} web servers"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web-sg"
    Type = "SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Explicit ingress rules
resource "aws_security_group_rule" "web_service_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP traffic from load balancer"
  security_group_id = aws_security_group.web_service.id
}

resource "aws_security_group_rule" "web_service_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS traffic from load balancer"
  security_group_id = aws_security_group.web_service.id
}

resource "aws_security_group_rule" "web_service_ssh" {
  count             = var.environment != "prod" ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.admin_cidr_block]
  description       = "SSH access for administration (non-prod only)"
  security_group_id = aws_security_group.web_service.id
}

# Explicit egress rules
resource "aws_security_group_rule" "web_service_egress_http" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTP outbound for package updates"
  security_group_id = aws_security_group.web_service.id
}

resource "aws_security_group_rule" "web_service_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "HTTPS outbound for API calls"
  security_group_id = aws_security_group.web_service.id
}
```

### **Secrets Management**

Use proper secrets management with AWS Secrets Manager or Parameter Store:

```hcl
# ✅ Good - Secrets managed securely
resource "aws_secretsmanager_secret" "database_credentials" {
  name        = "${local.name_prefix}-db-credentials"
  description = "Database credentials for ${var.service_name}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-secret"
    Type = "DatabaseSecret"
  })
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = aws_secretsmanager_secret.database_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.database_password.result
  })
}

resource "random_password" "database_password" {
  length  = 32
  special = true
}

# IAM role for EC2 instances to access secrets
resource "aws_iam_role" "web_service_role" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "web_service_secrets_policy" {
  name = "${local.name_prefix}-secrets-policy"
  role = aws_iam_role.web_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.database_credentials.arn
      }
    ]
  })
}
```

---

## 📊 Monitoring and Observability

### **CloudWatch Alarms and Dashboards**

Set up comprehensive monitoring for your infrastructure:

```hcl
# ✅ Good - Comprehensive monitoring setup
resource "aws_cloudwatch_dashboard" "web_service" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.web_service.arn_suffix],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.web_service.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", aws_lb.web_service.arn_suffix],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.web_service.arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Load Balancer Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", aws_autoscaling_group.web_service.name],
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", aws_autoscaling_group.web_service.name],
            ["AWS/AutoScaling", "GroupTotalInstances", "AutoScalingGroupName", aws_autoscaling_group.web_service.name]
          ]
          period = 300
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "Auto Scaling Group"
        }
      }
    ]
  })
}

# High-priority alarms
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${local.name_prefix}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors high error rate on ${var.service_name}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.web_service.arn_suffix
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${local.name_prefix}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2.0"
  alarm_description   = "This metric monitors high response time on ${var.service_name}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = aws_lb.web_service.arn_suffix
  }

  tags = local.common_tags
}

# SNS topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```

---

## 🔄 State Management and Backends

### **Remote State Configuration**

Use remote state with proper locking and versioning:

```hcl
# backend.tf - Remote state configuration
terraform {
  backend "s3" {
    bucket         = "company-terraform-state"
    key            = "services/user-api/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true

    # Workspace-based state isolation
    workspace_key_prefix = "environments"
  }
}

# State bucket setup (separate configuration)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "company-terraform-state"

  tags = {
    Name        = "Terraform State"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-state-lock"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}
```

---

## 🚀 Deployment Patterns

### **Blue-Green Deployment with Terraform**

Implement blue-green deployments for zero-downtime updates:

```hcl
# ✅ Blue-Green deployment configuration
variable "active_environment" {
  description = "Active environment (blue or green)"
  type        = string
  default     = "blue"
  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "Active environment must be blue or green."
  }
}

locals {
  environments = {
    blue = {
      name           = "${local.name_prefix}-blue"
      weight         = var.active_environment == "blue" ? 100 : 0
      instance_count = var.active_environment == "blue" ? var.instance_config.desired_size : 0
    }
    green = {
      name           = "${local.name_prefix}-green"
      weight         = var.active_environment == "green" ? 100 : 0
      instance_count = var.active_environment == "green" ? var.instance_config.desired_size : 0
    }
  }
}

# Blue environment
module "blue_environment" {
  source = "./modules/environment"

  name                = local.environments.blue.name
  instance_count     = local.environments.blue.instance_count
  launch_template_id = aws_launch_template.blue.id
  target_group_arn   = aws_lb_target_group.blue.arn

  tags = merge(local.common_tags, {
    Environment = "blue"
    Active      = var.active_environment == "blue" ? "true" : "false"
  })
}

# Green environment
module "green_environment" {
  source = "./modules/environment"

  name                = local.environments.green.name
  instance_count     = local.environments.green.instance_count
  launch_template_id = aws_launch_template.green.id
  target_group_arn   = aws_lb_target_group.green.arn

  tags = merge(local.common_tags, {
    Environment = "green"
    Active      = var.active_environment == "green" ? "true" : "false"
  })
}

# Load balancer with weighted routing
resource "aws_lb_listener_rule" "blue_green_routing" {
  listener_arn = aws_lb_listener.web_service.arn
  priority     = 100

  action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.blue.arn
        weight = local.environments.blue.weight
      }
      target_group {
        arn    = aws_lb_target_group.green.arn
        weight = local.environments.green.weight
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
```

---

## ✅ Infrastructure as Code Checklist

When creating or reviewing IaC:

### **Code Organization:**

- [ ] **Modular structure** - Reusable modules with clear interfaces
- [ ] **Consistent naming** - Following team conventions
- [ ] **Variable validation** - Input validation where appropriate
- [ ] **Output values** - Useful outputs for other modules

### **Security:**

- [ ] **Least privilege** - Minimal permissions for resources
- [ ] **Secrets management** - No hardcoded secrets in code
- [ ] **Encryption** - Data encrypted at rest and in transit
- [ ] **Network segmentation** - Proper VPC and subnet design

### **Reliability:**

- [ ] **Multi-AZ deployment** - High availability configuration
- [ ] **Backup strategies** - Automated backups configured
- [ ] **Health checks** - Proper health check configuration
- [ ] **Auto-scaling** - Automatic capacity management

### **Monitoring:**

- [ ] **CloudWatch metrics** - Key metrics monitored
- [ ] **Alerting** - Critical alerts configured
- [ ] **Dashboards** - Operational visibility
- [ ] **Log aggregation** - Centralized logging

### **State Management:**

- [ ] **Remote state** - Shared state storage
- [ ] **State locking** - Prevent concurrent modifications
- [ ] **Workspace isolation** - Environment separation
- [ ] **Version control** - All IaC in version control

---

## 🅰️ Azure Bicep Patterns

### **Module Organization - Bicep**

```bicep
// modules/storage/main.bicep
@description('Storage account configuration')
param storageConfig object

@description('Environment tags')
param tags object = {}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageConfig.name
  location: storageConfig.location
  kind: 'StorageV2'
  sku: {
    name: storageConfig.skuName
  }
  properties: {
    accessTier: storageConfig.accessTier
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
  tags: tags
}

output storageAccountId string = storageAccount.id
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
```

**Uso do módulo:**

```bicep
// main.bicep
module storage '../modules/storage/main.bicep' = {
  name: 'storageDeployment'
  params: {
    storageConfig: {
      name: 'mystorageacct${uniqueString(resourceGroup().id)}'
      location: location
      skuName: 'Standard_LRS'
      accessTier: 'Hot'
    }
    tags: commonTags
  }
}
```

### **Parameter Management - Bicep**

```bicep
// parameters/prod.bicepparam
using './main.bicep'

param environmentName = 'prod'
param location = 'eastus'

param storageConfig = {
  skuName: 'Standard_GRS'
  accessTier: 'Hot'
  enableHttpsTrafficOnly: true
}

param networkConfig = {
  vnetAddressPrefix: '10.0.0.0/16'
  subnetAddressPrefix: '10.0.1.0/24'
  enableDdosProtection: true
}
```

**Template principal:**

```bicep
// main.bicep
@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environmentName string

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Storage account configuration')
param storageConfig object

@description('Network configuration')
param networkConfig object

@description('Common tags for all resources')
param tags object = {
  Environment: environmentName
  ManagedBy: 'Bicep'
  DeployedAt: utcNow()
}

// Variables for naming
var resourcePrefix = 'myapp-${environmentName}'
var storageAccountName = '${resourcePrefix}sa${uniqueString(resourceGroup().id)}'
```

### **Security Patterns - Bicep**

**Key Vault e Managed Identity:**

```bicep
// Security module
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnet.id
          ignoreMissingVnetServiceEndpoint: false
        }
      ]
    }
  }
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${resourcePrefix}'
  location: location
}

// Role assignment
resource keyVaultSecretsUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: keyVault
  name: guid(keyVault.id, managedIdentity.id, keyVaultSecretsUserRoleDefinition)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}
```

**Network Security Groups:**

```bicep
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-${resourcePrefix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 4000
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}
```

### **Monitoring e Observabilidade - Bicep**

```bicep
// Monitoring module
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appi-${resourcePrefix}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Diagnostic settings for resources
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-${resourcePrefix}'
  scope: storageAccount
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
    ]
    logs: [
      {
        category: 'StorageRead'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
    ]
  }
}
```

### **Environment Management - Bicep**

**Structure por ambiente:**

```
bicep/
├── modules/
│   ├── storage/
│   │   └── main.bicep
│   ├── networking/
│   │   └── main.bicep
│   └── monitoring/
│       └── main.bicep
├── environments/
│   ├── dev/
│   │   ├── main.bicep
│   │   └── main.bicepparam
│   ├── staging/
│   │   ├── main.bicep
│   │   └── main.bicepparam
│   └── prod/
│       ├── main.bicep
│       └── main.bicepparam
└── shared/
    └── types.bicep
```

**Template condicional:**

```bicep
// Conditional deployment based on environment
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'asp-${resourcePrefix}'
  location: location
  sku: {
    name: environmentName == 'prod' ? 'P1v3' : 'B1'
    tier: environmentName == 'prod' ? 'PremiumV3' : 'Basic'
  }
  properties: {
    reserved: true
  }
}

// Scale settings based on environment
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (environmentName == 'prod') {
  name: 'autoscale-${resourcePrefix}'
  location: location
  properties: {
    profiles: [
      {
        name: 'DefaultProfile'
        capacity: {
          minimum: '2'
          maximum: '10'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlan.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
    enabled: true
    targetResourceUri: appServicePlan.id
  }
}
```

### **Best Practices - Bicep**

**1. Naming Conventions:**

```bicep
// Use descriptive and consistent naming
param shortAppName string = 'toy'
param shortEnvironmentName string = 'prod'

// Template expressions for resource names
var resourceNames = {
  storageAccount: '${shortAppName}${shortEnvironmentName}sa${uniqueString(resourceGroup().id)}'
  keyVault: 'kv-${shortAppName}-${shortEnvironmentName}-${uniqueString(resourceGroup().id)}'
  appService: 'app-${shortAppName}-${shortEnvironmentName}'
}

// Avoid starting with numbers
var storageAccountName = 'sa${uniqueString(resourceGroup().id)}'
```

**2. Parameter Validation:**

```bicep
@minLength(3)
@maxLength(50)
@description('Application name (3-50 characters)')
param applicationName string

@allowed(['dev', 'staging', 'prod'])
@description('Environment name')
param environmentName string

@secure()
@description('Database admin password')
param sqlServerAdminPassword string

@description('Virtual machine size')
param vmSize string = 'Standard_B2s'

// Custom validation
param storageAccountType string {
  metadata: {
    description: 'Storage account type'
  }
  validation: {
    condition: contains(['Standard_LRS', 'Standard_GRS', 'Premium_LRS'], storageAccountType)
    message: 'Storage account type must be Standard_LRS, Standard_GRS, or Premium_LRS'
  }
}
```

**3. Output Management:**

```bicep
@description('Storage account resource ID')
output storageAccountId string = storageAccount.id

@description('Storage account primary endpoints')
output storageEndpoints object = storageAccount.properties.primaryEndpoints

@secure()
@description('Storage account connection string')
output storageConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'

@description('Application insights instrumentation key')
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
```

### **Deployment Patterns - Bicep**

**Azure DevOps Pipeline:**

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - bicep/

variables:
  azureServiceConnection: "azure-service-connection"
  resourceGroupName: "rg-myapp-$(environmentName)"
  location: "eastus"

stages:
  - stage: Validate
    jobs:
      - job: ValidateBicep
        steps:
          - task: AzureCLI@2
            displayName: "Validate Bicep Template"
            inputs:
              azureSubscription: $(azureServiceConnection)
              scriptType: "bash"
              scriptLocation: "inlineScript"
              inlineScript: |
                az deployment group validate \
                  --resource-group $(resourceGroupName) \
                  --template-file bicep/main.bicep \
                  --parameters @bicep/parameters/$(environmentName).bicepparam

  - stage: Deploy
    dependsOn: Validate
    condition: succeeded()
    jobs:
      - deployment: DeployInfrastructure
        environment: $(environmentName)
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureCLI@2
                  displayName: "Deploy Bicep Template"
                  inputs:
                    azureSubscription: $(azureServiceConnection)
                    scriptType: "bash"
                    scriptLocation: "inlineScript"
                    inlineScript: |
                      az deployment group create \
                        --resource-group $(resourceGroupName) \
                        --template-file bicep/main.bicep \
                        --parameters @bicep/parameters/$(environmentName).bicepparam \
                        --confirm-with-what-if
```

**GitHub Actions Workflow:**

```yaml
# .github/workflows/deploy-bicep.yml
name: Deploy Bicep Template

on:
  push:
    branches: [main]
    paths: ["bicep/**"]

env:
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        environment: [dev, staging, prod]

    steps:
      - uses: actions/checkout@v4

      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Deploy Bicep Template
        uses: azure/arm-deploy@v1
        with:
          subscriptionId: ${{ env.AZURE_SUBSCRIPTION_ID }}
          resourceGroupName: rg-myapp-${{ matrix.environment }}
          template: ./bicep/main.bicep
          parameters: ./bicep/parameters/${{ matrix.environment }}.bicepparam
          failOnStdErr: false
```

### **Bicep vs Terraform - Decision Matrix**

| Critério              | Azure Bicep                   | Terraform              |
| --------------------- | ----------------------------- | ---------------------- |
| **Provider Focus**    | Azure-native, primeira classe | Multi-cloud, agnóstico |
| **Syntax**            | Declarativo, limpo            | HCL, expressivo        |
| **State Management**  | Sem estado (ARM)              | Estado explícito       |
| **Learning Curve**    | Fácil para Azure              | Moderada               |
| **Community**         | Microsoft + comunidade        | Ampla comunidade       |
| **Tooling**           | VS Code integrado             | Múltiplas opções       |
| **Deployment**        | ARM templates                 | Terraform providers    |
| **Resource Coverage** | 100% Azure                    | Multi-provider         |

### **Migration Strategies**

**Terraform para Bicep:**

```bash
# 1. Export existing resources to Bicep
az bicep decompile --file terraform-output.json

# 2. Refactor and organize modules
# 3. Implement parameter files
# 4. Test in non-production environment
# 5. Gradual migration with state import
```

### **Checklist - Bicep Best Practices**

#### **Module Design:**

- [ ] **Single responsibility** - One module, one purpose
- [ ] **Parameter validation** - Type safety and constraints
- [ ] **Clear outputs** - Well-documented return values
- [ ] **Reusable** - Environment agnostic

#### **Security:**

- [ ] **Managed identities** - No hardcoded credentials
- [ ] **Key Vault integration** - Secure secret management
- [ ] **RBAC** - Principle of least privilege
- [ ] **Network security** - NSGs and private endpoints

#### **Monitoring:**

- [ ] **Diagnostic settings** - Centralized logging
- [ ] **Application insights** - Application monitoring
- [ ] **Alerts** - Proactive monitoring
- [ ] **Metrics** - Performance tracking

#### **Deployment:**

- [ ] **What-if analysis** - Preview changes
- [ ] **Incremental deployment** - Safe updates
- [ ] **Rollback strategy** - Recovery plan
- [ ] **Environment parity** - Consistent deployments

---

## 🔗 Related DevOps Concepts

- **Deployment Patterns**: CI/CD pipelines, rollback strategies
- **Monitoring**: Application monitoring, log aggregation
- **Reliability**: SLA/SLO management, incident response

---

_This guide focuses specifically on Infrastructure as Code patterns. For universal principles like naming and organization, see shared-principles/clean-code/_
