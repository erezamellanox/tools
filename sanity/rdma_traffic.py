#!/usr/bin/env python

import sys
import time
import logging
from argparse import ArgumentParser
from Host import Host

LOGGING_LEVELS = {
                    'info'  : logging.INFO,
                    'debug' : logging.DEBUG
                 }

APPS = {
        "ud" : ["ibv_ud_pingpong -d %s -s 1024 -g %d -n %d -i %d",
                "ibv_ud_pingpong -d %s -s 1024 -g %d -n %d %s -i %d "],
        "uc" : ["ibv_uc_pingpong -d %s -g %d -n %d -i %d",
                "ibv_uc_pingpong -d %s -g %d -n %d %s -i %d"],
        "rc" : ["ibv_rc_pingpong -d %s -g %d -n %d -i %d",
                "ibv_rc_pingpong -d %s -g %d -n %d %s -i %d"],
        "srq" : ["ibv_srq_pingpong -d %s -g %d -n %d -i %d",
                "ibv_srq_pingpong -d %s -g %d -n %d %s -i %d"],
#        "xsrq" : ["ibv_xsrq_pingpong -d %s -g %d -n %d -i %d",
#                "ibv_xsrq_pingpong -d %s -g %d -n %d %s -i %d"]
       }


class RDMA(object):

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
        self.Parser.add_argument("-i", "--gid_indexs", help="GID indexs",
            type=int, default=[0,1], nargs='+')
        self.Parser.add_argument("-s", "--server", help="Server IP address",
            required=True)
        self.Parser.add_argument("-c", "--client", help="Client IP address",
            required=True)
        self.Parser.add_argument("-d", "--device", help="Device to use",
                required=True)
        self.Parser.add_argument("-n", "--num_iter", help="Number of iterations",
                type=int, default=1000)
        self.Parser.add_argument("-r", "--ud", help="Ignore running UD",
                action='store_true', default=False)
        self.Parser.add_argument("-p", "--port", help="Port number",
                type=int, default=1)

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
            if "ud" in app and self.ud:
                continue
                
            self.Logger.info("-"*40+str(app[0])+"-"*(40 - len(str(app[0]))))
            self.Logger.info("-"*80)
            for gid_index in self.gid_indexs:

                server_cmd = app[1][0] % (self.device, gid_index,
                        self.num_iter, self.port)
                client_cmd = app[1][1] % (self.device, gid_index,
                        self.num_iter, self.server, self.port)

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
    rdma_traffic = RDMA()
    rc = rdma_traffic.Execute(sys.argv[1:])
    sys.exit(rc)
