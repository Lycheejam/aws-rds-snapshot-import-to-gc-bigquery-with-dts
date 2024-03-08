terraform {
  backend "s3" {
    bucket = "tfstate-ap-northeast-1"
    # NOTE: keyの環境名を変数化して共通化したかったがterraformの仕様でできないらしいのでハードコードでそれぞれ作ることにした。
    key     = "aws-rds-snapshot-import-to-gc-bigquery-with-dts/development/terraform.tfstate"
    region  = "ap-northeast-1"
    profile = "dev"
  }
}
