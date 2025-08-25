// Modules
include { INPUT_CHECK }                 from '../modules/input_check'
include { DORADO_BASECALLER }           from './../modules/dorado/basecaller'
include { SAMTOOLS_FASTQ }              from './../modules/samtools/fastq'
include { MULTIQC }                     from './../modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'


workflow ONT_DEMUX {

    main:

    pod5              = params.input            ? Channel.fromPath(params.input, checkIfExists: true).collect() : Channel.empty()
    model             = params.model
    ch_samplesheet    = params.samplesheet      ? Channel.fromPath(params.samplesheet, checkIfExists: true).map { s -> [ ["kit": params.kit], s]}.collect() : Channel.value( [["this": "bla"],null])
    ch_multiqc_config = params.multiqc_config   ? Channel.fromPath(params.multiqc_config, checkIfExists: true).collect() : Channel.value([])
    ch_multiqc_logo   = params.multiqc_logo     ? Channel.fromPath(params.multiqc_logo, checkIfExists: true).collect() : Channel.value([])

    ch_versions = Channel.from([])
    multiqc_files = Channel.from([])

    // Check validity of samplesheet, if any
    INPUT_CHECK(ch_samplesheet.filter { m,s -> s})

    // Check if we have a samplesheet, else set null
    pod5.map { p ->
        def meta = [:]
        meta.kit = params.kit
        [ meta, p ]
    }.join(
        INPUT_CHECK.out.samplesheet, remainder: true
    ).filter { m, p, s ->
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
    DORADO_BASECALLER.out.called.map { m,d ->
        bams_from_calls(d)
    }.flatMap { v -> v }
    .set { bams }

    // Combine bams with the full metadata hash
    bams.map { m, bam ->
        tuple(m.barcode,m,bam)
    }.join(
        INPUT_CHECK.out.meta.map { m -> 
            [ m.barcode, m]
        }, remainder: true
    ).branch { bc, meta, bam, ameta ->
        with_meta: ameta
        without_meta: !ameta
    }.set  { ch_bams_by_meta }
    
    /* 
    Depending on whether a sample sheet was used, we now
    have either an extended meta hash or null - and for null,
    we need a meta hash with at least a sample_id
    */
    ch_bams_by_meta.with_meta.map { bc, meta, bam, ameta ->
        [ ameta, bam ]
    }.set { ch_bams_with_sample }

    ch_bams_by_meta.without_meta.map { bc, m, bam, ameta ->
        def meta = [:]
        meta.barcode = m.barcode
        meta.sample_id = m.barcode
        [ meta, bam ]
    }.set { ch_bams_without_sample }

    // Convert BAM to Fastq for downstream processing
    SAMTOOLS_FASTQ(
        ch_bams_with_sample.mix(ch_bams_without_sample)
    )
    ch_versions = ch_versions.mix(SAMTOOLS_FASTQ.out.versions)

    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    multiqc_files = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

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
        def barcode = "all"
        if (b.toString().contains("barcode") || b.toString().contains("unclassified")) {
            barcode = ( b.toString().split("/")[-2] )
        }
        meta.barcode = barcode 
        data << [ meta, file(b)]
    }

    return data
}