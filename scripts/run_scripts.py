#!/usr/bin/python3
import subprocess
import tempfile
import mysql.connector
import sys

force = len(sys.argv) > 1 and sys.argv[1] == "--force"

# Connexion to the data base

connection_params = {
    'host'    : "{RUN_SCRIPT_HOST}",
    'user'    : "{RUN_SCRIPT_USER}",
    'password': "{RUN_SCRIPT_PASS}",
    'database': "{RUN_SCRIPT_DB}",
}

db = mysql.connector.connect(**connection_params)

# get MAC adress
import fcntl
import socket
import struct

def getHwAddr(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    info = fcntl.ioctl(s.fileno(), 0x8927,  struct.pack('256s', bytes(ifname, 'utf-8')[:15]))
    return ':'.join('%02x' % b for b in info[18:24])

mac = getHwAddr("eth0") # we force eth0 name in finition.sh

cursor = db.cursor()
cursor.execute("""SELECT hostname FROM hostnames WHERE MAC=%s""",(mac,))
results = cursor.fetchall()
cursor.close()

if len(results) > 0:
    hostname = results[0][0]
else:
    cursor = db.cursor()
    cursor.execute("""INSERT INTO hostnames (MAC) VALUES (%s)""",(mac,))
    cursor.close()
    db.commit()

if not hostname:    
    hostname = "UNKNOWN-" + mac

print(hostname)    
subprocess.run(["hostnamectl","set-hostname",hostname])
    
# read last run register in 
info_file = "/var/lib/run_scripts/info.json"
# if this is not our MAC adress, this a deploy of an image
# we copy the script run on the master

import datetime as date
import json


try:
  with open(info_file,'r') as file:
    (old_mac, old_date) = json.load(file)
    if old_mac != mac:
        cursor = db.cursor()
        cursor.execute("""DELETE FROM run WHERE MAC = %s""",(mac,))
        cursor.close()
        cursor = db.cursor()
        cursor.execute("""CREATE TEMPORARY TABLE tmp AS(SELECT date,MAC,outputs,errors,exit_code,id
                          FROM run WHERE MAC = %s AND date <= %s AND exit_code = 0)""",(old_mac,old_date))
        cursor.close()
        cursor = db.cursor()
        cursor.execute("""UPDATE tmp SET MAC=%s""",(mac,))
        cursor.close()
        cursor = db.cursor()
        cursor.execute("""INSERT INTO run (date,MAC,outputs,errors,exit_code,id) (SELECT * FROM tmp)""")
        cursor.close()
        db.commit()
        with open(info_file, 'w') as file:
            json.dump((mac,old_date), file)

except IOError:
    pass
except json.decoder.JSONDecodeError:
    pass

# fetch script that we must run
cursor = db.cursor()

if force:
    cursor.execute("""
      SELECT * FROM script as s""")
else:
    cursor.execute("""
      SELECT * FROM script as s WHERE NOT EXISTS (
      SELECT null FROM run as r WHERE r.id = s.id AND r.mac = %s AND exit_code = 0)""", (mac,))

results = cursor.fetchall()
print(len(results),"commands to run.")
cursor.close()
date = None

# run them

try:
  for (id,date,name,script,input) in results:
    with tempfile.NamedTemporaryFile(delete=False,mode='wb') as tmpf:
        script = script.replace("\r","")
        tmpf.write(script.encode('utf-8'))
        tmpf.write("\n".encode('utf-8'))
        tmpf.flush()
        proc = subprocess.Popen(["/usr/bin/bash", "-e", tmpf.name],
                               stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE)

        input = "" if input == None else input
        (outputs, errors) = proc.communicate()
        outputs = outputs.decode()
        if force: print("OUPUTS\n", outputs)
        errors  = errors.decode()
        if force: print("ERRORS\n", errors)
        retc = proc.returncode

        cursor = db.cursor()    
        cursor.execute("""
          INSERT INTO run (MAC,id,outputs,errors,exit_code) 
                 VALUES (%s,%s,%s,%s,%s)""", (mac,id,outputs,errors,retc))
        cursor.close()
        db.commit()

  with open(info_file, 'w') as file:
      # register the work in info_file
      cursor = db.cursor()    
      cursor.execute("""SELECT CURRENT_TIMESTAMP""")
      date = cursor.fetchone()[0]
      json.dump((mac,date), file, default=str)

finally:
  db.close()
  
        
