//# some fastas are created with the header of >reference, so this changes the header
process fasta_prep {
  tag "${fasta}"

  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  memory 1.GB
  cpus 3

  publishDir    params.outdir, mode: 'copy'

  time '45m'

  container        = 'quay.io/biocontainers/pandas:1.1.5'

  when:
  fasta != null

  input:
  tuple val(sample), file(fasta)

  output:
  tuple val(sample), env(num_N), env(num_ACTG), env(num_degenerate), env(num_total), env(first_line), emit: fastas_results
  path "fasta_prep/${fasta}", optional: true, emit: fastas

  shell:
  '''
    mkdir -p fasta_prep

    echo ">!{sample}" > fasta_prep/!{fasta}
    grep -v ">" !{fasta} | fold -w 75 >> fasta_prep/!{fasta}

    num_N=$(grep -v ">" !{fasta} | grep -o 'N' | wc -l )
    num_ACTG=$(grep -v ">" !{fasta} | grep -o -E "C|A|T|G" | wc -l )
    num_degenerate=$(grep -v ">" !{fasta} | grep -o -E "B|D|E|F|H|I|J|K|L|M|O|P|Q|R|S|U|V|W|X|Y|Z" | wc -l )
    first_line=$(grep ">" consensus/!{sample}.consensus.fa | sed 's/>//g' )
    num_total=$(( $num_N + $num_degenerate + $num_ACTG ))

    if [ -z "$num_N" ] ; then num_N="0" ; fi
    if [ -z "$num_ACTG" ] ; then num_ACTG="0" ; fi
    if [ -z "$num_degenerate" ] ; then num_degenerate="0" ; fi
    if [ -z "$first_line" ] ; then first_line=!{sample} ; fi
    if [ -z "$num_total" ] ; then num_total=0 ; fi
  '''
}

process summary {
  tag "${sample}"

  publishDir    params.outdir, mode: 'copy'

  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  memory 1.GB
  cpus 3

  time '45m'

  container        = 'quay.io/biocontainers/pandas:1.1.5'

  input:
  tuple val(sample), val(num_N), val(num_ACTG), val(num_degenerate), val(num_total), val(first_line),
    // cecret workflow
    val(cleaner_version),
    val(aligner_version),
    val(trimmer_version),
    val(ivar_version),
    val(reads_passed),
    // qc subworkflow
    val(raw_1),
    val(raw_2),
    val(percentage_spec),
    val(percentage_human),
    val(ivar_variants),
    val(bcftools_variants),
    val(samtools_stats_after_size_results),
    val(coverage),
    val(covdepth),
    val(depth),
    val(samtools_num_failed_amplicons),
    val(bedtools_num_failed_amplicons)

  output:
  path "summary/${sample}.summary.csv", emit: summary_file

  shell:
  '''
    mkdir -p summary

    sample_id=($(echo !{sample} | cut -f 1 -d "_" ))

    header="sample_id,sample,fasta_line"
    result="${sample_id},!{sample},!{first_line}"

    if [ "!{params.fastqc}" != "false" ]
    then
      header="$header,fastqc_raw_reads_1,fastqc_raw_reads_2"
      result="$result,!{raw_1},!{raw_2}"
    fi

    if [ "!{params.cleaner}" == "fastp" ]
    then
      header="$header,fastp_reads_passed"
      result="$result,!{reads_passed}"
    fi

    if [ "!{params.samtools_coverage}" != "false" ]
    then
      header="$header,depth_after_trimming,1X_coverage_after_trimming"
      result="$result,!{covdepth},!{coverage}"
    fi

    if [ "!{params.samtools_depth}" != "false" ]
    then
      header="$header,num_pos_!{params.minimum_depth}X"
      result="$result,!{depth}"
    fi

    if [ "!{params.samtools_stats}" != "false" ]
    then
      header="$header,insert_size_after_trimming"
      result="$result,!{samtools_stats_after_size_results}"
    fi

    if [ "!{params.kraken2}" != "false" ]
    then
      organism=$(echo "!{params.kraken2_organism}" | sed 's/ /_/g')
      header="$header,%_human_reads,percent_${organism}_reads"
      result="$result,!{percentage_human},!{percentage_spec}"
    fi

    if [ "!{params.ivar_variants}" != "false" ]
    then
      header="$header,ivar_num_variants_identified"
      result="$result,!{ivar_variants}"
    fi

    if [ "!{params.bcftools_variants}" != "false" ]
    then
      header="$header,bcftools_variants_identified"
      result="$result,!{bcftools_variants}"
    fi

    if [ "!{params.bedtools_multicov}" != "false" ] && [ "!{params.trimmer}" != "none" ]
    then
      header="$header,bedtools_num_failed_amplicons"
      result="$result,!{bedtools_num_failed_amplicons}"
    fi

    if [ "!{params.samtools_ampliconstats}" != "false" ] && [ "!{params.trimmer}" != "none" ]
    then
      header="$header,samtools_num_failed_amplicons"
      result="$result,!{samtools_num_failed_amplicons}"
    fi

    header="$header,num_N,num_degenerage,num_non-ambiguous,num_total"
    result="$result,!{num_N},!{num_degenerate},!{num_ACTG},!{num_total}"

    header="$header,cleaner_version,aligner_version,trimmer_version,ivar_version"
    result="$result,!{cleaner_version},!{aligner_version},!{trimmer_version},!{ivar_version}"

    echo $header >  summary/!{sample}.summary.csv
    echo $result >> summary/!{sample}.summary.csv
  '''
}

process combine_results {
  tag "Combining Results"

  maxForks      10
  errorStrategy { task.attempt < 2 ? 'retry' : 'ignore'}
  pod annotation: 'scheduler.illumina.com/presetSize', value: 'standard-medium'
  memory 1.GB
  cpus 3

  time '45m'

  container        = 'quay.io/biocontainers/pandas:1.1.5'

  input:
  file(nextclade)
    file(pangolin)
    file(vadr)
    file(freyja)
    file(seqyclean)
    file(seqyclean_single)
    file(summary)
    file(combine_results)

  output:
  path "cecret_results.{csv,txt}", emit: final_file
  path "combined_summary.csv"

  shell:
  '''
    mkdir -p summary

    cat !{summary} | head -n 1 > combined_summary.csv
    for summary in !{summary}
    do
      tail -n +2 $summary >> combined_summary.csv.tmp
    done

    sort combined_summary.csv.tmp | uniq >> combined_summary.csv

    if [ -s "vadr.vadr.sqa" ] ; then tail -n +2 "vadr.vadr.sqa" | grep -v "#-" | tr -s '[:blank:]' ',' > vadr.csv ; fi

    python !{combine_results}
    cat cecret_results.csv | tr ',' '\\t' > cecret_results.txt
  '''
}
