module "bigquery" {
  source  = "terraform-google-modules/bigquery/google"
  version = "7.0.0"

  project_id  = var.gc_project_id
  dataset_id  = "${var.short_env}_data_${var.schema_name}_from_rds"
  description = "This dataset contains data imported from RDS snapshot"

  location = "US"

  access = []

  tables = [for table_name in var.tables : {
    table_id           = table_name,
    schema             = null,
    time_partitioning  = null,
    range_partitioning = null,
    clustering         = [],
    expiration_time    = null,
    labels = {
      env = var.short_env,
    },
    }
  ]
}

module "scheduled_queries" {
  source     = "terraform-google-modules/bigquery/google//modules/scheduled_queries"
  version    = "~> 7.0"
  depends_on = [module.bigquery, google_service_account.google_service_account_data_transfer_service, module.project-iam-bindings, module.bigquery_dataset-iam-bindings]

  project_id = var.gc_project_id

  queries = [for table_name in var.tables :
    {
      name           = "${var.short_env}_${var.schema_name}_${table_name}_from_s3"
      location       = "US"
      data_source_id = "amazon_s3"
      # NOTE: https://cloud.google.com/appengine/docs/flexible/python/scheduling-jobs-with-cron-yaml?hl=ja#formatting_the_schedule
      schedule               = "every day 10:00"
      destination_dataset_id = module.bigquery.bigquery_dataset.dataset_id
      disabled               = var.is_dts_scheduled_queries_disabled
      service_account_name   = google_service_account.google_service_account_data_transfer_service.email
      # NOTE: paramsの内容は下記URLのBQコマンド(CLI)のオプションを参照
      # https://cloud.google.com/bigquery/docs/s3-transfer?hl=ja#set_up_an_amazon_s3_data_transfer
      params = {
        destination_table_name_template = table_name
        data_path         = "s3://aws-rds-snapshot-import-to-gc-bigquery-with-dts-${var.short_env}/${var.db_instance_identifier}-{run_time+9h|\"%Y-%m-%d\"}/${var.schema_name}/${var.schema_name}.${table_name}/1/*.gz.parquet"
        access_key_id     = var.aws_access_key_id
        secret_access_key = var.aws_secret_access_key
        file_format       = "PARQUET"
        write_disposition = "WRITE_TRUNCATE"
      }
    }
  ]
}

resource "google_service_account" "google_service_account_data_transfer_service" {
  account_id   = "${var.short_env}-dts"
  display_name = "${var.short_env} dts"
  project      = var.gc_project_id
}

module "project-iam-bindings" {
  source     = "terraform-google-modules/iam/google//modules/projects_iam"
  depends_on = [google_service_account.google_service_account_data_transfer_service]
  projects   = [var.gc_project_id]
  mode       = "additive"

  bindings = {
    "roles/bigquery.jobUser" = [
      "serviceAccount:${google_service_account.google_service_account_data_transfer_service.email}",
    ]
  }
}

module "bigquery_dataset-iam-bindings" {
  source            = "terraform-google-modules/iam/google//modules/bigquery_datasets_iam"
  depends_on        = [module.bigquery.bigquery_dataset, google_service_account.google_service_account_data_transfer_service]
  project           = var.gc_project_id
  bigquery_datasets = [module.bigquery.bigquery_dataset.dataset_id]
  mode              = "additive"

  bindings = {
    "roles/bigquery.admin" = [
      "serviceAccount:${google_service_account.google_service_account_data_transfer_service.email}",
    ]
  }
}
