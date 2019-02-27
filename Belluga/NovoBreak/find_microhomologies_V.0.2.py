import sys
import os
import pandas as pd
import numpy as np
import subprocess


def identifymicrohomologies(consensus_length,blastfile_name):

        blast_results_df = pd.read_table(blastfile_name,comment='#',header=None,skip_blank_lines=True)
        blast_length = 0
        i = 0
        subject_ID = ""
        first_alignment_length = 0
        second_alignment_length = 0
        for line in blast_results_df.itertuples(index=True, name='Pandas'):
                if i == 2:
                        break
                if subject_ID == line[2]:
                        continue

                if line[5] <= 2 and first_alignment_length == 0:
                        first_alignment_length = line[4]
                        subject_ID = line[2]
                        i += 1
                        continue

                elif line[6] == consensus_length and second_alignment_length == 0:
                        second_alignment_length = line[4]
                        subject_ID = line[2]
                        i += 1
                        continue



        microhomology_length = first_alignment_length + second_alignment_length - consensus_length


        return microhomology_length

def makequeryfile(ID,QUERY):

        query_file_name = ID + '.query.tmp'
        query_file = open(query_file_name,'w')
        query_file.write(">"+ID+"\n"+QUERY)
        query_file.close
        return query_file_name

def makefastafile(reference,position1,position2,ThisScript_path):
        SEQUENCE1 = subprocess.check_output(["bash", ThisScript_path+"/getSequence.sh",reference,position1])
        SEQUENCE2 = subprocess.check_output(["bash", ThisScript_path+"/getSequence.sh",reference,position2])


        fasta_file = open('regions.tmp.fa', 'w')
        fasta_file.write(SEQUENCE1.decode('utf-8')+SEQUENCE2.decode('utf-8'))
        fasta_file.close()
        return

def read_VCF_file(vcf_file):
##reading VCF file as panda dataframe
        VCF_df=pd.read_table(vcf_file,comment='#',header=None,skip_blank_lines=True)
        VCF_df[[7, 'ORIENTATION', 'CIPOS', 'CIEND', 'TYPE', 'CONSENSUS', 'SVTYPE', 'CHR2', 'END', 'SVLEN']] = VCF_df[7].str.split(';',expand=True)
        new_df =VCF_df[[10,11,'SVTYPE',0,1,'CHR2','END','CONSENSUS','SVLEN','ORIENTATION',12]].copy()
        final_VCF_df=new_df.rename({0:'CHR1', 1:'POS', 10:'IDENTIFIER', 11:'CONTIGID', 12:'CONSENSUSLENGTH'}, axis='columns')

        ###this can probably be done in oneline ( changing "=" to "")

        final_VCF_df['SVTYPE'] = final_VCF_df['SVTYPE'].str.replace(r'SVTYPE=', '').astype('str')
        final_VCF_df['END'] = final_VCF_df['END'].str.replace(r'END=', '').astype('int')
        final_VCF_df['ORIENTATION'] = final_VCF_df['ORIENTATION'].str.replace(r'CT=', '').astype('str')
        final_VCF_df['SVLEN'] = final_VCF_df['SVLEN'].str.replace(r'SVLEN=', '').astype('int')
        final_VCF_df['CONSENSUS'] = final_VCF_df['CONSENSUS'].str.replace(r'CONSENSUS=', '').astype('str')
        final_VCF_df['CHR2'] = final_VCF_df['CHR2'].str.replace(r'CHR2=', '').astype('str')
        final_VCF_df['CONSENSUSLENGTH'] = final_VCF_df['CONSENSUSLENGTH'].str.replace(r'size', '').astype('int')
        final_VCF_df['MICROHOMOLOGY']= "FALSE"
        final_VCF_df['MICROHOMOLOGYLENGTH']= 0

        return final_VCF_df

def makeblastgenomedb(reference,database,ThisScript_path):


        subprocess.run(["bash",ThisScript_path+"/makeblastgenomedb.sh",reference, database])
        return

def makeblastcustomdb(fasta_file,ID,ThisScript_path):

        customdb_name = ID + ".blast.tmp.db"
        subprocess.run(["bash",ThisScript_path+"/makeblastcustomdb.sh",fasta_file,customdb_name])
        return customdb_name

def blastn(query,database,ThisScript_path):

        blastfile_name = query + "_blast.out"
        subprocess.run(["bash",ThisScript_path+"/blastn.sh",query,database])
        return blastfile_name


def main():
        if os.path.exists(ThisScript):
                print ("Found the script at: " + ThisScript)


#check if database is there already (if dir is already created)
        #if database.is_dir()==False:
        #database_directory = os.getcwd() + "/" + database
        if os.path.exists(database)==False:
                print ("Making genome blast database")
                makeblastgenomedb(reference,database,ThisScript_path)
                print ("Done")

##reading VCF file as panda dataframe
        print ("Creating pandas dataframe")
        VCF_df = read_VCF_file(vcf_file)
        print ("Done")


        ##getting the useful information for futur algorithms
        for row in VCF_df.itertuples(index=True, name='Pandas'):

        ##for fetching both reference sequences
        ## for now I extend each regions 100bp on each side, it could be better to check orientation and extend on one side only


                ID = getattr(row, "IDENTIFIER")+"_"+getattr(row,"CONTIGID")
                print ("Working on SV: " + ID)
                POS1 = getattr(row,"POS")-100
                POS2 = getattr(row,"POS")+100
                POS = str(getattr(row, "CHR1"))+":"+str(POS1)+"-"+str(POS2)

                END1 = getattr(row,"END")-100
                END2 = getattr(row,"END")+100
                END = str(getattr(row, "CHR2"))+":"+str(END1)+"-"+str(END2)

                print ("Making fasta file")
                makefastafile(reference,POS,END,ThisScript_path)
                print ("Done")

                print ("Making custom database")
                customdbname = makeblastcustomdb('regions.tmp.fa',ID,ThisScript_path)
                print ("Done")


                QUERY = row.CONSENSUS
                print ("Making query file")
                query_file = makequeryfile(ID,QUERY)
                print ("Done")

                print ("Blasting query on custom database")
                blastfile_name = blastn(query_file,customdbname,ThisScript_path)
                print ("Done")

                consensus_length = row.CONSENSUSLENGTH

                print ("Identifying microhomologies")
                if os.path.getsize(blastfile_name) > 0:
                        microhomology_length = identifymicrohomologies(consensus_length,blastfile_name)
                else:
                        microhomology_length = 0
                if microhomology_length >= 4:
                        VCF_df.at[row[0],'MICROHOMOLOGYLENGTH'] = microhomology_length
                        VCF_df.at[row[0],'MICROHOMOLOGY'] = "TRUE"
                print ("Done")

        VCF_df.to_csv('Final_VCF.csv', sep='\t')


##args are reference_database_name, reference_file_path, vcf_file



if __name__ == '__main__':
        if len(sys.argv) != 4:
                print >> sys.stderr, "This Script need exactly 3 arguments; args are <reference_database_name>, <reference_file_path>, <vcf_file>"
                exit(1)
        else:
                ThisScript, database, reference, vcf_file = sys.argv
                ThisScript_path = os.path.dirname(ThisScript)
                main()