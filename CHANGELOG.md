## 1.1.0d
\+ include changes from rxi's Lite (commit 38bd9b3...f074415)<br/>

### 1.0.4df - 14/01/21 patch
\* Fixed waitfor from callback<br/>
\* Better bracket\_match rendering<br/>
\* Better lfautoinsert<br/>
---
Fixed readme typo<br/>

### 1.0.3df - 08/01/21 patch
\+ Added rustlang support<br/>
\* Fixed lastproject<br/>

### 1.0.2df - 03/01/21 patch
\* Fixed bracket\_match.lua and selection.lua<br/>
\* Refixed lang\_lua.lua function definitions<br/>
\* Fixed colorprev.lua<br/>
\* Fixed lide showing "lite" instead of "lide"

### 1.0.1df - 02/01/21 patch
\+ lua intelisense<br/>
\+ Readded user/init.lua file<br/>
\* Fixed autocomp.lua and autoin<br/>
\* Scrollbar is now thicker<br/>
\* Fixed workspace.lua<br/>

### 1.0.0d - lide
\* Fixed color prev<br/>
\* A lot of fixes<br/>
\* Division of callback.draw.line in line and body<br/>
\- Github theme

### 1.2.3cf - 30/12/20 patch
\* Moved all graphical and update callbacks to `callback`<br/>
\* Changed all plugins to use `callback`'s methods<br/>
----
\- Fixed input callbacks in `autocomp.lua` and `autoin.lua`<br/>
\- Fixed `ifautoinsert.lua` bug for commentless languages<br/>

### 1.2.2cf - 29/12/20 patch
\- Fixed autocomplete (autocomp.lua) bug (renaming file makes it not work)<br/>
    * the bug was happening because it wasn't using the draw\_api so <br/>
      probably one was overwriting the other's root\_draw function.<br/>
\* Fixed indent behaviour<br/>
    * tabing at the beginning of the line was <br/>
      adding 3 spaces instead of 4

### 1.2.1cf - 28/12/20 patch
\* Fixed selection highlight (the commit 6d3e780 added a new color,<br/>
   but the a5f3714 removed it. This match adds again this feature)<br/>

### 1.2.0c Update
\* Changed tab behaviour to act as in VS Code<br/>
\* Changed tokenizer to highlight symbols before patterns<br/>
\* Terminal behaviour<br/>
\* Messages in message log<br/>
    * saved message shows shorter name<br/>
    * all messages in lower case<br/>
\- Removed windows trash<br/>
\+ Default plugins to better navegation and code editing
