rule Bam2fastq:
    input:
        "data/{sample}.bam"
    output:
        fq1= "data/bam2fastq/{sample}.pair1.fastq.gz",
        fq2= "data/bam2fastq/{sample}.pair2.fastq.gz"
    
    shell:
        "picard -Xmx20G "
        "SamToFastq VALIDATION_STRINGENCY=LENIENT "
        "INPUT={input} "
        "FASTQ={output.fq1} "
        "SECOND_END_FASTQ={output.fq2} "
        "INCLUDE_NON_PRIMARY_ALIGNMENTS=false"

rule Trimmomatic:
    input:
        fq1= "data/bam2fastq/{sample}.pair1.fastq.gz",
        fq2= "data/bam2fastq/{sample}.pair2.fastq.gz"
    output:
        fq1= "data/trimmomatic/{sample}.pair1.fastq.gz",
        fq2= "data/trimmomatic/{sample}.pair2.fastq.gz",
        unpaired_fq1= "data/trimmomatic/{sample}.unpaired1.fastq.gz",
        unpaired_fq2= "data/trimmomatic/{sample}.unpaired2.fastq.gz"        
    params:
        options = [
            "ILLUMINACLIP:data/adapters.fa:2:30:15:8:true",
            "TRAILING:30", "MINLEN:50"
        ]
    log:
        "logs/trimmomatic/{sample}.log"
    threads:
        32
    conda:
        "../envs/trimmomatic.yaml"
    shell:
        "trimmomatic PE "
        "-threads {threads} " 
        "-phred33 "
        "{input.fq1} {input.fq2} "
        "{output.fq1} {output.unpaired_fq1} "
        "{output.fq2} {output.unpaired_fq2} "
         "{params.options} "
        "&> {log}"

rule Bwa_mem:
    input:
        fa = config['ref']['fasta'],
        fq1 = "data/trimmomatic/{sample}.pair1.fastq.gz",
        fq2 = "data/trimmomatic/{sample}.pair2.fastq.gz",
        bam = "data/{sample}.bam"
    output:
        "data/bwa_mem/{sample}.sam"
    params:
        readgroup = config['bwa']['readgroup']
    shell:
        "bwa mem -M -t 16 "
        "-R {params.readgroup} "
        "{input.fa} "
        "{input.fq1} {input.fq2} "
        "> {output}"

rule Sam2bam:
    input:
        "data/bwa_mem/{sample}.sam"
    output:
        bam="data/Sam2bam/{sample}.bam",
        bai="data/Sam2bam/{sample}.bam.bai"
    shell:
        "samtools view -bS {input}"
        "-o {output.bam} && "
        "sambamba sort -t 12 -m 2GB {output.bam}"