#!/bin/bash
{% if restic_use_zfs %}
zfs snapshot {{ restic_zfs_pool }}/{{ restic_zfs_dataset }}@{{ restic_zfs_snapshot_name }}
zfs clone {{ restic_zfs_pool }}/{{ restic_zfs_dataset }}@{{ restic_zfs_snapshot_name }} {{ restic_zfs_pool }}/{{ restic_zfs_snapshot_name }}
{% endif %}
RESTIC_REPOSITORY={{ restic_repository }}
docker run --rm \
    -v {{ restic_backup_source }}:/data \
    -v {{ restic_cache }}:/root/.cache \
    -e RESTIC_REPOSITORY=${RESTIC_REPOSITORY} \
    -e RESTIC_PASSWORD={{ restic_password }} \
    -e AWS_ACCESS_KEY_ID={{ restic_aws_access_key_id }} \
    -e AWS_SECRET_ACCESS_KEY={{ restic_aws_secret_access_key }} \
    restic/restic snapshots &>/dev/null
status=$?
echo "Check Repo status $status"

if [ $status != 0 ]; then
    echo "Restic repository '${RESTIC_REPOSITORY}' does not exists. Running restic init."
    docker run --rm \
        -v {{ restic_backup_source }}:/data \
        -v {{ restic_cache }}:/root/.cache \
        -e RESTIC_REPOSITORY=${RESTIC_REPOSITORY} \
        -e RESTIC_PASSWORD={{ restic_password }} \
        -e AWS_ACCESS_KEY_ID={{ restic_aws_access_key_id }} \
        -e AWS_SECRET_ACCESS_KEY={{ restic_aws_secret_access_key }} \
        restic/restic init

    init_status=$?
    echo "Repo init status $init_status"

    if [ $init_status != 0 ]; then
        echo "Failed to init the repository: '${RESTIC_REPOSITORY}'"
        exit 1
    fi
fi

docker run --rm \
    -v {{ restic_backup_source }}:/data \
    -v {{ restic_cache }}:/root/.cache \
    -e RESTIC_REPOSITORY=${RESTIC_REPOSITORY} \
    -e RESTIC_PASSWORD={{ restic_password }} \
    -e AWS_ACCESS_KEY_ID={{ restic_aws_access_key_id }} \
    -e AWS_SECRET_ACCESS_KEY={{ restic_aws_secret_access_key }} \
    restic/restic backup /data

{% if restic_use_zfs %}
zfs destroy {{ restic_zfs_pool }}/{{ restic_zfs_snapshot_name }}
zfs destroy {{ restic_zfs_pool }}/{{ restic_zfs_dataset }}@{{ restic_zfs_snapshot_name }}
{% endif %}
