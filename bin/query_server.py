
import sys
import os
import json
import re
import hashlib
import random

import tornado.ioloop
import tornado.web
import tornado.httpserver

import prestoclient
import voltdbclient
import config

presto = prestoclient.PrestoClient(config.presto_server)
voltdb = voltdbclient.VoltDBClient(config.voltdb_server)

class QueryHandler(tornado.web.RequestHandler):

    def set_default_headers(self):
        self.set_header("Access-Control-Allow-Origin", "*")
        self.set_header("Access-Control-Allow-Methods", "POST,OPTIONS")
        self.set_header("Access-Control-Allow-Headers", "Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, X-Requested-By, If-Modified-Since, X-File-Name, Cache-Control")

    def post(self):

        remote_ip = self.request.remote_ip

        # check remote ip and simply block non NTU ips

        m = re.search('^140\.112\.\d+\.\d+$', remote_ip)
        if m == None:
            self.write("Not in allowed IP range.")        
        else:
            db_type = self.get_argument("db", "presto")

            if db_type == "presto":
                self.query_with_presto()
            elif db_type == "voltdb":
                self.query_with_voltdb()
            else:
                self.write("Given wrong database parameter")

    def query_with_voltdb(self):
            sql = self.get_argument("query")
            voltdb_ret = voltdb.query(sql)
            ret = {}
            if 'results' in voltdb_ret:
                if len(voltdb_ret['results']) > 0:
                    if 'schema' in voltdb_ret['results'][0]:
                        ret['Columns'] = voltdb_ret['results'][0]['schema']

                    if 'data' in voltdb_ret['results'][0]:
                        ret['Datalength'] = len(voltdb_ret['results'][0]['data'])
                        ret['Data'] = voltdb_ret['results'][0]['data']

            self.write(json.dumps(ret))
 

    def query_with_presto(self):        
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

#random.seed()
#random_api = hashlib.sha224(str(random.random())).hexdigest()
random_api = hashlib.md5(config.web_key).hexdigest()
print("Random API: ", random_api)

application = tornado.web.Application([
    (r"/" + random_api, QueryHandler),
])    

http_server = tornado.httpserver.HTTPServer(application, ssl_options={
    "certfile": "server.crt",
    "keyfile": "server.key",
})

if __name__ == "__main__":
    http_server.listen(8081)
    application.listen(8080)
    tornado.ioloop.IOLoop.instance().start()


