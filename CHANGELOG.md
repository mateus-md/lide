### 1.2.0c - 29/12 patch
\* Fixed autocomplete (autocomp.lua) bug (renaming file makes it not work)
    * the bug was happening because it wasn't using the draw\_api so <br/>
      probably one was overwriting the other's root\_draw function.
\* Fixed indent behaviour
    * tabing at the beginning of the line was <br/>
      adding 3 spaces instead of 4

### 1.2.0c - 28/12 patch
\* Fixed selection highlight (the commit 6d3e780 added a new color,<br/>
   but the a5f3714 removed it. This match adds again this feature)

### 1.2.0c Update
\* Changed tab behaviour to act as in VS Code
\* Changed tokenizer to highlight symbols before patterns
\* Terminal behaviour
\* Messages in message log
    * saved message shows shorter name
    * all messages in lower case
\- Removed windows trash
\+ Default plugins to better navegation and code editing
