#!/usr/bin/env python2
#
'''
1. This script will either:
  - bootstrap a new or an existing cluster
  - join/rejoin an existing cluster
2. Requirements (normally installed through puppet):
  - yum install python-argparse MySQL-python
3. Avoid joining all nodes at once
4. The paramter file contains credentials and will be stored inside /root/

Author: Massimiliano Adamo <maxadamo@gmail.com>
'''
import subprocess
import argparse
import textwrap
import logging
import shutil
import signal
import platform
import socket
import glob
import sys
import pwd
import grp
import os
from warnings import filterwarnings
import MySQLdb

FORCE = False
ALL_NODES = []
CREDENTIALS = {}

PURPLE = '\033[95m'
BLUE = '\033[94m'
GREEN = '\033[92m'
YELLOW = '\033[93m'
RED = '\033[91m'
WHITE = '\033[0m'
try:
    execfile('/root/galera_params.py')
except IOError:
    print "{}Could not access /root/galera_params.py{}".format(RED, WHITE)
    sys.exit(1)

OTHER_NODES = list(ALL_NODES)
OTHER_NODES.remove(socket.gethostbyname(socket.gethostname()))
OTHER_WSREP = []
REMAINING_NODES = []
LASTCHECK_NODES = []
for item in OTHER_NODES:
    OTHER_WSREP.append(item)


def ask(msg):
    """ Ask user confirmation """
    while True:
        print msg
        go_ahead = raw_input('Would you like to continue? (y/Y|n/N) > ')
        if go_ahead.lower() != 'y' and go_ahead.lower() != 'n':
            print 'you need to answer either y/Y|n/N\n'
        else:
            break
    if go_ahead.lower() == 'n':
        print ''
        os.sys.exit()


def kill_mysql():
    """kill mysql"""
    print "\nKilling any running instance of MySQL ..."
    init_script_1 = ['systemctl', 'stop', 'mysql.service']
    init_script_2 = ['systemctl', 'stop', 'mysql@bootstrap.service']
    mysqlproc = subprocess.Popen(
        ['pgrep', '-f', 'mysqld'],
        stdout=subprocess.PIPE)
    out, _ = mysqlproc.communicate()
    for pid in out.splitlines():
        os.kill(int(pid), signal.SIGKILL)
    if os.path.isfile("/var/lock/subsys/mysql"):
        os.unlink("/var/lock/subsys/mysql")
    for stop_script in [init_script_1, init_script_2]:
        try:
            subprocess.call(stop_script)
        except Exception:
            pass


def restore_mycnf():
    """restore /root/.my.cnf"""
    if os.path.isfile("/root/.my.cnf.bak"):
        os.rename("/root/.my.cnf.bak", "/root/.my.cnf")


def check_install():
    """check if Percona is installed"""
    if platform.dist()[0] not in ['fedora', 'redhat', 'centos']:
        print "{} not supported".format(platform.dist()[0])
        sys.exit(1)
    print "\ndetected {} {} ...".format(platform.dist()[0], platform.dist()[1])

    import yum
    # Remove loggin. Taken from: https://stackoverflow.com/a/46716482
    from yum.logginglevels import __NO_LOGGING
    yumloggers = [
        'yum.filelogging.RPMInstallCallback', 'yum.verbose.Repos',
        'yum.verbose.plugin', 'yum.Depsolve', 'yum.verbose', 'yum.plugin',
        'yum.Repos', 'yum', 'yum.verbose.YumBase', 'yum.filelogging',
        'yum.verbose.YumPlugins', 'yum.RepoStorage', 'yum.YumBase',
        'yum.filelogging.YumBase', 'yum.verbose.Depsolve'
    ]
    for loggername in yumloggers:
        logger = logging.getLogger(loggername)
        logger.setLevel(__NO_LOGGING)

    yumbase = yum.YumBase()
    pkg = 'Percona-XtraDB-Cluster-server-<%= @percona_major_version %>'
    if yumbase.rpmdb.searchNevra(name=pkg):
        pkg_list = yumbase.rpmdb.searchNevra(name=pkg)
        print 'detected {} ...'.format(pkg_list[0])
    else:
        print "{}{} not installed{}".format(RED, pkg, WHITE)
        sys.exit(1)
    return 'percona'


def clean_dir(clean_directory):
    """ purge files under directory """
    item_list = glob.glob(os.path.join(clean_directory, '*'))
    for fileitem in item_list:
        if os.path.isdir(fileitem):
            shutil.rmtree(fileitem)
        else:
            os.unlink(fileitem)


