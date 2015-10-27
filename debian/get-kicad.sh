#!/bin/bash

echo "========== Getting the revision number ==================="
revision=$(bzr log lp:kicad/4.0| head -n 2 | grep revno| awk '{print $2}')
version=4.0~bzr$revision
echo "Version: $version"
package=kicad-$version
origtarxz=kicad_$version.orig.tar.xz

echo "========== Getting the stable core ======================="
bzr export -r $revision $package lp:kicad/4.0
echo "========== Getting the UI translations ==================="
# TODO: Instead of cloning, we may be able to use git archive --remote <url> <sha1>
git clone https://github.com/KiCad/kicad-i18n $package/kicad-i18n
echo "========== Getting the documents ========================="
git clone https://github.com/KiCad/kicad-doc $package/kicad-doc
echo "========== Getting the module and symbol libraries ======="
git clone https://github.com/KiCad/kicad-library $package/kicad-library
echo "========== Getting the footprint libraries ==============="
mkdir -p $package/kicad-pretty
# Use github API to list repos for org KiCad, then subset the JSON reply for only
# *.pretty repos in the "full_name" variable.
PRETTY_REPOS=`curl https://api.github.com/orgs/KiCad/repos?per_page=2000 2> /dev/null \
	| sed -E 's:.+ "full_name".*"KiCad/(.+\.pretty)",:\1:p;d'`
PRETTY_REPOS=`echo $PRETTY_REPOS | tr " " "\n" | sort`
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
for pretty in $PRETTY_REPOS; do
	echo "Getting: $pretty"
	git clone https://github.com/KiCad/$pretty $package/kicad-pretty/$pretty
done
IFS=$SAVEIFS

echo "========== Compressing the archive ======================="
tar --create --xz --exclude=.git --file $origtarxz $package
echo "Sizes:"
echo "Core:       "$(du --exclude=kicad-i18n --exclude=kicad-doc --exclude=kicad-library --exclude=kicad-pretty -sh $package)
echo "I18n:       "$(du --exclude=.git -sh $package/kicad-i18n)
echo "Doc:        "$(du --exclude=.git -sh $package/kicad-doc)
echo "Library:    "$(du --exclude=.git -sh $package/kicad-library)
echo "Footprints: "$(du --exclude=.git -sh $package/kicad-pretty)

