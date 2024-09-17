# Automating Job Submission with HTCondor's DAGMan

HTCondor's Directed Acyclic Graph Manager (DAGMan) utility enables you to automate the submission of your HTCondor jobs.
This tutorial guides you through how to use DAGMan to submit two HTCondor jobs.

## Setup

Copy the contents of this directory at `/data/datagrid/htcondor_tutorial/tutorial-dagman-intro` to your working directory.
Or clone the Github repository available at [https://github.com/CHTC/tutorial-dagman-intro](https://github.com/CHTC/tutorial-dagman-intro):

```
git clone -b '2024-09-Utrecht' https://github.com/CHTC/tutorial-dagman-intro.git
```

Once download is complete, you should see a directory `tutorial-dagman-intro`.
Navigate into that directory:

```
cd tutorial-dagman-intro
```

If you list the contents of the directory with the `ls` command, you should see the following files:

```
A-check.sh A.sh A.sub B.sh B.sub LICENSE my-first.dag README.md
```

You are now ready to continue with the tutorial.

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

To submit the DAG workflow for execution, run the command

```
condor_submit_dag my-first.dag
```

This will print some information about the submission and the files that are/will be created, something like this:

```
$ condor_submit_dag my-first.dag

-----------------------------------------------------------------------
File for submitting this DAG to HTCondor           : my-first.dag.condor.sub
Log of DAGMan debugging messages                   : my-first.dag.dagman.out
Log of HTCondor library output                     : my-first.dag.lib.out
Log of HTCondor library error messages             : my-first.dag.lib.err
Log of the life of condor_dagman itself            : my-first.dag.dagman.log

Submitting job(s).
1 job(s) submitted to cluster 550383.
-----------------------------------------------------------------------
```

Currently when you submit a DAG workflow, this creates a "DAGMan Job" in the queue on the access point.
This is the manifestation of the automated helper that monitors and submits jobs on your behalf.
Unlike a "regular" HTCondor job, the DAGMan job is executing on the access point itself.

When the DAGMan job first starts, it analyzes the DAG workflow declared in your description file.
Using that information, it decides which jobs are ready for submission.

## Monitoring the DAG execution

Like any other HTCondor job, the DAGMan job has an ID and log file and can be inspected with `condor_q`. 
If you check the queue right away with `condor_q`, you'll only see the DAGMan job itself.
As time goes on and DAGMan submits jobs automatically on your behalf, you'll those individual jobs appear
and disappear in the queue.

To get a live update of the progress of the DAG execution, you can use the `condor_watch_q` command:

```
condor_watch_q
```

This monitors the events sent to the `.log` file(s) of jobs in the queue and updates every 2 seconds, with
colors and progress bars.

> In upcoming versions of HTCondor (>= 24), `condor_watch_q` will automatically track jobs belonging
> to a DAG workflow.
> In the meantime, you can accomplish similar behavior with 
>
> ```
> condor_watch_q -f my-first.dag.nodes.log
> ```
>

For more information about your DAG workflow, you can use the `-dag` and `-nobatch` options with `condor_q`.
For example,

```
condor_q -dag
```

```
condor_q -dag -nobatch
```

## What's happening?

In this example, the following sequence of events occurs:

1. You submit the DAGMan job with `condor_submit_dag`
2. DAGMan job starts running on the access point and analyzes the DAG workflow declared in your `.dag` file.
3. DAGMan determines the first job(s) to submit is job `A`.
4. DAGMan submits job `A` using `A.sub`.
5. Job `A` is queued and the DAGMan job monitors its progress.
6. Job `A` executes like a regular HTCondor job.
7. DAGMan sees that job `A` has completed.
8. DAGMan executes the POST script `A-check.sh`.
9. The script should run successfully, meaning job `A` encountered no errors.
10. Now that job `A` and its POST script have completed successfully, DAGMan determines job `B` is ready to submit.
11. DAGMan submits job `B` using `B.sub`.
12. Job `B` is queued and the DAGMan job monitors its progress.
13. Job `B` executes like a regular HTCondor job.
14. DAGMan sees that job `B` has completed.
15. DAGMan (by default) decides job `B` completed successfully if its exit code is 0.
16. (Assuming job `B` completed successfully) DAGMan determines that all work has completed successfully.
17. DAGMan job itself completes.

As the individual jobs are submitted on your behalf by the DAGMan job, you will see them appear in the queue.
As those individual jobs complete, they will disappear from the queue like any other regular HTCondor job, 
and return their `.out`, `.err`, and other output files.
Unless there is an error, the DAGMan job will remain running in the queue during the entire execution of the DAG workflow.

For more information about the steps that DAGMan is taking on your behalf to execute your DAG workflow,
you can examine the contents of the `my-first.dag.dagman.out` file created automatically when you first submitted the DAGMan job.
This file is essentially a log of the DAG execution, but can be difficult to read until you are familiar with its structure.

## Completed DAG workflow

If your DAG workflow completes successfully, you should see the following in your directory:

```
$ tree
.
├── A-check.out
├── A-check.sh
├── A.err
├── A.log
├── A.out
├── A.sh
├── A.sub
├── B.err
├── B.out
├── B.sh
├── B.sub
├── LICENSE
├── my-first.dag
├── my-first.dag.condor.sub
├── my-first.dag.dagman.log
├── my-first.dag.dagman.out
├── my-first.dag.lib.err
├── my-first.dag.lib.out
├── my-first.dag.metrics
├── my-first.dag.nodes.log
└── README.md

0 directories, 21 files
```

Take a look at the contents of `A.out` and `B.out`. 
Has the workflow produced the comparison we initially described?

## What are all the files?

In addition to the files that are normally generated by the execution of job `A` and job `B`, 
there are quite a few files of the form `.dag.X` that are created.
Only a couple of the files, however, are of potential use to most users.

As mentioned above, the `my-first.dag.dagman.out` is a log of the execution of your DAG workflow.
This can be useful for understanding where in the DAG workflow the DAGMan job is currently at.

Also created is a `my-first.dag.nodes.log`. 
This file is a central copy of all of the log entries for the individual jobs submitted as part of your DAG workflow.
For example, in `A.sub` we define `log = A.log` and in `B.sub` we define `log = B.log`. 
These individual log files will be created as normal, but their contents will be mirrored into the `my-first.dag.nodes.log`.

> DAGMan uses the contents of the `my-first.dag.nodes.log` file for tracking the progress of all of the jobs
> it has submitted on your behalf.

Finally, the `my-first.dag.metrics` file is created when the DAGMan job itself completes (whether successfully or not) and
contains some statistics aobut the execution of the DAG workflow.

## What if something goes wrong?

The appendix at the end of this training has an exercise to explore what happens if job `A` does not pass its check.

The short version is that the DAGMan job will attempt to submit as much work as it can that is not dependent on the job that failed.
After it has done so, it will create a "rescue" DAG workflow in the file named `my-first.dag.rescue001`.
The contents of this file describe what jobs have completed and which ones failed and so need to be rerun.

The next time you run the `condor_submit_dag my-first.dag` command, DAGMan will automatically detect the rescue file
and use it to "rescue" the execution of the DAG workflow.
The jobs that have completed successfully before will be skipped, and DAGMan will go straight to submitting the jobs that failed previously
(and resuming monitoring and submission of the subsequent dependent jobs).

All you have to do is correct the issue that caused one of your jobs to fail, then rerun the `condor_submit_dag my-first.dag` command.
The DAGMan job will handle the rest.

## What if a job goes on hold?

The DAGMan job will keep running, monitoring the status of the held job. 
(There is eventually a timeout, however, after which it marks it as a failure and triggers the "rescue" behavior described above.)

If you can fix the issue that caused the job to go on hold without having to resubmit the job, you can do `condor_release` to return the job to matchmaking status.
The DAGMan job will see the change and status and proceed with its management of your DAG execution as normal.

If you can't fix the issue without resubmitting the job, you will have to `condor_rm` the job to remove it from the queue.
DAGMan will count that job as a failure, and trigger the "rescue" behavior above.

## Can I do ___?

The answer is probably "yes". 
The DAGMan utility is a large and complex system for automating HTCondor job submissions.
For more information, we encourage you to look at the [HTCondor documentation](https://htcondor.readthedocs.io/en/latest/automated-workflows/index.html).

## Appendix: Introducing failure 

*If time allows*

The jobs in the above example are very simple, and are almost guaranteed to behave as expected.
This may not be the case for all jobs.

As explained above, if a particular job fails then DAGMan can create a "rescue" file that will allow you to resume the DAG execution at the point of failure.

We are now going to introduce a failure in our jobs and see how the DAGMan job behaves, and how we can work around the failure.

### Setup

For this part, is probably easiest to create a subdirectory and copy the job files into it.
The following should accomplish this:

```
mkdir failure-exercise
cp A-check.sh A.sh A.sub B.sh B.sub my-first.dag failure-exercise/
cd failure-exercise
```

### Introducing the failure

In the new directory, run the following command:

```
sed -i 's/echo "(/ecoh "(/' A.sh B.sh
```

This replaces the `echo` command on a specific line in the `A.sh` and `B.sh` scripts with the incorrect command `ecoh`. 
Since `ecoh` is not a command, each of those scripts will fail at that line.

We can later correct this mistake by changing `ecoh` back to `echo` (but not yet!).

### Submit the DAG workflow

Otherwise, everything about the DAG workflow that we are executing is the same as described above.
To proceed, submit your DAG description file:

```
condor_submit_dag my-first.dag
```

Monitor the progress of the DAG execution.

### DAGMan and failure

In this case, you will see that the DAGMan job only tries to submit job `A`.
After job `A` completes, the DAGMan job will exit the queue instead of trying to submit the next job, job `B`.

Once the DAGMan job has exited (you no longer see it in your `condor_q` output or it has completed in the `condor_watch_q` output),
look at the files in the directory.
You should see a new `my-first.dag.rescue001` file has been created.

Examine the contents of the `my-first.dag.rescue001`, the `my-first.dag.metrics`, and the `my-first.dag.dagman.out` files.
Can you see what happened to the DAGMan execution?

The information you find in those files should show that only 1 job (job `A`) was run but that the job was considered a failure.
Further, job `A` was considered a failure because when `A-check.sh` was executed, it returned a failure.

### Troubleshooting the failure

Since the execution of `A-check.sh` was considered a failure, we should look at the output of that specific script.
You should see something like this:

```
$ cat A-check.out
A.out does not show the correct line.
A.err does not exist or is not empty.
Job A did not pass the check!
```

According to the script output, job `A` failed to show the correct line in the report and its `.err` file was not empty (since you should see the `.err` file when you `ls` in the directory).

Next, look in the `A.err` file.
You should see something like this:

```
$ cat A.err
<CONDOR_SCRATCH_DIR>/A.sh: line 10: ecoh: command not found
```

As expected, the issue with the execution of job `A` is the typo that we introduced above.

To correct this error, open `A.sh` and change the command on line 10 from `ecoh` to `echo`, but don't change anything else.
*Do not fix the typo in `B.sh` yet!*

### DAGMan and rescue

With job `A` fixed, we can submit the DAG workflow again:

```
condor_submit_dag my-first.dag
```

Note that this is the exact same command we ran the first time.
When the DAGMan job starts, it will automatically check if any rescue files exist and use the most recent one.

While a rescue file does exist at this time, there is no difference yet in how the DAG workflow will be executed because the DAG execution failed on the very first job.

As this second execution attempt of the DAG workflow proceeds, you should see that job `A` is submitted, completes, and passes its check successfully.
This will be evident when DAGMan submits job `B` to the queue.

After job `B` completes, the DAGMan job will complete as well.
At first glance, you may think this means the DAG workflow completed successfully, but you will see another `.dag.rescue###` file has been created.

Examine the contents of the `my-first.dag.rescue002`, the `my-first.dag.metrics`, and the `my-first.dag.dagman.out` files.
Can you see what happened to the DAGMan execution?

The information you find in those files should show that 2 jobs (job `A` and job `B`) were run but that job `B` was considered a failure.

### More troubleshooting

Let's pretend we didn't know there was a typo in `B.sh`. 
How can you troubleshoot this failure?
The answer is just the same as you would troubleshoot any other job that didn't function correctly.
So in this case, a good starting point is to look at the `B.out` and `B.err` files and see if you can identify the problem.

Again, the typo in the script is causing the failure. 
Open `B.sh` and change the command on line 10 from `ecoh` to `echo`, but don't change anything else.

### DAGMan and rescue (again)

Submit your DAG workflow one more time with

```
condor_submit_dag my-first.dag
```

Again, this is the same command as before.

This time, when the DAGMan job starts up it will use the `my-first.dag.rescue002` file (because it's the most recent rescue file) to resume the execution of the DAG.
When it does so, it will see that job `A` has already been completed successfully.
Thus, the DAGMan job will only submit job `B` this time.

Now when job `B` completes, it should be successful (non-zero exit code). 
That in turn means that the full DAG workflow has finally completed successfully.
When the DAGMan job completes and exits the queue, this time it will not create rescue file.

Examine the contents of the `my-first.dag.metrics` and the `my-first.dag.dagman.out` files.
Can you see confirm that the DAG workflow has completed successfully?