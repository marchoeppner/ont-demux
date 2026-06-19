// Modules
include { INPUT_CHECK }                 from './../modules/input_check'
include { DORADO_BASECALLER }           from './../modules/dorado/basecaller'
include { DORADO_SUMMARY }              from './../modules/dorado/summary'
include { DORADO_DEMUX }                from './../modules/dorado/demux'
include { SAMTOOLS_FASTQ }              from './../modules/samtools/fastq'
include { MULTIQC }                     from './../modules/multiqc/main'
include { NANOPLOT }                    from './../modules/nanoplot'
include { MD5SUM as MD5SUM_BASECALL }   from './../modules/md5sum'
include { MD5SUM as MD5SUM_DEMUX }      from './../modules/md5sum'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'
include { MD5SUM as MD5SUM_FASTQ }      from './../modules/md5sum'


workflow ONT_DEMUX {

    main:

    pod5              = params.input            ? channel.fromPath(params.input, checkIfExists: true).collect() : channel.empty()
    model             = params.model
    ch_samplesheet    = params.samplesheet      ? channel.fromPath(params.samplesheet, checkIfExists: true).collect() : channel.empty()

    ch_multiqc_config = params.multiqc_config   ? channel.fromPath(params.multiqc_config, checkIfExists: true).collect() : channel.value([])
    ch_multiqc_logo   = params.multiqc_logo     ? channel.fromPath(params.multiqc_logo, checkIfExists: true).collect() : channel.value([])

    pipeline_info = channel.fromPath(dumpParametersToJSON(params.outdir)).collect()

    ch_meta = channel.from([])
    ch_versions = channel.from([])
    multiqc_files = channel.from([])

    // Check validity of samplesheet, if any
    if (params.samplesheet) {

        INPUT_CHECK(ch_samplesheet)
        ch_meta = INPUT_CHECK.out.meta
    } 

    // Run basecalling 
    DORADO_BASECALLER(
        pod5,
        model,
        params.duplex
    )
    ch_versions = ch_versions.mix(DORADO_BASECALLER.out.versions)

    // Generate md5sum for basecalled bam
    DORADO_BASECALLER.out.bams.view()
    MD5SUM_BASECALL(
        DORADO_BASECALLER.out.bams
    )

    if (params.samplesheet) {
        /* 
        Demultiplex basecalled reads - 
        No separate trimming is performed as that may 
        negatively affect demultiplexing. Adapters and sequencing primers
        are removed together with the barcodes
        */
        DORADO_DEMUX(
            DORADO_BASECALLER.out.bams,
            file(params.samplesheet)
        )
        ch_versions = ch_versions.mix(DORADO_DEMUX.out.versions)
        ch_demuxed = DORADO_DEMUX.out.demuxed

        MD5SUM_DEMUX(
            DORADO_DEMUX.out.bams
        )
    } else {
        ch_demuxed = DORADO_BASECALLER.out.called
    }

    // Get BAMs from basecalling output
    ch_demuxed.map { d ->
        bams_from_calls(d)
    }.flatMap { v -> v }
    .set { bams }

    // Combine bams with the full metadata hash
    bams.map { m, bam ->
        tuple(m.sample_id,m,bam)
    }.join(
        ch_meta.map { m -> 
            [ m.sample_id, m]
        }, remainder: true
    ).branch { _s, _meta, _bam, ameta ->
        with_meta: ameta
        without_meta: !ameta
    }.set  { ch_bams_by_meta }
    
    ch_bams_by_meta.without_meta.view()
    /* 
    Depending on whether a sample sheet was used, we now
    have either an extended meta hash or null - and for null,
    we need a meta hash with at least a sample_id ( = the barcode)
    */
    ch_bams_by_meta.with_meta.map { _s, _meta, bam, ameta ->
        [ ameta, bam ]
    }.set { ch_bams_with_sample }

    ch_bams_by_meta.without_meta.map { _s, m, bam, _ameta ->
        def meta = [:]
        meta.barcode = m.sample_id
        meta.sample_id = m.sample_id
        [ meta, bam ]
    }.set { ch_bams_without_sample }

    ch_all_bams = ch_bams_with_sample.mix(ch_bams_without_sample)
    // Convert BAM to Fastq for downstream processing
    SAMTOOLS_FASTQ(
        ch_all_bams
    )
    ch_versions = ch_versions.mix(SAMTOOLS_FASTQ.out.versions)

    MD5SUM_FASTQ(
        SAMTOOLS_FASTQ.out.fastq.map{_m,f -> f} 
    )
    ch_versions = ch_versions.mix(MD5SUM_FASTQ.out.versions)

    // Read BAM file and compute summary
    DORADO_SUMMARY(
        ch_all_bams
    )
    ch_versions = ch_versions.mix(DORADO_SUMMARY.out.versions)
    
    // Plot sample stats from Dorado summary output
    NANOPLOT(
        DORADO_SUMMARY.out.txt
    )
    ch_versions = ch_versions.mix(NANOPLOT.out.versions)
    multiqc_files = multiqc_files.mix(NANOPLOT.out.txt.map {_m,t -> t})

    // Collect all software versions
    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    multiqc_files = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

    // Render MultiQC report
    MULTIQC(
        multiqc_files.collect(),
        ch_multiqc_config,
        ch_multiqc_logo
    )

    emit:
    qc = MULTIQC.out.html
}

// Custom function to turn a list of BAM files into a meta-data enabled channel
def bams_from_calls(dir) {
    def data = []
    def bams = file("${dir}/**.*am")
    bams.each { b ->
        def meta = [:]
        def sample_id = ( b.toString().split("/")[-2] )

        meta.sample_id = sample_id 
        data << [ meta, file(b)]
    }

    return data
}

// turn the summaryMap to a JSON file
def dumpParametersToJSON(outdir) {
    def timestamp = new java.util.Date().format('yyyy-MM-dd_HH-mm-ss')
    def filename  = "params_${timestamp}.json"
    def temp_pf   = new File(workflow.launchDir.toString(), ".${filename}")
    def jsonStr   = groovy.json.JsonOutput.toJson(params)
    temp_pf.text  = groovy.json.JsonOutput.prettyPrint(jsonStr)

    nextflow.extension.FilesEx.copyTo(temp_pf.toPath(), "${outdir}/pipeline_info/params_${timestamp}.json")
    temp_pf.delete()
    return file("${outdir}/pipeline_info/params_${timestamp}.json")
}