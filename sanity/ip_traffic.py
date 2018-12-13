#!/usr/bin/env python

import os
import sys
import logging
from argparse import ArgumentParser

LOGGING_LEVELS = {
                    'info'  : logging.INFO,
                    'debug' : logging.DEBUG
                 }

class IP(object):

    def GetLogger(self):
        if not hasattr(self, "logger"):
            logging.basicConfig(level=LOGGING_LEVELS[self.verbos])
            self.logger = logging.getLogger(self.__class__.__name__)
        return self.logger

    def GetParser(self):
        if not hasattr(self, "parser"):
            self.parser = ArgumentParser()
        return self.parser

    def ParseArgs(self, args):
        self.Parser.add_argument("-v", "--verbose", help="Verbosity level",
                default="info", choices=["info", "debug"])
        self.Parser.add_argument("-s", "--server", help="Server IP address",
                required=True)
        self.Parser.add_argument("-c", "--client", help="Client IP address",
                required=True)
        self.Parser.add_argument("-n", "--network", help="IPv4 Network to run traffic over it",
                required=True)
        
        self.Parser.parse_args(namespace=self, args=args)

    def Execute(self, args):
        self.ParseArgs(args)
        cmd = "mlx_traffic_test -s %s -c %s -n %s" % (self.server, self.client, self.network)

        return os.system(cmd)

    Logger = property(GetLogger)
    Parser = property(GetParser)


if __name__ == "__main__":
    ip_obj = IP()
    rc = ip_obj.Execute(sys.argv[1:])
    sys.exit(rc)
