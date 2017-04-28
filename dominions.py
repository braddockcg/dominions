#!/usr/bin/env python3

import sys
import os
import argparse
import io
import json
import time
from datetime import datetime
from subprocess import check_call
import hashlib, binascii

# pip3 install filelock
import filelock


chain_defaults = {
    'user_number': 1,
    'user_alias': 'User Alias',
    'user_real_name': 'User Real Name',
    'user_callsign': '',
    'user_age': 99,
    'user_sex': 'M',
    'user_gold': 0,
    'user_last_logon': '05/19/89',
    'columns': 80,
    'width': 25,
    'security_level': 0,
    'co_sysop': 0,
    'sysop': 0,
    'ansi': 1,
    'remote': 1,
    'secs_till_logoff': 3600.0,
    'gfiles_dir': '',
    'data_dir': '',
    'log': '',
    'baud_rate': '9600',
    'com_port': 0,
    'system_name': 'Dominions BBS',
    'system_sysop': 'Dock9',
    'time_of_logon': 99999,
    'user_sec_on_system': 0,
    'uploaded': 0,
    'uploads': 0,
    'downloaded': 0,
    'downloads': 0,
    'parity': '8N1'
}


chain_template = """{user_number}\r
{user_alias}\r
{user_real_name}\r
{user_callsign}\r
{user_age}\r
{user_sex}\r
{user_gold}\r
{user_last_logon}\r
{columns}\r
{width}\r
{security_level}\r
{co_sysop}\r
{sysop}\r
{ansi}\r
{remote}\r
{secs_till_logoff}\r
{gfiles_dir}\r
{data_dir}\r
{log}\r
{baud_rate}\r
{com_port}\r
{system_name}\r
{system_sysop}\r
{time_of_logon}\r
{user_sec_on_system}\r
{uploaded}\r
{uploads}\r
{downloaded}\r
{downloads}\r
{parity}\r
"""


# This must be set before any chdir() call
global source_dir
abspath = os.path.abspath(__file__)
source_dir = os.path.dirname(abspath)


def get_source_dir():
    """Directory of the python executable"""
    global source_dir
    return source_dir


def call(args, shell=False):
    print(' '.join(args))
    check_call(args, shell=shell)


def dosemu(args):
    dosemurc = os.path.join(get_source_dir(), 'dosemurc')
    cmd = ['dosemu', '-dumb', '-f', dosemurc]
    cmd.extend(args)
    call(cmd)



def install(source):
    """Our current directory should be an empty game directory"""
    if os.path.exists('DOMIN2.EXE'):
        raise Exception("Refusing to install over an existing game")
    call(['unzip', os.path.join(source, 'dom2v20b.zip')])
    call(['unzip', 'DOM2.EXE'])


def initialize_game(gamedb):
    dosemurc = os.path.join(get_source_dir(), 'dosemurc')
    cmd = 'echo -n "y" | dosemu -dumb -f ' + dosemurc + ' RESETDOM.EXE'
    call(cmd, shell=True)
    gamedb.db['initialized'] = True
    gamedb.save()


def hash_password(password, salt):
    dk = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 100000)
    return binascii.hexlify(dk).decode('utf-8')


def write_chain_file(fname, chain_data):
    data = chain_defaults.copy()
    data.update(chain_data)
    with io.open(fname, 'wt', encoding='utf-8') as f:
        f.write(chain_template.format(**data))


def run_turns(gamedb):
    last_turn = gamedb.get_turn_timestamp()
    t = datetime.utcnow()
    dt = (t - last_turn).total_seconds()
    period = gamedb.get_turn_period()
    if dt > period:
        dosemu(['DOMEVENT.EXE'])
        gamedb.save_turn_timestamp()


def run(username, gamedb):
    chain = {}
    u = gamedb.db['users'][username]
    chain['user_number'] = u['id']
    chain['user_alias'] = username
    chain['user_real_name'] = username
    write_chain_file('CHAIN.TXT', chain)
    dosemu(['DOMIN2.EXE'])


