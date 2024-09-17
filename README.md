# Automating Job Submission with HTCondor's DAGMan

HTCondor's Directed Acyclic Graph Manager (DAGMan) utility enables you to automate the submission of your HTCondor jobs.
This tutorial guides you through how to use DAGMan to submit two HTCondor jobs.

## Setup

Copy the contents of this directory at `/data/datagrid/htcondor_tutorial/tutorial-dagman-intro` to your working directory.
Or clone the Github repository available at [https://github.com/CHTC/tutorial-dagman-intro](https://github.com/CHTC/tutorial-dagman-intro):

```
git clone -b '2024-09-Utrecht' https://github.com/CHTC/tutorial-dagman-intro.git
```

## Workflow Design

In this tutorial, you will be creating a DAG workflow to submit jobs A and B (with corresponding submit files `A.sub` and `B.sub`), 
such that job B only runs if job A runs successfully.

In this example, job A (using `A.sub`) will report on the machine where its executable script was executed.
Then, job B will use the report outputted by job A to make a comparison to the machine where its executable script was executed.
For this to work as desired, job A must complete and successfully return its report before job B can be submitted.

The workflow looks like this:

1. Submit job A
2. Job A completes
3. Check output of job A
4. If job A was successful, submit job B
5. Job B completes

Our goal is to use the DAGMan utility to handle these steps automatically on our behalf.

## Directory structure

The necessary files have already been created for this workflow. 
We are using a flat directory structure, so all of the files are in same location (and so will be the output when created).
You can see the structure with the `tree` command:

```
tree
```

should show something like

```
$ tree
.
├── A-check.sh
├── A.sh
├── A.sub
├── B.sh
├── B.sub
├── LICENSE
├── my-first.dag
└── README.md

0 directories, 8 files
```

Here's a short explanation of the files:

* `A.sub`: HTCondor submit file for job A
* `A.sh`: Executable script for job A
* `A-check.sh`: Script the confirms the output of job A is correct
* `B.sub`: HTCondor submit file for job B
* `B.sh`: Executable script for job B
* `my-first.dag`: DAG description file

The other files are related to the repository structure.

## DAG description file

We have to declare the jobs that we want the DAGMan utility to automatically submit, and the criteria for when those jobs should be submitted.
This has been done already in the `my-first.dag` file, which has the following contents:

```
$ cat my-first.dag
JOB A A.sub
SCRIPT POST A A-check.sh
JOB B B.sub

PARENT A CHILD B
```

The first line declares a job with the label `A` and a corresponding submit file `A.sub`.
The second line declares that job `A` has a script `A-check.sh` that must be executed after the submission of `A.sub` finishes;
DAGMan will consider job `A` successful only if the execution of `A-check.sh` is also successful.
The third line declares a job with the label `B` and a corresponding submit file `B.sub`.
Finally, the last line declares that job `A` is the "parent" of job `B`, which means job `B` will be submitted if and only if job `A` is totally successful.

> Note that the order of the lines does not technically matter, but for your own organization it may be helpful to declare items in the order
> you expect them to be executed.

### "DAG" vs "DAGMan"

"DAG" is the workflow - the jobs and the sequence in which you want them submitted.

"DAGMan" is the tool used to execute the "DAG" and is responsible for monitoring and automatically submitting the jobs in the correct sequence.

The contents of the DAG description file (`.dag`) generally describes the structure of the DAG workflow, 
but can also include commands to modify the behavior of the DAGMan instance that is executing the workflow.

## Submitting the DAG


