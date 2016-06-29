# Ansible scripts for installing course exercises on a Proteios server

1) Log into you new proteios server (http://SERVER:8080/proteios/app) using a web browser . 	
	a) Create user bils (password 'bils').
	b) Create user course (password 'course').
2) Run ansible-playbook course-ansible.yml
3) Log into host and run perl RegisterCourseMzMLProteios.pl
4) Run ansible-playbook tmt-course-ansible.yml
5) Log into host and run perl RegisterTMTCourseMzMLProteios.pl

6) To enable front end proxy:
	a) Start a bunch of Proteios servers from images to find their IPs
	b) Edit the proxies.conf file
	c) Run ansible-playbook proxy.yml