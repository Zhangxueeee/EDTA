#!/bin/bash
# Contributors: Weijia Su (weijia@iastate.edu); Shujun Ou (shujun.ou.1@gmail.com)
# 06/14/2019


####################
### Installation ###
####################

# conda create -n TIR-Learner
# conda activate TIR-Learner
# conda install -y -c anaconda scikit-learn=0.19.0
# conda install -y -c anaconda biopython pandas glob2
# conda install -y -c conda-forge multiprocess regex
# conda install -y -c bioconda blast


#############
### Usage ###
#############

# sh TIR-Learner.sh genome.fa CPU_num


## pre-set parameters
rawFile=$1 #the genome file with relative path
#filePath=`realpath $rawFile`
#genomeFile=`basename $filePath`
#[ -f $genomeFile ] || ln -s $filePath $genomeFile
genomeFile=`realpath $rawFile` #the genome file with real path
genomeName="TIR-Learner"
path=$(dirname "$0") #program path
dir=$(pwd) #current work directory
#grfp="$path/../GenericRepeatFinder/bin/"
grfp="~/las/bin/GenericRepeatFinder/bin/"
t=16 #CPUs

## allow user to specify CPU number
if [ ! -z "$2" ];
        then t=$2
fi


####################
### Preparations ###
####################

echo "############################################################ Pre-Processing ###########################################################"

## Check sequence file
#[ -f $genomeFile ] || ln -s $rawFile $genomeFile
python3 $path/pre.py -g $genomeFile -name $genomeName

## mkdir temp
for i in Module1 Module2 Module3; do [ -d $i ] || mkdir $i; done


################
### Module 1 ###
################

echo "############################################################ Module 1 Begin ###########################################################"

cd $dir"/Module1"
[ -d $genomeName ] || mkdir $genomeName
[ -d temp ] || mkdir temp

if [ ! 0 ]; then #debug
echo test
fi

