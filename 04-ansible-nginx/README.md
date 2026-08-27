# Devoir Ansible - nginx + durcissement

## Roles
- **nginx** : configuration via template Jinja2 (nginx.conf.j2, index.html.j2) et variables dans defaults/main.yml. Page web minimale avec bouton + compteur JS. Handler `restart nginx`.
- **fail2ban** (bonus) : configuration jail.local via template Jinja2, execute et teste en local (WSL). Handler `restart fail2ban`.
- **ufw** (bonus) : code complet et fonctionnel, non execute dans playbook.yml car applique a WSL, un firewall bloquerait l'acces reseau de la machine de developpement elle-meme. Pret a etre execute sur un vrai serveur cible (ex: instance EC2) en ajoutant `- ufw` a la liste des roles.

## Execution
