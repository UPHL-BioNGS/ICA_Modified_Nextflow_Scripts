process ivar_consensus {
  tag           "${sample}"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "cecret", mode: 'copy'
  container     'staphb/ivar:1.3.1'
  maxForks      10
  cpus          4

  input:
  tuple val(sample), file(bam), file(reference_genome)

  output:
  path "consensus/${sample}.consensus.fa",                                                            emit: consensus
  path "consensus/${sample}.consensus.qual.txt",                                                      emit: qual
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log"
  tuple val(sample), env(num_N), env(num_ACTG), env(num_degenerate), env(num_total), env(first_line), emit: consensus_results
  tuple val(sample), env(ivar_version),                                                               emit: ivar_version

  shell:
  '''
    mkdir -p consensus logs/!{task.process}
    log=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    date > $log
    samtools --version >> $log
    ivar version >> $log
    ivar_version=$(ivar version | grep "version")

    samtools mpileup -A -d !{params.mpileup_depth} -B -Q 0 --reference !{reference_genome} !{bam} | \
      ivar consensus !{params.ivar_consensus_options} -m !{params.minimum_depth} -p consensus/!{sample}.consensus | tee -a $log

    if [ -f "consensus/!{sample}.consensus.fa" ]
    then
      num_N=$(grep -v ">" consensus/!{sample}.consensus.fa | grep -o 'N' | wc -l )
      num_ACTG=$(grep -v ">" consensus/!{sample}.consensus.fa | grep -o -E "C|A|T|G" | wc -l )
      num_degenerate=$(grep -v ">" consensus/!{sample}.consensus.fa | grep -o -E "B|D|E|F|H|I|J|K|L|M|O|P|Q|R|S|U|V|W|X|Y|Z" | wc -l )
      first_line=$(grep ">" consensus/!{sample}.consensus.fa | sed 's/>//g' )

      if [ -z "$num_N" ] ; then num_N="0" ; fi
      if [ -z "$num_ACTG" ] ; then num_ACTG="0" ; fi
      if [ -z "$num_degenerate" ] ; then num_degenerate="0" ; fi
      if [ -z "$first_line" ] ; then first_line=!{sample} ; fi
    else
      num_N="0"
      num_ACTG="0"
      num_degenerate="0"
      first_line=!{sample}
    fi

    if [ -z "$num_N" ] ; then num_N="0" ; fi
    if [ -z "$num_ACTG" ] ; then num_ACTG="0" ; fi
    if [ -z "$num_degenerate" ] ; then num_degenerate="0" ; fi
    num_total=$(( $num_N + $num_degenerate + $num_ACTG ))
  '''
}

