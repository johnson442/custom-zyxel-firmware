#!/bin/bash

customdir=/tmp/mount
bcmdir=/tmp/consumer

srcdir=$customdir/zyxel-source/GPL_Release_V100AAJZ17C0

#Test for base build directory
if [ ! -d "$bcmdir" ] ;then

    if [ ! -f "$srcdir/bcm963xx_4.12L.06B_consumer_release.tar.gz" ];then
        echo "Please fetch zyxel source with git (see README) or aquire from Zyxel"
        exit
    else
        mkdir -p /tmp/consumer
        tar -zxvf $srcdir/bcm963xx_4.12L.06B_consumer_release.tar.gz -C /tmp/consumer
        echo "Zyxel source extracted to $bcmdir"
    fi

fi

if [ ! -d "$bcmdir/bcm963xx_router" ] ;then

    echo -n "Run consumer_install? (y/n) "
    read cinstall

    if [ "cinstall" != "${cinstall#[Yy]}" ] ;then

        cd $bcmdir
        #patch < $customdir/consumer_install.patch

        ./consumer_install

        #patch -R < $customdir/consumer_install.patch

        echo "Zyxel consumer_install finished"
        echo ""
    else
        echo "Bye!"
        exit
    fi
fi




echo -n "Apply jumbo frames patch? (y/n)? "
read jumbo

echo -n "Enable multiple telnet sessions? (y/n)? "
read telnet

echo -n "Updated adsl_phy (x6)? (y/n)? "
read adslx6

if [ "$adslx6" != "${adslx6#[Yy]}" ] ;then
    adslx1=n
else
    echo -n "Updated adsl_phy (x1)? (y/n)? "
    read adslx1
fi

echo -n "Enabled custom commands at boot? (y/n)? "
read customcmds

echo -n "Enabled stats logging and webserver? (y/n)? "
read stats

echo ""

echo "Jumbo frames - $jumbo"
echo "Multiple telnet - $telnet"
echo "Updated adsl_phy (x6) - $adslx6"
echo "Updated adsl_phy (x1) - $adslx1"
echo "Custom boot commands - $customcmds"
echo "Stats logging and server - $stats"

echo ""

echo -n "Apply to build? (y/n) "

read doit

if [ "$doit" != "${doit#[Yy]}" ] ;then
    echo ""
else
    echo "Bye!"
    exit
fi

customversion="17"

if [ ! -d "$customdir/original" ] ;then
    mkdir $customdir/original
fi


if [ "$jumbo" != "${jumbo#[Yy]}" ] ;then
    cd $bcmdir
    patch -p3 < $customdir/jumboframes.patch
    customversion+="-jumbo"
    echo "Jumbo frames enabled"
fi

if [ "$telnet" != "${telnet#[Yy]}" ] ;then
    cp $bcmdir/bcm963xx_router/userspace/private/apps/telnetd/telnetd_VMG1312-B10A_save $customdir/original/
    cp $customdir/1312_telnetd $bcmdir/bcm963xx_router/userspace/private/apps/telnetd/telnetd_VMG1312-B10A_save
    customversion+="-tel"
    echo "Multiple telnet sessions enabled"
fi

if [ "$adslx1" != "${adslx1#[Yy]}" ] ;then
    cp $bcmdir/bcm963xx_router/bcmdrivers/broadcom/char/adsl/impl1/adsl_phyVMG1312-B10A.bin_save $customdir/original/
    cp $customdir/A2pv6F039x1_adsl_phy.bin $bcmdir/bcm963xx_router/bcmdrivers/broadcom/char/adsl/impl1/adsl_phyVMG1312-B10A.bin_save
    customversion+="-x1"
    echo "Using updated x1 adsl_phy.bin"
fi

if [ "$adslx6" != "${adslx6#[Yy]}" ] ;then
    cp $bcmdir/bcm963xx_router/bcmdrivers/broadcom/char/adsl/impl1/adsl_phyVMG1312-B10A.bin_save $customdir/original/
    cp $customdir/A2pv6F039x6_adsl_phy.bin $bcmdir/bcm963xx_router/bcmdrivers/broadcom/char/adsl/impl1/adsl_phyVMG1312-B10A.bin_save
    customversion+="-x6"
    echo "Using updated x6 adsl_phy.bin"
fi

if [ "$stats" != "${stats#[Yy]}" ] ;then

    #Build mongoose http server
    cd $customdir/stats-staging/mongoose/
    make
    #Move server and html/css/js to build
    cp $customdir/stats-staging/mongoose/stats-server $customdir/stats-staging/stats-server/stats-server-bin
    cp -r $customdir/stats-staging/stats-server $bcmdir/bcm963xx_router/userspace/private/apps/httpd/
    mv $bcmdir/bcm963xx_router/userspace/private/apps/httpd/stats-server/stats-server-bin $bcmdir/bcm963xx_router/userspace/private/apps/httpd/

    #Save original build files
    cp $bcmdir/bcm963xx_router/userspace/private/apps/httpd/Makefile $customdir/original/httpd_Makefile_1312
    cp $bcmdir/bcm963xx_router/targets/fs.src/etc/profile $customdir/original/1312_profile

    #Replace httpd Makefile and profile with ones that move and launch the stats-server
    #cp $customdir/stats-staging/stats_httpd_Makefile_1312 $bcmdir/bcm963xx_router/userspace/private/apps/httpd/Makefile
    #cp $customdir/stats-staging/1312_stats_profile $bcmdir/bcm963xx_router/targets/fs.src/etc/profile

    cd $bcmdir/bcm963xx_router/userspace/private/apps/httpd/
    patch < $customdir/stats-staging/1312-stats-Makefile.patch

    cd $bcmdir/bcm963xx_router/targets/fs.src/etc/
    patch < $customdir/stats-staging/stats-profile.patch

    customversion+="-stats1.1"

    echo "Stats logging and webserver enabled"
