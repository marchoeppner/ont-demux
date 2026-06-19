process MD5SUM {

    label 'short_serial'
    
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"
    

    input:
    path(targets)

    output:
    path('*.md5'), emit: md5sums
    path("versions.yml"), emit: versions

    script:
    def args = task.ext.args ?: ''

    """
    find -L * -maxdepth 0 -type f \\
        ! -name '*.md5' \\
        -exec sh -c 'md5sum ${args} "\$1" > "\$1.md5"' _ "{}" \\;
   
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        md5sum: \$(echo \$(md5sum --version | head -n1 | sed 's/.*) //')
    END_VERSIONS

    """
}