class GameDB(object):
    def __init__(self):
        self.fname = 'gamedb.json'
        self.db = {
                'users': {},
                'turn_period': 60 * 60 * 24,
                'initialized': False
                }

    def load(self):
        if not os.path.exists(self.fname):
            return
        with io.open(self.fname, 'rt', encoding='utf-8') as f:
            self.db = json.load(f)

    def save(self):
        with io.open(self.fname, 'wt', encoding='utf-8') as f:
            json.dump(self.db, f, indent=4)

    def get_max_userid(self):
        max_id = 0
        for user in self.db['users'].values():
            max_id = max(max_id, user['id'])
        return max_id

    def add_user(self, username, password):
        salt = os.urandom(16)
        p = hash_password(password, salt)
        strsalt = binascii.hexlify(salt).decode('utf-8')
        user_id = self.get_max_userid() + 1
        self.db['users'][username] = {
                'password': p, 
                'salt': strsalt,
                'id': user_id
                }
        self.save()

    def get_turn_timestamp(self):
        v = self.db['turn_timestamp']
        dt = datetime(v[0], v[1], v[2], v[3], v[4], v[5])
        return dt

    def save_turn_timestamp(self):
        now = datetime.utcnow()
        self.db['turn_timestamp'] = list(now.utctimetuple())
        self.save()

    def get_turn_period(self):
        return self.db['turn_period']

    def rm_user(self, username):
        del self.db['users'][username]
        self.save()

    def verify_password(self, username, password):
        user = self.db['users'][username]
        strsalt = user['salt']
        salt = binascii.unhexlify(strsalt)
        p = hash_password(password, salt)
        if p == user['password']:
            return True
        else:
            return False

    def select_user(self):
        usernames = list(self.db['users'].keys())
        usernames.sort()
        print("0. New User")
        for idx, username in enumerate(usernames):
            print('%i. %s' % (idx + 1, username))
        idx = input('User number? ')
        try:
            idx = int(idx) - 1
        except ValueError as e:  # Might be username string
            if idx in usernames:
                return idx
            else:
                raise Exception("Invalid user selection.")
        if idx >= 0 and idx < len(usernames):
            return usernames[idx]
        else:
            return None  # New User


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--gamedir', default='.', 
            help='Game directory.  Defaults to current directory.')

    subparsers = parser.add_subparsers(help='sub-command', dest='cmd')

    install_parser = subparsers.add_parser('install', help='Install a new Dominions Game')
    install_parser.add_argument('target', help='Directory to install a new Dominions Game into')
    install_parser.add_argument('--source', required=False, default=get_source_dir(), 
            help='(optional) Directory to install a new Dominions Game FROM')

    add_parser = subparsers.add_parser('add', help='Add a new user')
    add_parser.add_argument('user', help='username to add')
    add_parser.add_argument('password', help='password')

    rm_parser = subparsers.add_parser('rm', help='Remove a user')
    rm_parser.add_argument('user', help='username to remvoe')

    run_parser = subparsers.add_parser('run', help='Run Dominions')
    run_parser.add_argument('--user', '-u', default=None, help='username to run as')

    turn_parser = subparsers.add_parser('turn', help='Run Dominions nightly turn event')

    args = parser.parse_args()

    # Create the game direcotry if it does not already exist
    if args.cmd == 'install':
        args.gamedir = args.target
    if not os.path.exists(args.gamedir):
        os.mkdir(args.gamedir)
    elif not os.path.exists(os.path.join(args.gamedir, 'gamedb.json')):
        raise Exception("No Game Database in directory " + args.gamedir)
    os.chdir(args.gamedir)

    lock = filelock.FileLock("lockfile")
    try:
        with lock.acquire(timeout=5):

            gamedb = GameDB()
            gamedb.load()

            if args.cmd == 'install':
                install(args.source)
                gamedb.save_turn_timestamp()
                gamedb.save()
            elif args.cmd == 'add':
                gamedb.add_user(args.user, args.password)
            elif args.cmd == 'rm':
                gamedb.rm_user(args.user)
            elif args.cmd == 'turn':
                dosemu(['DOMEVENT.EXE'])
                gamedb.save_turn_timestamp()
            elif args.cmd == 'run':
                if args.user is None:
                    while True:
                        username = gamedb.select_user()
                        if username == None:
                            print('Creating new user...')
                            username = input('New Username? ')
                            password = input('New Password? ')
                            gamedb.add_user(username, password)
                            break
                        else:
                            password = input("Password? ")
                            correct = gamedb.verify_password(username, password)
                            if correct:
                                break
                            else:
                                print("!!!")
                                print("Wrong username or password")
                                print("!!!")
                else:
                    username = args.user
                if not gamedb.db['initialized']:
                    initialize_game(gamedb)
                run_turns(gamedb)
                run(username, gamedb)
    except filelock.Timeout:
        print("Someone else is playing, try again later.")


if __name__ == '__main__':
    main()

