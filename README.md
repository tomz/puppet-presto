
# Puppet module for deploying Presto distributed SQL engine

This puppet module is used to deploy [Presto](https://github.com/facebook/presto) on Apache Hadoop cluster. Hadoop and Hive softwares should be installed in advance. Currently it is tested with Apache Hadoop 2.2.0 and Hive 0.12.0.

## Usage

Once you installed this module by puppet command line. You can find module files under `/etc/puppet/modules/presto`. First step is to modify related parameters by changing the content of `manifests/params.pp`.

The parameters you would like to modify include:

* $version: Presto version number. The module will automatically download corresponding Presto distribution.
* $master: The hostname of Presto coordinator.
* $slaves: The hostnames of Presto workers.
* $hive_metastore: The hostname of Hive metastore thrift server.

There are also the parameters about installation path and data path of Presto, system user and group of Presto. Modify them according to your configuration.

After these parameters are done, put this module in the resource definition.

        node 'your nodes' {
            include java                                                  
            include presto::cluster                                      
        }

Currently this module would not run Presto automatically on clsuter nodes. It also doesn't help install Discovery Service but uses embeded version of it.




