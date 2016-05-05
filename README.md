# thesis_benchmarks
Benchmarks for my thesis and optimized Riemann solvers.

<b>Note:</b>
This manual and the scripts and configuration files of this repository described therein were written for use on the TACC Stampede
Supercomputer using the Intel ifort Fortran compiler, version 15.0.2, and might have to be changed in order to run on your local machine.

Tests were run with the following configurations:
<ul>
  <li>Vanilla code FFLAGS: <code>-O2 -ipo [-pg|-DUSEPAPI]</code>, LFLAPGS: <code>-qopenmp-stubs [-pg|-lpapi]</code>
  <li>Optimized (SoA) code: FFLAGS: <code>-O2 -ipo -align array32byte -qopenmp-simd -xavx [-pg|-DUSEPAPI]</code>,
  LFLAGS: <code>-qopenmp-stubs [-pg|-lpapi]</code>
</ul>

Test results are available in my thesis. Unfortunately, the data is too big to upload here, but the tests can be re-run following
the instructions below.
<h2>Note on <code>create_jobs.sh</code></h2>
The bash script <code>create_jobs.sh</code> can be used to create various builds with different run settings and execute them as job on Stampede.
Therefore, some variables will have to be set, which will be explained in the following. After setting up the file, it can be executed with <code>./create_jobs.sh [all|runs|make]</code>
Usually <code>all</code> is the right choice. It attempts to build a binary with the compilation and linker flags passed,
overrides the grid size and the AMR levels in the setrun.py file and submits a job which is executed within a directory with the following based on the following pattern:

<code>run_${NAME}_${res}_${flagstring}</code>, where "NAME" is the given name (should include scenario name, for example),
"res" is the resolution set for x/y dimensions (multiple possible) and "flagstring" are the (trimmed) compilation flags. For example,
a gprof run for a SoA Chile scenario (with the respective compilation flags) and NAME=chile_soa for a 300x300 grid size would be stored in
the directory <code>run_chile_soa_300_O2_ipo_align_array32byte_qopenmp_simd_xavx_pg</code>

<h2>General settings</h2>
The following, general settings must be considered for all scenarios.
The following files might need to be changed in order to run the tests. Note that these descriptions specifically describe the parameters
that must be changed when executing automated runs with the create_jobs.sh script.
<ul>
  <li>Code, depending on what should be measured: <code>rpn2_geoclaw.f90, rpt2_geoclaw.f90, flux2_fw.f90, amr2.f90</code> - under <code>src</code> directory.
  <ul><li>For example, if you want to measure the normal Riemann solver FLOPS etc. with PAPI,
  make sure that the subroutine <code>flux2</code> surrounds the call to <code>rpn2</code> with a <code>papi_start()</code>/<code>papi_stop(mx)</code> pair.
  Additionally, for output purposes you should ensure that the call to <code>papi_summary</code> in the end of the program routine <code>amr2</code>
  has the correct name passed as parameter.</li></ul>
  </li>
  <li>job.sh - If running with the <code>create_jobs.sh</code>, only the time and node is relvant.
      Node should be normal in this case, as development only allows one job at a time. Otherwise, configure the job file as explained <a href="https://portal.xsede.org/tacc-stampede#running-slurm-queue">here</a></li>
  <li>Makefile - For automated jobs, only changing the <code>LFLAGS</code> is relevant. Add <code>-lpapi</code> if using PAPI, or <code>-pg</code> for obtaining a gprof output.
  Of course you can use both simultaneously, but for better results it was chosen to only enable one option at a time. If PAPI is <i>not</i> used,
  the module <code>$(CLAWUTILS)/src/papi_module.f90 \</code> should be commented out as otherwise linker errors can occur.</li>
  
  <li>create_jobs.sh - This is the most important file as here the following parameters are set:
  <ul>
    <li>NAME - This is the base name for the runs of this test. This is important to set as all the runs will be stored in directories with name <code>run_$NAME_$RESOLUTION_$FLAGS</code>.
    <li>FLAGS - This overrides the compiler flags in the Makefile. See what flags are used for the vanilla/vector run above. Note that for gprof or PAPI runs,
    <code>-pg</code> or <code>-DUSEPAPI</code> must be used as compiler option, respectively.
  </ul>
  </li>
</ul>
After setting up the scenario, it can be run with <code>./create_jobs.sh all</code>.
If the directory for the build already exists (same compilation flags, doesn't detect code changes!),
you are asked to overwrite the build.
The runs are stored in the <code>$WORK</code> filesystem (see <a href="https://portal.xsede.org/tacc-stampede#filesystems">this link</a> for a description), however a symlink to the directory is set under <code>./runs/</code>


<h3>Running the dry or wet scenario</h3>
The dry or wet scenarios can be found in <code>sl_bowl_radial</code>
First of all, you must decide  whether you want to execute the Vanilla version or the optimized version. This is done by executing <code>set_soa_vanilla.sh &lt;vanilla|soa&gt;</code>,
which sets symlinks for the Makefile and job file.

In addition to the aformentioned settings, you must consider the following settings for these scenarios:
<ul>
  <li>maketopo.py - In this Python file, the initial water height is set. The function <code>qinit(x,y)</code> describes
  the intial distribution for the dry case and the radial water hump, respectively. Just comment in/out accordingly for dry or wet scenario, respectively.</li>
  <li>amrlevels in <code>create_jobs.sh</code> - Additionally, the AMR level can be set. For the wet/dry scenario it was set to 1. (no AMR)</li>
</ul>

<h3>Running the Chile 2010 scenario</h3>
For the Chile scenario, the vanilla and SoA version lie in different directories.
<ul>
  <li>The SoA version is in <code>soa_step2</code></li>
  <li>For the Vanilla version can be found in <code>vanilla_papi</code> (it's called "papi" but of course gprof runs can also be excuted with this version)
</ul>
In addition to the aforementioned settings, the following changes might have to be performed.
<ul>
  <li>amrlevels in <code>create_jobs.sh</code> - Additionally, the AMR level can be set. For the Chile scenario it was set to either 1 
  for testing on different uniform grid sizes (no AMR), and for the AMR run level 3 refinement was used.</li>
</ul>
