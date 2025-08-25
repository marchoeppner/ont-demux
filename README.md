# ont-demux

This Pipeline performs basecalling and optional demultiplexing of Nanopore sequencing data. It supports the use of a samplesheet to map barcodes to sample names and generates both BAM and FastQ files per sample (or the entire run, if no barcodes were used). It can run with or without GPUs - but a GPU is generally recommended. As with any Nextflow pipeline, ont-demux should be capable or running both locally and on a cluster (which then requires a site-specific config file).

Ont-demux was developed for use with MinION (and GridION) sequencers. While it should be capable of also basecalling/demultiplexing Promethion data, it is potentially not optimized for such large data sets (using chunking or similar). Happy to consider adding better support if there is interest.

## Documentation 

1. [What happens in this pipeline?](docs/pipeline.md)
2. [Installation and configuration](docs/installation.md)
3. [Running the pipeline](docs/usage.md)
4. [Output](docs/output.md)
5. [Software](docs/software.md)
5. [Troubleshooting](docs/troubleshooting.md)
6. [Developer guide](docs/developer.md)
