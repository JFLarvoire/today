# today tools

A set of programs for computing and displaying various ephemeris times for today.

| Program      | Description                                                                |
| ------------ | -------------------------------------------------------------------------- |
| sunrise      | Display the sunrise time as HH:MM, or as a very detailed string            |
| sunset       | Display the sunset time as HH:MM, or as a very detailed string             |
| potm         | Display the Phase Of The Moon                                              |
| today        | Display all the above in plain English                                     |
| localtime    | Display the local time as HH:MM:SS                                         |
| WhereAmI.bat | Get system location information based on the IP address (Windows version)  |
| whereami.tcl | Get system location information based on the IP address (Unix version)     |

All binary programs accept an optional date/time argument, formatted as described below.
By default, they use the current date and time.

* ISO 8601 format for date/time: [YYYY-MM-DD][T][HH[:MM[:SS]]][Z]
   * YYYY-MM-DD is the optional date. The default is today.
   * T is an optional letter T joining the date and time. A space will work also, but in this case the argument must be quoted.
   * HH:MM:SS is the optional time. Minutes and seconds are optional. The two ':' can be replaced by 'h' and 'm' respectively.
   * Z is an optional trailing letter Z indicating a GMT date/time. The default is a local time.
* Shortened date format: [+YY]YYMMDD[HH[MM[SS]]]
   * This is the original format supported by today, with just numbers. Prepend a '+' if specifying the century.

All programs and scripts have an option -? or -h to display a detailed help screen.

### History

The programs were written in 1985, by Keith E. Brandt, John Dilley, Robert Bond, Martin Minow.  
Published in 2003 (?) at http://www.linuxha.com/athome/common/today.tgz.

Updated in 2009 by Neil Cherry to work better with the more intelligent C compilers of that time.  
The updated version was published at http://www.linuxha.com/athome/common/today-20091222.tgz

As of 2019-01-20, there was an empty repository at https://github.com/linuxha/today, that was probably intended to
contain Neil Cherry's latest version of today tools.

Updated in 2019 by Jean-François Larvoire, based on the 2009 version. Changes versus that 2009 version:

* Fixed all warnings reported by modern C compilers.
* Moved all location-specific definitions to new file params.h. Default setup for Grenoble, France.
* Added make files for DOS and Windows, from: https://github.com/JFLarvoire/SysToolsLib/tree/master/C/include
* Added command-line parsing to all programs. Use option -? or -h to get help.
* Added command-line options to sunrise and sunset, to add or subtract a given offset from the sunrise or sunset time.
* The potm program now also draws the moon crescent using ASCII art.
* Moved the date/time parsing routine from today.c to new file parsetime.c, and use it for all programs.
* Added a localtime program, to test date/time parsing improvements, and convert GMT time to local time.
* Added a configuration system (see below), and whereami.* scripts for automatically initializing it.

### Location configuration system

The initial programs had to be modified and rebuilt for use in a different location.  
This is still possible by modifying the constants defined in params.h.
But obviously this is very inconvenient.

The 2019 versions support location configuration files, and environment strings.
The programs search for the first location information file, in the following order:

1. In the user location file ("~/.location" for Unix, or "%USERPROFILE%\\location.inf" for Windows)
2. In the system location file ("/etc/location.conf" for Unix, or "%windir%\\location.inf" for Windows)
3. In the built-in constants from param.h.

| Variable definition example  | Description                               |
| ---------------------------- | ----------------------------------------- |
| LATITUDE = 37.787954         | Latitude. +=North. Required.              |
| LONGITUDE = -122.407498      | Longitude. +=East. Required.              |
| CITY = San Francisco         | City name. Required.                      |
| TZABBR = PST                 | Time Zone Abbreviation. Required.         |
| DSTZABBR = PDT               | TZ DST Abbreviation. Required if exists.  |
| COUNTRYCODE = US             | Two-letter country code. Optional.        |
| COUNTRYNAME = United States  | Country name. Optional.                   |
| REGIONCODE = CA              | Region or state code. Optional.           |

Notes:

* The = sign is optional
* Anything beginning with # or // is a comment, and is ignored by the programs.

Finally, if environment variables are defined, they override the values found in the configuration files above.

The easiest way to initialize a configuration file is to use the whereami.* script for your system.

### whereami.* scripts

These scripts use a web service API to get location information based on the system IP address.
So they work only if the system is connected to the Internet.

#### Windows:

* Open a command prompt running as Administrator
* Run `whereami.bat` to see the location information.
* Run `whereami.bat -s` to write that location information into "%windir%\\location.inf".

