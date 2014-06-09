# /etc/puppet/modules/presto/manifests/master.pp

class presto::cluster {

    require presto::params
    require presto
 
}
