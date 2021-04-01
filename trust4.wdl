task TRUST4_TASK {

    File? gene_reference
    File? gene_annotation
    String sample_name
    File? input_bam
    File? fq_1
    File? fq_2
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

    if [[ ! -z "${input_bam}" ]]; then
        run-trust4 \
        -b ${input_bam} \
        -t 8 \
        -f ${dollar}{gene_reference} \
        --ref ${dollar}{gene_annotation} \
        -o ${sample_name}

    elif [[ -z "${fq_2}" ]]; then
        run-trust4 \
            -u ${fq_1} \
            -t 8 \
            -f ${dollar}{gene_reference} \
            --ref ${dollar}{gene_annotation} \
            -o ${sample_name}

    else
        run-trust4 \
            -1 ${fq_1} \
            -2 ${fq_2} \
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
    File? bam
    File? fq_1
    File? fq_2
    String? Docker = "nciccbr/ccbr_trust4:v1.0.2-beta"
    Int preemptible = 2
    Int maxRetries = 1

    if (defined(bam)||defined(fq_1)) {
        call TRUST4_TASK {
            input:
                input_bam=bam,
                fq_1=fq_1,
                fq_2=fq_2,
                sample_name=sample_name,
                gene_reference=gene_reference,
                gene_annotation=gene_annotation,
                Docker=Docker,
                preemptible=preemptible,
                maxRetries=maxRetries
        }
    }
}


