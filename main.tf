terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      version = "0.117.0"
    }
  }
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
  service_account_key_file = file("~/key.json")
}

// Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = var.service_account_id
  description        = "static access key for object storage"
}

// Create KMS Key
resource "yandex_kms_symmetric_key" "key-a" {
  name              = "my-encryption-key"
  description       = "Key for encrypting bucket objects"
  default_algorithm = "AES_256"
  rotation_period   = "8760h" // 1 year
}

// Use keys to create bucket with encryption
resource "yandex_storage_bucket" "test" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket     = "vmaltsev-bucket"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-a.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

// Upload an object to the bucket
resource "yandex_storage_object" "test-picture" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket     = "vmaltsev-bucket"
  key        = "picture.jpg"
  source     = var.image_path
  acl        = "public-read"
  tags = {
    test = "value"
  }
}
