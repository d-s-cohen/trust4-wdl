task TRUST4_TASK_BAM {

    File? gene_reference
    File? gene_annotation
    String sample_name
    File input_bam
    String Docker
    Int preemptible
    Int maxRetries
    
    String dollar = "$"
    
    command <<<

    set -e

    # define reference files

    if [[ -z "${gene_reference}" ]]; then
        gene_reference="/opt2/TRUST4/hg38_bcrtcr.fa"
    fi

    if [[ -z "${gene_annotation}" ]]; then
        gene_annotation="/opt2/TRUST4/human_IMGT+C.fa"
    fi

    # trust4

    run-trust4 \
        -b ${input_bam} \
        -t 8 \
        -f ${dollar}{gene_reference} \
        --ref ${dollar}{gene_annotation} \
        -o ${sample_name}
      
   >>>
    
    output {
      File report="${sample_name}_cdr3.out"
      File simpleReport="${sample_name}_report.tsv"
   }
   

    runtime {
            docker: Docker
            disks: "local-disk 500 SSD"
            memory: "20GB"
            cpu: "8"
            preemptible: preemptible
            maxRetries: maxRetries
    }
    


}



task TRUST4_TASK_FASTQ {

    File? gene_reference
    File? gene_annotation
    String sample_name
    File left_fq
    File? right_fq
    String Docker
    Int preemptible
    Int maxRetries   
    
    String dollar = "$"
    
    command <<<

    set -e

    # define reference files

    if [[ -z "${gene_reference}" ]]; then
        gene_reference='/opt2/TRUST4/hg38_bcrtcr.fa'
    fi

    if [[ -z "${gene_annotation}" ]]; then
        gene_annotation='/opt2/TRUST4/human_IMGT+C.fa'
    fi

    # trust4

    if [[ -z "${right_fq}" ]]; then
        run-trust4 \
            -u ${left_fq} \
            -t 8 \
            -f ${dollar}{gene_reference} \
            --ref ${dollar}{gene_annotation} \
            -o ${sample_name}

    else
        run-trust4 \
            -1 ${left_fq} \
            -2 ${right_fq} \
            -t 8 \
            -f ${dollar}{gene_reference} \
            --ref ${dollar}{gene_annotation} \
            -o ${sample_name}

    fi

      
   >>>
    
    output {
      File report="${sample_name}_cdr3.out"
      File simpleReport="${sample_name}_report.tsv"
   }
   

    runtime {
            docker: Docker
            disks: "local-disk 500 SSD"
            memory: "20GB"
            cpu: "8"
            preemptible: preemptible
            maxRetries: maxRetries
    }
    
    
}



workflow trust4_wf {

    String sample_name
    File? gene_reference
    File? gene_annotation
    File? rnaseq_aligned_bam
    File? left_fq
    File? right_fq
    String? Docker = "nciccbr/ccbr_trust4:v1.0.2-beta"
    Int preemptible = 2
    Int maxRetries = 1

    if (defined(rnaseq_aligned_bam)) {
        call TRUST4_TASK_BAM {
            input:
                input_bam=rnaseq_aligned_bam,
                sample_name=sample_name,
                gene_reference=gene_reference,
                gene_annotation=gene_annotation,
                Docker=Docker,
                preemptible=preemptible,
                maxRetries=maxRetries
        }
    }

    if (defined(left_fq)) {
        call TRUST4_TASK_FASTQ {
            input:
                sample_name=sample_name,
                gene_reference=gene_reference,
                gene_annotation=gene_annotation,
                left_fq=left_fq,
                right_fq=right_fq,
                Docker=Docker,
                preemptible=preemptible,
                maxRetries=maxRetries
        }
    }

}

