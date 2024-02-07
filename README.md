# Backward
Backward is Atari Falcon software dedicated to Falcon - ST compatibility

# Motivations
I did write it over the 1993-1995 period. It aims at increasing compatibility of *Atari ST* softwares with the *Atari Falcon 30*.
I publish it for historial interest, if any. It has a strong coupling with the Falcon 30 hardware and have limited applications as of today.

# Presentation
Out of the box, roughly 60%-70% of Atari ST games were properly running on the Falcon, but thanks to various tricks, **Backward**
significantly improved the situation. The causes of incompatiblity were numerous: new BIOS version (many games used
undocumented features/entry points), processor differences, frequency diference, bugs in the ROMs, subtle hardware differences.

# Major Versions history
* Backward I allowed to turn off several features for compatibility: processor frequency, use of cache. It relied only on pre existing compatibility oriented features of the Falcon.
* Backward II was available as a TSR (i.e. start in memory, even after a reboot) and started to implements several fixes for the TOS (the operating system).
* Backward III added a library manager allowing (for the registered version) to associate a specific configuration with any disquette.
Booting on a known disk would automatically apply the adequate configuration, turning into a plug and play solution.

# Features of Backward III
## Hardware control
* control of processor frequency (16/8Mhz). _Some games were timing dependant, and a processor running twice as fast made them unplayable._
* control of procesor data cache. _The 68030 data cache offered a significant performance improvement and as such it more subtly 
impacted game speeds._
* control of processor instruction cache. The 60830 instruction cache ignored write attempts, as such, self modifying code failed on the Falcon. A strategy often used by copy protection to obfuscate the code. Alas, the 68000 had a single DWORD (32bits) instruction cache, while the 68030 had no cache at all when disabled, so there were still compatibility issues. 
* enable/disable the internal speaker: for convenience
* enable/disable the internal HD: the OS used a bit more memory to support the harddrive, which was a problem for games using fixed addresses.
* graphic video modes: hotkey switching between 50/60 Hz image refresh
* bus error handling: the Falcon bus was less permisive than the ST's and therefore some applications raised
exceptions that lead to crash, typicaly in their music routine. It turns out that the ST hardware ignored part of the hardware address lines for decoding, so hardware registers were accessible via aliased addresses, while only the official address was supported on Falcon. The aliasing possibility of the Atari ST were often used as an optimization, which would trigger a bus exception (two bombs) on the Falcon; sometimes it was simply a bug from the game. Backward proposed 3 strategies to deal with that situation:
  * Handle the exception and correct the access on the fly. This was the safest approach, but games triggering a lot of exceptions
  were slowed down (in practice, anything with digitized sound).
  * ST mode: disable the exception. You could tell Falcon hardware to ignorer address errors. The problem is that faulty accesses were lost, resulting in distorded soun.
  * Fix the code: in case of error, Backward tried to patch the original code. It was the most efficient when it worked,
  but only the most common patterns were recognized, and it failed back to on the fly correction when the code was not recognized; then it was really impacting performances

## TOS fixes
* memory size override
* integration of several BIOS patches. _Through the years, I identified and fixed several bugs within the BIOS._ You have to keep in mind that it was not possible to update your OS in those machines. You had the version that was burned in the ROMs and that's it.
* modifications of the OS variables mapping, so that games using undocumented variables could still function.
* turning GEM on/off: it allowed to shave some bytes within the system variables. _I was even able to have some games running whereas that could only run on the TOS 1.0._
* using the TOS version of your own choosing, assuming you had a file copy of it.


# Some technical details
* Backward is full assembler, even the GUI. Which was not a smart choice, but I did not know C at that time, and any kind of basic was out of question.
* While the 68030 came with an integrated MMU, allowing memory virtualization, the operating system made no use of it. In the latest version of Backward, I had implemented a crude virtual memory manager that allowed me to enable a 'copy on write' strategy for the ROMs. This way I could patch them easily, and ultimately allow users to load whatever TOS versions they wanted.
* I used to ask people to send me copy of their TOS so I could adjust my patches to each version. My Falcon had a TOS 4.02, but I got my hands on a TOS 4.01 and a TOS 4.04.
* In the end, Backwards contained something like 20+ bug fixes for various part of the TOS (XBIOS, GEM, LineA and LineF instructions..)
