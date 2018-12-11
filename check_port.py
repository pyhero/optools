#!/usr/bin/env python3
"""
check specified ports or list_ports
Panda 2018-12-11
"""
import socket

timeout = 2

ports_not_check = []

ports_mapping = {
    'sshd': [22, ],
    'nginx': [80, 443, ],
    'mysql': [3306, ],
}

list_ports = [port for ports in ports_mapping.values() for port in ports if port not in ports_not_check]


def check_port(host, port, protocol='tcp', timeout=timeout):
    socket_type = socket.SOCK_STREAM if protocol == 'tcp' else socket.SOCK_DGRAM
    sock = socket.socket(socket.AF_INET, socket_type)
    sock.settimeout(timeout)
    result = sock.connect_ex((host, port))
    if result == 0:
        return True
    else:
        return False


if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser()
    parser.add_argument('-H', action='store', dest='HOSTS', help='Hosts e.g. "8.8.8.8,114.114.114.114"')
    parser.add_argument('-P', action='store', dest='PORTS', help='PORTS e.g. "80,443,8080"')
    parser.add_argument('-S', action='store', dest='SOCKET', choices=['tcp', 'udp'], default='tcp',
                        help='protocol e.g. tcp or udp')

    args = parser.parse_args()

    if not args.HOSTS:
        raise Exception('-H {hosts} is required')
    else:
        HOSTS = [h for h in args.HOSTS.split(',')]

    PORTS = [int(p) for p in args.PORTS.split(',')] if args.PORTS else list_ports

    protocol = args.SOCKET

    for host in HOSTS:
        print('checking {}... (may take {}s)'.format(host, len(PORTS) * timeout))
        result = list()
        for port in PORTS:
            if check_port(host, port, protocol=protocol):
                result.append(port)

        if len(result) > 0:
            print('\033[1;33mWARN\033[0m: {}\'s {} are opened.'.format(host, sorted(result)))
        else:
            print('\033[1;32mINFO\033[0m: {}\'s {} are disabled.'.format(host, sorted(PORTS)))
