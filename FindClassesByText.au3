; =============================================================================
;
; Find Classes by Text v1.2
; Written by Alex Peters, 29/May/2013
;
; Lists the ClassNameNNs of a window grouped by the displayed text. Useful for
; determining the ClassNameNN of e.g. a text control when AutoIt Window Info
; cannot help (due for instance to overlapping controls on the window).
;
; =============================================================================


#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <TreeViewConstants.au3>
#include <WindowsConstants.au3>

Opt('GUIOnEventMode', True)
Opt('MustDeclareVars', True)
Opt('WinWaitDelay', 0)

; Variables to be accessed by event-handling functions.
Global $GUIHandle, $TreeHandle, $CaptureBtnHandle, $CopyItemBtnHandle
Global $CopyAllBtnHandle
Global $CapturedTitle = '[No window captured yet; click to capture]'
Global $InCaptureMode = False
Global $Capturing = False
Global $TextClasses
Global $SelectedItem

; GUI positioning constants.
Global Const $PADDING = 12
Global Const $BTN_HEIGHT = 40
Global Const $COPY_BTN_WIDTH = 60


; =============================================================================

PrepareGUI()

While True
    WinWaitNotActive($GUIHandle)
    ; Another window is active. Capture it if appropriate.
    If $InCaptureMode Then
        Local $CapturedWindow = WinGetHandle('[ACTIVE]')
        Beep(400, 50)
        $Capturing = True
        UpdateControlStates()
        ; Grab title for display on button.
        $CapturedTitle = WinGetTitle($CapturedWindow)
        ; Get the information and build a TreeView.
        $TextClasses = WinGetClassesByText($CapturedWindow)
        BuildTree()
        ; Return to normal operation mode.
        ToggleCaptureMode()
    EndIf
    WinWaitActive($GUIHandle)
WEnd


; =============================================================================
; PrepareGUI():
;     Creates and shows the GUI and its base controls.
; =============================================================================

Func PrepareGUI()

    ; Create the window.
    $GUIHandle = GUICreate('Find Classes by Text v1.2', _
            @DesktopWidth / 2, @DesktopHeight / 2, Default, Default, _
            BitOR($GUI_SS_DEFAULT_GUI, $WS_SIZEBOX, $WS_MAXIMIZEBOX))
    GUISetOnEvent($GUI_EVENT_RESIZED, 'Event_GUIResize')
    GUISetOnEvent($GUI_EVENT_CLOSE, 'Event_GUIClose')

    ; Create the Capture button.
    $CaptureBtnHandle = GUICtrlCreateButton('', _
            Default, Default, Default, Default, $BS_MULTILINE)
    GUICtrlSetResizing($CaptureBtnHandle, _
            $GUI_DOCKLEFT + $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKHEIGHT)
    GUICtrlSetOnEvent($CaptureBtnHandle, 'ToggleCaptureMode')

    ; Create the Copy Item button.
    $CopyItemBtnHandle = GUICtrlCreateButton('Copy' & @LF & '&item', _
            Default, Default, Default, Default, $BS_MULTILINE)
    GUICtrlSetResizing($CopyItemBtnHandle, _
            $GUI_DOCKWIDTH + $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKHEIGHT)
    GUICtrlSetOnEvent($CopyItemBtnHandle, 'CopySelectedItem')

    ; Create the Copy All button.
    $CopyAllBtnHandle = GUICtrlCreateButton('Copy' & @LF & '&all', _
            Default, Default, Default, Default, $BS_MULTILINE)
    GUICtrlSetResizing($CopyAllBtnHandle, _
            $GUI_DOCKWIDTH + $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKHEIGHT)
    GUICtrlSetOnEvent($CopyAllBtnHandle, 'CopyAllItems')

    ; Arrange everything nicely.
    RepositionControls()

    ; Ensure that the GUI reflects the initial state correctly.
    UpdateControlStates()

    ; Show the GUI.
    GUISetState()

EndFunc

; =============================================================================
; BuildTree():
;   Creates a TreeView control containing the specified text snippets and
;   associated ClassNameNNs.
; =============================================================================

