// Modules
include { INPUT_CHECK }                 from './../modules/input_check'
include { DORADO_BASECALLER }           from './../modules/dorado/basecaller'
include { SAMTOOLS_FASTQ }              from './../modules/samtools/fastq'
include { DORADO_SUMMARY }              from './../modules/dorado/summary'
include { MULTIQC }                     from './../modules/multiqc/main'
include { NANOPLOT }                    from './../modules/nanoplot'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'


workflow ONT_DEMUX {

    main:

    pod5              = params.input            ? channel.fromPath(params.input, checkIfExists: true).collect() : channel.empty()
    model             = params.model
    ch_samplesheet    = params.samplesheet      ? channel.fromPath(params.samplesheet, checkIfExists: true).map { s -> [ ["kit": params.kit], s]}.collect() : channel.value( [["this": "bla"],null])
    ch_multiqc_config = params.multiqc_config   ? channel.fromPath(params.multiqc_config, checkIfExists: true).collect() : channel.value([])
    ch_multiqc_logo   = params.multiqc_logo     ? channel.fromPath(params.multiqc_logo, checkIfExists: true).collect() : channel.value([])

    pipeline_info = channel.fromPath(dumpParametersToJSON(params.outdir)).collect()

    ch_versions = channel.from([])
    multiqc_files = channel.from([])

    // Check validity of samplesheet, if any
    INPUT_CHECK(ch_samplesheet.filter { _m,s -> s})

    // Check if we have a samplesheet, else set null
    pod5.map { p ->
        def meta = [:]
        meta.kit = params.kit
        [ meta, p ]
    }.join(
        INPUT_CHECK.out.samplesheet, remainder: true
    ).filter { _m, p, _s ->
        p
    }.set { ch_demux }

    // Run basecalling with (optional) integrated demultiplexing
    DORADO_BASECALLER(
        ch_demux,
        model,
        params.duplex
    )
    ch_versions = ch_versions.mix(DORADO_BASECALLER.out.versions)

    // Get BAMs from basecalling output
    DORADO_BASECALLER.out.called.map { _m,d ->
        bams_from_calls(d)
    }.flatMap { v -> v }
    .set { bams }

    // Combine bams with the full metadata hash
    bams.map { m, bam ->
        tuple(m.sample_id,m,bam)
    }.join(
        INPUT_CHECK.out.meta.map { m -> 
            [ m.sample_id, m]
        }, remainder: true
    ).branch { _bc, _meta, _bam, ameta ->
        with_meta: ameta
        without_meta: !ameta
    }.set  { ch_bams_by_meta }
    
    /* 
    Depending on whether a sample sheet was used, we now
    have either an extended meta hash or null - and for null,
    we need a meta hash with at least a sample_id ( = the barcode)
    */
    ch_bams_by_meta.with_meta.map { _bc, _meta, bam, ameta ->
        [ ameta, bam ]
    }.set { ch_bams_with_sample }

    ch_bams_by_meta.without_meta.map { _bc, m, bam, _ameta ->
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
    def bams = file("${dir}/**.bam")
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