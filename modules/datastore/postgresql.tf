#
# Configure RDS server
#

# RDS PostgreSQL instance
resource "opentelekomcloud_rds_instance_v3" "postgres" {
  name              = "postgres-main"
  flavor            = var.flavor
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id
  availability_zone = ["${var.region}-01", "${var.region}-02"]
  ha_replication_mode = "sync"

  db {
    type     = "PostgreSQL"
    version  = "16"
    password = var.db_passwd
    port     = 5432
  }

  volume {
    type = "CLOUDSSD"
    size = 100           # GB — minimum is 40
  }

  backup_strategy {
    start_time = "02:00-03:00"   # UTC
    keep_days  = 7
  }
  tags = var.common_tags
}



