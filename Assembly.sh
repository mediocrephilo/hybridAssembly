## End assembly if command fails
set -e

## Set color variables
Original=$"\033[0m"
Yellow=$"\033[1;33m"
Green=$"\033[0;32m"
Red=$"\033[0;31m"
Blue=$"\033[1;34m"

## Ask for pathway to assembly directory
echo -e "${Blue}Please enter absolute pathway to assembly directory: ${Original}"
read Pathway
echo -e "\n \n"
echo -e "${Yellow}Assembly will be performed in directory:${Original}$Pathway \n \n"

## Move to assembly directory
echo -e "${Yellow}Moving to assembly directory...${Original}"
cd $Pathway
echo -e "\n \n"

## Ask for sample name
echo -e "${Blue}Please input sample ID for naming output files:${Original}"
read ID
echo -e "${Yellow}Sample name is: ${Original}$ID \n \n"

## Ask for unicycler mode
echo -e "${Blue}What mode would you like to run unicycler in? Please enter either normal, bold, or conservative:${Original}"
read Mode

## Check if unicycler mode is correct
if ! [[ ${Mode} =~ ^(normal|bold|conservative)$ ]];
then echo -e "${Red}Unicycler mode not recognized, ending assembly...${Original}" & exit
else echo -e "${Yellow}Unicycler will run in $Mode mode...${Original} \n \n"
fi

## Set date variable
Date=$(date +%m-%d-%Y_%H:%M)

## Show commands for assembly
set -x

## Make assembly directory
{ echo -e "${Yellow}Creating new assembly directory...${Original}"; } 2> /dev/null
mkdir ${ID}_Assembly_${Date}
{ echo -e "\n \n"; } 2> /dev/null

## Set short and long read variables
{ echo -e "${Yellow}Setting short and long read variables...${Original}"; } 2> /dev/null
Long=*NB*.fastq*
Short1=*R1*.fastq*
Short2=*R2*.fastq*
{ echo -e "\n \n"; } 2> /dev/null

## Copy all assembly files to assembly directory
{ echo -e "${Yellow}Copying all assembly files to new directory...${Original}"; } 2> /dev/null
cp $Long ${ID}_Assembly_${Date}
cp $Short1 ${ID}_Assembly_${Date}
cp $Short2 ${ID}_Assembly_${Date}
{ echo -e "\n \n"; } 2> /dev/null

## Move to new assembly directory
{ echo -e "${Yellow}Moving to new assembly directory...${Original}"; } 2> /dev/null
cd ${ID}_Assembly_${Date}
{ echo -e "\n \n"; } 2> /dev/null

## Perform short read trimming
{ echo -e "${Yellow}Performing short read trimming with trimmomatic...${Original}"; } 2> /dev/null
conda run -n trimmomaticENV trimmomatic PE -trimlog ${ID}_Short_Reads_Trimmed.txt -summary ${ID}_Summary_Stats.txt $Short1 $Short2 -baseout ${ID}_Trimmed.fastq.gz SLIDINGWINDOW:4:20 MINLEN:15
{ echo -e "\n \n"; } 2> /dev/null

## Set trimmed short read variables
{ echo -e "${Yellow}Setting trimmed short read variables...${Original}"; } 2> /dev/null
Short1_Trimmed=*1P*.fastq.gz
Short2_Trimmed=*2P*.fastq.gz
{ echo -e "\n \n"; } 2> /dev/null

## Perform long read trimming
{ echo e- "${Yellow}Performing long read trimming with NanoFilt...${Original}"; } 2> /dev/null
conda run -n nanoENV NanoFilt -q 7 -l 200 $Long | gzip > ${ID}_Long_Reads_Trimmed.fastq.gz
{ echo -e "\n \n"; } 2> /dev/null

## Set trimmed long read variable
{ echo -e "${Yellow}Setting trimmed long read variable...${Original}"; } 2> /dev/null
Long_Trimmed=${ID}Long_Reads_Trimmed.fastq.gz
{ echo -e "\n \n"; } 2> /dev/null

## Run nanostat on filtered long reads
{ echo -e "${Yellow}Creating long read trimming stats file...${Original}"; } 2> /dev/null
conda run -n nanoENV NanoStat --fastq $Long_Trimmed > ${ID}_NanoStat.txt
{ echo -e "\n \n"; } 2> /dev/null

## Run unicycler assembly
{ echo -e "${Yellow}Performing assembly with unicycler...${Original}"; } 2> /dev/null
conda run -n unicycler5ENV unicycler -1 $Short1_Trimmed -2 $Short2_Trimmed -l $Long_Trimmed -o ${ID}_Unicycler_Assembly --mode $Mode
{ echo -e "\n \n"; } 2> /dev/null

## Move to unicycler assembly folder
{ echo -e "${Yellow}Moving to unicycler assembly folder...${Original}"; } 2> /dev/null
cd ${ID}_Unicycler_Assembly
{ echo -e "\n \n"; } 2> /dev/null

## Run QUAST
{ echo -e "${Yellow}Performing quality assessment with QUAST...${Original}"; } 2> /dev/null
conda run -n quastENV quast *assembly.fasta -o ${ID}_QUAST
{ echo -e "\n \n"; } 2> /dev/null

## Annoatate genome with Prokka
{ echo -e "${Yellow}Annotating genome with Prokka...${Original}"; } 2> /dev/null
conda run -n prokkaENV prokka --prefix $ID --outdir ${ID}_Prokka *assembly.fasta
{ echo -e "\n \n"; } 2> /dev/null

## Print assembly completion message
{ echo -e "${Green}Assembly complete, have a nice day!${Original}"; } 2> /dev/null
