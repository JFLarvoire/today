# today tools

A set of programs for computing and displaying various ephemeris times for today.

| Program   | Description                            |
| --------- | -------------------------------------- |
| sunrise   | Display the sunrise time as HH:MM      |
| sunset    | Display the sunset time as HH:MM       |
| potm      | Display the Phase Of The Moon          |
| today     | Display all the above in plain English |
| localtime | Display the local time as HH:MM:SS     |

All programs accept an optional date/time argument, formatted as described below.
By default, they use the current time.

* ISO 8601 format for date/time: [YYYY-MM-DD][T][HH[:MM[:SS]]][Z]
   * YYYY-MM-DD is the optional date  
   * T is an optional letter T joining the date and time. A space will work also, but in this case the argument must be quoted.  
   * HH:MM:SS is the optional time. Minutes and seconds optional.  
   * Z is an optional trailing letter Z indicating a GMT date/time.  
* Shortenened date format: [+YY]YYMMDD[HH[MM[SS]]]  

Use option -? to display a detailed help screen for each program.

### History

The programs were written in 1985, by Keith E. Brandt, John Dilley, Robert Bond, Martin Minow.  
Published in 2003 (?) at http://www.linuxha.com/athome/common/today.tgz.

Updated in 2009 by Neil Cherry to work better with the more intelligent C compilers of that time.  
The updated version was published at http://www.linuxha.com/athome/common/today-20091222.tgz

Updated in 2019 by Jean-François Larvoire. Changes versus the 2009 version:

* Fixed all warnings reported by modern C compilers.
* Moved all location-specific definitions to new file params.h. Default setup for Grenoble, France.
* Added make files for DOS and Windows, from: https://github.com/JFLarvoire/SysToolsLib/tree/master/C/include
* Added command-line options to sunrise and sunset, to add or subtract a given offset from the sunrise or sunset time.
  Use option -? or -h to get help.
* The potm program now also draws the moon crescent using ASCII art.
* Moved the date/time parsing routine from today.c to new file parsetime.c, and use it for all programs.
* Added a localtime program, to test date/time parsing extensions, and convert GMT time to local time.

## Build procedure

In all cases, first edit the params.h file, and change the geographical parameters for your location:

- Latitude
- Longitude
- Time zone offset versus GMT
- Time zone name
- Daylight saving time zone name

The default is setup for Grenoble, France.  
The original settings for Spotswood, New Jersey, and Fort Collins, Colorado, are still there, commented out.

### For Unix

Run `make`.  
This builds all today tools for the current version of Unix.
The output files will be in a subdirectory named after the Unix flavor and processor name. Ex: `bin/Linux.x86_64`

### For Windows with Microsoft tools

You'll need Microsoft Visual C++, that comes with Microsoft Visual Studio.
A free version is downloadable from Microsoft web site.

Run `include\configure.bat`.  
This locates the Microsoft tools installed, and generates a config.%HOSTNAME%.bat file.  
This also adds configure.bat and make.bat proxies in the project root directory.
This needs to be done once before making the first build, then again only if you install other versions of Visual Studio.

Run `make.bat`.  
This builds all today tools for both the x86 and amd64 processors, and possibly others depending on the compilers installed.  
The output files will be in `bin\WIN32` for the x86, and in `bin\WIN64` for the amd64.  
If you have Visual Studio 8 installed, a version for Windows 95 will also be built into `bin\WIN95`.  
If you have MSVC 1.5 installed, a version for MS-DOS will also be built into `bin\DOS`.

## License

As far as I know, those in the root directory were published on the Internet without specifing a license,
and are thus in the public domain.

The files in the include subdirectory come from the [SysToolsLib](https://github.com/JFLarvoire/SysToolsLib)
library [include files](https://github.com/JFLarvoire/SysToolsLib/tree/master/C/include),
and are licensed under the Apache 2 license.

