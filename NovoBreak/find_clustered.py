import sys
import os
import pandas as pd
import numpy as np
import subprocess

#vcf_file = "PD3890a_BRCA1_0.99946411.PASS.vcf.gz"

def read_VCF_file(vcf_file):
##reading VCF file as panda dataframe
        VCF_df=pd.read_table(vcf_file,comment='#',header=None,skip_blank_lines=True)
    #    VCF_df[[7, 'ORIENTATION', 'CIPOS', 'CIEND', 'TYPE', 'CONSENSUS', 'SVTYPE', 'CHR2', 'END', 'SVLEN']] = VCF_df[7].str.split(';',expand=True)

def main():
        VCF_df = read_VCF_file(vcf_file)
        print(VCF_df)
        
##args are reference_database_name, reference_file_path, vcf_file 
if __name__ == '__main__':
        if len(sys.argv) != 2:
                print >> sys.stderr, "This Script need exactly 1 arguments; args are <reference_database_name>, <reference_file_path>, <vcf_file>"
                exit(1)
        else:
                ThisScript, vcf_file = sys.argv

                main()