echo "Module 1, Step 1: Blast Genome against Reference Library"
python3 $path/Module1/Blast_Ref.py -g $genomeFile -name $genomeName -p $path -t $t -d $dir"/Module1"
#python3 $path/Module1/Blast_Ref.py -g $rawFile -name $genomeName -p $path -t $t -d $dir"/Module1"
cp $genomeName/*blast* temp/

echo "Module 1, Step 2: Select 100% coverage entries from Blast results"
python3 $path/Module1/Fullcov.py  -name $genomeName -p $path -d $dir"/Module1"

echo "Module 1, Step 3: Making blastDB and get candidate sequences"
python3 $path/Module1/GetSeq.py -g $genomeFile -name $genomeName -p $path -t $t -d $dir"/Module1"
#python3 $path/Module1/GetSeq.py -g $rawFile -name $genomeName -p $path -t $t -d $dir"/Module1"

echo "Module 1, Step 4: Check TIR and TSD"
python3 $path/Module1/CheckTIRTSD.py -name $genomeName -p $path -t $t -d $dir"/Module1"

echo "Module 1, Step 5: Write to Gff3"
python3 $path/Module1/WriteToGff_M1.py -name $genomeName -p $path -t $t -d $dir"/Module1"

echo "Module 1, Step 6: Check Low Complexity"
python3 $path/Module1/Lowcomp_M1.py -g $genomeFile -name $genomeName -p $path -t $t -d $dir"/Module1"
#python3 $path/Module1/Lowcomp_M1.py -g $rawFile -name $genomeName -p $path -t $t -d $dir"/Module1"

echo "############################################################ Module 1 Finished ###########################################################"

#exit

################
### Module 2 ###
################

echo "############################################################ Module 2 Begin ###########################################################"

cd $dir"/Module2/"
[ -d $genomeName ] || mkdir $genomeName
[ -d temp ] || mkdir temp

echo "Module 2, Step 1: Split Genome and  Run GRF program to find Inverted Repeats"
python3 $path/Module2/RunGRF.py -g $genomeFile -name $genomeName -p $path -t $t -d $dir"/Module2" -grfp $grfp
cp -r $genomeName/$genomeName* temp/

echo "Module 2, Step 2: Process GRF results"
python3 $path/Module2/ProcessGRFmite.py -g $genomeFile -name $genomeName -p $path -t $t -d $dir"/Module2"
cp -r $genomeName/*-p temp/

echo "Module 2 , Step 3 : GRF result blast reference sequences"
python3 $path/Module2/Blast_ref.py -name $genomeName -p $path -t $t -d $dir"/Module2"
cp $genome/*_RefLib temp/

echo "Module 2 , Step 4: Get sequences from 80% similarity"
python3 $path/Module2/GetSeq_M2.py -g $genomeFile -name $genomeName -p $path -t $t -d $dir"/Module2"

echo "Module 2 , Step 5: Check TIR and TSD"
python3 $path/Module2/CheckTIRTSD_M2.py -name $genomeName -p $path -t $t -d $dir"/Module2"

echo "Module 2 , Step 6: Write to gff3"
python3 $path/Module2/WriteToGff_M2.py -name $genomeName -p $path -t $t -d $dir"/Module2"

echo "Module 2 , Step 7: Remove Low complexity"
python3 $path/Module2/Lowcomp_M2.py -g $genomeFile -name $genomeName -p $path -t $t -d $dir"/Module2"

echo "############################################################ Module 2 Finished ###########################################################"


################
### Module 3 ###
################

echo "############################################################ Module 3 Begin ###########################################################"

cd $dir"/Module3/"
[ -d $genomeName ] || mkdir $genomeName
[ -d temp ] || mkdir temp

mv ../Module2/$genomeName/*_nonHomo.fa $genomeName/

echo "Module 3, Step 1: Get dataset"
python3 $path/Module3/getDataset.py -name $genomeName -p $path -t $t -d $dir"/Module3"
cp $genomeName/*.csv temp/
cp $genomeName/*nonHomo.fa temp/

echo "Module 3, Step 2: ML prediction"
python3 $path/Module3/ML_Ensemble.py -g $genomeFile -name $genomeName -p $path -t $t -d $dir"/Module3"

echo "Module 3, Step 3: Check TIR/TSD"
python3 $path/Module3/CheckTIRTSD_M3.py -name $genomeName -p $path -t $t -d $dir"/Module3"

echo "Module 3, Step 4: Write to Gff"
python3 $path/Module3/WriteToGff_M3.py -name $genomeName -p $path -t $t -d $dir"/Module3"

echo "Module 3, Step 5: Remove Low complexity"
python3 $path/Module3/Lowcomp_M3.py -g $genomeFile -name $genomeName -p $path -t $t -d $dir"/Module3"

echo "############################################################ Module 3 Finished ###########################################################"


######################
### Postprocessing ###
######################

echo "############################################################ Post Processing  ###########################################################"

cd $dir
[ -d $genomeName ] || mkdir $genomeName

echo "Get Final GFF"
python3 $path/CombineAll.py -name $genomeName -p $path -t $t -d $dir

mv *.gff3 $genomeName
rm *Low

echo "Get fasta file"
python3 $path/GetAllSeq.py -g $genomeFile -name $genomeName -p $path -t $t -d $dir

mkdir TIR-Learner-Result
mv $genomeName/*FinalAnn.gff3 TIR-Learner-Result/
mv $genomeName/*FinalAnn.fa TIR-Learner-Result/
rm -r $genomeName"_combine"
rm $genomeFile-+-db.nin $genomeFile-+-db.nsd $genomeFile-+-db.nsq $genomeFile-+-db.nhr $genomeFile-+-db.nog $genomeFile-+-db.nsi #shujun
#rm -r $genomeName

echo "############################################################ TIR-Learner is finished! ###########################################################"