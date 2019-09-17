import sys
import os
import pandas as pd
import numpy as np
import subprocess

#vcf_file = "PD3890a_BRCA1_0.99946411.PASS.vcf.gz"
#inclure interval gap en variable

def moduleload():

        subprocess.run(["bash", ThisScript_path+"moduleload.sh"])

def align_fastas(cluster_nmb,outputdir):

		subprocess.run(["bash", ThisScript_path+"align_files.sh"])
##aligning mutated fasta and normal fasta with mafft


def read_VCF_file(vcf_file):
##reading VCF file as panda dataframe
    VCF_df=pd.read_table(vcf_file,comment='#',header=None,skip_blank_lines=True)
    new_df =VCF_df[[0, 1, 3 ,4]].copy()
    new_df.columns = ["CHR", "POS", "REF", "ALT"]
    return new_df


def dataframe_to_list(df):
#this creates a list of pair of line numbers delimmiting clusters in dataframe 
    pos_list = df['POS'].values.tolist()

    return(pos_list)

def find_clusters(vcf_file):

#find line nmb for each cluster pairs
    pair=(0,0)
    cluster_nmb=0
    Pairs={cluster_nmb:pair}
    line_nmb=0
    old_pos=0
    with open(vcf_file) as f:
        for line in f:
            line_nmb += 1
            if not line.startswith("#"):
                ligne = line.split("\t")
                
                if (distance(old_pos,ligne[1])<10):
                    pair=(pair[0],line_nmb)
                else:
                    
                    Pairs[cluster_nmb] = pair
                    pair=(line_nmb,line_nmb)
                    cluster_nmb+=1
                    
                old_pos=ligne[1]
    del Pairs[0]            
    return Pairs




def distance(pos1,pos2):

    pos1=int(pos1)
    pos2=int(pos2)
    distance = abs(pos1 - pos2)
    return(distance)

def make_bed(vcf_file):
    with open(vcf_file) as f1:
            old_pos=0
            cluster_nmb=0
            for line in f1:
                if not line.startswith("#"):
                    ligne = line.split("\t")

                    if (cluster_nmb!=0 and distance(old_pos,ligne[1])>10):
                        file_name = "cluster"+str(cluster_nmb)+".tmp.bed"
                        end_pos=int(old_pos)
                        interval=[chrom,str(start_pos - 200),str(end_pos + 200)]
                        
                        with open(file_name, "w") as f2:


                            f2.write('\t'.join(interval))

                        chrom=ligne[0]                   
                        start_pos=int(ligne[1])
                        cluster_nmb+=1
                    elif (cluster_nmb==0):
                        chrom=ligne[0]                   
                        start_pos=int(ligne[1])
                        cluster_nmb+=1
                        
                    old_pos=ligne[1]

                    file_name = "cluster"+str(cluster_nmb)+".tmp.bed"
                    end_pos=int(ligne[1])
                    interval=[chrom,str(start_pos - 200) ,str(end_pos + 200)]
                    with open(file_name, "w") as f2:

                            f2.write('\t'.join(interval))
    return

def make_fasta(cluster_nmb):

        subprocess.run(["bash",ThisScript_path+"make_mut_fasta.sh",cluster_nmb,ref_file,outputdir])

        return

def align_seq(mut_fasta, normal_fasta):
        return

def make_cluster_files(vcf_file, header_file):
    
#   write header to file
#   write lines to file

    with open(vcf_file) as f1:
            old_pos=0
            cluster_nmb=0
            for line in f1:
                if not line.startswith("#"):
                    ligne = line.split("\t")
                    
                    if (cluster_nmb!=0 and distance(old_pos,ligne[1])>10):
                        file_name = "cluster"+str(cluster_nmb)+".tmp.vcf"
                        with open(file_name, "w") as f2, open(header_file, 'r') as f3:
                            for l in f3:
                                f2.write(l)

                            f2.write("".join(lines))
                                           
                    
                    if (distance(old_pos,ligne[1])<10):

                        
                        lines.append(line)


                    else :
                        cluster_nmb+=1
                        lines=[line]

                        
                    old_pos=ligne[1]
#write last cluster

                    file_name = "cluster"+str(cluster_nmb)+".tmp.vcf"
                    with open(file_name, "w") as f2, open(header_file, 'r') as f3:
                        for line in f3:
                                f2.write(line)
                        f2.write("".join(lines))
                    
    return
    
         
def main():

#        print(find_clusters(vcf_file))
#        make_cluster_files(vcf_file, header_file)
         moduleload()
         make_bed(vcf_file)
         


##args are reference_database_name, reference_file_path, vcf_file 
if __name__ == '__main__':
    if len(sys.argv) != 5:
        print >> sys.stderr, "This Script need exactly 4 arguments; args are <vcf_file>, <header_file>, <reference.fa>, <outputdir>"
        exit(1)
    else:
        ThisScript, vcf_file, header_file, reference , outputdir = sys.argv
        ThisScript_path = os.path.dirname(ThisScript)
        main()

