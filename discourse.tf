resource "aws_s3_bucket" "discourse_uploads" {
    bucket = "massgo-discourse-uploads"
    versioning { enabled = true }
    acl = "public_read"

    lifecycle_rule = {
        id = "purge-tombstone"
        prefix = "tombstone/"
        enabled = true
        expiration = { days = 30 }
    }

    logging {
        target_bucket = "${aws_s3_bucket.logs.bucket}"
        target_prefix = "buckets/discourse-uploads/"
    }
}

resource "aws_s3_bucket" "discourse_backups" {
    bucket = "massgo-discourse-backups"
    versioning { enabled = true }
    acl = "private"

    logging {
        target_bucket = "${aws_s3_bucket.logs.bucket}"
        target_prefix = "buckets/discourse-backups/"
    }
}