def initialize_mysql(datadirectory):
    """initialize mysql default schemas"""
    fnull = open(os.devnull, 'wb')
    clean_dir(datadirectory)
    try:
        subprocess.call([
            '/usr/sbin/mysqld',
            '--initialize-insecure',
            '--datadir={}'.format(datadirectory),
            '--user=mysql'],
                        stdout=fnull)
    except Exception as err:
        print "Error initializing DB: {}".format(err)
        sys.exit(1)
    fnull.close()


def check_leader(leader=None):
    """check if this node is the leader"""
    grastate_dat = '/var/lib/mysql/grastate.dat'
    grastate = open(grastate_dat)
    for line in grastate.readlines():
        if 'safe_to_bootstrap' in line and '1' in line:
            leader = True
    if not leader:
        print 'It may not be safe to bootstrap the cluster from this node.'
        print 'It was not the last one to leave the cluster and may not contain all the updates.'
        print 'To force cluster bootstrap with this node, edit the {} file manually and set safe_to_bootstrap to 1'.format(grastate_dat)
        os.sys.exit(1)


def bootstrap_mysql(boot):
    """bootstrap the cluster"""
    fnull = open(os.devnull, 'wb')
    kill_mysql()
    if boot == "new":
        if os.path.isfile('/root/.my.cnf'):
            os.rename('/root/.my.cnf', '/root/.my.cnf.bak')
    else:
        check_leader()

    try:
        subprocess.call([
            '/usr/bin/systemctl',
            'start',
            'mysql@bootstrap.service'
        ])
    except Exception as err:
        print "Error bootstrapping the cluster: {}".format(err)
        sys.exit(1)
    if boot == "new":
        try:
            subprocess.call([
                "/usr/bin/mysqladmin",
                "--no-defaults",
                "--socket=/var/lib/mysql/mysql.sock",
                "-u", "root", "password",
                CREDENTIALS["root"]],
                            stdout=fnull, stderr=subprocess.STDOUT)
        except Exception as err:
            print "Error setting root password: {}".format(err)
        restore_mycnf()


def checkhost(sqlhost):
    """check the socket on the other nodes"""
    print "\nChecking socket on {} ...".format(sqlhost)
    fnull = open(os.devnull, 'wb')
    ping = subprocess.Popen(["/bin/ping", "-w2", "-c2", sqlhost],
                            stdout=fnull, stderr=subprocess.STDOUT)
    _, __ = ping.communicate()
    retcode = ping.poll()
    fnull.close()
    if retcode != 0:
        print "{}Skipping {}: ping failed{}".format(RED, sqlhost, WHITE)
        OTHER_WSREP.remove(sqlhost)
    else:
        cnx_sqlhost = None
        try:
            cnx_sqlhost = MySQLdb.connect(
                user='sstuser',
                passwd=CREDENTIALS["sstuser"],
                unix_socket='/var/lib/mysql/mysql.sock',
                host=sqlhost)
        except Exception:
            print "{}Skipping {}: socket is down{}".format(
                YELLOW, sqlhost, WHITE)
            OTHER_WSREP.remove(sqlhost)
        else:
            print "{}Socket on {} is up{}".format(GREEN, sqlhost, WHITE)
        finally:
            if cnx_sqlhost:
                cnx_sqlhost.close()


def checkwsrep(sqlhost):
    """check if the other nodes belong to the cluster"""
    fnull = open(os.devnull, 'wb')
    ping = subprocess.Popen(["/bin/ping", "-w2", "-c2", sqlhost],
                            stdout=fnull, stderr=subprocess.STDOUT)
    _, __ = ping.communicate()
    retcode = ping.poll()
    fnull.close()
    if retcode == 0:
        print "\nChecking if {} belongs to cluster ...".format(sqlhost)
        cnx_sqlhost = None
        wsrep_status = 0
        try:
            cnx_sqlhost = MySQLdb.connect(
                user='sstuser',
                passwd=CREDENTIALS["sstuser"],
                unix_socket='/var/lib/mysql/mysql.sock',
                host=sqlhost
                )
            cursor = cnx_sqlhost.cursor()
            wsrep_status = cursor.execute("""show variables LIKE 'wsrep_on'""")
        except Exception:
            pass
        finally:
            if cnx_sqlhost:
                cnx_sqlhost.close()
        if wsrep_status == 1:
            LASTCHECK_NODES.append(sqlhost)
            print "{}{} belongs to cluster{}".format(GREEN, sqlhost, WHITE)
        else:
            print "{}Skipping {}: it is not in the cluster{}".format(
                YELLOW, sqlhost, WHITE)