Func BuildTree()

    ; Delete any existing TreeView; this is the easiest way to get rid of all
    ; existing window data.
    $SelectedItem = ''
    If $TreeHandle <> '' Then GUICtrlDelete($TreeHandle)

    ; Create a new TreeView.
    $TreeHandle = GUICtrlCreateTreeView(0, 0, 0, 0, _
            $GUI_SS_DEFAULT_TREEVIEW, $WS_EX_CLIENTEDGE)
    GUICtrlSetResizing($TreeHandle, $GUI_DOCKBORDERS)

    ; Keep everything nicely arranged.
    RepositionControls()

    ; Populate with text snippets and associated ClassNameNNs.
    For $I = 1 To $TextClasses[0][0]
        Local $TextNode = GUICtrlCreateTreeViewItem( _
                Escape($TextClasses[$I][0]), $TreeHandle)
                GUICtrlSetOnEvent(-1, 'Event_TreeViewItemSelect')
        Local $Classes = StringSplit($TextClasses[$I][1], @LF)
        For $J = 1 To $Classes[0]
            GUICtrlCreateTreeViewItem($Classes[$J], $TextNode)
            GUICtrlSetOnEvent(-1, 'Event_TreeViewItemSelect')
        Next
    Next

EndFunc


; =============================================================================
; RepositionControls():
;     Aligns the GUI controls nicely after a resize or after a new control is
;     created.
; =============================================================================

Func RepositionControls()

    Local Const $Area       = WinGetClientSize($GUIHandle)
    Local Const $MinLeft    = $PADDING
    Local Const $MaxLeft    = $Area[0] - $PADDING
    Local Const $MinTop     = $PADDING
    Local Const $MaxWidth   = $MaxLeft - $MinLeft
    Local Const $MaxHeight  = $Area[1] - 2 * $PADDING

    GUICtrlSetPos($CaptureBtnHandle, _
            $MinLeft, $MinTop, _
            $MaxWidth - 2 * $COPY_BTN_WIDTH - 2 * $PADDING, $BTN_HEIGHT)
    GUICtrlSetPos($CopyItemBtnHandle, _
            $MaxLeft - 2 * $COPY_BTN_WIDTH - $PADDING, $MinTop, _
            $COPY_BTN_WIDTH, $BTN_HEIGHT)
    GUICtrlSetPos($CopyAllBtnHandle, _
            $MaxLeft - $COPY_BTN_WIDTH, $MinTop, _
            $COPY_BTN_WIDTH, $BTN_HEIGHT)

    If $TreeHandle Then GUICtrlSetPos($TreeHandle, _
            $MinLeft, $MinTop + $BTN_HEIGHT + $PADDING, _
            $MaxWidth, $MaxHeight - $BTN_HEIGHT - $PADDING)

EndFunc


; =============================================================================
; UpdateControlStates():
;     Enables/disables controls as appropriate when the script's state changes
;     (e.g. capturing data, entering capture mode).
; =============================================================================

Func UpdateControlStates()

    If $InCaptureMode Then
        If $Capturing Then
            GUICtrlSetState($CaptureBtnHandle, $GUI_DISABLE)
            GUICtrlSetData($CaptureBtnHandle, 'Capturing...')
        Else
            GUICtrlSetData($CaptureBtnHandle, _
                '[Activate window to be captured or click to cancel]')
        EndIf
        GUICtrlSetState($CopyItemBtnHandle, $GUI_DISABLE)
        GUICtrlSetState($CopyAllBtnHandle, $GUI_DISABLE)
        If $TreeHandle Then GUICtrlSetState($TreeHandle, $GUI_DISABLE)
    Else
        GUICtrlSetData($CaptureBtnHandle, $CapturedTitle)
        GUICtrlSetState($CaptureBtnHandle, $GUI_ENABLE)
        If $SelectedItem Then
            GUICtrlSetState($CopyItemBtnHandle, $GUI_ENABLE)
        Else
            GUICtrlSetState($CopyItemBtnHandle, $GUI_DISABLE)
        EndIf
        If IsArray($TextClasses) AND $TextClasses[0][0] Then
            GUICtrlSetState($CopyAllBtnHandle, $GUI_ENABLE)
        Else
            GUICtrlSetState($CopyAllBtnHandle, $GUI_DISABLE)
        EndIf
        If $TreeHandle Then GUICtrlSetState($TreeHandle, $GUI_ENABLE)
    EndIf

