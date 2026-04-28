#
# Persistent data for Wordpress
#
# Ideally, we would like to have used SFS GPFS as this is
# redundant across multiple AZs.  We are using SFS Turbo Standard
# on a single AZ, and we rely on CBR (which would allow us 1 Hour RPO)
# for DR.
#

resource "opentelekomcloud_sfs_turbo_share_v1" "wordpress_sfs" {
  name              = "sfs-wordpress"
  size              = 500
  share_proto       = "NFS"
  share_type        = "STANDARD"
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  security_group_id = var.security_group_id
  availability_zone = "${var.region}-02"  # Hard coding to AZ2 for the moment
}

resource "opentelekomcloud_cbr_policy_v3" "wordpress_backup_policy" {
  name           = "backup-policy-wordpress"
  operation_type = "backup"

  # Trigger every hour (00 to 23)
  trigger_pattern = [
    # "FREQ=DAILY;BYHOUR=00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23;BYMINUTE=00"]
    # "FREQ=DAILY;BYHOUR=01;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=00;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=01;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=02;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=03;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=04;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=05;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=06;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=07;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=08;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=09;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=10;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=11;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=12;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=13;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=14;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=15;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=16;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=17;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=18;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=19;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=20;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=21;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=22;BYMINUTE=00",
    "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR,SA,SU;BYHOUR=23;BYMINUTE=00",
  ]
  operation_definition {
    # 1. Total rolling backups to keep (e.g., 24 for the last 24 hours)
    max_backups = 24

    # 2. Long-term daily retention
    # This keeps the last backup of the day for 3 days
    day_backups = 3

    timezone = "UTC+01:00"
  }
}

resource "opentelekomcloud_cbr_vault_v3" "wordpress_cbr" {
  name = "vault-wordpress"

  billing {
    size          = 1000        # Capacity in GB (must be >= SFS Turbo size)
    object_type   = "turbo"    # CRITICAL: Must be 'turbo' for SFS
    protect_type  = "backup"
    charging_mode = "post_paid"
  }

  # Associate your existing SFS Turbo resource
  resource {
    id   = opentelekomcloud_sfs_turbo_share_v1.wordpress_sfs.id
    type = "OS::Sfs::Turbo"
    name = "wordpress-backup-link"
  }

  # Attach the policy created in step 1
  policy {
    id = opentelekomcloud_cbr_policy_v3.wordpress_backup_policy.id
  }
  tags = var.common_tags

}
