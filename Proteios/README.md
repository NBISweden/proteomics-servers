# Ansible scripts for installing Proteios SE on Ubuntu 14.04 server

The scripts in this folder can be used to install the latest version of Proteios Software Environment on a fresh Ubuntu server. Note that you'll need all files in the folder.

##Instructions 
First test ssh login to server (Ubuntu 14.04 LTS) using your certificate to check that you can access the server. Make sure that TCP ports 8080 (for http access to Proteios), and
8080 and 35000-36000 (for accessing the Proteios FTP server) are not blocked by any external firewall if you have trouble accessing the server at a later stage. 
Then:

1. Edit ansible_hosts so that [proteios] points to the IP number of your new server.
2. Edit ansible.cfg:
  * Set the path to your private key file: `private_key_file = ...`
  * Set the remote user account to use: `remote_user = ...`
3. Run: `ansible-playbook proteios-ansible.yml`
4. Check that you can log into proteios server as root (http://SERVER:8080/proteios/app) using a web browser.
5. Run: `ansible-playbook tandem.yml`
6. Run: `ansible-playbook featuredetection.yml`
7. Run: `ansible-playbook msgfplus.yml`
8. Log into you new proteios server (http://SERVER:8080/proteios/app) using a web browser. 
  * List plugins to activate them (View->Plugins). 
  * Create users

Done!

If you want to install a Proteios course server, proceed with the instructions and scripts in the Course_Server subfolder.  

### FTP server
If you want to start the Proteios FTP server, run `ansible-playbook ftp.yml`. Rerun the same script after server updates (see below) or if the FTP server has become inaccessible.
The ftp server can be reached using passive FTP at port 8021.  

### Custom search database
If you want to add a custom database to the Proteios server:

 1. First ensure that the database fasta file contains an equal amount of decoy entries which have an `r` prefix. Target entries should thus not have accessions starting with `r`.  
 2. Place the database fasta file in the same folder as the scripts.
 3. Edit `add_database.yml` with the fasta file name, and a short name (without whitespace) to appear in the database selection interface. For example:
```
database_file_name: swissprot_human_rev_20160606.fasta
database_name: sp_human_rev
```
 4. Run `ansible-playbook add_database.yml`.

### Update server
If you want to update your Proteios server with the latest patches and latest version of Proteios, just rerun `ansible-playbook proteios-ansible.yml` anytime.
