# Backward
Backward is Atari Falcon software dedicated to Falcon - ST compatibility

# Motivations
I did write it over the 1993-1995 period. It aims at increasing compatibility of *Atari ST* softwares with the *Atari Falcon 30*.
I publish it for historial interest, if any, as it has a strong coupling with the Falcon 30 hardware.

# Presentation
Out of the box, roughly 60%-70% of games were properly running on the Falcon, but thanks to various tricks, Backward
significantly improved the situation. The causes of incompatiblity were the new BIOS version (many games used
undocumented features/entry points), processor difference, frequency diference, bugs in the BIOS...

# Versions history
* Backward I allowed to turn off several features for compatibility: processor frequency, use of cache
* Backward II was available as a TSR and started to implements several fix for the TOS (the operating system)
* Backward III added a library manager allowing (for the registered version) to associate configuration with your floppy disks.
Booting on a known disk would automatically apply the adequate configuration.

# Features of Backward III
## hardware control
* control of processor frequency (16/8Mhz). _Some games were timing dependant, and running twice faster made them unplayable._
* control of procesor data cache. _The 68030 data cache offered a significant performance improvement and as such it more subtly 
impacted game speeds._
* control of processor instruction cache. _Some games, typically their copy protections, integrated dynamic code, but
the instruction cache did not support dynamic code
* enable/disable the internal speaker
* enable/disable the internal HD
* graphic video mode
* bus error handling: the Falcon bus was less permisive than the ST's and therefore some applications raised
exceptions that lead to crash, typicaly in their music routine. In fact, several hardware registers could be accessed
through multiple address on the ST, whereas only the official address was supported on Falcon. Backward proposed 3 strategies:
  * Handle the exception and correct the access. This was the safest, but games triggering a lot of exceptions
  were slowed down.
  * ST mode: disable the exception. The problem is that some faulty access were lost.
  * Fix the code: in case of error, Backward tried to patch the original code. It was the most efficient when it works,
  but as only a handful of patterns were recognized, it could lead to worse performance than the other two when it did not
  recognize the code.

## TOS
* memory size override
* integration of several BIOS patches. _Through the years, I identified and fixed several bugs within the BIOS._ You have to keep in mind that it was not possible to update your OS in those machines. You had the version that was burned in the ROMs and that's it.
* modifications of the OS variables mapping, so that games using undocumented variables could still function.
* turning GEM on/off: it allowed to shave some bytes within the system variables. _I was even able to have some games running whereas that could only run on the TOS 1.0._
* using the TOS version of your own choosing, assuming you had a file copy of it.


# Some technical details
* Backward is full assembler, even the GUI. Which was not a smart choice, but I did not know C at that time, and any kind of basic was out of question.
* While the 68030 came with an integrated MMU, allowing memory virtualization, the operating system made no use of it. In the latest version of Backward, I had implemented a crude virtual memory manager that allowed me to enable a 'copy on write' strategy for the ROMs. This way I could patch them easily, and ultimately allow users to load whatever TOS versions they wanted.
* I used to ask people to send me copy of their TOS so I could adjust my patches to each version. My Falcon had a TOS 4.02, but I got my hands on a TOS 4.01 and a TOS 4.04.
* In the end, Backwards contained something like 20+ bug fixes for the BIOS.