def try_joining(how, datadirectory):
    """If we have nodes try Joining the cluster"""
    kill_mysql()
    init_script = ['systemctl', 'start', 'mysql.service']
    if how == "new":
        if os.path.isfile('/root/.my.cnf'):
            os.rename('/root/.my.cnf', '/root/.my.cnf.bak')

    if not LASTCHECK_NODES:
        print "{}There are no nodes available in the Cluster{}".format(
            RED, WHITE)
        print "\nEither:"
        print "- None of the hosts has the value 'wsrep_ready' to 'ON'"
        print "- None of the hosts is running the MySQL process\n"
        sys.exit(1)
    else:
        try:
            subprocess.call(init_script)
        except Exception:
            print "{}Unable to gently join the cluster{}".format(RED, WHITE)
            print "Force joining cluster with {}".format(LASTCHECK_NODES[0])
            if os.path.isfile(os.path.join(datadirectory, "grastate.dat")):
                os.unlink(os.path.join(datadirectory, "grastate.dat"))
                try:
                    subprocess.call(init_script)
                except Exception as err:
                    print "{}Unable to join the cluster{}: {}".format(
                        RED, WHITE, err)
                    sys.exit(1)
                finally:
                    restore_mycnf()
            else:
                restore_mycnf()
                print "{}Unable to join the cluster{}".format(RED, WHITE)
                sys.exit(1)
        else:
            restore_mycnf()
        print '\nsuccessfully joined the cluster\n'


def create_monitor_table():
    """create test table for monitor"""
    print "\nCreating DB test if not exist\n"
    cnx_local_test = MySQLdb.connect(user='root',
                                     passwd=CREDENTIALS["root"],
                                     host='localhost',
                                     unix_socket='/var/lib/mysql/mysql.sock')
    cursor = cnx_local_test.cursor()
    cursor.execute("SET sql_notes = 0;")
    try:
        cursor.execute("""
                    CREATE DATABASE IF NOT EXISTS `test`
                    """)
    except Exception as err:
        print "Could not create database test: {}".format(err)
        sys.exit(1)
    else:
        cnx_local_test.commit()
        cnx_local_test.close()

    print "Creating table for Monitor\n"
    cnx_local_test = MySQLdb.connect(user='root',
                                     passwd=CREDENTIALS["root"],
                                     host='localhost',
                                     unix_socket='/var/lib/mysql/mysql.sock',
                                     db='test')
    cursor = cnx_local_test.cursor()

    try:
        cursor.execute("""
                    CREATE TABLE IF NOT EXISTS `monitor` (
                        `id` varchar(255) DEFAULT NULL
                        ) ENGINE=InnoDB DEFAULT CHARSET=utf8
                    """)
        cnx_local_test.commit()
    except Exception as err:
        print "Could not create test table: {}".format(err)
        sys.exit(1)
    else:
        cnx_local_test.commit()

    try:
        cursor.execute("""
                    INSERT INTO test.monitor SET id=("placeholder");
                    """)
        cnx_local_test.commit()
    except Exception as err:
        print "Unable to write to test table: {}".format(err)
    finally:
        if cnx_local_test:
            cnx_local_test.close()


def drop_anonymous():
    """drop anonymous user"""
    all_localhosts = [
        "localhost", "127.0.0.1", "::1",
        socket.gethostbyname(socket.gethostname())
    ]
    cnx_local = MySQLdb.connect(
        user='root',
        passwd=CREDENTIALS["root"],
        unix_socket='/var/lib/mysql/mysql.sock',
        host='localhost')
    cursor = cnx_local.cursor()
    for onthishost in all_localhosts:
        try:
            cursor.execute("""DROP USER ''@'{}'""".format(onthishost))
        except Exception:
            pass
    if cnx_local:
        cursor.execute("""FLUSH PRIVILEGES""")
        cnx_local.close()


