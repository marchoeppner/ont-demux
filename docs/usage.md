# Usage information

[Basic execution](#basic-execution)

[Pipeline version](#specifying-pipeline-version)

[Resources](#resources)

## Basic execution

Please see our [installation guide](installation.md) to learn how to set up this pipeline first. 

A basic execution of the pipeline looks as follows:

a) Without a site-specific config file

```bash
nextflow run marchoeppner/ont-demux -profile singularity --input path/to/pod5 \\
--run_name demux \
--model hac@v5.2.0 \
--kit SQK-RBK114-24
```

In this example, the pipeline will assume it runs on a single computer with the singularity container engine available. Available options to provision software are:

`-profile singularity`

`-profile apptainer`

`-profile docker` 

`-profile podman` 

Additional software provisioning tools as described [here](https://www.nextflow.io/docs/latest/container.html) may also work, but have not been tested by us. Please note that conda is **not** currently supported, because some of the software dependencies (namely Dorado) are not yet available as conda packages. 

b) with a site-specific config file

```bash
nextflow run marchoeppner/ont-demux -profile my_config --input path/to/pod5 \\
--run_name demux \
--model hac@v5.2.0 \
--kit SQK-RBK114-24
```

where my_config is a configuration for your local system, hosted at https://github.com/bio-raum/nf-configs.

## Specifying pipeline version

If you are running this pipeline in a production setting, you will want to lock the pipeline to a specific version. This is natively supported through nextflow with the `-r` argument:

```bash
nextflow run marchoeppner/THIS_PIPELINE -profile my_profile -r 1.0 <other options here>
```

The `-r` option specifies a github [release tag](https://github.com/marchoeppner/THIS_PIPELINE/releases) or branch, so could also point to `main` for the very latest code release. Please note that every major release of this pipeline (1.0, 2.0 etc) comes with a new reference data set, which has the be [installed](installation.md) separately.

## Options

The pipeline exposes minimal options. These are:

### `--kit` [ default = null]

The nanopore library kit used. Examples include:

| Kit | Dorado name |
| --- | ----------- |
| Ligation Sequencing | SQK-LSK114 |
| Ligation Sequencing XL | SQK-LSK114-XL |
| Native Barcoding (24) | SQK-NBD114-24 |
| Native Barcoding (96) | SQK-NBD114-96 |
| Ultra-long DNA Sequencing | SQK-ULK114 |
| Rapid Barcoding (24) | SQK-RBK114-24 |
| Rapid Barcoding (96) | SQK-RBK114-96 |
| Rapid Sequencing | SQK-RAD114 |
| Rapid PCR Barcoding (24) | SQK-RPB114-24 |
| 16S Barcoding (24) | SQK-16S114-24 |

### `--model` [ default = null]

The Dorado basecalling model to use. Typical options include:

| Model | Accuracy | Version |
| ----- | -------- | ------- |
|sup@v5.2.0 | SUP | 5.2.0 |
|hac@v5.2.0 | HAC | 5.2.0 |
|fast@v5.2.0 | FAST | 5.2.0 |
|sup@v502.0 | SUP | 5.0.0 |
|hac@v5.0.0 | HAC | 5.0.0 |
|fast@v5.0.0 | FAST | 5.0.0 |
|sup@v4.3.0 | SUP | 4.3.0 |
|hac@v4.3.0 | HAC | 4.3.0 |
|fast@v4.3.0 | FAST | 4.3.0 |


Accuracy refers to the overall basecalling accuracy and is divided into three categories: 
- fast (FAST): Fastest algorithm, but poorest overall basecalling accuracy
- high-accuracy (HAC): High accuracy, but slower speed
- super accuracy (SUP): Very high accuracy, but very slow speed (only to be used on a GPU!)

If you need the absolute best accuracy (i.e. when analysing variants, or reconstructing bacterial genomes for epidemiological analyses), use SUP. Else, HAC is usually fine. For most users, the most recent version of the model is preferrable - unless you need your base-called data to be compatible with older data sets.

### `--samplesheet` [ default = null]

A samplesheet can be used to inform the pipeline about sample names; else everything will just be named "all" or "barcodexy", depending on whether barcoding was used or not. The samplesheet must be CSV-formatted and follow the guidelines outlined [here](https://github.com/nanoporetech/dorado/blob/release-v1.1/documentation/SampleSheets.md). An example samplesheet may look as follows:

```CSV
experiment_id,kit,flow_cell_id,sample_id,flow_cell_product_code,alias,barcode
Listeria_Test,SQK-RBK114-24,FBA71669,Listeria_Test01,FLO-MIN114,L02,barcode01
Listeria_Test,SQK-RBK114-24,FBA71669,Listeria_Test01,FLO-MIN114,L03,barcode02
Listeria_Test,SQK-RBK114-24,FBA71669,Listeria_Test01,FLO-MIN114,L05,barcode03
Listeria_Test,SQK-RBK114-24,FBA71669,Listeria_Test01,FLO-MIN114,L06,barcode04
```

The samples are then named after the alias matched to each barcode. 

**Please note** - the experiment_id has to match the name you gave your run in MinKNOW. Else no matching between barcodes and aliases can occur. If you are unsure about the name you gave to your run, you can use the following command line call (with the pod5 package installed, e.g. via pip or conda):

```bash
pod5 inspect debug /path/to/pod5 | grep experiment_name
```

### `--run_name` [ default = null ]

A descriptive name for your run; mostly used for documentation purposes. 

