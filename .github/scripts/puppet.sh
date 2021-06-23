#!/usr/bin/env bash

if [ -z "$PLATFORM" ]; then
    echo "PLATFORM not set"
    exit 1
fi

if [ -z "$VERSION" ]; then
    echo "VERSION not set"
    exit 1
fi

if [ -z "$AGENT_TYPE" ]; then
    echo "AGENT_TYPE not set"
    exit 1
fi

if [ -z "$ACTION" ]; then
    echo "ACTION not set"
    exit 1
fi

if [ -z "$PROJECT" ]; then
    echo "PROJECT not set"
    exit 1
fi

if [ -z "$ZONE" ]; then
    echo "ZONE not set"
    exit 1
fi

if [ -z "$ADDRESS" ]; then
    echo "ADDRESS not set"
    exit 1
fi

run_puppet_linux() {
    echo "creating dir /etc/puppet/modules"
    ssh "ci@${ADDRESS}" "sudo mkdir -p /etc/puppet/modules" || return

    # single quote $(whoami) to prevent shell expansion, we want to set
    # the owner to the ci user, not the github actions user
    echo "setting perms for permissions /etc/puppet"
    ssh "ci@${ADDRESS}" 'sudo chown -R $(whoami) /etc/puppet' || return

    echo "installing dependencies with r10k"
    rsync ./Puppetfile "ci@${ADDRESS}:/etc/puppet/Puppetfile" || return
    ssh "ci@${ADDRESS}" 'cd /etc/puppet/ && r10k puppetfile install' || return

    echo "copying module to /etc/puppet/modules/cloud_ops"
    rsync -r ./* \
        "ci@${ADDRESS}:/etc/puppet/modules/cloud_ops" \
        --exclude test/ || return

    echo "copying test cases"
    rsync -r test/cases "ci@${ADDRESS}:/tmp" || return

    site_path="/tmp/cases/${PLATFORM}/${AGENT_TYPE}/${VERSION}/${ACTION}/manifests/site.pp"
    module_path="/etc/puppet/modules"

    echo "running puppet apply"
    ssh "ci@${ADDRESS}" sudo /opt/puppetlabs/bin/puppet apply --verbose --modulepath="${module_path}" "${site_path}" || return

    # exit on success
    exit 0
}

run_puppet_windows() {
    echo 'creating dir C:\ci\puppet\modules\cloud_ops'
    ssh "ci@${ADDRESS}" "md C:\\ci\\puppet\\modules\\cloud_ops" || return

    echo "installing dependencies with r10k"
    scp ./Puppetfile "ci@${ADDRESS}:C:/Users/ci/" || return
    ssh "ci@${ADDRESS}" 'r10k puppetfile install' || return

    echo "copying module and test cases to C:/ci/puppet/modules/cloud_ops/"
    scp -r ./* \
        "ci@${ADDRESS}:C:/ci/puppet/modules/cloud_ops/" || return

    site_base='C:/ci/puppet/modules/cloud_ops'
    site_path="${site_base}/test/cases/${PLATFORM}/${AGENT_TYPE}/${VERSION}/${ACTION}/manifests/site.pp"
    module_path="C:/ci/puppet/modules"

    echo "running puppet apply"
    ssh "ci@${ADDRESS}" puppet apply --verbose --modulepath="${module_path}" "${site_path}" || return

    echo "cleaning up"
    ssh "ci@${ADDRESS}" "rmdir C:\\ci /s /q" || return

    # exit on success
    exit 0
}


# Run up to 3 times, sometimes Github Actions --> GCP connections can be dropped
# causing failures unrelated to the test.
count=3
for i in $(seq ${count}); do
    echo "Puppet attempt ${i} of ${count}"

    case $PLATFORM in
    linux)
        run_puppet_linux
        ;;
    windows)
        run_puppet_windows
        ;;
    *)
        echo "unknown platform: ${PLATFORM}"
        exit 1
        ;;
    esac

    echo "Attempt failed, sleep 10 seconds before trying again"
    sleep 10
done

# Exit non zero on failure
exit 1