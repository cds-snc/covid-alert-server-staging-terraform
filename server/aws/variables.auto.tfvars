###
# Global
###

region = "ca-central-1"
# Enable the new ARN format to propagate tags to containers (see config/terraform/aws/README.md)
billing_tag_key   = "CostCentre"
billing_tag_value = "CovidShield"

###
# AWS Cloud Watch - cloudwatch.tf
###

cloudwatch_log_group_name = "CovidShield"

###
# AWS ECS - ecs.tf
###

ecs_name        = "CovidShield"
metric_provider = "stdout"
tracer_provider = "stdout"

# Key Retrieval
ecs_key_retrieval_name = "KeyRetrieval"
# Value should come from a TF_VAR environment variable (e.g. set in a Github Secret)
# ecs_task_key_retrieval_env_hmac_key = ""
# Value should come from a TF_VAR environment variable (e.g. set in a Github Secret)
# ecs_task_key_retrieval_env_ecdsa_key = ""

# Key Submission
ecs_key_submission_name = "KeySubmission"
# Value should come from a TF_VAR environment variable (e.g. set in a Github Secret)
# Must be a string of the form <secret1>=<MMC_code>:<secret2>=<MMC_code> - https://www.mcc-mnc.com
# ecs_task_key_submission_env_key_claim_token = ""

#Autoscaling ECS

submission_autoscale_enabled = true
retrieval_autoscale_enabled  = true
min_capacity                 = 1
cpu_units                    = 512
memory                       = 1024

###
# AWS VPC - networking.tf
###

vpc_cidr_block = "10.0.0.0/16"
vpc_name       = "CovidShield"

###
# AWS RDS - rds.tf
###

rds_db_subnet_group_name = "server"

# Key Retrieval/Submission
rds_server_db_name = "server"
rds_server_db_user = "root"
# Value should come from a TF_VAR environment variable (e.g. set in a Github Secret)
# rds_server_db_password       = ""
rds_server_allocated_storage = "5"
rds_server_instance_class    = "db.t3.small"

###
# AWS Route 53 - route53.tf
###
# Value should come from a TF_VAR environment variable (e.g. set in a Github Secret)
# route53_zone_name = ""


###
# Feature Flags
###
feature_shield       = true
feature_count_alarms = true


###
# Metrics Alarms
###

diagnosis_key_total_warn     = 9000
diagnosis_key_total_critical = 13500

claimed_one_time_code_total_warn     = 3000
claimed_one_time_code_total_critical = 4500

unclaimed_one_time_code_total_warn     = 250
unclaimed_one_time_code_total_critical = 400

enable_test_tools = true

###
# Create CSV Lambda Variables
###

create_csv_tag                   = "latest"
cbs_satellite_bucket_name_prefix = "cbs-satellite-"