def create_users(thisuser):
    """create users root, monitor and sst and delete anonymous"""
    cnx_local = MySQLdb.connect(user='root',
                                passwd=CREDENTIALS["root"],
                                unix_socket='/var/lib/mysql/mysql.sock',
                                host='localhost')
    cursor = cnx_local.cursor()
    print "Creating user: {}".format(thisuser)
    if thisuser == 'sstuser':
        thisgrant = 'PROCESS, SELECT, RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.*'
    elif thisuser == 'monitor':
        thisgrant = 'UPDATE ON test.monitor'

    if thisuser == "root":
        for onthishost in ["localhost", "127.0.0.1", "::1"]:
            try:
                cursor.execute("""
                    CREATE USER IF NOT EXISTS '{}'@'{}' IDENTIFIED BY '{}'
                    """.format(thisuser, onthishost, CREDENTIALS[thisuser]))
            except Exception as err:
                print "Unable to create user {} on {}: {}".format(
                    thisuser,
                    onthishost,
                    err)
            try:
                cursor.execute("""
                    GRANT ALL PRIVILEGES ON *.* TO '{}'@'{}' WITH GRANT OPTION
                    """.format(thisuser, onthishost))
            except Exception as err:
                print "Unable to set permission for {} at {}: {}".format(
                    thisuser,
                    onthishost,
                    err)
                os.sys.exit()
            try:
                cursor.execute("""
                    set PASSWORD for '{}'@'{}' = '{}'
                    """.format(thisuser, onthishost, CREDENTIALS[thisuser]))
            except Exception as err:
                print "Unable to set password for {} on {}: {}".format(
                    thisuser,
                    onthishost,
                    err)
                os.sys.exit()
    else:
        for thishost in ALL_NODES:
            try:
                cursor.execute("""
                    CREATE USER '{}'@'{}' IDENTIFIED BY '{}'
                    """.format(thisuser, thishost, CREDENTIALS[thisuser]))
            except Exception:
                print "Unable to create user {} on {}".format(
                    thisuser,
                    thishost)
            try:
                cursor.execute("""
                        GRANT {} TO '{}'@'{}'
                        """.format(thisgrant, thisuser, thishost))
            except Exception as err:
                print "Unable to set permission for {} at {}: {}".format(
                    thisuser, thishost, err)
    if cnx_local:
        cursor.execute("""FLUSH PRIVILEGES""")
        cnx_local.close()


class Cluster(object):
    """ This class will either:
      - create a new cluster on a server
      - create an existing cluster on a server
      - join a new cluster on a server
      - join an existing cluster on a server
      - check cluster status
      - show SQL statements
    """
    def __init__(self, manner, mode, datadir='/var/lib/mysql', force=FORCE):
        self.manner = manner
        self.mode = mode
        self.datadir = datadir
        self.force = FORCE
        os.chown(self.datadir, pwd.getpwnam("mysql").pw_uid,
                 grp.getgrnam("mysql").gr_gid)

    def createcluster(self):
        """create and bootstrap a cluster"""
        for hostitem in OTHER_NODES:
            checkhost(hostitem)
        if OTHER_WSREP:
            for wsrepitem in OTHER_WSREP:
                REMAINING_NODES.append(wsrepitem)
        if REMAINING_NODES:
            alive = str(REMAINING_NODES)[1:-1]
            print "{}\nThe following nodes are alive in cluster:{}\n  {}".format(
                RED, WHITE, alive)
            print "\n\nTo boostrap a new cluster you need to switch them off\n"
            os.sys.exit(1)
        else:
            if self.mode == "new" and not self.force:
                ask('\nThis operation will destroy the local data')
            clean_dir(self.datadir)
            initialize_mysql(self.datadir)
            bootstrap_mysql(self.mode)
            if self.mode == "new":
                create_monitor_table()
                ALL_NODES.append("localhost")
                for creditem in CREDENTIALS:
                    create_users(creditem)
                print ""
                drop_anonymous()

    def joincluster(self):
        """join a cluster"""
        for hostitem in OTHER_NODES:
            checkhost(hostitem)
        if OTHER_WSREP:
            for wsrepitem in OTHER_WSREP:
                REMAINING_NODES.append(wsrepitem)
        if REMAINING_NODES:
            for wsrephost in OTHER_WSREP:
                checkwsrep(wsrephost)
        if LASTCHECK_NODES:
            if self.mode == "new" and not self.force:
                ask('\nThis operation will destroy the local data')
                print "\ninitializing mysql tables ..."
                initialize_mysql(self.datadir)
            elif self.mode == "new" and self.force:
                print "\ninitializing mysql tables ..."
                initialize_mysql(self.datadir)
        try_joining(self.manner, self.datadir)

    def checkonly(self):
        """runs a cluster check"""
        OTHER_WSREP.append(socket.gethostbyname(socket.gethostname()))
        for hostitem in ALL_NODES:
            checkhost(hostitem)
        if OTHER_WSREP:
            for wsrepitem in OTHER_WSREP:
                REMAINING_NODES.append(wsrepitem)
        if REMAINING_NODES:
            for wsrephost in OTHER_WSREP:
                checkwsrep(wsrephost)
        print ''

    def show_statements(self):
        """Show SQL statements to create all stuff"""
        os.system('clear')
        ALL_NODES.append("localhost")
        print "\n# remove anonymous user\nDROP USER ''@'localhost'"
        print "DROP USER ''@'{}'".format(socket.gethostbyname(socket.gethostname()))
        print "\n# create monitor table\nCREATE DATABASE IF NOT EXIST `test`;"
        print "CREATE TABLE IF NOT EXISTS `test`.`monitor` ( `id` varchar(255) DEFAULT NULL ) ENGINE=InnoDB DEFAULT CHARSET=utf8;"
        print 'INSERT INTO test.monitor SET id=("placeholder");'
        for thisuser in ['root', 'sstuser', 'monitor']:
            print "\n# define user {}".format(thisuser)
            if thisuser == "root":
                for onthishost in ["localhost", "127.0.0.1", "::1"]:
                    print "set PASSWORD for 'root'@'{}' = '{}'".format(
                        onthishost, CREDENTIALS[thisuser])
            for thishost in ALL_NODES:
                if thisuser != "root":
                    print "CREATE USER \'{}\'@\'{}\' IDENTIFIED BY \'{}\';".format(
                        thisuser, thishost, CREDENTIALS[thisuser])
            for thishost in ALL_NODES:
                if thisuser == "sstuser":
                    thisgrant = "PROCESS, SELECT, RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.*"
                elif thisuser == "monitor":
                    thisgrant = "UPDATE ON test.monitor"
                if thisuser != "root":
                    print "GRANT {} TO '{}'@'{}';".format(
                        thisgrant, thisuser, thishost)
        print ""


