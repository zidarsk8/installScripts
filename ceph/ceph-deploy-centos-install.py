from ceph_deploy.util import pkg_managers
from ceph_deploy.lib.remoto import process


def install(distro, version_kind, version, adjust_repos):
    release = distro.release
    machine = distro.machine_type

    # Even before EPEL, make sure we have `wget`
    # pkg_managers.yum(distro.conn, 'wget')

    # Get EPEL installed before we continue:
    if adjust_repos:
        install_epel(distro)
    if version_kind in ['stable', 'testing']:
        key = 'release'
    else:
        key = 'autobuild'

    if adjust_repos:
        process.run(
            distro.conn,
            [
                'rpm',
                '--import',
                '/root/ceph_centos/keys/ceph_release.key'
                #"https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/{key}.asc".format(key=key)    # replaced with offline resource
            ]
        )

        if version_kind == 'stable':
            url = 'http://ceph.com/rpm-{version}/el6/'.format(
                version=version,
                )
        elif version_kind == 'testing':
            url = 'http://ceph.com/rpm-testing/'
        elif version_kind == 'dev':
            url = 'http://gitbuilder.ceph.com/ceph-rpm-centos{release}-{machine}-basic/ref/{version}/'.format(
                release=release.split(".",1)[0],
                machine=machine,
                version=version,
                )

        process.run(
            distro.conn,
            [
                'rpm',
                '-Uvh',
                '--replacepkgs',
                '/root/ceph_centos/extra-rpm/ceph-release-1-0.el6.noarch.rpm'
                #'{url}noarch/ceph-release-1-0.el6.noarch.rpm'.format(url=url),    # replaced with offline resource
            ],
        )

    process.run(
        distro.conn,
        [   
            'rpm',
            '-Uvh',
            '--replacepkgs',
            '/root/ceph_centos/ceph-rpm/*.rpm'
            # 'yum',
            # '-y',
            # '-q',
            # '--downloadonly',
            # '--downloaddir=/tmp/ceph-rpm',
            # 'install',
            # 'ceph',
        ],
    )


def install_epel(distro):
    """
    CentOS and Scientific need the EPEL repo, otherwise Ceph cannot be
    installed.
    """
    if distro.name.lower() in ['centos', 'scientific']:
        distro.conn.logger.info('adding EPEL repository')
        if float(distro.release) >= 6:
            # process.run(    # replaced with offline resource
            #     distro.conn,
            #     ['wget', 'http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm'],
            # )
            pkg_managers.rpm(
                distro.conn,
                [
                    '--replacepkgs',
                    '/root/ceph_centos/extra-rpm/epel-release-6*.rpm',
                ],
            )
        else:
            process.run(
                distro.conn,
                ['wget', 'http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm'],
            )
            pkg_managers.rpm(
                distro.conn,
                [
                    '--replacepkgs',
                    'epel-release-5*.rpm'
                ],
            )
