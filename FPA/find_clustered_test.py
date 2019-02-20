import sys
import os
import subprocess
import argparse



class Cluster:
    def __init__(self,chrom,start_pos,end_pos, pos_list,cluster_nmb,mut_dict):
        self.chrom = str(chrom)
        self.start_pos = start_pos
        self.end_pos = end_pos
        self.pos_list = pos_list  
        self.cluster_nmb = cluster_nmb
        self.mut_dict = mut_dict   
    
    def get_ref_sequence(self):
        deletion_length=0
        for pos, mut in self.mut_dict.items():

            if len(mut[0]) > 1:
                deletion_length=deletion_length+(len(mut[0])-1)
        interval=self.chrom+":"+str(self.start_pos - int(extension))+"-"+str(self.end_pos + int(extension) + deletion_length)
        seq=(subprocess.check_output(["bash", ThisScript_path+"/getSequence.sh",reference,interval])).decode('utf-8')
        print(len(seq))
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

    def make_fasta(self,seq_ref,seq_mut):
        
        fasta=">"+str(self.chrom)+"\t"+str(int(self.start_pos)-int(extension))+":"+str((int(self.end_pos)+int(extension)+self.deletion_length()))+"_reference_sequence"+"\n"+seq_ref+">"+str(self.chrom)+"\t"+str(int(self.start_pos)-int(extension))+":"+str((int(self.end_pos)+int(extension)+self.deletion_length()))+"_mutated_sequence"+"\n"+seq_mut
 
        return(fasta)
         
    def deletion_length(self):
        deletion_length=0
        for pos, mut in self.mut_dict.items():

            if len(mut[0]) > 1:
                deletion_length=deletion_length+(len(mut[0])-1)
        
        return(deletion_length)
    
    def make_bed(self):

        file_name = "cluster"+str(self.cluster_nmb)+".tmp.bed"
        print(file_name)
        interval=self.chrom,str(self.start_pos - int(extension)),str(self.end_pos + int(extension))
        print("interval is: " + interval)
        with open(file_name, "w") as f1:

            f1.write('\t'.join(interval))
        return
def distance(pos1,pos2):

    pos1=int(pos1)
    pos2=int(pos2)
    distance = abs(pos1 - pos2)
    return(distance)

def write(text_string,output_file):

        with open(output_file, "w") as f1:
            f1.write(text_string)
        return

def mafft_alignment(fasta_file,aligned_fasta_name):

    subprocess.run(["bash",ThisScript_path+"/mafft.sh",fasta_file,aligned_fasta_name])
    return

def annotate_vcf(vcf_file,dist,output):

#TODO: must change error redirecting to somekind of log file instead of /dev/null (the blackhole of linux)
    subprocess.run(["bash",ThisScript_path+"/add_cluster_info.sh",vcf_file,dist,output])
    return()




def main():
        print(reference)
        print(extension)
        annotate_vcf(vcf_file,dist,outputdir)
        annotated_vcf_file=outputdir+vcf_file_name+".snpCluster.vcf"
        print(annotated_vcf_file)
        with open(annotated_vcf_file) as f1:
            old_pos=0
            cluster_nmb=0
            pos_list=[]
            mut_dict={}
            chrom=0
            start_pos=0
            end_pos=0
            for line in f1:
                if not line.startswith("#"):
                    ligne = line.split("\t")

                    if (cluster_nmb!=0 and distance(old_pos,ligne[1])>10):
                        end_pos=int(old_pos)  
                                              
                        cluster=Cluster(chrom,start_pos,end_pos,pos_list,cluster_nmb,mut_dict)
                        print("this is cluster nmb: "+ str(cluster_nmb))
                        print(mut_dict)
                        ref_seq=cluster.get_ref_sequence()
                        mut_seq=cluster.get_mutated_sequence(ref_seq)
                        fasta=cluster.make_fasta(ref_seq,mut_seq)
                        fasta_name="cluster"+str(cluster_nmb)+".tmp.fasta"
                        write(fasta,fasta_name)
                        aligned_fasta_name="cluster"+str(cluster_nmb)+".aln.tmp.fasta"
                        mafft_alignment(fasta_name,aligned_fasta_name)
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
            ref_seq=cluster.get_ref_sequence()
            mut_seq=cluster.get_mutated_sequence(ref_seq)
            fasta=cluster.make_fasta(ref_seq,mut_seq)
            fasta_name="cluster"+str(cluster_nmb)+".tmp.fasta"
            write(fasta,fasta_name)
            aligned_fasta_name="cluster"+str(cluster_nmb)+".aln.tmp.fasta"
            mafft_alignment(fasta_name,aligned_fasta_name)


#TODO:chose output directory
if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    optional = parser._action_groups.pop() #this will remove optional args to place them after required when outputing the usage
    required = parser.add_argument_group('required arguments')
    required.add_argument("-r","--reference", type=str, help="This is the reference genome used to identify mutations in the input vcf file", required=True)
    required.add_argument("-v","--vcf_file", type=str, help="This is the input vcf, can not be in gzip format (please gunzip it first)", required=True)
    optional.add_argument("-e","--extension", type=int, default="200", help="This will define how long you chose to extend the sequence on both side of the cluster [default=200]",required=False)
    optional.add_argument("-d","--distance", type=str, default="10", help="This will define the maximum distance between two mutations to define a cluster [default=10]",required=False)
    optional.add_argument("-o","--output", type=str, default="./", help="Chose were all intermediat and final files are output",required=False)
    parser._action_groups.append(optional)

    
   # parser.parse_args(['-h'])
    args=parser.parse_args()
    print ("Input file: %s" % args.vcf_file)
    reference=args.reference
    vcf_file=args.vcf_file
    vcf_file_name=os.path.basename(vcf_file)
    print(vcf_file_name)
    extension=args.extension
    dist=args.distance
    outputdir=args.output
    
    ThisScript= sys.argv[0]
    ThisScript_path = os.path.dirname(ThisScript)

    main()
   
    

