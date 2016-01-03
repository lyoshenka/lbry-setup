# lbry-setup

An installer to set up [lbry](https://github.com/lbryio/lbry) and [lbrycrd](https://github.com/lbryio/lbrycrd) for Linux.

If you're a Linux user who never uses anything that is more than one step to install, this is for you. However, it is written by an idiot. We can only officially recommend that you follow the individual steps above until non-idiots have certified the script's correctness.

Run this into your shell:

    bash <( \curl -sSL https://raw.githubusercontent.com/lbryio/lbry-setup/master/lbry_setup.sh )

If you don't have `curl`, you can use `wget`

    bash <( \wget -qO- https://raw.githubusercontent.com/lbryio/lbry-setup/master/lbry_setup.sh )


If you want to customize the install directory, put `INSTALL_DIR="/path/to/dir" ` at the beginning of the above command. You can also change the `CONFIG_DIR` the same way if you want.