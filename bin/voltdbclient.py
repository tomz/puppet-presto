import urllib
import urllib2
import json

class VoltDBClient:

    def __init__(self, server_url):
        self.server_url = server_url

    def query(self, sql):

        # Construct the procedure name, parameter list, and URL.
        voltparams = json.dumps([sql])
        httpparams = urllib.urlencode({
            'Procedure': '@AdHoc',
            'Parameters' : voltparams
        })

        # Execute the request
        data = urllib2.urlopen(self.server_url, httpparams).read()
        
        # Decode the results
        result = json.loads(data)

        # retrieved data in result['results'][0]['data']
        
        return result

