# /etc/puppet/modules/presto/manafests/params.pp

class presto::params {

	include java::params

	$version = $::hostname ? {
		default			=> "0.69",
	}

 	$presto_user = $::hostname ? {
		default			=> "hduser",
	}
 
 	$hadoop_group = $::hostname ? {
		default			=> "hadoop",
	}
        
	$java_home = $::hostname ? {
		default			=> "${java::params::java_base}/jdk${java::params::java_version}",
	}

	$hadoop_base = $::hostname ? {
		default			=> "/opt/hadoop",
	}
 
	$hadoop_conf = $::hostname ? {
		default			=> "${hadoop_base}/hadoop/conf",
	}
 
	$presto_base = $::hostname ? {
		default			=> "/opt/presto",
	}
 
	$presto_conf = $::hostname ? {
		default			=> "${presto_base}/presto/etc",
	}

    $presto_datapaths = $::hostname ? {
        default         => ["/var/presto", "/var/presto/data"],
    }

    $presto_datapath = $::hostname ? {
        default         => "/var/presto/data",
    }
 
    $presto_user_path = $::hostname ? {
		default			=> "/home/${presto_user}",
	}             

    $master = $::hostname ? {
        default         => "test1.openstacklocal",
    }
 
    $slaves = $::hostname ? {
        default         => ["test2.openstacklocal", "test3.openstacklocal", "test4.openstacklocal", "test5.openstacklocal"],
    }

    $hive_metastore = $::hostname ? {
        default         => "test1.openstacklocal",
    }
 
}