process ivar_variants {
  tag           "${sample}"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "cecret", mode: 'copy'
  container     'staphb/ivar:1.3.1'
  maxForks      10
  cpus          4

  when:
  params.ivar_variants

  input:
  tuple val(sample), file(bam), file(reference_genome), file(gff_file)

  output:
  tuple val(sample), file("ivar_variants/${sample}.variants.tsv"),        emit: variant_tsv
  tuple val(sample), file("ivar_variants/${sample}.ivar_variants.vcf"),   emit: ivar_variant_file
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log"
  tuple val(sample), env(variants_num),                                   emit: ivar_variants_results

  shell:
  '''
    mkdir -p ivar_variants logs/!{task.process}
    log=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log
    samtools --version >> $log
    ivar version >> $log

    samtools mpileup -A -d !{params.mpileup_depth} -B -Q 0 --reference !{reference_genome} !{bam} | \
      ivar variants -p ivar_variants/!{sample}.variants !{params.ivar_variants_options} -m !{params.minimum_depth} -r !{reference_genome} -g !{gff_file} | tee -a $log

    variants_num=$(grep "TRUE" ivar_variants/!{sample}.variants.tsv | wc -l)

    if [ -z "$variants_num" ] ; then variants_num="0" ; fi

    echo '##fileformat=VCFv4.2'                                                                               >  ivar_variants/!{sample}.ivar_variants.vcf
    echo '##source=iVar'                                                                                      >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##INFO=<ID=DP,Number=1,Type=Integer,Description="Total Depth">'                                     >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##FILTER=<ID=PASS,Description="Result of p-value <= 0.05">'                                         >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##FILTER=<ID=FAIL,Description="Result of p-value > 0.05">'                                          >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">'                                       >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##FORMAT=<ID=REF_DP,Number=1,Type=Integer,Description="Depth of reference base">'                   >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##FORMAT=<ID=REF_RV,Number=1,Type=Integer,Description="Depth of reference base on reverse reads">'  >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##FORMAT=<ID=REF_QUAL,Number=1,Type=Integer,Description="Mean quality of reference base">'          >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##FORMAT=<ID=ALT_DP,Number=1,Type=Integer,Description="Depth of alternate base">'                   >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##FORMAT=<ID=ALT_RV,Number=1,Type=Integer,Description="Deapth of alternate base on reverse reads">' >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##FORMAT=<ID=ALT_QUAL,Number=1,Type=String,Description="Mean quality of alternate base">'           >> ivar_variants/!{sample}.ivar_variants.vcf
    echo '##FORMAT=<ID=ALT_FREQ,Number=1,Type=String,Description="Frequency of alternate base">'              >> ivar_variants/!{sample}.ivar_variants.vcf
    echo -e '#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\t!{sample}'                                >> ivar_variants/!{sample}.ivar_variants.vcf
    tail -n+2 !{task.process}/!{sample}.variants.tsv | \
      awk '{print $1 "\t" $2 "\t.\t" $3 "\t" $4 "\t.\t.\tREF_DP=" $5 ";REF_RV=" $6 ";REF_QUAL=" $7 ";ALT_DP=" $8 ";ALT_RV=" $9 ";ALT_QUAL=" $10 "\tGT:PL\t1/1:" $12 "," $12-$8 "," $8 }' \
      >> ivar_variants/!{sample}.ivar_variants.vcf
  '''
}

process ivar_trim {
  tag           "${sample}"
  pod           annotation: 'scheduler.illumina.com/presetSize' , value: 'standard-large'
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  publishDir    "cecret", mode: 'copy'
  container     'staphb/ivar:1.3.1'
  maxForks      10
  cpus          4
  
  input:
  tuple val(sample), file(bam), file(primer_bed)

  output:
  tuple val(sample), file("ivar_trim/${sample}.primertrim.sorted.bam"),                                                         emit: trimmed_bam
  tuple val(sample), file("ivar_trim/${sample}.primertrim.sorted.bam"), file("ivar_trim/${sample}.primertrim.sorted.bam.bai"),  emit: bam_bai
  path "logs/${task.process}/${sample}.${workflow.sessionId}.log"
  path "ivar_trim/${sample}_ivar.log",                                                                                          emit: ivar_trim_files
  tuple val(sample), env(trimmer_version),                                                                                      emit: trimmer_version

  shell:
  '''
    mkdir -p ivar_trim logs/!{task.process}
    log=logs/!{task.process}/!{sample}.!{workflow.sessionId}.log

    # time stamp + capturing tool versions
    date > $log
    ivar version >> $log
    trimmer_version="ivar : $(ivar version | grep version)"

    # trimming the reads
    ivar trim !{params.ivar_trim_options} -e -i !{bam} -b !{primer_bed} -p ivar_trim/!{sample}.primertrim | tee -a $log

    grep "Found" -A 10000 $log | grep -A 10000 "primers in BED file" > ivar_trim/!{sample}_ivar.log

    # sorting and indexing the trimmed bams
    samtools sort ivar_trim/!{sample}.primertrim.bam -o ivar_trim/!{sample}.primertrim.sorted.bam | tee -a $log
    samtools index ivar_trim/!{sample}.primertrim.sorted.bam | tee -a $log
  '''
}
