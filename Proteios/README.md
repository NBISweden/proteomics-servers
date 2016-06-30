# Ansible scripts for installing Proteios SE on Ubuntu 14.04 server

The scripts can be used to install on a fresh Ubuntu server. Currently the user account 'ubuntu' will be used.

##Instructions 
First test ssh login to server (Ubuntu 14.04 LTS) using your certificate to check that you can access the server.
Then:

1. Edit ansible_hosts so that [proteios] points to the IP number of your new server.
2. Edit ansible.cfg if using a new certificate for logging in.
3. Run: ansible-playbook proteios-ansible.yml
4. Check that you can log into proteios server as root (http://SERVER:8080/proteios/app) using a web browser.
5. Run: ansible-playbook tandem.yml
6. Run: ansible-playbook featuredetection.yml
7. Log into you new proteios server (http://SERVER:8080/proteios/app) using a web browser. 
  * List plugins to activate tham (View->Plugins). 
  * Create users

Done!

If you want to install a Proteios course server, proceed with the instructions and scripts in the Course_Server subfolder. 

