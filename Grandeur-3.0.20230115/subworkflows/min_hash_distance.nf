include { mash }  from '../modules/mash' addParams(params)

workflow min_hash_distance {
    take:
        ch_reads
        ch_contigs
        ch_mash_db
  
    main:
        if (params.mash_db) {
            mash(ch_contigs.join(ch_reads, by: 0, remainder: true).combine(ch_mash_db.ifEmpty([])))
        } else {
            mash(ch_contigs.join(ch_reads, by: 0, remainder: true).map{it -> tuple(it[0], it[1], it[2], '/db/RefSeqSketchesDefaults.msh')})
        }

        mash.out.results
            .map { it -> it [1] }
            .collectFile(
                storeDir: "${params.outdir}/mash/",
                keepHeader: true,
                sort: { file -> file.text },
                name: "mash_summary.csv")
            .set { summary }

    emit:
        for_summary = summary
        for_flag    = mash.out.results
        mash_err    = mash.out.err
}
