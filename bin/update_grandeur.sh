#/bin/bash

#####################################################
# written by Erin Young                             #
# for creating a new directory for grandeur for ICA #
#####################################################

USAGE="""
To put the Grandeur files in ICA_Modified_Nextflow_Scripts

# to update from ~/sandbox/Grandeur
update_grandeur.sh -v version
# to download from github
update_grandeur.sh -v version -g
"""

echo $USAGE

github=""

while getopts "gv:h" o; do
    case "${o}" in
        g)
            echo "Downloading from github"
            github=true
        ;;
        v)
            VER=${OPTARG}
            echo "Specifying version as $VER"
        ;;
        :)
            echo "Nothing specified for option. Exiting."
            echo $USAGE
            exit 1
        ;;
        *)
            echo "What is $OPTARG ?"
            echo $USAGE
            exit 1
        ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$VER" ] ; then echo "$(date): VERSION MUST BE SPECIFIED" ; echo $USAGE; exit 1; fi


if [ -z "$github" ]
then
    rsync -rvh ~/sandbox/Grandeur ~/sandbox/ICA_Modified_Nextflow_Scripts --exclude=".[!.]*"
    mv ~/sandbox/ICA_Modified_Nextflow_Scripts/Grandeur ~/sandbox/ICA_Modified_Nextflow_Scripts/Grandeur-$VER
    echo "$(date): sync complete"
else
    cd ~/sandbox/ICA_Modified_Nextflow_Scripts
    wget https://github.com/UPHL-BioNGS/Grandeur/archive/refs/tags/v$VER.tar.gz
    tar -xzf v$VER.tar.gz
    rm v$VER.tar.gz
    # resulting directory name is Grandeur-$VER
    echo "$(date): download complete"
fi

# removing all the commends for ICA specific configurations
cd ~/sandbox/ICA_Modified_Nextflow_Scripts/Grandeur-$VER
for module in modules/*
do
    cat $module | sed 's/\/\/#UPHLICA //g' > $module.tmp
    mv $module.tmp $module
done

# changing the database directories
cat grandeur.nf | \
    sed 's/^params.kraken2_db.*/params.kraken2_db = workflow.launchDir + "\/kraken2_db\/"/g' | \
    sed 's/^params.blast_db.*/params.blast_db = workflow.launchDir + "\/blast_db\/"/g' | \
    sed 's/^params.mash_db.*/params.mash_db = workflow.launchDir + "\/new_mash\/"/g' \
    > grandeur.nf.tmp

mv grandeur.nf.tmp grandeur.nf

echo "$(date): Finished!"