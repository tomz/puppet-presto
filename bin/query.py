
import prestoclient
import config

sql = "SHOW TABLES"

# Replace localhost with ip address or dns name of the Presto server running the discovery service
presto = prestoclient.PrestoClient(config.presto_server)

if not presto.runquery(sql):
    print "Error: ", presto.getlasterrormessage()
else:
    # We're done now, so let's show the results
    print "Columns: ", presto.getcolumns()
    if presto.getdata(): print "Datalength: ", presto.getnumberofdatarows(), " Data: ", presto.getdata()