def parse():
    """Parse options thru argparse and run it..."""
    intro = """\
         Use this script to bootstrap, join nodes within a Galera Cluster
         ----------------------------------------------------------------
           Avoid joining more than one node at once!
         """
    parser = argparse.ArgumentParser(
        formatter_class=lambda prog:
        argparse.RawDescriptionHelpFormatter(prog, max_help_position=29),
        description=textwrap.dedent(intro),
        epilog="Author: Massimiliano Adamo <maxadamo@gmail.com>")
    parser.add_argument(
        '-cg', '--check-galera', help='check if all nodes are healthy',
        action='store_true', dest='Cluster(None, None).checkonly()',
        required=False)
    parser.add_argument(
        '-dr', '--dry-run', help='show SQL statements to run on this cluster',
        action='store_true', dest='Cluster(None, None).show_statements()',
        required=False)
    parser.add_argument(
        '-je', '--join-existing', help='join existing Cluster',
        action='store_true',
        dest='Cluster("existing", "existing").joincluster()', required=False)
    parser.add_argument(
        '-be', '--bootstrap-existing', help='bootstrap existing Cluster',
        action='store_true', dest='Cluster(None, "existing").createcluster()',
        required=False)
    parser.add_argument(
        '-jn', '--join-new', help='join new Cluster', action='store_true',
        dest='Cluster("new", "new").joincluster()', required=False)
    parser.add_argument(
        '-bn', '--bootstrap-new', action='store_true',
        help='bootstrap new Cluster',
        dest='Cluster(None, "new").createcluster()', required=False)
    parser.add_argument(
        '-f', '--force', action='store_true',
        help='force bootstrap new or join new Cluster', required=False)

    return parser.parse_args()


# Here we Go.
if __name__ == "__main__":
    filterwarnings('ignore', category=MySQLdb.Warning)
    try:
        _ = pwd.getpwnam("mysql").pw_uid
    except KeyError:
        print "Could not find the user mysql \nGiving up..."
        sys.exit(1)
    try:
        _ = grp.getgrnam("mysql").gr_gid
    except KeyError:
        print "Could not find the group mysql \nGiving up..."
        sys.exit(1)

    ARGS = parse()
    ARGSDICT = vars(ARGS)
    if ARGS.force:
        FORCE = True

    check_install()

    if not any(ARGSDICT.values()):
        print '\n\tNo arguments provided.\n\tUse -h, --help for help'
    else:
        for key in list(ARGSDICT.keys()):
            if ARGSDICT[str(key)] is True:
                if key != 'force':
                    eval(key)
