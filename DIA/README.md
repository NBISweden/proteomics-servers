# Ansible scripts for installation of DIA analysis server

The scripts will update, install dependencies, and different versions of DIANA and pyprophet on an Ubunutu 14.04 server.

- `diana-ansible.yml` for DIANA 1.0.0, as in the Teleman paper.
- `diana-latest.yml` for the latest version of DIANA from GitHub, and PyProphet from the Teleman GitHub branch.
- `diana-latest_pypi.yml` [recommended] for the latest version of DIANA from GitHub, and PyProphet 0.22.2 installed from the PyPi installer