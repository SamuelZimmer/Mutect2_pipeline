# def get_normal(wildcards)
#     #code that gets normal bam
#     return wildcards.sample
# def get_tumor(wildcards)
#     #code that gets tumor bam
#     return


#TODO find a better way of get sample name information to input to mutect2

def get_files(wildcards) :
    sample = wildcards.sample
    normal = PAIRS[wildcards.sample]
    return ["data/Recalibration/" + sample + ".bam", "data/Recalibration/" + sample + ".bam.bai", "data/Recalibration/" + normal + ".bam", "data/Recalibration/" + normal + ".bam.bai"]

rule Mutect2:
        input:
            bams = get_files,
            fa = config['ref']['fasta']
        output:
            "results/mutect2/{sample}_{chr}.vcf"
        group: "mutect2"
        shell:
            "TUMORSAMPLE=`samtools view -H {input.bams[1]} | grep '@RG' | gawk 'NR==1{{ if (match($0,/SM:[ A-Za-z0-9_-]*/,m)) print m[0] }}' | sed 's/SM://'` && "
            "NORMALSAMPLE=`samtools view -H {input.bams[3]} | grep '@RG' | gawk 'NR==1{{ if (match($0,/SM:[ A-Za-z0-9_-]*/,m)) print m[0] }}' | sed 's/SM://'` && "
            "java -jar /cvmfs/soft.computecanada.ca/easybuild/software/2017/Core/gatk/4.0.8.1/gatk-package-4.0.8.1-local.jar "
            "Mutect2 "
            "--reference {input.fa} "
            "-I {input.bams[1]} "
            "-I {input.bams[3]} "
            "--tumor-sample $TUMORSAMPLE "
            "--normal-sample $NORMALSAMPLE "
            "-L {wildcards.chr} "
            "--output {output}"

rule Filter_mutect:
        input:
            "results/mutect2/{sample}_{chr}.vcf"
        output:
            "results/mutect2/{sample}_{chr}_filtered.vcf"
        group: "mutect2"
        shell:
            "java -jar /cvmfs/soft.computecanada.ca/easybuild/software/2017/Core/gatk/4.0.8.1/gatk-package-4.0.8.1-local.jar "
            "FilterMutectCalls "
            "--output {output} "
            "--variant {input}"

rule Concat_mutect:
        input:
            expand("results/mutect2/{sample}_{chr}_filtered.vcf", sample=SAMPLES, chr=CHR)
        output:
            vcf = "results/mutect2/{sample}.vcf.gz",
            tbi = "results/mutect2/{sample}.vcf.gz.tbi"
        group: "mutect2"
        shell:
            "bcftools concat -a "
            "{input} "
            "| bgzip -cf > {output.vcf} && "
            "tabix -pvcf {output.vcf}"
