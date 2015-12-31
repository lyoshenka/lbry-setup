#!/bin/sh

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