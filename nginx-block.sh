set -euo pipefail
sudo apt install -y nginx
sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/conf.d/globalblacklist.conf -O /etc/nginx/conf.d/globalblacklist.conf

if [ ! -d "/etc/nginx/bots.d" ]; then
  mkdir /etc/nginx/bots.d
fi

sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/bots.d/blockbots.conf -O /etc/nginx/bots.d/blockbots.conf
sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/bots.d/ddos.conf -O /etc/nginx/bots.d/ddos.conf
sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/bots.d/whitelist-ips.conf -O /etc/nginx/bots.d/whitelist-ips.conf
sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/bots.d/whitelist-domains.conf -O /etc/nginx/bots.d/whitelist-domains.conf
sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/bots.d/blacklist-user-agents.conf -O /etc/nginx/bots.d/blacklist-user-agents.conf
sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/bots.d/custom-bad-referrers.conf -O /etc/nginx/bots.d/custom-bad-referrers.conf
sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/bots.d/blacklist-ips.conf -O /etc/nginx/bots.d/blacklist-ips.conf
sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/bots.d/bad-referrer-words.conf -O /etc/nginx/bots.d/bad-referrer-words.conf
sudo wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/conf.d/botblocker-nginx-settings.conf -O /etc/nginx/conf.d/botblocker-nginx-settings.conf
sudo wget https://raw.githubusercontent.com/xlabr/u/sh/nginx/agentdeny -O /etc/nginx/conf.d/agentdeny
sudo wget https://raw.githubusercontent.com/xlabr/u/sh/nginx/goodbotoblack -O /etc/nginx/bots.d/blacklist-user-agents.conf
