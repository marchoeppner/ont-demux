# Common issues

## The pipeline runs into the wall time for base calling

Typically, when running into the "wall", the job gets resubmitted with double the wall time. Still, it wastes expensive compute time when a job gets cancelled before completion. So why does this happen?

Basically, we made the assumption that the majority of GPUs will run basecalling at >= 1GB/hour. The wall time is then calculated dynymically based on the size of the pod5 folder in GB times 2 in hours. This is effectively double what should be needed for even the most demanding basecalling tasks (i.e. SUP models). 

If this is insufficient for your setup, you may not be running with a (recent-enough) GPU (especially older Turing and Pascal cards will severely underperform!). Consider running a less demanding base calling model; and else let us know about your system specs and we can discuss options. 

## I have passed a sample sheet but I still do not get FastQ files named after my sample alias

As mentioned in the relevant part of the usage information, the sample sheet has to have a column `experiment_id`, which must mach the `experiment_name` of your run. 

## The pipeline crashes when trying to pull the Dorado container

Yes, the Dorado container is pretty big (> 9 GB). Depending on your internet connection, Nextflow may decide to kill the process if it takes too long. You can check the error message and simply copy/paste the command into the command line and let the pull run outside of Nextflow until it completes. And then just resume your pipeline run. 