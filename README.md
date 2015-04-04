# Backward
Backward is Atari Falcon software dedicated to Falcon - ST compatibility

# Motivations
I did write it over the 1993-1995 period. It aims at increasing compatibility of *Atari ST* softwares with the *Atari Falcon 30*.
I publish it for historial interest, if any, as it has a string coupling with the Falcon 30 hardware.

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
* integration of several BIOS patches