EndFunc


; =============================================================================
; Event_GUIClose():
;     Called when the GUI is asked to close (e.g. when the user clicks the X).
; =============================================================================

Func Event_GUIClose()

    Exit

EndFunc


; =============================================================================
; Event_GUIResize():
;     Called after the user has completed a resize operation on the GUI.
; =============================================================================

Func Event_GUIResize()

    RepositionControls()

EndFunc


; =============================================================================
; Event_TreeViewItemSelect():
;     Called after the user has selected a TreeView item.
; =============================================================================

Func Event_TreeViewItemSelect()

    $SelectedItem = @GUI_CtrlId
    UpdateControlStates()

EndFunc


; =============================================================================
; CopySelectedItem():
;     Called when the user clicks the "Copy Item" button.  Copies the text of
;     the selected TreeView item to the clipboard.
; =============================================================================

Func CopySelectedItem()

    ClipPut(GUICtrlRead($SelectedItem, 1))

EndFunc


; =============================================================================
; CopyAllItems():
;     Called when the user clicks the "Copy All" button.  Copies the entire
;     content of the TreeView to the clipboard.
; =============================================================================

Func CopyAllItems()

    Local $Output = 'Control ClassNameNNs grouped by text for window ' _
        & Escape($CapturedTitle) & @CRLF & @CRLF

    Local $I, $J
    For $I = 1 To $TextClasses[0][0]
        $Output &= Escape($TextClasses[$I][0]) & @CRLF
        Local $Classes = StringSplit($TextClasses[$I][1], @LF)
        For $J = 1 To $Classes[0]
            $Output &= @TAB & $Classes[$J] & @CRLF
        Next
        $Output &= @CRLF
    Next

    ClipPut($Output)

EndFunc


; =============================================================================
; ToggleCaptureMode():
;     Called when the Capture button is clicked, and enters or exits capturing
;     mode as appropriate.  Also called when data capturing is complete.
; =============================================================================

Func ToggleCaptureMode()

    $InCaptureMode = NOT $InCaptureMode
    $Capturing = False
    UpdateControlStates()

EndFunc


; ==============================================================================
; WinGetClassesByText():
;     Returns a text/class list in the form of a two-dimensional array. Element
;     [0][0] contains a count of following text/class pairs. Element [X][0]
;     holds the text and element [X][1] holds an @LF-delimited list of
;     ClassNameNNs sharing that text.
; ==============================================================================

Func WinGetClassesByText($Title, $Text = '')

    Local $Classes = WinGetControlIDs($Title, $Text)
    Local $Texts[$Classes[0] + 1][2]
    $Texts[0][0] = 0

    For $I = 1 To $Classes[0]
        AddClass($Texts, ControlGetText($Title, $Text, $Classes[$I]), $Classes[$I])
    Next

    Return $Texts

EndFunc


; ==============================================================================
; WinGetControlIDs():
;     Returns an array of ClassNameNNs for a window where element 0 is a count.
; ==============================================================================

Func WinGetControlIDs($sTitle, $sText = '')

    Local $avClasses[1], $iCounter, $sClasses, $sClassStub, $sClassStubList

    ; Request an unnumbered class list.
    $sClassStubList = WinGetClassList($sTitle, $sText)

    ; Return an empty response if no controls exist.
    ; Additionally set @Error if the specified window was not found.
    If $sClassStubList = '' Then
        If @Error Then SetError(1)
        $avClasses[0] = 0
        Return $avClasses
    EndIf

    ; Prepare an array to hold the numbered classes.
    ReDim $avClasses[StringLen($sClassStubList) - _
            StringLen(StringReplace($sClassStubList, @LF, '')) + 1]

    ; The first element will contain a count.
    $avClasses[0] = 0

    ; Count each unique class, enumerate them in the array and remove them from
    ; the string.
    Do
        $sClassStub = _
                StringLeft($sClassStubList, StringInStr($sClassStubList, @LF))
        $iCounter = 0
        While StringInStr($sClassStubList, $sClassStub)
            $avClasses[0] += 1
            $iCounter += 1
            $avClasses[$avClasses[0]] = _
                    StringTrimRight($sClassStub, 1) & $iCounter
            $sClassStubList = _
                    StringReplace($sClassStubList, $sClassStub, '', 1)
        WEnd
    Until $sClassStubList = ''

    Return $avClasses

