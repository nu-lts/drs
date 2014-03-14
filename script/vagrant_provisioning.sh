#!/usr/bin/env bash

echo "Adding EPEL repository"
sudo wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm

echo "Adding REMI repository"
sudo wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm

echo "Enabling EPEL and REMI repositories"
sudo rpm -Uvh remi-release-6*.rpm epel-release-6*.rpm

echo "Installing package dependencies"

sudo yum install file-libs-5.04-15.el6.x86_64 --assumeyes
sudo yum install sqlite-devel-3.6.20-1.el6.x86_64 --assumeyes
sudo yum install ghostscript-8.70-19.el6.x86_64 --assumeyes
sudo yum install ImageMagick-6.5.4.7-7.el6_5.x86_64 --assumeyes
sudo yum install redis-2.4.10-1.el6.x86_64 --assumeyes
sudo yum install libreoffice-core-4.0.4.2-9.el6.x86_64 --assumeyes
sudo yum install unzip-6.0-1.el6.x86_64 --assumeyes
sudo yum install git-1.7.1-3.el6_4.1.x86_64 --assumeyes
sudo yum install zsh-4.3.10-7.el6.x86_64 --assumeyes

echo "Installing FITS"

cd ~
curl -O https://fits.googlecode.com/files/fits-0.6.2.zip
unzip fits-0.6.2.zip
chmod +x fits-0.6.2/fits.sh
sudo mv fits-0.6.2 /opt/fits-0.6.2

echo 'PATH=$PATH:/opt/fits-0.6.2' >> ~/.bashrc 
echo 'export PATH'  >> ~/.bashrc 
source /etc/bashrc

echo "Installing RVM"

\curl -L https://get.rvm.io | bash -s stable --rails --ruby=2.0.0

echo "Setting up DRS"

gem install bundler
bundle install
rake db:migrate
rails g hydra:jetty
rake jetty:config
rake reset_data
rake db:test:prepare
touch .git/hooks/pre-push
echo 'rake smoke_test' >> .git/hooks/pre-push

echo "Installing Oh-My-Zsh"

\curl -L http://install.ohmyz.sh | sh
sudo chsh -s /bin/zsh vagrant
