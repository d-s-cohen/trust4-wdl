task TRUST4_BULK_TASK {

    File? gene_reference
    File? gene_annotation
    String sample_name
    File? input_bam
    File? fq_1
    File? fq_2
    String? barcode_10x
    String Docker
    Int preemptible
    Int maxRetries
    
    String dollar = "$"
    
    command <<<

    set -e

    # define reference files

    if [[ -z "${gene_reference}" ]]; then
        gene_reference_run="/opt2/TRUST4/hg38_bcrtcr.fa"
    else
        gene_reference_run="${gene_reference}"
    fi

    if [[ -z "${gene_annotation}" ]]; then
        gene_annotation_run="/opt2/TRUST4/human_IMGT+C.fa"
    else
        gene_annotation_run="${gene_annotation}"
    fi

    # check 10x

    if [[ ! -z "${barcode_10x}" ]]; then
        support_barcode_10x="--barcode ${barcode_10x}"
    else   
        support_barcode_10x=""
    fi

    # trust4

    if [[ ! -z "${input_bam}" ]]; then
        run-trust4 \
            -b ${input_bam} \
            -t 8 \
            ${dollar}{support_barcode_10x} \
            -f ${dollar}{gene_reference_run} \
            --ref ${dollar}{gene_annotation_run} \
            -o ${sample_name}

    elif [[ -z "${fq_2}" ]]; then
        run-trust4 \
            -u ${fq_1} \
            -t 8 \
            -f ${dollar}{gene_reference_run} \
            --ref ${dollar}{gene_annotation_run} \
            -o ${sample_name}

    else
        run-trust4 \
            -1 ${fq_1} \
            -2 ${fq_2} \
            -t 8 \
            -f ${dollar}{gene_reference_run} \
            --ref ${dollar}{gene_annotation_run} \
            -o ${sample_name}

    fi

    gzip ${sample_name}_annot.fa
    gzip ${sample_name}_cdr3.out
    gzip ${sample_name}_report.tsv

    if [[ ! -z "${barcode_10x}" ]]; then
        gzip ${sample_name}_barcode_report.tsv
    fi
      
   >>>
    
    output {
      File annot="${sample_name}_annot.fa.gz"
      File report="${sample_name}_cdr3.out.gz"
      File simpleReport="${sample_name}_report.tsv.gz"
      File? barcodeReport="${sample_name}_barcode_report.tsv.gz"
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


task TRUST4_SMART_TASK {

    File? gene_reference
    File? gene_annotation
    String sample_name
    Array[File]? smart_1
    Array[File]? smart_2
    String Docker
    Int preemptible
    Int maxRetries

    Boolean defined_smart_2 = defined(smart_2)
    
    String dollar = "$"
    
    command <<<

    set -e

    # define reference files

    if [[ -z "${gene_reference}" ]]; then
        gene_reference_run="/opt2/TRUST4/hg38_bcrtcr.fa"
    else
        gene_reference_run="${gene_reference}"
    fi

    if [[ -z "${gene_annotation}" ]]; then
        gene_annotation_run="/opt2/TRUST4/human_IMGT+C.fa"
    else
        gene_annotation_run="${gene_annotation}"
    fi

    # trust4

    if [ "${defined_smart_2}" = true ]; then
        perl /opt2/TRUST4/trust-smartseq.pl \
            -1 "${write_lines(smart_1)}" \
            -2 "${write_lines(smart_2)}" \
            -t 8 \
            -f ${dollar}{gene_reference_run} \
            --ref ${dollar}{gene_annotation_run} \
            -o ${sample_name}
    else
        perl /opt2/TRUST4/trust-smartseq.pl \
            -1 "${write_lines(smart_1)}" \
            -t 8 \
            -f ${dollar}{gene_reference_run} \
            --ref ${dollar}{gene_annotation_run} \
            -o ${sample_name}
    fi

    gzip ${sample_name}_annot.fa
    gzip ${sample_name}_report.tsv

   >>>
    
    output {
      File annot="${sample_name}_annot.fa.gz"
      File simpleReport="${sample_name}_report.tsv.gz"
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
    Array[File]? smart_1
    Array[File]? smart_2
    String? barcode_10x
    String? Docker = "dscohen/trust4:v1.0.2"
    Int preemptible = 2
    Int maxRetries = 1

    if (defined(bam)||defined(fq_1)) {
        call TRUST4_BULK_TASK {
            input:
                input_bam=bam,
                fq_1=fq_1,
                fq_2=fq_2,
                sample_name=sample_name,
                barcode_10x=barcode_10x,
                gene_reference=gene_reference,
                gene_annotation=gene_annotation,
                Docker=Docker,
                preemptible=preemptible,
                maxRetries=maxRetries
        }
    }

    if ((defined(smart_1))&&(!(defined(bam)||defined(fq_1)))) {
        call TRUST4_SMART_TASK {
            input:
                smart_1=smart_1,
                smart_2=smart_2,
                sample_name=sample_name,
                gene_reference=gene_reference,
                gene_annotation=gene_annotation,
                Docker=Docker,
                preemptible=preemptible,
                maxRetries=maxRetries
        }
    }

}