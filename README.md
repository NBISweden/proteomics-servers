# proteomics-servers
This repository contains [Ansible](http://docs.ansible.com/ansible/intro_installation.html) scripts for installation of proteomics servers. Ansible 2.0 or higher is needed. The scripts have been tested on cloud deployments of Ubuntu 14.04 LTS. The scripts are divided into folders as follows:

* Proteios: Update of server packages and installation of Proteios Software Environment, including external software: 
 - X!Tandem, MS-GF+ search engines 
 - dinosaur, msInspect feature detectors
* OpenMS: Compilation and installation of OpenMS and TOPP.
* TPP: Compilation and installation of Trans-Proteomic Pipeline.
* DIA: Update of server packages, and installation of software for DIA targeted analysis 