fi

if [ "$customcmds" != "${customcmds#[Yy]}" ] ;then

    #Save original profile
    if [ ! -f $customdir/original/1312_profile ];then
        cp $bcmdir/bcm963xx_router/targets/fs.src/etc/profile $customdir/original/1312_profile
    fi

    cd $bcmdir/bcm963xx_router/targets/fs.src/etc/
    patch < $customdir/customcmd-profile.patch

    customversion+="-cmd"
fi



#Save original version string file
cp $bcmdir/bcm963xx_router/targets/VMG1312-B10A/VMG1312-B10A $customdir/original/VMG1312-B10A_vstring
versionfile=$bcmdir/bcm963xx_router/targets/VMG1312-B10A/VMG1312-B10A

#Use selected features to update version string
sed -i "s|MSTC_EXTERNAL_VERSION=\"1.00(AAJZ.17)C0\"|MSTC_EXTERNAL_VERSION=\"$customversion\"|g" $versionfile
sed -i "s|MSTC_INTERNAL_VERSION=\"1.00(AAJZ.17)C0\"|MSTC_INTERNAL_VERSION=\"$customversion\"|g" $versionfile

echo "Version string updated to "$customversion

echo -n "Continue to actual build (y/n)? "
read build

if [ "$build" != "${build#[Yy]}" ] ;then

    cd $bcmdir/bcm963xx_router/
    make PROFILE=VMG1312-B10A


    if [ ! -d "$customdir/images" ] ;then
        mkdir $customdir/images
    fi

    model="1312-B10A-"
    customversion+=".bin"
    model+=$customversion
    cp images/ras.bin $customdir/images/$model

    echo ""
    echo "Build complete, image saved to "$customdir"/images/"$model
    echo ""
    echo "Check for rational file size! 17-19MB"
    echo ""
fi

echo -n "Revert all changes to build? (y/n)? "
echo -n "Same can be achieved by removing bcm963xx_router folder and extracting again."
read revert

if [ "$revert" != "${revert#[Yy]}" ] ;then
: '
    cd $bcmdir/bcm963xx_router/
    make clean

    if [ "$jumbo" != "${jumbo#[Yy]}" ] ;then
        cd $bcmdir
        patch -R -p3 < $customdir/jumboframes.patch
        echo "Jumbo frames patch reversed"
    fi

    if [ "$telnet" != "${telnet#[Yy]}" ] ;then
        cp $customdir/original/telnetd_VMG1312-B10A_save $bcmdir/bcm963xx_router/userspace/private/apps/telnetd/telnetd_VMG1312-B10A_save
        echo "Original telnetd restored"
    fi

    if [ "$adslx1" != "${adslx1#[Yy]}" ] ;then
        cp $customdir/original/adsl_phyVMG1312-B10A.bin_save $bcmdir/bcm963xx_router/bcmdrivers/broadcom/char/adsl/impl1/adsl_phyVMG1312-B10A.bin_save
        echo "Original adsl_phy.bin restored"
    fi

    if [ "$adslx6" != "${adslx6#[Yy]}" ] ;then
        cp $customdir/original/adsl_phyVMG1312-B10A.bin_save $bcmdir/bcm963xx_router/bcmdrivers/broadcom/char/adsl/impl1/adsl_phyVMG1312-B10A.bin_save
        echo "Original adsl_phy.bin restored"
    fi

    if [ "$stats" != "${stats#[Yy]}" ] ;then

    rm -rf $bcmdir/bcm963xx_router/userspace/private/apps/httpd/stats-server/
    rm -f $bcmdir/bcm963xx_router/userspace/private/apps/httpd/stats-server-bin

    cp $customdir/original/httpd_Makefile_1312 $bcmdir/bcm963xx_router/userspace/private/apps/httpd/Makefile
    cp $customdir/original/1312_profile $bcmdir/bcm963xx_router/targets/fs.src/etc/profile

    cd $customdir/stats-staging/mongoose
    make clean
    rm $customdir/stats-staging/stats-server/stats-server-bin

    echo "Stats logging and webserver removed"
    fi

    if [ "$customcmds" != "${customcmds#[Yy]}" ] ;then
        cp $customdir/original/1312_profile $bcmdir/bcm963xx_router/targets/fs.src/etc/profile
        echo "Custom commands removed"
    fi

    cp $customdir/original/VMG1312-B10A_vstring $bcmdir/bcm963xx_router/targets/VMG1312-B10A/VMG1312-B10A
    echo "Restored version string"
'
     rm -rf $bcmdir/bcm963xx_router
     cd $bcmdir

     patch < $customdir/consumer_install_source.patch

     ./consumer_install

     patch -R < $customdir/consumer_install_source.patch


     echo ""
     echo "Clean source extracted to $bcmdir/bcm963xx_router"
     echo ""
     echo "Bye"

     if [ "$stats" != "${stats#[Yy]}" ] ;then
         cd $customdir/stats-staging/mongoose
         make clean
         rm $customdir/stats-staging/stats-server/stats-server-bin
     fi

fi


