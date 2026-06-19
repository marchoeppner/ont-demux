process DORADO_DEMUX {
    label 'gpu'
    label 'basecalling'

    // container "ontresearch/dorado:shac8f356489fa8b44b31beba841b84d2879de2088e" // 1.4.0
    container "ontresearch/dorado:sha38b4ce849afa13eac8075f0b41cecd30799f169b" // 2.0.0

    input:
    path(bam)
    val(samplesheet)

    output:
    path("bam_pass"), emit: demuxed
    path("bam_pass/*/*.*am"), emit: bams
    path('versions.yml'), emit: versions

    script:

    def args = task.ext.args ?: ''
    def options = samplesheet ? "--sample-sheet ${samplesheet}" : ""

    """
    dorado demux \
    --output-dir demux \
    $options \
    $args $bam

    find ./ -name bam_pass -exec cp -R {} . \\;

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        dorado: \$(dorado --version 2>&1 | tail -n1)
    END_VERSIONS
    """

}
