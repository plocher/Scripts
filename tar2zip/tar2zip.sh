#!/bin/sh
# convert a tar.gz file (as produced by makeboard) into the form used by seeed studio's fusion product


tarfile=$1
zipdir=`echo $tarfile | sed -e "s/\.gerbers\.tar$//"`
zipfile=`echo $tarfile | sed -e "s/\.tar$/\.zip/"`
echo "$tarfile ==> $zipdir  ...   $zipfile"
mkdir $zipdir
cd $zipdir
tar xvf ../$tarfile
cd ..
zip -r $zipfile $zipdir
rm -rf $zipdir
if [ ! -d OLD ] ; then  mkdir OLD; fi
mv $tarfile OLD

