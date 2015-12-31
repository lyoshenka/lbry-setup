#!/bin/sh

rm —R -f /Library/Python/2.7/site-packages/lbrynet-0.0.4-py2.7.egg
rm -f /usr/local/bin/lbrynet-announce_hash_to_dht
rm -f /usr/local/bin/lbrynet-console
rm -f /usr/local/bin/lbrynet-create-network
rm -f /usr/local/bin/lbrynet-daemon
rm -f /usr/local/bin/lbrynet-gui
rm -f /usr/local/bin/lbrynet-launch-node
rm -f /usr/local/bin/lbrynet-launch-rpc-node
rm -f /usr/local/bin/lbrynet-lookup-hosts-for-hash
rm -f /usr/local/bin/lbrynet-rpc-node-cli
rm -f /usr/local/bin/lbrynet-stdin-uploader
rm -f /usr/local/bin/lbrynet-stdout-downloader
rm -R -f /Applications/LBRY.app

easy_install pip
pip install gmpy

git clone https://github.com/lbryio/lbry.git
cd lbry
python setup.py install
cd ..
rm -R lbry

git clone https://github.com/jackrobison/lbrynet-app.git
cd lbrynet-app
unzip LBRY.app.zip
mv -f LBRY.app /Applications
cd ..
rm -R lbrynet-app
chmod +x /Applications/LBRY.app/Contents/Resources/lbrycrdd
chmod +x /Applications/LBRY.app/Contents/Resources/lbrycrd-cli
