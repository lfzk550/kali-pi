#!/bin/bash

if [ ! -d "/mnt/workspace" ] && [ -z "${S3_BUCKET}" ] && [ -z "${WEBDAV_URL}" ]; then
    exit 1
fi

echo "启动 Pi 配置实时备份服务"

while true; do
    inotifywait -r -e modify,create,delete,move --fromfile "/bz/watch.txt" --exclude '(^|/)(\.git|\.venv|venv)(/|$)'
    if [ -n "${S3_BUCKET}" ]; then
        sleep 6
        rclone sync /root/ /tmp/root/ \
            --filter-from /bz/rules.txt --delete-excluded \
            --create-empty-src-dirs --links --ignore-errors --metadata
        if [ -n "${BACKUP_ENC_PASS}" ]; then
            tar -zcPf - /tmp/root | gpg --batch --yes --passphrase "$BACKUP_ENC_PASS" --symmetric --cipher-algo AES256 -o /tmp/data.tar.gz
        else
            tar -zcPf /tmp/data.tar.gz /tmp/root
        fi
        rclone copyto /tmp/data.tar.gz ":s3:${S3_BUCKET}/${S3_BACKUP_PATH:-backups/data_pi.tar.gz}" \
            --s3-provider Other \
            --s3-access-key-id "${S3_KEY_ID}" \
            --s3-secret-access-key "${S3_ACCESS_KEY}" \
            --s3-endpoint "${S3_ENDPOINT:-https://s3.cstcloud.cn}" \
            --links --ignore-errors --metadata
    elif [ -n "${WEBDAV_URL}" ]; then
        if [ -z "${WEBDAV_PASSWD_MASK}" ]; then
            WEBDAV_PASSWD_MASK=$(rclone obscure "${WEBDAV_PASSWD}")
        fi
        sleep 6
        rclone sync /root/ /tmp/root/ \
            --filter-from /bz/rules.txt --delete-excluded \
            --create-empty-src-dirs --links --ignore-errors --metadata
        if [ -n "${BACKUP_ENC_PASS}" ]; then
            tar -zcPf - /tmp/root | gpg --batch --yes --passphrase "$BACKUP_ENC_PASS" --symmetric --cipher-algo AES256 -o /tmp/data.tar.gz
        else
            tar -zcPf /tmp/data.tar.gz /tmp/root
        fi
        rclone copyto /tmp/data.tar.gz ":webdav:/${WEBDAV_BACKUP_PATH:-backups/data_pi.tar.gz}" \
            --webdav-vendor other \
            --webdav-url "${WEBDAV_URL}" \
            --webdav-user "${WEBDAV_USER}" \
            --webdav-pass "${WEBDAV_PASSWD_MASK}" \
            --header "User-Agent: ${WEBDAV_CLIENT_UA:-Zotero/8.0}" \
            --links --ignore-errors --metadata
    else
        sleep 1
        rclone sync /root/ /mnt/workspace/root/ \
            --filter-from /bz/rules.txt --delete-excluded \
            --create-empty-src-dirs --links --ignore-errors --metadata
    fi
done
