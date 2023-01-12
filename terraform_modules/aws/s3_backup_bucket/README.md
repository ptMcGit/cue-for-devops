# S3 Backup Bucket

## Overview

An S3 bucket designed to take backups.

- ACLs are applied to it to allow backup writers to write to it.
- Lifecycle rules are applied to move things to cold storage over time.
