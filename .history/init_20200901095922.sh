#!/bin/bash
apt-get install software-properties-common -y
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable"
apt-get update -y
apt-get -y install docker-ce
curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)"\
   -o /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/1.26.2/contrib/completion/bash/docker-compose\
   -o /etc/bash_completion.d/docker-compose
chmod +x /usr/local/bin/docker-compose
#ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
usermod -aG docker jenkins
usermod -aG docker bitnami

mkdir /app
mkdir /ngx
aws s3 sync s3://16-ted-search/app/ /app
aws s3 cp s3://16-ted-search/nginx.conf /ngx/nginx.conf
aws s3 cp s3://16-ted-search/my-wait.sh /ngx/my-wait.sh
aws s3 sync s3://16-ted-search/static/ /ngx/static
aws s3 cp s3://16-ted-search/ec2-compose.yml /docker-compose.yml

sed -i 's|http://backends;|http://prod:9191;|' /ngx/nginx.conf
service docker start