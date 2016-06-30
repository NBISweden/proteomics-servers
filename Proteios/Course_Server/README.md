# Ansible scripts for installing course exercises on a Proteios server

1. Log into you new proteios server (http://SERVER:8080/proteios/app) using a web browser . 	
  * Create user bils (password 'bils').
  * Create user course (password 'course').
2. Run ansible-playbook course-ansible.yml
3. Log into host and run perl RegisterCourseMzMLProteios.pl
4. Run ansible-playbook tmt-course-ansible.yml
5. Log into host and run perl RegisterTMTCourseMzMLProteios.pl

## To enable front end proxy (for accessing multiple machines without public IP, at ports 8081-
 1. Start a bunch of Proteios servers from images to find their IPs
 2. Edit the proxies.conf file
 3. Run ansible-playbook proxy.yml