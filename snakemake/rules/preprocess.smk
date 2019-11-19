#TODO should change tmpdir to apppropriate tmpdir for slurm
#TODO should fix cluster.json to use group to find job ressources
rule FixMate:
    input:
        "data/Sam2bam/{sample}.bam"
    output:
        tmp = "data/Fixmate/{sample}.tmp.bam",
        bam = "data/Fixmate/{sample}.bam"
    shell:
        "java -XX:ParallelGCThreads=4 -Xmx40G -jar /cvmfs/soft.mugqic/CentOS6/software/bvatools/bvatools-1.4/bvatools-1.4-full.jar "
        "groupfixmate "
        " --level 1 "
        "--bam {input} "
        "--out {output.tmp} && "
        "sambamba sort -t 40 -m 2GB --tmpdir='$SLURM_TMPDIR' "
        "{output.bam}"

rule Sambamba_markDuplicates:
    input:
        "data/Fixmate/{sample}.bam"
    output:
        "data/Sambamba_markDuplicates/{sample}.bam"
    shell:
        "sambamba markdup -t 5 "
        "{input} "
        "--tmpdir '$SLURM_TMPDIR' "
        "{output}"

rule Recalibration_report:
    input:
        bam = "data/Sambamba_markDuplicates/{sample}.bam",
        dbsnp = config['recalibration']['dbsnp'],
        mills = config['recalibration']['mills'],
        fa = config['ref']['fasta']
    output:
        "data/Recalibration/{sample}.recalibration_report.grp"
    group: "recalibration"
    shell:
        "java -Djava.io.tmpdir='$SLURM_TMPDIR' -XX:ParallelGCThreads=4 -Xmx20G "
        "-jar /cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-3.8/GenomeAnalysisTK.jar "
        "--analysis_type BaseRecalibrator "
        "--num_cpu_threads_per_data_thread 20 "
        "--input_file {input.bam} "
        "--reference_sequence {input.fa} "
        "--knownSites {input.dbsnp} "
        "--knownSites {input.mills} "
        "--out {output}"

rule Recalibration:
    input:
        bam = "data/Sambamba_markDuplicates/{sample}.bam",
        dbsnp = config['recalibration']['dbsnp'],
        mills = config['recalibration']['mills'],
        fa = config['ref']['fasta'],
        grp = "data/Recalibration/{sample}.recalibration_report.grp"
    group: "recalibration"
    output:
        "data/Recalibration/{sample}.bam"
    shell:
        "java -Djava.io.tmpdir='$SLURM_TMPDIR' -XX:ParallelGCThreads=4 -Xmx20G "
        "-jar /cvmfs/soft.mugqic/CentOS6/software/GenomeAnalysisTK/GenomeAnalysisTK-3.8/GenomeAnalysisTK.jar "
        "--analysis_type PrintReads "
        "--num_cpu_threads_per_data_thread 20 "
        "--input_file {input.bam} "
        "--reference_sequence {input.fa} "
        "--BQSR {input.grp} "
        "--out {output} "

rule Recalibration_index:
    input:
        "data/Recalibration/{sample}.bam"
    output:
        "data/Recalibration/{sample}.bam.bai"
    group:"recalibration"    
    shell:
        "samtools index {input} {output}"
