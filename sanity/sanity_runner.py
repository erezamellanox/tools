#!/usr/bin/env python

import sys
import time
import logging
from Host import Host
from argparse import ArgumentParser

LOGGING_LEVELS = {
                    'info'  : logging.INFO,
                    'debug' : logging.DEBUG
                 }

TOPO = {
#        "CX3-Pro" : ["10.194.7.10", "10.194.8.10", "mlx4_0"],
        "CIB" : ["10.194.7.11", "10.194.8.11", "mlx5_0"],
        "CX4" : ["10.194.7.12", "10.194.8.12", "mlx5_0"],
        "CX4-Lx" : ["10.194.7.13", "10.194.8.13", "mlx5_0"],
        "CX5" : ["10.194.7.14", "10.194.8.14", "mlx5_0"],
        }


class Runner(object):

    def __init__(self, name, info, logger):
        self.name = name
        self.info = info
        self.pids = []
        self.host = Host(info[0], logger)

    def GetPIDs(self):
        return self.pids

    def SetCMD(self, cmd):
        self.cmd = cmd

    def GetCMD(self):
        return self.cmd

    def GetName(self):
        return self.name

    def GetInfo(self):
        return self.info

    def GetHostRunner(self):
        return self.host

    Name = property(GetName)
    Info = property(GetInfo)
    PIDs = property(GetPIDs)
    CMD = property(GetCMD)
    HostRunner = property(GetHostRunner)


class SanityRunner(object):

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
        self.Parser.add_argument("-s", "--subnets", help="Subnets to test",
                default=["11", "12"], nargs='+')

        self.Parser.parse_args(namespace=self, args=args)

    def GetRunners(self):
        if not hasattr(self, "runners"):
            self.runners = []
            for hca, info in TOPO.iteritems():
                self.runners.append(Runner(hca, info, self.Logger))
        return self.runners

    def GetHosts(self):
        if not hasattr(self, "hosts"):
            self.hosts = []
            for hca, ips in TOPO.iteritems():
                for ip in ips[:-1]:
                    self.hosts.append(Host(ip, self.Logger))
        return self.hosts


    def RunSanity(self):

        rcs = [0]
        for runner, subnet in self.runnerToSubnet.iteritems():
            runner.pids.append(runner.HostRunner.RunProcess(runner.CMD))

        for runner in self.Runners:
            for pid in runner.PIDs:
                (rc, out) = runner.HostRunner.WaitProcess(pid)
                self.Logger.info("\n"+out)
                if rc:
                    rcs += [rc]
            runner.pids = []

        return sum(rcs)

    def RunIp(self):

        rcs = [0]
        self.runnerToSubnet = {}
        for subnet in self.subnets:
            for runner in self.Runners:
                self.runnerToSubnet[runner] = subnet
                cmd = "/.autodirect/mthswgwork/kamalh/scripts/sanity/ip_traffic.py -s %s -c %s -n %s.194.0.0" % (runner.Info[0], runner.Info[1], subnet)
                runner.SetCMD(cmd)

            rcs += [self.RunSanity()]

        self.runnerToSubnet = {}
        for subnet in ["43", "45"]:
            for runner in self.Runners:
                if runner.Name in ["CX4", "CX4Lx", "CX3-Pro", "CX5"]:
                    self.runnerToSubnet[runner] = subnet
                    cmd = "/.autodirect/mthswgwork/kamalh/scripts/sanity/ip_traffic.py -s %s -c %s -n %s.194.0.0" % (runner.Info[0], runner.Info[1], subnet)
                    runner.SetCMD(cmd)
            rcs += [self.RunSanity()]

        self.runnerToSubnet = {}
        for subnet in ["52", "53"]:
            for runner in self.Runners:
                if runner.Name in ["CX4", "CIB", "CX3-Pro", "CX5"]:
                    self.runnerToSubnet[runner] = subnet
                    cmd = "/.autodirect/mthswgwork/kamalh/scripts/sanity/ip_traffic.py -s %s -c %s -n %s.194.0.0" % (runner.Info[0], runner.Info[1], subnet)
                    runner.SetCMD(cmd)
            rcs += [self.RunSanity()]
                
        return sum(rcs)

    def RunRDMACM(self):

        rcs = [0]
        self.runnerToSubnet = {}
        for subnet in self.subnets:
            for runner in self.Runners:
                self.runnerToSubnet[runner] = subnet
                cmd = "/.autodirect/mthswgwork/kamalh/scripts/sanity/rdmacm_traffic.py -n 1000 -s %s -c %s --tested_server %s%s --tested_client %s%s" % (runner.Info[0], runner.Info[1], subnet, runner.Info[0]    [2:], subnet, runner.Info[1][2:])
                runner.SetCMD(cmd)

            rcs += [self.RunSanity()]
        return sum(rcs)

    def RunRDMA(self):

        rcs = [0]
        self.runnerToSubnet = {}
        for subnet in self.subnets:
            for runner in self.Runners:
                self.runnerToSubnet[runner] = subnet

                if runner.Info[2] == "mlx4_0":
                    if "11" in subnet:
                        cmd = "/.autodirect/mthswgwork/kamalh/scripts/sanity/rdma_traffic.py -d %s -i 0 -s %s -c %s --ud" % (runner.Info[2], runner.Info[0], runner.Info[1])
                    elif "12" in subnet:
                        cmd = "/.autodirect/mthswgwork/kamalh/scripts/sanity/rdma_traffic.py -d %s -i 0 1 2 3 -s %s -c %s -p 2 --ud" % (runner.Info[2], runner.Info[0], runner.Info[1])

                elif runner.Info[2] == "mlx5_0" and runner.Name == "CIB":
                    if "11" in subnet:
                        cmd = "/.autodirect/mthswgwork/kamalh/scripts/sanity/rdma_traffic.py -d %s -i 0 -s %s -c %s" % (runner.Info[2], runner.Info[0], runner.Info[1])
                    elif "12" in subnet:
                        cmd = "/.autodirect/mthswgwork/kamalh/scripts/sanity//rdma_traffic.py -d %s -i 0 -s %s -c %s -p 2" % (runner.Info[2], runner.Info[0], runner.Info[1])

                elif runner.Info[2] == "mlx5_0":
                    if "11" in subnet:
                        cmd = "/.autodirect/mthswgwork/kamalh/scripts/sanity/rdma_traffic.py -d %s -i 0 1 2 3 -s %s -c %s" % (runner.Info[2], runner.Info[0], runner.Info[1])
                    elif "12" in subnet:
                        cmd = "/.autodirect/mthswgwork/kamalh/scripts/sanity/rdma_traffic.py -d mlx5_1 -i 0 1 2 3 -s %s -c %s" %  (runner.Info[0], runner.Info[1])
                runner.SetCMD(cmd)

            rcs += [self.RunSanity()]
        return sum(rcs)

    def Execute(self, args):
        self.ParseArgs(args)
        rc = 0
        #rc = self.RunIp()
        rc = rc or self.RunRDMACM()
        #rc = rc or self.RunRDMA()
        return rc

    Parser = property(GetParser)
    Logger = property(GetLogger)
    Hosts = property(GetHosts)
    Runners = property(GetRunners)


if __name__ == '__main__':
    sanity_runner = SanityRunner()
    rc = sanity_runner.Execute(sys.argv[1:])
    sys.exit(rc)