If you don't have administration rights:
* Open a normal command prompt
* Run `whereami.bat` to see the location information.
* Run `whereami.bat -u` to write that location information into "%USERPROFILE%\\location.inf".

#### Unix

* Open a command shell.
* Run `chmod +x whereami.tcl` to make sure whereami.tcl is executable.
* Run `./whereami.tcl` to see the location information.
* Run `sudo "$PWD/whereami.tcl" -s` to write that location information into "/etc/location.conf".

If you don't have root rights:
* Run `./whereami.tcl -u` to write that location information into "~/.location".

#### Precision of the location information

In most cases, the web service API will not report your actual location, but that of your ISP.  
If you're running a whereami script in an intranet within a large organization, you might get the location
of the place where your intranet is connected to the Internet... Which might be in a very distant city!  
So on a laptop, it is recommended to run the `whereami -s` script from home rather that from work.

For best precision, pinpoint your place in Google maps, then manually update the latitude, longitude, and city name
in the configuration file generated by the whereami.* script.


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

Run `make install`.  
This copies the executables to /usr/local/bin.

### For Windows with Microsoft tools

You'll need Microsoft Visual C++, that comes with Microsoft Visual Studio.
A free version called Microsoft Visual Studio Community Edition is downloadable from Microsoft web site at:
https://visualstudio.microsoft.com/downloads/  
Important: While installing Visual Studio Community Edition, make sure to select the following optional components:

- The workload "Desktop Development with C++"
- Options "C++/CLI support" and "Standard Library modules" (In the list at the right of the installation wizard)

Run `include\configure.bat`.  
This locates the Microsoft tools installed, and generates a config.%HOSTNAME%.bat file.  
This also adds configure.bat and make.bat proxies in the project root directory.  
This needs to be done once before making the first build, then again only if you install other versions of Visual Studio.

Run `make.bat`.  
This builds all today tools for both the x86 and amd64 processors, and possibly others depending on the compilers installed.  
The output files will be in `bin\WIN32` for the x86, and in `bin\WIN64` for the amd64 version.  
If you have Visual Studio 2005 installed, a WIN32s version for Windows 95 will also be built into `bin\WIN95`.  
If you have MSVC 1.5 installed, a 16-bits version for MS-DOS will also be built into `bin\DOS`.

Copy the executables into a tools directory listed in your PATH. Use C:\Windows if you don't know which directory to use.
Ex: `copy bin\WIN32\*.exe %windir%`

To build a release for uploading on GitHub, run: `make.bat release`

### For MS-DOS with Microsoft tools

You'll need Microsoft Visual C++ 1.52c.  
It is still available for MSDN subscribers, as part of the Visual Studio 2005 DVD image, but not installed by default by the VS 2005 setup.

Gotcha: The VC++ 1.52 compiler is a WIN32 program that runs in all 32 and 64-bits versions of Windows.
But unfortunately the VC++ 1.52 setup.exe program is a WIN16 program, which only runs on old 32-bits versions of Windows.
This requires doing extra steps for successfully installing the compiler in modern 64-bits versions of Windows:

- Install a 32-bits VM running Windows XP, that can run WIN16 programs out-of-the-box. (This has to be an x86 VM, not an amd64 VM with XP/64)  
  Note: Newer 32-bits x86 versions of Windows can still run WIN16 programs, but this may require some tinkering. If needed, look for instructions on the Internet.
- Give that VM access to the host's file system.
- Run the VC++ 1.52 setup in the VM, and install it in the VM's C:\MSVC. (Necessary so that the setup builds vcvars.bat correctly.)
- Once this is done, copy the VM's C:\MSVC to the host's C:\MSVC. (vcvars.bat will thus refer to the host's C drive.)

The build instructions are the same as for Windows.

If you have both VC++ 1.52 for building DOS apps, and a recent Visual Studio version for building Windows apps,
the make files will build both DOS and Windows versions, and the WIN32 version will be bound with the DOS version.
The resulting WIN32 exe files will thus run in all versions of DOS and Windows.

## License

As far as I know, those in the root directory were published long ago without specifying a license,
and are thus in the public domain.

The files in the include subdirectory come from the [SysToolsLib](https://github.com/JFLarvoire/SysToolsLib)
library [include files](https://github.com/JFLarvoire/SysToolsLib/tree/master/C/include),
and are licensed under the Apache 2 license.

The whereami.* scripts use time zone information extracted from Boost's [date_time_zonespec.csv](https://github.com/boostorg/date_time/blob/master/data/date_time_zonespec.csv),
See Boost license at https://github.com/boostorg/date_time/blob/develop/LICENSE
