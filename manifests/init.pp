# /etc/puppet/modules/presto/manafests/init.pp

class presto {

    require presto::params
    
# group { "${presto::params::hadoop_group}":
#     ensure => present,
#     gid => "800"
# }
# 
# user { "${presto::params::presto_user}":
#     ensure => present,
#     comment => "Hadoop",
#     password => "!!",
#     uid => "800",
#     gid => "800",
#     shell => "/bin/bash",
#     home => "${presto::params::presto_user_path}",
#     require => Group["hadoop"],
# }
# 
# file { "${presto::params::presto_user_path}":
#     ensure => "directory",
#     owner => "${presto::params::presto_user}",
#     group => "${presto::params::hadoop_group}",
#     alias => "${presto::params::presto_user}-home",
#     require => [ User["${presto::params::presto_user}"], Group["hadoop"] ]
# }
 
    file {"${presto::params::presto_base}":
        ensure => "directory",
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        alias => "presto-base",
    }

    file {"${presto::params::presto_conf}":
        ensure => "directory",
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        alias => "presto-conf",
        require => [File["presto-base"], Exec["untar-presto"]],
        before => [File["presto-node-properties"]]
    }
 
    file {$presto::params::presto_datapaths:
        ensure => "directory",
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        require => [File["presto-base"], Exec["untar-presto"]],
        before => [File["presto-node-properties"]]
    }
 
    exec { "download ${presto::params::presto_base}/presto-server-${presto::params::version}.tar.gz":
        command => "wget http://central.maven.org/maven2/com/facebook/presto/presto-server/${presto::params::version}/presto-server-${presto::params::version}.tar.gz",
        cwd => "${presto::params::presto_base}",
        alias => "download-presto",
        user => "${presto::params::presto_user}",
        before => Exec["untar-presto"],
        require => File["presto-base"],
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
        creates => "${presto::params::presto_base}/presto-server-${presto::params::version}.tar.gz",
    }

    file { "${presto::params::presto_base}/presto-server-${presto::params::version}.tar.gz":
        mode => 0644,
        ensure => present,
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        alias => "presto-source-tgz",
        before => Exec["untar-presto"],
        require => [File["presto-base"], Exec["download-presto"]],
    }
    
    exec { "untar presto-server-${presto::params::version}.tar.gz":
        command => "tar xfvz presto-server-${presto::params::version}.tar.gz",
        cwd => "${presto::params::presto_base}",
        creates => "${presto::params::presto_base}/presto-server-${presto::params::version}",
        alias => "untar-presto",
        onlyif => "test 0 -eq $(ls -al ${presto::params::presto_base}/presto-server-${presto::params::version} | grep -c bin)",
        user => "${presto::params::presto_user}",
        before => [ File["presto-symlink"], File["presto-app-dir"]],
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
    }

    file { "${presto::params::presto_base}/presto-server-${presto::params::version}":
        ensure => "directory",
        mode => 0644,
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        alias => "presto-app-dir",
        require => Exec["untar-presto"],
    }
        
    file { "${presto::params::presto_base}/presto":
        force => true,
        ensure => "${presto::params::presto_base}/presto-server-${presto::params::version}",
        alias => "presto-symlink",
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        require => File["presto-app-dir"],
        before => [ File["presto-conf"], File["presto-node-properties"] ]
    }
    
    file { "${presto::params::presto_conf}/node.properties":
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        mode => "644",
        alias => "presto-node-properties",
        replace => false,
        require => [ File["presto-app-dir"], File["presto-conf"] ],
        content => template("presto/node.properties.erb"),
    }

    package { "uuid":
        ensure  => installed,
        alias   => "package-uuid",
    }
 
    file { "${presto::params::presto_conf}/replace_uuid.sh":
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        mode => "744",
        alias => "presto-replace-uuid",
        require => [ File["presto-conf"], File["presto-node-properties"], Package["uuid"] ],
        source => "puppet:///modules/presto/replace_uuid.sh",
    }

