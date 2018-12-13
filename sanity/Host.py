#!/usr/bin/env python

from mlxlib.remote import mlxrpc
from reg2_wrapper.utils import logger

class Host(object):

    def __init__(self, ip, logger):
        self.ip = ip
        self.logger = logger

    def GetIP(self):
        return self.ip

    def GetLogger(self):
        return self.logger

    def ImportModules(self):
        modules = ['mlxlib.common.execute']
        for module in modules:
            self.ProxyServer.import_module(module)

    def GetProxyServer(self):
        if not hasattr(self, "proxy_server"):
            self.proxy_server = mlxrpc.RemoteRPC(self.ip)
            self.ImportModules()
        return self.proxy_server

    def ExecuteCommand(self, command):
        self.Logger.info("%s - Executing command: %s" % (self.IP,
            command))
        (rc, output) = self.ProxyServer.modules.execute.execute_get_output(command)
        if rc:
            self.Logger.error("%s - %s" % (self.IP, output))

        return (rc, output)    

    def RunProcess(self, command, shell=False):
        self.Logger.info("%s - Executing command: %s" % (self.IP,
            command))
      
        pid = self.ProxyServer.modules.execute.run_process(command,
                shell=shell)

        return pid


    def WaitProcess(self, pid):

        (rc, output) = self.ProxyServer.modules.execute.wait_process(pid)
        if rc:
            self.Logger.error("%s - %s" % (self.IP, output))

        return (rc, output)

    def KillProccess(self, pid):

        try:
            self.ProxyServer.modules.execute.kill_pid(pid)

        except OSError:
            self.ProxyServer.modules.execute.kill_pid(pid, 1)

    IP          = property(GetIP)        
    Logger      = property(GetLogger)
    ProxyServer = property(GetProxyServer)

