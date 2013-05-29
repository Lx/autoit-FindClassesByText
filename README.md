# Find Classes By Text

An [AutoIt][] GUI script to enumerate a window's controls grouped by
their text content.

## Explanation

Sometimes it can be difficult to automate some software for one of a
few reasons:

*   Perhaps different fields share a common control ID.
*   Perhaps the GUI designer overlapped many controls, so
    [AutoIt Window Info][] won't show you the one that you actually
    have your mouse over.

This script aims to provide a solution.  The idea is for you to
populate such a GUI with different values in each field, and then allow
this script to 'capture' that window.  It will then group controls
sharing the same text values and display their `ClassNameNN`s, which is
generally** an excellent way to reliably differentiate between
controls.

## Operation

1.  Prepare the window that you wish to automate.
2.  Start this script.
3.  Click the **Capture** button.
4.  Activate the other window by clicking on it.
5.  Return to the script's window and browse the assembled TreeView.

** Proven not to work with .NET applications;
[_ControlGetHandleByPos()][] may be your only hope there.

## Version history

### Next release

*   Add a "Copy Item" button to copy the text of the currently selected
    TreeView item to the clipboard (thanks to [big_daddy][] for the
    idea)
*   Show control text as an AutoIt string definition (with macros as
    appropriate) instead of just naively wrapping it in single quotes

### v1.1 (27/May/2013)

*   Adjust for script-breaking changes in AutoIt v3.2.12.0 (thanks to
    [ptrex][])

### v1.0 (4/Mar/2006)

*   Initial release

[AutoIt]: http://www.autoitscript.com/
[AutoIt Window Info]: http://www.autoitscript.com/autoit3/docs/intro/au3spy.htm
[big_daddy]: http://www.autoitscript.com/forum/topic/22490-find-classes-by-text-v11/#entry158637
[_ControlGetHandleByPos()]: http://www.autoitscript.com/forum/topic/14323-controlgethandlebypos/
[ptrex]: http://www.autoitscript.com/forum/topic/22490-find-classes-by-text/#entry623888
