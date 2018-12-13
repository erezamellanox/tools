#!/usr/bin/env python


import sys
import time
import logging
from Host import Host
from argparse import ArgumentParser

LOGGING_LEVELS = {
                    'info' : logging.INFO,
                    'debug' : logging.DEBUG
        }

APPS = {
        'rdma'      : ["rdma_server",       "rdma_client -s %s"],
        'rping'     : ["rping -s -C %d",    "rping -C %d -ca %s"],
        'ucmatose'  : ["ucmatose -C %d",    "ucmatose -C %d -s %s"],
#        'udaddy'    : ["udaddy -C %d",      "udaddy -C %d -s %s"],
        'mckey'     : ["mckey -m 224.0.0.10 -C %d -b %s",
                                    "mckey -m 224.0.0.10 -C %d -b %s -s"],
        }

class RDMACM(object):

    def GetLogger(self):
        if not hasattr(self, "logger"):
            logging.basicConfig(level=LOGGING_LEVELS[self.verbose])
            self.logger = logging.getLogger(self.__class__.__name__)
        return self.logger

    def GetParser(self):
        if not hasattr(self, "parser"):
            self.parser = ArgumentParser()
        return self.parser


    def ParseArgs(self, args):
        self.Parser.add_argument("-v", "--verbose", help="Verbosity level",
            default="info", choices=["info", "debug"])
        self.Parser.add_argument("-n", "--num_pkts", help="Num packets",
            type=int, default=10)
        self.Parser.add_argument("-s", "--server", help="Server IP address",
            required=True)
        self.Parser.add_argument("-c", "--client", help="Client IP address",
            required=True)
        self.Parser.add_argument("--tested_server", help="Tested server IP address",
            required=True)
        self.Parser.add_argument("--tested_client", help="Tested client IP address",
            required=True)
        self.Parser.add_argument("-m", "--ignore_mckey", action='store_true',
                    help="Don\'t run mckey")

        self.Parser.parse_args(namespace=self, args=args)

    def GetClient(self):
        if not hasattr(self, "client_obj"):
            self.client_obj = Host(self.client, self.Logger)
        return self.client_obj

    def GetServer(self):
        if not hasattr(self, "server_obj"):
            self.server_obj = Host(self.server, self.Logger)
        return self.server_obj

    def Execute(self, args):
        self.ParseArgs(args)

        for app in APPS.iteritems():
            if self.ignore_mckey and "mckey" in app:
                continue
            self.Logger.info("-"*40+str(app[0])+"-"*(40 - len(str(app[0]))))
            self.Logger.info("-"*80)

#            ip = ".".join([str(int(self.server[:2]) + 1)] +
#                    self.server.split('.')[1:])
            ip = self.tested_server
#            client_ip = ".".join([str(int(self.client[:2]) + 1)] +
#                    self.client.split('.')[1:])
            client_ip = self.tested_client


            if not "rdma" in app[0]:
                if "key" in app[0]:
                    server_cmd = app[1][0] % (self.num_pkts, ip)
                    client_cmd = app[1][1] % (self.num_pkts, client_ip)
                else:
                    server_cmd = app[1][0] % self.num_pkts
                    client_cmd = app[1][1] % (self.num_pkts, ip)
            else:
                server_cmd = app[1][0]
                client_cmd = app[1][1] % ip


            server_pid = self.Server.RunProcess(server_cmd)
            time.sleep(1)

            client_pid = self.Client.RunProcess(client_cmd)
            (client_rc, out) = self.Client.WaitProcess(client_pid)
            if client_rc:
                self.Logger.error("%s - Client Failed" % self.client)
                self.Server.KillProccess(server_pid)

            (server_rc, out) = self.Server.WaitProcess(server_pid)
            if server_rc:
                self.Logger.error("%s - Server Failed" % self.server)

            if client_rc or server_rc:
                return 1

            self.Logger.info("-"*80)
        return 0

    Parser = property(GetParser)
    Logger = property(GetLogger)
    Client = property(GetClient)
    Server = property(GetServer)

if __name__ == "__main__":
    rdmacm_traffic = RDMACM()
    rc = rdmacm_traffic.Execute(sys.argv[1:])
    sys.exit(rc)
