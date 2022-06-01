# Gitlab

To run docker-compose up you have to adapt `.env`

## Usage

Set the following environment variables:

### AWS - S3 Backup is not needed

```env
DOMAIN=
SMTP_PASSWORD=
```

Rename docker-compose-no-s3.yaml -> docker-compose.yaml

### AWS - S3 Backup needed

```env
DOMAIN=
SMTP_PASSWORD=
AWS_REGION=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_UPLOAD_REMOTE_DIR=
```

Rename docker-compose-s3.yaml -> docker-compose.yaml

### And then run

```sh
docker-compose up -d
```

## Gitlab Runner

If you want to add a GitLab runner, go to your Runner Configuration (/admin/runners) in Gitlab and replace the registration inside the [script](./gitlab-runner-register.sh)

Execute the script:

```sh
# Maybe you missed the right to execute it
chmod +x gitlab-runner-register.sh
# Run script
./gitlab-runner-register.sh
```

### AWS S3 Troubleshooting

If the Backups are not automatically deployed to your AWS S3, you need to manually add this to your `gitlab.rb` file like following

```rb
gitlab_rails['manage_backup_path'] = true
gitlab_rails['backup_path'] = "/var/opt/gitlab/backups"
gitlab_rails['backup_upload_connection'] = {
   'provider' => 'AWS',
   'region' => 'eu-central-1',
   'aws_access_key_id' => 'AKIA...YOUR_SECRET_ACCESS_KEY_ID',
   'aws_secret_access_key' => 'YOUR_SECRET_ACCESS_KEY',
   # # If IAM profile use is enabled, remove aws_access_key_id and aws_secret_access_key
   'use_iam_profile' => false
 }
gitlab_rails['backup_upload_remote_directory'] = 'YOUR_REMOTE_S3_DIRECTORY'
gitlab_rails['backup_multipart_chunk_size'] = 104857600
```

the `gitlab.rb` can be found on your server (after starting gitlab) under `/dodger/gitlab/data/gitlab.rb`.

After editing you need to restart the container