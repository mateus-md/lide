## 1.1.4d
\* smarter `ifautoinsert.lua`</br>
\+ dart lang support<br/>
---<br/>
\- bug with last commit (autoinsert not working correctly)<br/>

## 1.1.3d
\* changed "on close" events' messages<br/>
\* fixed bug with autoin (removing quotes on backspace if caret is at the beginning of the line)<br/>
\+ implementation of code linter via plugin<br/>
\+ caret color changes when overlaping color previews<br/>
---<br/>
\* lowercased some log messages<br/>
\* fixed core file (unrenamed file from lite to lide)<br/>

## 1.1.2df - 08/02/21 patch
\* fixed highlight bug in lang\_c (scribbles coloring lines below)<br/>

## 1.1.1d
\+ smarter lfautoinsert (puts else between then and end if there are no lines between them and don\'t puts end if the line below is else)<br/>

## 1.1.0d
\+ include changes from rxi's Lite (commit 38bd9b3...f074415)<br/>
---<br/>
\* fixed issue with last commit (pull rxi's commit)<br/>

### 1.0.4df - 14/01/21 patch
\* fixed waitfor from callback<br/>
\* better bracket\_match rendering<br/>
\* better lfautoinsert<br/>
---<br/>
\* fixed readme typo<br/>

### 1.0.3df - 08/01/21 patch
\+ added rustlang support<br/>
\* fixed lastproject<br/>

### 1.0.2df - 03/01/21 patch
\* fixed bracket\_match.lua and selection.lua<br/>
\* refixed lang\_lua.lua function definitions<br/>
\* fixed colorprev.lua<br/>
\* fixed lide showing "lite" instead of "lide"

### 1.0.1df - 02/01/21 patch
\+ lua intelisense<br/>
\+ readded user/init.lua file<br/>
\* fixed autocomp.lua and autoin<br/>
\* scrollbar is now thicker<br/>
\* fixed workspace.lua<br/>

### 1.0.0d - lide
\* fixed color prev<br/>
\* a lot of fixes<br/>
\* division of callback.draw.line in line and body<br/>
\- github theme

### 1.2.3cf - 30/12/20 patch
\* moved all graphical and update callbacks to `callback`<br/>
\* changed all plugins to use `callback`'s methods<br/>
---<br/>
\- fixed input callbacks in `autocomp.lua` and `autoin.lua`<br/>
\- fixed `ifautoinsert.lua` bug for commentless languages<br/>

### 1.2.2cf - 29/12/20 patch
\- fixed autocomplete (autocomp.lua) bug (renaming file makes it not work)<br/>
    * the bug was happening because it wasn't using the draw\_api so <br/>
      probably one was overwriting the other's root\_draw function.<br/>
\* fixed indent behaviour<br/>
    * tabing at the beginning of the line was <br/>
      adding 3 spaces instead of 4

### 1.2.1cf - 28/12/20 patch
\* fixed selection highlight (the commit 6d3e780 added a new color,<br/>
   but the a5f3714 removed it. This match adds again this feature)<br/>

### 1.2.0c Update
\* changed tab behaviour to act as in VS Code<br/>
\* changed tokenizer to highlight symbols before patterns<br/>
\* terminal behaviour<br/>
\* messages in message log<br/>
    * saved message shows shorter name<br/>
    * all messages in lower case<br/>
\- removed windows trash<br/>
\+ default plugins to better navegation and code editing