EndFunc


; ==============================================================================
; AddClass():
;     Adds a class to a text entry in the given text/class list. If the given
;     text is not already contained then a new element is created.
; ==============================================================================

Func AddClass(ByRef $Texts, $Text, $Class)

    For $I = 1 To $Texts[0][0]
        If $Text == $Texts[$I][0] Then
            $Texts[$I][1] &= @LF & $Class
            Return
        EndIf
    Next

    ; This point is reached if the text doesn't already exist in the list.
    $Texts[0][0] += 1
    $Texts[$Texts[0][0]][0] = $Text
    $Texts[$Texts[0][0]][1] = $Class

EndFunc


; ==============================================================================
; Escape($Input):
;     Returns an escaped version of $Input such that Execute(Escape($Input))
;     would return $Input.  Intended to make some special character sequences
;     easier to spot, and also to allow any string to be conveyed meaningfully
;     on a single line.
; ==============================================================================

Func Escape(Const ByRef $InputStr)

    ; AutoIt representations of certain special character sequences.  Longer
    ; sequences must be defined AFTER shorter ones contained by them in order
    ; to be correctly honoured (i.e. @CRLF after @CR).
    Local $Macros[4] = [ '@CR', '@CRLF', '@LF', '@TAB' ]

    ; The output string to be built incrementally and eventually returned.
    Local $OutputStr = ''

    ; Process the input string as a series of optional string literals followed
    ; by optional macros.  Start at the beginning and keep going until all of
    ; the input string has been examined.
    Local $StartPos = 1
    While $StartPos <= StringLen($InputStr)

        ; Find the first position in this part of the string where literal
        ; string data ends.  Assume at first that the entire remainder of the
        ; string is one big literal.  If we find a macro, remember which one.
        Local $LiteralEndPos = StringLen($InputStr) + 1
        Local $Macro = ''

        ; Look for each macro and remember which one appears first.  Check them
        ; all, because e.g. @CRLF would have the same position as @CR.
        Local $I
        For $I = 0 To UBound($Macros) - 1
            Local $ThisMacroPos _
                = StringInStr($InputStr, Execute($Macros[$I]), 0, 1, $StartPos)
            If $ThisMacroPos = 0 Then ContinueLoop
            If $LiteralEndPos > 0 AND $ThisMacroPos > $LiteralEndPos _
                Then ContinueLoop
            $LiteralEndPos = $ThisMacroPos
            $Macro = $Macros[$I]
        Next

        ; Escape the string literal if there is one.
        Local $Literal _
            = StringMid($InputStr, $StartPos, $LiteralEndPos - $StartPos)
        If $Literal <> '' Then
            If $OutputStr <> '' Then $OutputStr &= ' & '
            If _
                StringInStr($Literal, '"') _
                AND NOT StringInStr($Literal, "'") _
            Then
                ; It contains double quotes but not single quotes.
                ; Surround it with single quotes.
                $OutputStr &= "'" & $Literal & "'"
            Else
                ; It contains no quotes, or just single, or both.
                ; Surround it with doubles and escape any doubles within.
                $OutputStr &= '"' & StringReplace($Literal, '"', '""') & '"'
            EndIf
            $StartPos = $LiteralEndPos
        EndIf

        ; If we found a macro earlier then write it out.
        If $Macro <> '' Then
            If $OutputStr <> '' Then $OutputStr &= ' & '
            $OutputStr &= $Macro
            $StartPos += StringLen(Execute($Macro))
        EndIf

    WEnd

    If $OutputStr == '' Then $OutputStr = '""'
    Return $OutputStr

EndFunc
