
import sys
import os
import json
import re

import tornado.ioloop
import tornado.web

import prestoclient
import config

presto = prestoclient.PrestoClient(config.presto_server)

class QueryHandler(tornado.web.RequestHandler):
    def post(self):

        remote_ip = self.request.remote_ip

        # check remote ip and simply block non NTU ips

        m = re.search('^140\.112\.\d+\.\d+$', remote_ip)
        if m == None:
            self.write("Not in allowed IP range.")        
        else:
            sql = self.get_argument("query")
            if not presto.runquery(sql):
                error = json.dumps({'Error': presto.getlasterrormessage()})
                self.write(error)
            else:
                ret = {}
                ret['Columns'] = presto.getcolumns()
                if presto.getdata():
                    ret['Datalength'] = presto.getnumberofdatarows()
                    ret['Data'] = presto.getdata()
                self.write(json.dumps(ret))


application = tornado.web.Application([
    (r"/query", QueryHandler),
])    


if __name__ == "__main__":
    application.listen(8080)
    tornado.ioloop.IOLoop.instance().start()


