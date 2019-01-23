configfile: "config.yaml"

# include: "scripts/functions.py"

rule main:
    input:
        expand("{data_dir}/results/{sample}.vcf",
                data_dir = config['data_dir'],
                sample = config['samples'],
                ),

rule postprocess_variants:
    input:
        config['reference'],
        "{data_dir}/tmp/{sample}.outfile",
    output:
        "{data_dir}/results/{sample}.vcf",
    conda:
        "envs/deepvariant.yaml",
    shell:
        """
        dv_postprocess_variants.py                                              \
            --ref {input[0]}                                                    \
            --infile {input[1]}                                                 \
            --outfile {output[0]}
        """

rule call_variants:
    input:
        "{data_dir}/tmp/{sample}.examples",
    output:
        "{data_dir}/tmp/{sample}.outfile",
    conda:
        "envs/deepvariant.yaml",
    shell:
        """
        dv_call_variants.py                                                     \
            --examples {input[0]}                                               \
            --sample {wildcards.sample}                                         \
            --outfile {output[0]}
        """

rule make_examples:
    input:
        config['reference'],
        expand("{reference}.fai", reference = config['reference']),
        "{data_dir}/raw/{sample}.bam",
        "{data_dir}/raw/{sample}.bam.bai"
    output:
        directory("{data_dir}/tmp/{sample}.examples"),
    conda:
        "envs/deepvariant.yaml",
    shell:
        """
        mkdir -p {wildcards.data_dir}/log
        mkdir -p {output}

        dv_make_examples.py                                                     \
            --sample {wildcards.sample}                                         \
            --ref {input[0]}                                                    \
            --reads {input[2]}                                                  \
            --logdir {wildcards.data_dir}/log                                   \
            --examples {output}
        """

rule create_fai:
    input:
        "{reference}",
    output:
        "{reference}.fai",
    shell:
        """
        samtools faidx {input[0]}
        """

rule create_bai:
    input:
        "{data_dir}/raw/{sample}.bam",
    output:
        "{data_dir}/raw/{sample}.bam.bai",
    shell:
        """
        samtools index {input[0]}
        """