    #exec { "Set machine uuid":
    #    command => "./replace_uuid.sh",
    #    cwd => "${presto::params::presto_conf}",
    #    alias   => "set-uuid",
    #    user    => "${presto::params::presto_user}",
    #    path    => ["/bin", "/usr/bin", "/usr/sbin", "${presto::params::presto_conf}"],
    #    onlyif  => "test 1 -eq $(grep -c 'ffffffff-ffff-ffff-ffff-ffffffffffff' ${presto::params::presto_conf}/node.properties)",
    #    require => [ Package["uuid"], File["presto-node-properties"], File["presto-replace-uuid"] ],
    #}
 
    exec { "Set machine uuid":
        command => 'sed -i "s/node.id=ffffffff-ffff-ffff-ffff-ffffffffffff/node.id=$(uuid)/g" node.properties',
        cwd => "${presto::params::presto_conf}",
        alias   => "set-uuid",
        user    => "${presto::params::presto_user}",
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
        onlyif  => "test 1 -eq $(grep -c 'ffffffff-ffff-ffff-ffff-ffffffffffff' ${presto::params::presto_conf}/node.properties)",
        require => [ Package["uuid"], File["presto-node-properties"] ],
    }
 
    file { "${presto::params::presto_conf}/jvm.config":
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        mode => "644",
        alias => "presto-jvm-config",
        require => [ File["presto-app-dir"], File["presto-conf"] ],
        content => template("presto/jvm.config.erb"),
    }

    if $fqdn == $presto::params::master {
 
        file { "${presto::params::presto_conf}/config.properties":
            owner => "${presto::params::presto_user}",
            group => "${presto::params::hadoop_group}",
            mode => "644",
            alias => "presto-config-properties",
            require => [ File["presto-app-dir"], File["presto-conf"] ],
            content => template("presto/config.properties.master.erb"),
        }
    }

    if member($presto::params::slaves, $fqdn) {

        file { "${presto::params::presto_conf}/config.properties":
            owner => "${presto::params::presto_user}",
            group => "${presto::params::hadoop_group}",
            mode => "644",
            alias => "presto-config-properties",
            require => [ File["presto-app-dir"], File["presto-conf"] ],
            content => template("presto/config.properties.slave.erb"),
        }
    }

    file { "${presto::params::presto_conf}/log.properties":
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        mode => "644",
        alias => "presto-log-properties",
        require => [ File["presto-app-dir"], File["presto-conf"] ],
        content => template("presto/log.properties.erb"),
    }
 
    file {"${presto::params::presto_conf}/catalog":
        ensure => "directory",
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        alias => "presto-conf-catalog",
        require => [ File["presto-app-dir"], File["presto-conf"] ],
    }
 
    file { "${presto::params::presto_conf}/catalog/jmx.properties":
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        mode => "644",
        alias => "presto-jmx-properties",
        require => [ File["presto-app-dir"], File["presto-conf"] ],
        content => template("presto/jmx.properties.erb"),
    }
 
    file { "${presto::params::presto_conf}/catalog/hive.properties":
        owner => "${presto::params::presto_user}",
        group => "${presto::params::hadoop_group}",
        mode => "644",
        alias => "presto-hive-properties",
        require => [ File["presto-app-dir"], File["presto-conf"] ],
        content => template("presto/hive.properties.erb"),
    }
 
    exec { "set presto_home":
        command => "echo 'export PRESTO_HOME=${presto::params::presto_base}/presto' >> /etc/profile.d/hadoop.sh",
        alias => "set-prestohome",
        user => "root",
        require => [File["presto-app-dir"]],
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
        onlyif => "test 0 -eq $(grep -c PRESTO_HOME /etc/profile.d/hadoop.sh)",
    }
 
    exec { "set presto path":
        command => "echo 'export PATH=\$PATH:${presto::params::presto_base}/presto/bin' >> /etc/profile.d/hadoop.sh",
        alias => "set-prestopath",
        user => "root",
        before => Exec["set-prestohome"],
        path    => ["/bin", "/usr/bin", "/usr/sbin"],
        onlyif => "test 0 -eq $(grep -c '${presto::params::presto_base}/presto/bin' /etc/profile.d/hadoop.sh)",
    }

}
