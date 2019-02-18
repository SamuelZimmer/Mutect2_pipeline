import sys
import os
import pandas as pd
import numpy as np
import subprocess

#vcf_file = "PD3890a_BRCA1_0.99946411.PASS.vcf.gz"
#inclure interval gap en variable




class Cluster:
    def __init__(self,chrom,start_pos,end_pos, pos_list,cluster_nmb,mut_dict):
        self.chrom = chrom
        self.start_pos = start_pos
        self.end_pos = end_pos
        self.pos_list = pos_list  
        self.cluster_nmb = cluster_nmb
        self.mut_dict = mut_dict   
    
    def get_ref_sequence(self):
        cluster_length=0
        for pos, mut in self.mut_dict.items():

            if len(mut[1]) > 1:
                cluster_length=cluster_length+(len(mut[1])-1)
                        
        interval=self.chrom+":"+str(self.start_pos - int(extension))+"-"+str(self.end_pos + int(extension) + cluster_length)
        seq=(subprocess.check_output(["bash", ThisScript_path+"/getSequence.sh",reference,interval])).decode('utf-8')
        return(seq)

    def get_mutated_sequence(self,ref_seq):
        
        print("This is the normal sequence")
        print(ref_seq)
        Seq=list(ref_seq)
        seq_lag=0
        for pos, mut in self.mut_dict.items():

            if int(pos) == int(self.start_pos):
                if len(mut[0])<=len(mut[1]):
                    Seq[int(extension)]=mut[1]
                else:
                    del Seq[(int(extension)+1):(int(extension)+len(mut[0]))]
                    seq_lag=seq_lag+len(mut[0])-1
                print("after first mutation")
                print("".join(Seq))

            else :
                if len(mut[0])<=len(mut[1]):
                    Seq[int(extension)+distance(pos,self.start_pos)-seq_lag]=mut[1]
                
                else:
                    del Seq[(int(extension)+distance(self.start_pos,pos)+1)-seq_lag:(int(extension)+distance(self.start_pos,pos)+len(mut[0]))-seq_lag]
                    seq_lag=seq_lag+len(mut[0])-1
                print("after next mutation")
                print("".join(Seq))

        print("this is the final mutated sequence")
        print("".join(Seq))
        return("".join(Seq))

def make_fasta(seq):

    return
         

def distance(pos1,pos2):

    pos1=int(pos1)
    pos2=int(pos2)
    distance = abs(pos1 - pos2)
    return(distance)

def make_bed(self):

    file_name = "cluster"+str(self.cluster_nmb)+".tmp.bed"
    print(file_name)
    interval=self.chrom,str(self.start_pos - int(extension)),str(self.end_pos + int(extension))
    print("interval is: " + interval)
    with open(file_name, "w") as f1:

        f1.write('\t'.join(interval))
         
def main():

        with open(vcf_file) as f1:
            old_pos=0
            cluster_nmb=0
            pos_list=[]
            mut_dict={}
            chrom=0
            start_pos=0
            for line in f1:
                if not line.startswith("#"):
                    ligne = line.split("\t")

                    if (cluster_nmb!=0 and distance(old_pos,ligne[1])>10):
                        end_pos=int(old_pos)  
                                              
                        cluster=Cluster(chrom,start_pos,end_pos,pos_list,cluster_nmb,mut_dict)
                        print("this is cluster nmb: "+ str(cluster_nmb))
                        print(mut_dict)
                        cluster.get_mutated_sequence(cluster.get_ref_sequence())
                        mut_dict={}
                        mut_dict[ligne[1]]=(ligne[3],ligne[4])
                        pos_list=[ligne[1]]
                                    
                        chrom=ligne[0]                   
                        start_pos=int(ligne[1])
                        cluster_nmb+=1
                        

                    if (distance(old_pos,ligne[1])<10):

                        pos_list.append(ligne[1])
                        mut_dict[ligne[1]]=(ligne[3],ligne[4])
                        

                    elif (cluster_nmb==0):
                        chrom=ligne[0]                   
                        start_pos=int(ligne[1])
                        cluster_nmb+=1
                        pos_list.append(ligne[1])
                        mut_dict[ligne[1]]=(ligne[3],ligne[4])
                        
                        
                        
                    old_pos=ligne[1]

                    end_pos=int(ligne[1])
            cluster=Cluster(chrom,start_pos,end_pos,pos_list,cluster_nmb,mut_dict)
            print("this is cluster nmb: "+ str(cluster_nmb))
            print(mut_dict)
            cluster.get_mutated_sequence(cluster.get_ref_sequence())



        

##args are reference_database_name, reference_file_path, vcf_file 
if __name__ == '__main__':
    if len(sys.argv) != 4:
        print >> sys.stderr, "This Script need exactly 3 arguments; args are <vcf_file>, <reference.fa>, <int(extension) size [int]>"
        exit(1)
    else:
        ThisScript, vcf_file, reference, extension = sys.argv
        ThisScript_path = os.path.dirname(ThisScript)
        main()

