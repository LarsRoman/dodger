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
```

Rename docker-compose-s3.yaml -> docker-compose.yaml

And then run

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
