Crosscompiling Maxima for Windows
=================================

On a Ubuntu/Debian System just install some tools for crosscompiling:

apt-get install g++-mingw-w64-i686 cmake nsis wine mingw-w64-dev p7zip-full rsync

then you can start the crosscompiling-process:


cd build # change to the build directory
cmake ..
make
make package

This will download the required Software (CLISP, Gnuplot, Maxima,
wXmaxima, wXwidgets, Tcl, Tk, jsMath TeX Fonts) from the internet
into the directory "download".

The packages will be compiled (if necessary) and a Windows 
installer for Maxima is generated.

This should work (at least) on Ubuntu, Debian and Opensuse.
(if you want you may even omit the first "make")

Instead of "make clean" just remove everything in the build directory.

If you want to use the current wxMaxima development version, you can use
cmake -DUSE_WXMAXIMA_GIT=YES ..



In case a software gets upgraded (and no new patches are needed), it should
be sufficient to just increase the version number and MD5-checksum for the new
release in CMakeLists.txt.


Best regards,
Wolfgang Dautermann


Some issues:
------------

Creating a windows compiled help file (chm) is only possible with 
proprietary tools and it does work without on Linux. 
So the (generated) help files from Andrej's package are included.
I suggest removing the code (or make it optional (e.g. --enable-chm-help or 
something similar) and use by default the standard HTML help (as in Linux)
Why create a proprietary file format?


Testing the installed package:
==============================

After building it, you can (and should) test the new Maxima installation package.
Install it on Windows and check that the installation (and later the deinstallation)
works properly. To test Maxima, try the following:

 o Run the maxima testsuite: run_testsuite()
 o Try compiling a function.  This has been a problem in the past
    - f(x):=x+2;
    - compile(f);
    - f(2);
 o Test the graphics systems in both xmaxima and wxmaxima
    plot2d(sin(x),[x,0,10]);
    plot2d(sin(x),[x,0,10],[plot_format,xmaxima]);
    plot3d(x*y,[x,-1,1],[y,-1,1]);
    scene(cone);
    plotdf([-y,x],[trajectory_at,5,0]);
    load(draw)$
    draw3d(xu_grid = 30, yv_grid = 60, surface_hide = true,
          parametric_surface(cos(phi) * sin(theta),
                       sin(phi) * sin(theta),
                       cos(theta),
                       theta, 0, %pi, phi, 0, 2 * %pi))$
 o Check that plotting to Postscript works
    plot2d(sin(x),[x,0,10],[ps_file,"ps_test.ps"]);
 o Try out the on-line help: describe(sin)
 o Try out, if external packages (e.g. lapack) work:
   load(lapack);
   fpprintprec : 6;
   M : matrix ([9.5, 1.75], [3.25, 10.45]);
   dgeev (M);

   should return the eigenvalues of M (and false, false since we did
   not compute eigenvectors: [[7.54331, 12.4067], false, false]

 o Check that the windows help files work from the Start menu 
   and from within xmaxima and wxmaxima
 o Try if double-clicking on a .wxmx file opens it
 o The wxMaxima source comes with a file (test/testbench_simple.wxmx)
   that tries to trigger everything that has gone wrong in previous
   wxMaxima builds.  They include the commands that will test the
   graphics system in the next step.
   Open that file and then select "Cells/Evaluate all cells" in this
   file and check if the file is processed correctly.
