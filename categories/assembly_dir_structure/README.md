**Suggested Assembly directory structure and script to create it**

The asm_dir_struct.sh script can be used to see information about directories that support the assembly.
The script can also be used to create the structure for you.

Invoking asm_dir_struct.sh with no arguments shows information about the directory names and functions.
Running it with a directory option, usually a dot '.' indicating the current directory, prints a
list of commnds to create the structure.
You can save this to a file and make modifications before running.
However what we typically do is pipe it into bash while in the directory where we want to create the assembly.
```
asm_dir_struct.sh . | bash
```

Here is the default structure. You can always feel free to add directories that you will need and reove
those that aren't suitable for yhis assembly's needs.
