#!/usr/bin/python3
from http.server import BaseHTTPRequestHandler, HTTPServer
import psutil
import platform
import time
from datetime import datetime

hostName = "localhost"
serverPort = 19198

class MyServer(BaseHTTPRequestHandler):
    def do_GET(self):
        reset="\033[0m"
        clear_line="\r\033[2K"
        cyan="\033[36m"
        yellow="\033[33m"
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        if self.path=="/sysinfo":
            mem = psutil.virtual_memory()
            memused = int(mem.used/1024/1024)
            memtotal = int(mem.total/1024/1024)
            uptime = int(time.time()-psutil.boot_time())
            mins = int(uptime/60)
            hour, mins = divmod(mins, 60)
            days, hour = divmod(hour, 24)
            cpu = [i for i in open("/proc/cpuinfo").read().strip().split("\n") if "model name" in i][0][13:]
            self.wfile.write(f"{clear_line}{cyan}CPU{reset}: {cpu} x{psutil.cpu_count()}\n".encode())
            self.wfile.write(f"{clear_line}{cyan}CPU Usage{reset}: {round(psutil.cpu_percent(),1)}%\n".encode())
            self.wfile.write(f"{clear_line}{cyan}Load Avg.{reset}: {' '.join([str(round(i,1)) for i in psutil.getloadavg()])}\n".encode())
            self.wfile.write(f"{clear_line}{cyan}Platform{reset}: {platform.platform()}\n".encode())
            self.wfile.write(f"{clear_line}{cyan}System Date & Time{reset}: {datetime.now():%Y-%m-%d %H:%M}\n".encode())
            self.wfile.write(f"{clear_line}{cyan}Uptime{reset}: {days}d {hour}h {mins}m\n".encode())
            self.wfile.write(f"{clear_line}{cyan}Memory{reset}: {memused} MiB {yellow}/{reset} {memtotal} MiB".encode())
            self.wfile.write(f"{clear_line}\n".encode())
if __name__ == "__main__":
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
