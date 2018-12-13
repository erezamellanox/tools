#!/usr/bin/env python

import sys
import logging
from Host import Host
from argparse import ArgumentParser

LOGGING_LEVELS = {
                    'info'  : logging.INFO,
                    'debug' : logging.DEBUG
                 }

class run_cmd(object):
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
        self.Parser.add_argument("-i", "--ips", help="IP addressed", nargs='+')
        self.Parser.add_argument("-c", "--cmd", help="Command to run")

        self.Parser.parse_args(namespace=self, args=args)

    def GetHosts(self):
        if not hasattr(self, "hosts"):
            self.hosts = set()
            for ip in self.ips:
                    self.hosts.add(Host(ip, self.Logger))
        return self.hosts

    def Execute(self, args):
        self.ParseArgs(args)


        hostToPid = {}
        for host in self.Hosts:
            hostToPid[host] = host.RunProcess(self.cmd, shell=True)

        for host in self.Hosts:
            (rc, out) = host.WaitProcess(hostToPid[host])
            if rc:
                self.Logger.error("-E- Failed to run %s on %s" % (self.cmd, host.IP))
            self.Logger.info("-"*17+"%s" % (host.IP)+"-"*21)
            self.Logger.info("\n\n"+out)
            self.Logger.info("-"*49)

    Parser = property(GetParser)
    Logger = property(GetLogger)
    Hosts = property(GetHosts)

if __name__ == "__main__":
    run_cmd_obj = run_cmd()
    rc = run_cmd_obj.Execute(sys.argv[1:])
    sys.exit(rc)
