# Installation

## Installing nextflow

Nextflow is a highly portable pipeline engine. Please see the official [installation guide](https://www.nextflow.io/docs/latest/getstarted.html#installation) to learn how to set it up.

This pipeline expects Nextflow version 25.04.2, available [here](https://github.com/nextflow-io/nextflow/releases/tag/v23.10.1).

## Software provisioning

This pipeline is set up to work with a range of software provisioning technologies - no need to manually install packages. 

You can choose one of the following options:

[Docker](https://docs.docker.com/engine/install/)

[Singularity](https://docs.sylabs.io/guides/3.11/admin-guide/)

[Apptainer](https://apptainer.org/docs/admin/main/installation.html)

[Podman](https://podman.io/docs/installation)


The pipeline comes with simple pre-set profiles for all of these as described [here](usage.md); if you plan to use this pipeline regularly, consider adding your own custom profile to our [central repository](https://github.com/bio-raum/nf-configs) to better leverage your available resources. Please not that Conda is **not supported** at this time. 

## Site-specific config file

If you run on anything other than a local system, this pipeline requires a site-specific configuration file to be able to talk to your cluster or compute infrastructure. Nextflow supports a wide range of such infrastructures, including Slurm, LSF and SGE - but also Kubernetes and AWS. For more information, see [here](https://www.nextflow.io/docs/latest/executor.html).

Site-specific config-files for our pipeline ecosystem are stored centrally on [github](https://github.com/bio-raum/nf-configs). Please talk to us if you want to add your system.

### Using GPUs

The pipeline will automatically try to detect and use a GPU when running on a single system - no work required on your part. At the moment, only single GPU configurations are considered, and the pipeline will pick the first GPU it sees. 

If you are running on a compute cluster with a mix of normal and GPU-enabled nodes, you can make use of the label 'gpu' in your site-specific config file:

```
process {
    executor = "slurm
    queue = "all"
    "withLabel:gpu".clusterOptions = "--gres=gpu:1"
}
```

This would then use a Slurm resource manager, the partition all - and require all the jobs with the label 'gpu' (i.e. Dorado base calling) to run on nodes that have one GPU available. You may also be able to use the slurm option `--constraint` for this; your mileage may vary depending on resource manager and overall cluster configuration. 