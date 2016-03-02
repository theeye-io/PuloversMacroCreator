﻿Playback(Macro_On, LoopInfo := "", ManualKey := "", UDFParams := "", RunningFunction := "", FlowControl := "")
{
	local PlaybackVars := [], LVData := [], LoopDepth := 0, LoopCount := [0], StartMark := []
	, m_ListCount := ListCount%Macro_On%, mLoopIndex, cLoopIndex, iLoopIndex := 0, mLoopLength, mLoopSize, mListRow
	, Action, Step, TimesX, DelayX, Type, Target, Window, Loop_Start, Loop_End, Lab, _Label, _i, Pars, _Count, TimesLoop, FieldsData
	, NextStep, NStep, NTimesX, NType, NTarget, NWindow, _each, _value, _key, _depth, _pair, _index, _point
	, pbParams, VarName, VarValue, Oper, RowData, ActiveRows, Increment := 0, TabIdx, RowIdx, LabelFound
	, ScopedParams := [], UserGlobals, GlobalList, CursorX, CursorY
	, Func_Result, SVRef, FuncPars, ParamIdx := 1, EvalResult

	If (LoopInfo.GetCapacity())
	{
		LoopDepth := LoopInfo.LoopDepth
	,	PlaybackVars := LoopInfo.PlaybackVars
	,	Loop_Start := LoopInfo.Range.Start
	,	Loop_End := LoopInfo.Range.End
	,	mLoopSize := LoopInfo.Count
	,	Increment := LoopInfo.Increment
	}
	Else
	{
		If (LoopInfo > 0)
			Loop_Start := LoopInfo
		CoordMode, Mouse, Screen
		MouseGetPos, CursorX, CursorY
		If (Record = 1)
		{
			GoSub, RecStop
			GoSub, b_Start
			Sleep, 500
			GoSub, RowCheck
		}
		Pause, Off
		Try Menu, Tray, Icon, %ResDllPath%, 46
		Menu, Tray, Default, %w_Lang008%
		If (AutoHideBar)
		{
			If (!WinExist("ahk_id " PMCOSC))
				GoSub, ShowControls
		}
		
		PlaybackVars[LoopDepth] := []
	,	PlayOSOn := 1, tbOSC.ModifyButtonInfo(1, "Image", 55)
		If ((ShowProgBar = 1) && (RunningFunction = ""))
			GuiControl, 28:+Range0-%m_ListCount%, OSCProg
		mLoopSize := o_TimesG[Macro_On]
	}
	CoordMode, Mouse, %CoordMouse%
	SetTitleMatchMode, %TitleMatch%
	SetTitleMatchMode, %TitleSpeed%
	DetectHiddenWindows, %HiddenWin%
	DetectHiddenText, %HiddenText%
	If (!FlowControl.GetCapacity())
		FlowControl := {Break: 0, Continue: 0, If: 0}
	CurrentRange := m_ListCount, ChangeProgBarColor("20D000", "OSCProg", 28)
	Gui, chMacro:Default
	Gui, chMacro:ListView, InputList%Macro_On%
	LVManager.SetHwnd(ListID%Macro_On%)
	Loop, %m_ListCount%
	{
		RowData := LVManager.RowText(A_Index)
	,   LVData[A_Index] := [RowData*]
	}
	ActiveRows := LV_GetSelCheck()
,	mLoopLength := (UDFParams.GetCapacity() || ManualKey || Increment) ? 1 : o_TimesG[Macro_On]
	While (mLoopLength = 0 || A_Index <= mLoopLength)
	{
		If (StopIt)
			break
		cLoopIndex := A_Index + Increment
		Loop, %m_ListCount%
		{
			mLoopIndex := iLoopIndex ? 1 : cLoopIndex
		,	PlaybackVars[LoopDepth][mLoopIndex, "A_Index"] := mLoopIndex
		,	mListRow := A_Index
			For _each, _value in PlaybackVars[LoopDepth][mLoopIndex]
				(InStr(_each, "A_")=1) ? "" : %_each% := _value
			If (StopIt)
				break 2
			If (Loop_Start > 0)
			{
				Loop_Start--
				continue
			}
			If (Loop_End = A_Index)
				return
			If (!ActiveRows.Checked[A_Index])
				continue
			If ((pb_From) && (A_Index < ActiveRows.FirstSel))
				continue
			If ((pb_To) && (A_Index > ActiveRows.FirstSel))
				break
			If ((pb_Sel) && (!ActiveRows.Selected[A_Index]))
				continue
			Data_GetTexts(LVData, A_Index, Action, Step, TimesX, DelayX, Type, Target, Window)
			If ((ShowProgBar = 1) && (RunningFunction = "") && (FlowControl.Break = 0) && (FlowControl.Continue = 0) && (FlowControl.If = 0))
			{
				If Type not in %cType7%,%cType17%,%cType21%,%cType35%,%cType38%,%cType39%,%cType40%,%cType41%,%cType44%,%cType45%,%cType46%,%cType47%,%cType48%,%cType49%,%cType42%
				{
					GuiControl, 28:, OSCProg, %A_Index%
					GuiControl, 28:, OSCProgTip, % "M" Macro_On " [Loop: " (iLoopIndex ? 1 "/" (LoopCount[LoopDepth][1] + 1) : mLoopIndex "/" mLoopSize) " | Row: " A_Index "/" m_ListCount "]"
				}
				Else If (ManualKey)
				{
					GuiControl, 28:, OSCProg, %A_Index%
					GuiControl, 28:, OSCProgTip, % "M" Macro_On " [Loop: " (iLoopIndex ? 1 "/" (LoopCount[LoopDepth][1] + 1) : mLoopIndex "/" mLoopSize) " | Row: " A_Index "/" m_ListCount "]"
				}
			}
			If ((ManualKey) && (ShowStep = 1))
			{
				NextStep := A_Index + 1
				If (NextStep > LVData.Length())
					NextStep := 1
				While ((!ActiveRows.Checked[NextStep]) || (LVData[NextStep, 8] = cType42))
				{
					NextStep++
					If (A_Index > m_ListCount)
						return
				}
				Data_GetTexts(LVData, NextStep,, NStep, NTimesX,, NType, NTarget, NWindow)
				ToolTip, 
				(LTrim
				%d_Lang021%: %NextStep%
				%NType%, %NStep%   [x%NTimesX% @ %NWindow%|%NTarget%]

				%d_Lang022%: %A_Index%
				%Type%, %Step%   [x%TimesX% @ %Window%|%Target%]
				)
			}
			If (WinExist("ahk_id " PMCOSC))
				Gui, 28:+AlwaysOntop
			If (Type = cType48)
			{
				AssignParse(Step, VarName, Oper, VarValue)
				If (VarName = "")
					VarName := Step, VarValue := UDFParams[ParamIdx].Value
				Else
					VarValue := (IsObject(UDFParams[ParamIdx].Value = "")) ? UDFParams[ParamIdx].Value
							:	(UDFParams[ParamIdx].Value = "") ? VarValue : UDFParams[ParamIdx].Value
				VarValue := (VarValue = "true") ? 1
						: (VarValue = "false") ? 0
						: Trim(VarValue, """")
			,	ScopedParams[ParamIdx] := {ParamName: VarName
										, VarName: UDFParams[ParamIdx].Name
										, Value: %VarName%
										, NewValue: VarValue
										, Type: (Target = "ByRef") ? "ByRef" : "Param"}
				ParamIdx++
				continue
			}
			If (Type = cType47)
			{
				If (!IsObject(ScopedVars[RunningFunction]))
					ScopedVars[RunningFunction] := []
				If (!IsObject(Static_Vars[RunningFunction]))
					Static_Vars[RunningFunction] := {}
				ScopedVars[RunningFunction].Push([])
			,	SVRef := ScopedVars[RunningFunction][ScopedVars[RunningFunction].MaxIndex()]
				Loop, Parse, Window, /, %A_Space%
				{
					If (A_Index = 2)
					{
						Loop, Parse, A_LoopField, `,, %A_Space%
						{
							AssignParse(A_LoopField, VarName, Oper, VarValue)
							If (VarName = "")
							{
								If (!Static_Vars[RunningFunction].HasKey(A_LoopField))
									Static_Vars[RunningFunction][A_LoopField] := ""
							}
							Else
							{
								If (!Static_Vars[RunningFunction].HasKey(VarName))
									Static_Vars[RunningFunction][VarName] := (VarValue = "true") ? 1
																			: (VarValue = "false") ? 0
																			: Trim(VarValue, """")
							}
						}
					}
				}
				If (Target = "Global")
				{
					GlobalList := ""
					Loop, Parse, Window, /, %A_Space%
					{
						If (A_Index = 1)
						{
							Loop, Parse, A_LoopField, `,, %A_Space%
							{
								AssignParse(A_LoopField, VarName, Oper, VarValue)
								If (VarName = "")
									SVRef[A_LoopField] := %A_LoopField%, %A_LoopField% := ""
								Else
									SVRef[VarName] := %VarName%, %VarName% := (VarValue = "true") ? 1
																			: (VarValue = "false") ? 0
																			: Trim(VarValue, """")
							}
						}
					}
				}
				Else If (Target = "Local")
				{
					GlobalList := ""
					Loop, Parse, Window, /, %A_Space%
					{
						If (A_Index = 1)
							Loop, Parse, A_LoopField, `,, %A_Space%
								GlobalList .= A_LoopField ","
					}
					UserGlobals := User_Vars.Get(true)
					For each, Section in UserGlobals
						For _key, _value in Section
							GlobalList .= _key ","
					UserGlobals := ""
					
					SavedVars(, VarsList, true)
					For _each, _value in VarsList
					{
						If (_value = "##_Locals:")
							break
						If _value in %GlobalList%
							continue
						SVRef[_value] := %_value%, %_value% := ""
					}
				}
				For _each, _value in Static_Vars[RunningFunction]
					SVRef[_each] := %_value%
				,	%_each% := _value
				
				For _each, _value in ScopedParams
					SVRef[_value.ParamName] := _value.Value
				,	VarName := _value.ParamName
				,	%VarName% := _value.NewValue
				continue
			}
			If (Type = cType49)
			{
				Try
					Func_Result := Eval(Step, PlaybackVars[LoopDepth][mLoopIndex])
				Catch 
				{
					MsgBox, 16, %d_Lang007%, % "Function: " RunningFunction
						.	"`n" d_Lang007 ":`t`t" e.Message "`n" d_Lang066 ":`t" (InStr(e.Message, "0x800401E3") ? d_Lang088 : e.Extra)
				}
				
				For _each, _value in ScopedParams
				{
					If (_value.Type = "ByRef")
					{
						ParamName := _value.ParamName
					,	_value.NewValue := %ParamName%
					}
				}
				
				For _each, _value in SVRef
				{
					If (Static_Vars[RunningFunction].HasKey(_each))
						Static_Vars[RunningFunction][_each] := %_each%
					%_each% := _value
				}
				
				For _each, _value in ScopedParams
				{
					If (_value.Type = "ByRef")
					{
						VarName := _value.VarName
					,	%VarName% := _value.NewValue
					}
				}
				
				ScopedVars[RunningFunction].Pop()
				return Func_Result
			}
			If ((Type = cType3) || (Type = cType13))
				MouseReset := 1
			If (Type = cType17)
			{
				FlowControl.If := IfStatement(FlowControl.If, PlaybackVars[LoopDepth][mLoopIndex]
							, Action, Step, TimesX, DelayX, Type, Target, Window, FlowControl.Break, FlowControl.Continue)
				If (ManualKey)
					WaitFor.Key(o_ManKey[ManualKey], 0)
				continue
			}
			If (FlowControl.If != 0)
				continue
			If ((Type = cType36) || (Type = cType37) || (Type = cType50))
			{
				If ((FlowControl.Break > 0) || (FlowControl.Continue > 0))
					continue
				CheckVars(PlaybackVars[LoopDepth][mLoopIndex], Step, DelayX)
			,	TabIdx := 0, RowIdx := 0, LabelFound := false
				Loop, %TabCount%
				{
					TabIdx := A_Index
					If (Step = TabGetText(TabSel, A_Index))
					{
						LabelFound := true
						break
					}
					Else
					{
						Gui, chMacro:ListView, InputList%TabIdx%
						Loop, % ListCount%A_Index%
						{
							LV_GetText(Row_Type, A_Index, 6)
						,	LV_GetText(TargetLabel, A_Index, 3)
							If ((Row_Type = cType35) && (TargetLabel = Step))
							{
								RowIdx := A_Index, LabelFound := true
								break 2
							}
						}
					}
				}
				If (!LabelFound)
				{
					MsgBox, 20, %d_Lang007%, % "Macro" Macro_On ", " d_Lang065 " " mListRow
						. "`n" d_Lang007 ":`t`t" d_Lang109 "`n" d_Lang066 ":`t" Step
					IfMsgBox, No
						StopIt := 1
					continue
				}
				If (Type = cType36)
				{
					_Label := [TabIdx, RowIdx, ManualKey]
					return _Label
				}
				If (Type = cType37)
				{
					_Label := Playback(TabIdx, RowIdx, ManualKey)
					If (IsObject(_Label))
						return _Label
					Else If (_Label)
					{
						Lab := _Label, _Label := 0
						If (_Label := Playback(Lab,, ManualKey))
							return _Label
					}
				}
				If (Type = cType50)
				{
					Action := RegExReplace(Action, ".*\s")
					For _each, _key in RegisteredTimers
					{
						If (_key = Step)
						{
							aHK_Timer%_each% := TabIdx, aHK_Label%_Label% := RowIdx
							If (Action = "Once")
							{
								DelayX := DelayX > 0 ? DelayX * -1 : -1
								SetTimer, RunTimerOn%_each%, %DelayX%
							}
							Else If (Action = "Period")
								SetTimer, RunTimerOn%_each%, %DelayX%
							Else If (Action = "Delete")
							{
								SetTimer, RunTimerOn%_each%, Delete
								RegisteredTimers.Delete(_each)
							}
							Else
								SetTimer, RunTimerOn%_each%, %Action%
							If (ManualKey)
								WaitFor.Key(o_ManKey[ManualKey], 0)
							If ((ShowProgBar = 1) && (RunningFunction = ""))
								GuiControl, 28:+Range0-%m_ListCount%, OSCProg
							continue 2
						}
					}
					For _each, _key in RegisteredTimers
					{
						If (_each != A_Index)
						{
							RegisteredTimers[_each] := Step
						,	aHK_Timer%_each% := TabIdx, aHK_Label%_Label% := RowIdx
							If (Action = "Once")
							{
								DelayX := DelayX > 0 ? DelayX * -1 : -1
								SetTimer, RunTimerOn%_each%, %DelayX%
							}
							Else If (Action = "Period")
								SetTimer, RunTimerOn%_each%, %DelayX%
							Else If (Action = "Delete")
							{
								SetTimer, RunTimerOn%_each%, Delete
								RegisteredTimers.Delete(_each)
							}
							Else
								SetTimer, RunTimerOn%_each%, %Action%
							If (ManualKey)
								WaitFor.Key(o_ManKey[ManualKey], 0)
							If ((ShowProgBar = 1) && (RunningFunction = ""))
								GuiControl, 28:+Range0-%m_ListCount%, OSCProg
							continue 2
						}
					}
					If (RegisteredTimers.Length() < 10)
					{
						_Label := RegisteredTimers.Push(Step)
					,	aHK_Timer%_Label% := TabIdx, aHK_Label%_Label% := RowIdx
						If (Action = "Once")
						{
							DelayX := DelayX > 0 ? DelayX * -1 : -1
							SetTimer, RunTimerOn%_Label%, %DelayX%
						}
						Else If (Action = "Period")
							SetTimer, RunTimerOn%_Label%, %DelayX%
						Else If (Action = "Delete")
						{
							SetTimer, RunTimerOn%_Label%, Delete
							RegisteredTimers.Delete(_Label)
						}
						Else
							SetTimer, RunTimerOn%_Label%, %Action%
					}
					Else
						TrayTip, %d_Lang107% %Step%, %d_Lang108%,, 19
				}
				If (ManualKey)
					WaitFor.Key(o_ManKey[ManualKey], 0)
				If ((ShowProgBar = 1) && (RunningFunction = ""))
					GuiControl, 28:+Range0-%m_ListCount%, OSCProg
				continue
			}
			If (Type = cType35)
				continue
			If ((ManualKey) && (Type = cType5))
					continue
			If ((Type = cType7) || (Type = cType38) || (Type = cType39)
			|| (Type = cType40) || (Type = cType41) || (Type = cType45) || (Type = cType51))
			{
				If (Action = "[LoopStart]")
				{
					If (FlowControl.Break > 0)
					{
						FlowControl.Break++
						continue
					}
					If (FlowControl.Continue > 0)
					{
						FlowControl.Continue++
						continue
					}
					Pars := SplitStep(PlaybackVars[LoopDepth][mLoopIndex], Step, TimesX, DelayX, Type, Target, Window)
				,	CheckVars(PlaybackVars[LoopDepth][mLoopIndex], TimesX)
				,	LoopDepth++
				,	PlaybackVars[LoopDepth] := []
				,	iLoopIndex++, StartMark[LoopDepth] := A_Index
				,	PlaybackVars[LoopDepth][mLoopIndex, "A_Index"] := 1
				,	LoopCount[LoopDepth] := ""
				
					For _depth, _pair in PlaybackVars
					{
						If (_depth = LoopDepth)
							break
						For _index, _point in _pair[mLoopIndex]
							For _each, _value in PlaybackVars[LoopDepth - 1]
								PlaybackVars[LoopDepth][_each, _index] := _point
					}
					
					If (Type = cType38)
					{
						Loop, Read, % Pars[1], % Pars[2]
						{
							If (StopIt)
								break 3
							PlaybackVars[LoopDepth][A_Index, "A_LoopReadLine"] := A_LoopReadLine
						,	LoopCount[LoopDepth] := [A_Index - 1, "", Target]
						}
					}
					Else If (Type = cType39)
					{
						Loop, Parse, % Pars[1], % Pars[2], % Pars[3]
						{
							If (StopIt)
								break 3
							PlaybackVars[LoopDepth][A_Index, "A_LoopField"] := A_LoopField
						,	LoopCount[LoopDepth] := [A_Index - 1, "", Target]
						}
					}
					Else If (Type = cType40)
					{
						Loop, Files, % Pars[1], % Pars[2]
						{
							If (StopIt)
								break 3
							PlaybackVars[LoopDepth][A_Index, "A_LoopFileName"] := A_LoopFileName
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileExt"] := A_LoopFileExt
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileFullPath"] := A_LoopFileFullPath
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileLongPath"] := A_LoopFileLongPath
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileShortPath"] := A_LoopFileShortPath
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileShortName"] := A_LoopFileShortName
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileDir"] := A_LoopFileDir
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileTimeModified"] := A_LoopFileTimeModified
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileTimeCreated"] := A_LoopFileTimeCreated
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileTimeAccessed"] := A_LoopFileTimeAccessed
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileAttrib"] := A_LoopFileAttrib
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileSize"] := A_LoopFileSize
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileSizeKB"] := A_LoopFileSizeKB
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopFileSizeMB"] := A_LoopFileSizeMB
						,	LoopCount[LoopDepth] := [A_Index - 1, "", Target]
						}
					}
					Else If (Type = cType41)
					{
						Loop, Reg, % Pars[1], % Pars[2]
						{
							If (StopIt)
								break 3
							PlaybackVars[LoopDepth][A_Index, "A_LoopRegName"] := A_LoopRegName
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopRegType"] := A_LoopRegType
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopRegKey"] := A_LoopRegKey
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopRegSubKey"] := A_LoopRegSubKey
						,	PlaybackVars[LoopDepth][A_Index, "A_LoopRegTimeModified"] := A_LoopRegTimeModified
						,	LoopCount[LoopDepth] := [A_Index - 1, "", Target]
						}
					}
					Else If (Type = cType45)
					{
						VarName := Eval(Pars[1], PlaybackVars[LoopDepth][mLoopIndex])[1]
						For _each, _value in VarName
						{
							If (StopIt)
								break 3
							PlaybackVars[LoopDepth][A_Index, Pars[2]] := _each
						,	PlaybackVars[LoopDepth][A_Index, Pars[3]] := _value
						,	LoopCount[LoopDepth] := [A_Index - 1, "", Target]
						}
					}
					Else If (Type = cType51)
					{
						If (!Eval(Step, PlaybackVars[LoopDepth][mLoopIndex])[1])
						{
							PlaybackVars[LoopDepth][mLoopIndex, "A_Index"] := mLoopIndex
						,	FlowControl.Break++
							continue
						}
						LoopCount[LoopDepth] := [0, Step]
					}
					Else
						LoopCount[LoopDepth] := [TimesX - 1, "", Target]
					If (!IsObject(LoopCount[LoopDepth]))
					{
						PlaybackVars[LoopDepth][mLoopIndex, "A_Index"] := mLoopIndex
					,	FlowControl.Break++
					}
					continue
				}
				If (Action = "[LoopEnd]")
				{
					_Count := LoopCount[LoopDepth][1]
				,	LoopInfo := {LoopDepth: LoopDepth
							,	PlaybackVars: PlaybackVars
							,	Range: {Start: StartMark[LoopDepth], End: A_Index}
							,	Count: _Count + 1}
					If (LoopCount[LoopDepth][3] != "")
					{
						If (Eval(LoopCount[LoopDepth][3], PlaybackVars[LoopDepth][mLoopIndex])[1])
							_Count := 0
					}
					Loop
					{
						PlaybackVars[LoopDepth][A_Index + 1, "A_Index"] := A_Index + 1
						If (LoopCount[LoopDepth][2] != "")
						{
							If (!Eval(LoopCount[LoopDepth][2], PlaybackVars[LoopDepth][A_Index + 1])[1])
								break
						}
						Else If (_Count = 0)
							break
						If (StopIt)
							break 3
						If (FlowControl.Break > 0)
						{
							FlowControl.Break--
							break
						}
						If (FlowControl.Continue > 1)
						{
							FlowControl.Continue--
							break
						}
						If (FlowControl.Continue > 0)
							FlowControl.Continue--
						
						LoopInfo.Increment := A_Index
					,	GoToLab := Playback(Macro_On, LoopInfo, ManualKey,,, FlowControl)
						If (IsObject(GoToLab))
						{
							For _each, _value in ScopedParams
							{
								If (_value.Type = "ByRef")
								{
									ParamName := _value.ParamName
								,	_value.NewValue := %ParamName%
								}
							}
							
							For _each, _value in SVRef
							{
								If (Static_Vars[RunningFunction].HasKey(_each))
									Static_Vars[RunningFunction][_each] := %_each%
								%_each% := _value
							}
							
							For _each, _value in ScopedParams
							{
								If (_value.Type = "ByRef")
								{
									VarName := _value.VarName
								,	%VarName% := _value.NewValue
								}
							}
							
							return GoToLab
						}
						Else If (GoToLab = "_return")
							break 3
						Else If (GoToLab)
						{
							Lab := GoToLab, GoToLab := 0
							If (_Label := Playback(Lab,, ManualKey,,, FlowControl))
								return _Label
							return
						}
						If (_Count = A_Index)
							break
						If (LoopCount[LoopDepth][3] != "")
						{
							If (Eval(LoopCount[LoopDepth][3], PlaybackVars[LoopDepth][A_Index + 1])[1])
								break
						}
					}
					LoopCount[LoopDepth] := "", LoopDepth--, iLoopIndex--
					If (ManualKey)
						WaitFor.Key(o_ManKey[ManualKey], 0)
					continue
				}
			}
			If ((FlowControl.Break > 0) || (FlowControl.Continue > 0))
				continue
			If ((Type = cType21) || (Type = cType44) || (Type = cType46))
			{
				Step := StrReplace(Step, "``n", "`n")
			,	Step := StrReplace(Step, "``t", "`t")
			,	Step := StrReplace(Step, "``,", ",")
			,	AssignParse(Step, VarName, Oper, VarValue)
			,	CheckVars(PlaybackVars[LoopDepth][mLoopIndex], Step, Target, Window, VarName, VarValue)
				If (Type = cType21)
				{
					If (Target = "Expression")
					{
						Loop, Parse, VarValue, `n, %A_Space%%A_Tab%
						{
							EvalResult := Eval(A_LoopField, PlaybackVars[LoopDepth][mLoopIndex])
							If (A_Index = 1)
								VarValue := EvalResult[1]
						}
					}
					Try
						AssignVar(VarName, Oper, VarValue, PlaybackVars[LoopDepth][mLoopIndex], RunningFunction)
					Catch e
					{
						MsgBox, 20, %d_Lang007%, % "Macro" Macro_On ", " d_Lang065 " " mListRow
							.	"`n" d_Lang007 ":`t`t" e.Message "`n" d_Lang066 ":`t" (InStr(e.Message, "0x800401E3") ? d_Lang088 : e.Extra) "`n`n" d_Lang035
						IfMsgBox, No
						{
							StopIt := 1
							continue
						}
					}
					Try SavedVars(VarName,,, RunningFunction)
				}
				Else If ((Target != "") && (!RegExMatch(Target, "\.ahk$")))
				{
					pbParams := Target "." Action "(" VarValue ")"
					Try
					{
						VarValue := Eval(pbParams, PlaybackVars[LoopDepth][mLoopIndex])
					,	AssignVar(VarName, ":=", VarValue, PlaybackVars[LoopDepth][mLoopIndex], RunningFunction)
					}
					Catch e
					{
						MsgBox, 20, %d_Lang007%, % "Macro" Macro_On ", " d_Lang065 " " mListRow
							.	"`n" d_Lang007 ":`t`t" e.Message "`n" d_Lang066 ":`t" (InStr(e.Message, "0x800401E3") ? d_Lang088 : e.Extra) "`n`n" d_Lang035
						IfMsgBox, No
						{
							StopIt := 1
							continue
						}
					}
					Try SavedVars(VarName,,, RunningFunction)
				}
				Else If ((Type = cType44) && (Target != ""))
				{
					pbParams := Eval(VarValue, PlaybackVars[LoopDepth][mLoopIndex])
					If (A_AhkPath)
					{
						Try
						{
							VarValue := RunExtFunc(Target, Action, pbParams*)
						,	AssignVar(VarName, ":=", VarValue, PlaybackVars[LoopDepth][mLoopIndex], RunningFunction)
						}
						
						Try SavedVars(VarName,,, RunningFunction)
					}
				}
				Else If (Type = cType44)
				{
					Loop, %TabCount%
					{
						TabIdx := A_Index
						If ((Action "()") = TabGetText(TabSel, A_Index))
						{
							Gui, chMacro:ListView, InputList%TabIdx%
							Loop, % ListCount%TabIdx%
							{
								LV_GetText(Row_Type, A_Index, 6)
								LV_GetText(TargetFunc, A_Index, 3)
								If ((Row_Type = cType47) && (TargetFunc = Action))
								{
									pbParams := {}
								,	FuncPars := ExprGetPars(VarValue)
								,	EvalResult := Eval(VarValue, PlaybackVars[LoopDepth][mLoopIndex])
									For _each, _value in EvalResult
										pbParams[_each] := {Name: FuncPars[_each], Value: _value}
									Func_Result := Playback(TabIdx,,, pbParams, Action)
								,	VarValue := Func_Result[1]
									Try
										AssignVar(VarName, ":=", VarValue, PlaybackVars[LoopDepth][mLoopIndex], RunningFunction)
									Catch e
									{
										MsgBox, 20, %d_Lang007%, % "Macro" Macro_On ", " d_Lang065 " " mListRow
											.	"`n" d_Lang007 ":`t`t" e.Message "`n" d_Lang066 ":`t" (InStr(e.Message, "0x800401E3") ? d_Lang088 : e.Extra) "`n`n" d_Lang035
										IfMsgBox, No
										{
											StopIt := 1
											continue 3
										}
									}
									Try SavedVars(VarName,,, RunningFunction)
									continue 3
								}
							}
						}
					}
					If (IsFunc(Action))
					{
						If (!Func(Action).IsBuiltIn)
							If Action not in Screenshot,Zip,UnZip
								continue
								
						pbParams := Eval(VarValue, PlaybackVars[LoopDepth][mLoopIndex])
						Try
						{
							VarValue := %Action%(pbParams*)
						,	AssignVar(VarName, ":=", VarValue, PlaybackVars[LoopDepth][mLoopIndex], RunningFunction)
						}
						Catch e
						{
							MsgBox, 20, %d_Lang007%, % "Macro" Macro_On ", " d_Lang065 " " mListRow
								.	"`n" d_Lang007 ":`t`t" e.Message "`n" d_Lang066 ":`t" (InStr(e.Message, "0x800401E3") ? d_Lang088 : e.Extra) "`n`n" d_Lang035
							IfMsgBox, No
							{
								StopIt := 1
								continue
							}
						}
						Try SavedVars(VarName,,, RunningFunction)
					}
				}
				If (ManualKey)
					WaitFor.Key(o_ManKey[ManualKey], 0)
				continue
			}
			If ((Type = cType15) || (Type = cType16))
			{
				Loop, 5
					Act%A_Index% := ""
				Loop, Parse, Action, `,,%A_Space%
					Act%A_Index% := A_LoopField
			}
			Else
			{
				If (InStr(Step, "``n"))
					Step := StrReplace(Step, "``n", "`n")
				If (InStr(Step, "``t"))
					Step := StrReplace(Step, "``t", "`t")
				If (InStr(Step, "``,"))
					Step := StrReplace(Step, "``,", ",")
			}
			If (Type = "Return")
				break 2
			If (Type = cType29)
			{
				If (LoopDepth = 0)
					break 2
				Else
				{
					If Step is number
						FlowControl.Break += Step
					Else
						FlowControl.Break++
					continue
				}
			}
			If (Type = cType30)
			{
				If Step is number
					FlowControl.Continue += Step
				Else
					FlowControl.Continue++
				continue
			}
			If (Type = cType42)
				continue
			TimesLoop := TimesX > 1
		,	CheckVars(TimesX)
		,	FieldsData := {Action: Action, Step: Step, DelayX: DelayX, Type: Type, Target: Target, Window: Window}
			While (TimesX)
			{
				PlaybackVars[LoopDepth][mLoopIndex, "A_Index"] := TimesLoop ? A_Index : mLoopIndex
			,	Pars := SplitStep(PlaybackVars[LoopDepth][mLoopIndex], Step, TimesX, DelayX, Type, Target, Window)
				If (StopIt)
				{
					Try Menu, Tray, Icon, %DefaultIcon%, 1
					Menu, Tray, Default, %w_Lang005%
					break 3
				}
				Try
					TakeAction := PlayCommand(Type, Action, Step, DelayX, Target, Window, Pars, PlaybackVars[LoopDepth][mLoopIndex], RunningFunction)
				Catch e
				{
					MsgBox, 20, %d_Lang007%, % d_Lang064 " Macro" Macro_On ", " d_Lang065 " " mListRow
						.	"`n" d_Lang007 ":`t`t" e.Message "`n" d_Lang066 ":`t" (InStr(e.Message, "0x800401E3") ? d_Lang088 : e.Extra) "`n`n" d_Lang035
					IfMsgBox, No
						StopIt := 1
				}
				PlaybackVars[LoopDepth][mLoopIndex, "ErrorLevel"] := ErrorLevel
				If ((Type = cType15) || (Type = cType16))
				{
					If ((TakeAction = "Break") || ((Target = "Break") && (SearchResult = 0)))
					{
						TakeAction := 0
						break
					}
					Else If ((Target = "Continue") && (SearchResult))
						break
					Else If (Target = "")
						TimesX--
				}
				Else
					TimesX--
				For _each, _value in FieldsData
					%_each% := _value
				If Type in Sleep,KeyWait,MsgBox
					continue
				If !(ManualKey)
					PlayCommand("Sleep", Action, Step, DelayX, Target, Window, Pars, PlaybackVars[LoopDepth][mLoopIndex], RunningFunction)
			}
			If (ManualKey)
				WaitFor.Key(o_ManKey[ManualKey], 0)
		}
		If (StopIt || FlowControl.Break)
			break
	}
	If (UDFParams.GetCapacity())
	{
		Func_Result := [""]
	
		For _each, _value in ScopedParams
		{
			If (_value.Type = "ByRef")
			{
				ParamName := _value.ParamName
			,	_value.NewValue := %ParamName%
			}
		}
		
		For _each, _value in SVRef
		{
			If (Static_Vars[RunningFunction].HasKey(_each))
				Static_Vars[RunningFunction][_each] := %_each%
			%_each% := _value
		}
		
		For _each, _value in ScopedParams
		{
			If (_value.Type = "ByRef")
			{
				VarName := _value.VarName
			,	%VarName% := _value.NewValue
			}
		}

		ScopedVars[RunningFunction].Pop()
		
		return Func_Result
	}
	If ((MouseReturn = 1) && (MouseReset = 1))
	{
		CoordMode, Mouse, Screen
		Click, %CursorX%, %CursorY%, 0
	}
	CoordMode, Mouse, %CoordMouse%
	Progress, Off
	SplashTextOff
	SplashImage, Off
	BlockInput, MouseMoveOff
	BlockInput, Off
	CurrentRange := ""
	If !(aHK_Timer)
	{
		Try Menu, Tray, Icon, %DefaultIcon%, 1
		Menu, Tray, Default, %w_Lang005%
		PlayOSOn := 0
		tbOSC.ModifyButtonInfo(1, "Image", 48)
		If (AutoHideBar)
		{
			If (WinExist("ahk_id " PMCOSC))
				GoSub, 28GuiClose
			Else
				Gui, 28:+AlwaysOntop
		}
	}
	If (CloseAfterPlay)
		ExitApp
	If (OnFinishCode > 1)
		GoSub, OnFinishAction
}

;##### Playback Commands #####

PlayCommand(Type, Action, Step, DelayX, Target, Window, Pars, CustomVars, RunningFunction)
{
	local Par1, Par2, Par3, Par4, Par5, Par6, Par7, Par8, Par9, Par10, Par11, Win
		, _each, _value, _Section, SelAcc, IeIntStr, lMatch, lMatch1, lResult, TakeAction
	For _each, _value in Pars
		Par%_each% := _value
	
	GoSub, pb_%Type%
	return
	
	pb_Send:
		If (WinActive("ahk_id " PMCWinID))
		{
			StopIt := 1
			return
		}
		Send, %Step%
	return
	pb_ControlSend:
		Win := SplitWin(Window)
		ControlSend, %Target%, %Step%, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_Click:
		If (WinActive("ahk_id " PMCWinID))
		{
			StopIt := 1
			return
		}
		Click, %Step%
	return
	pb_ControlClick:
		Win := SplitWin(Window)
		ControlClick, %Target%, % Win[1], % Win[2], %Par1%, %Par2%, %Par3%, % Win[3], % Win[4]
	return
	pb_SendEvent:
		If (WinActive("ahk_id " PMCWinID))
		{
			StopIt := 1
			return
		}
		If (Action = "[Text]")
			SetKeyDelay, %DelayX%
		SendEvent, %Step%
	return
	pb_Sleep:
		If ((Type = cType5) && (Step = "Random"))
			SleepRandom(, DelayX, Target)
		Else
		{
			If ((RandomSleeps) && (Step != "NoRandom"))
				SleepRandom(DelayX,,, RandPercent)
			Else If (SlowKeyOn)
				Sleep, (DelayX*SpeedDn)
			Else If (FastKeyOn)
				Sleep, (DelayX/SpeedUp)
			Else If ((Type = cType13) && (Action = "[Text]"))
				return
			Else
				Sleep, %DelayX%
		}
	return
	pb_MsgBox:
		Step := StrReplace(Step, "``n", "`n")
		Step := StrReplace(Step, "``,", ",")
		Try Menu, Tray, Icon, %ResDllPath%, 77
		ChangeProgBarColor("Blue", "OSCProg", 28)
		MsgBox, % Target, % (Window != "") ? Window : AppName, %Step%, %DelayX%
		Try Menu, Tray, Icon, %ResDllPath%, 46
		ChangeProgBarColor("20D000", "OSCProg", 28)
	return
	pb_SendRaw:
		If (WinActive("ahk_id " PMCWinID))
		{
			StopIt := 1
			return
		}
		SendRaw, %Step%
	return
	pb_ControlSendRaw:
		Win := SplitWin(Window)
		ControlSendRaw, %Target%, %Step%, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_ControlSetText:
		Win := SplitWin(Window)
		ControlSetText, %Target%, %Step%, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_Run:
		If (Par4 != "")
		{
			Run, %Par1%, %Par2%, %Par3%, %Par4%
			Try SavedVars(Par4,,, RunningFunction)
		}
		Else
			Run, %Par1%, %Par2%, %Par3%
	return
	pb_RunWait:
		Try Menu, Tray, Icon, %ResDllPath%, 77
		ChangeProgBarColor("Blue", "OSCProg", 28)
		If (Par4 != "")
		{
			RunWait, %Par1%, %Par2%, %Par3%, %Par4%
			Try SavedVars(Par4,,, RunningFunction)
		}
		Else
			RunWait, %Par1%, %Par2%, %Par3%
		Try Menu, Tray, Icon, %ResDllPath%, 46
		ChangeProgBarColor("20D000", "OSCProg", 28)
	return
	pb_RunAs:
		RunAs, %Par1%, %Par2%, %Par3%
	return
	pb_Process:
		Process, %Par1%, %Par2%, %Par3%
	return
	pb_Shutdown:
		Shutdown, %Step%
	return
	pb_GetKeyState:
		GetKeyState, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_MouseGetPos:
		Loop, 4
		{
			If (Par%A_Index% = "")
				Par%A_Index% := "_null"
		}
		MouseGetPos, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%
		_null := ""
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_PixelGetColor:
		PixelGetColor, %Par1%, %Par2%, %Par3%, %Par4%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_SysGet:
		SysGet, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_SetCapsLockState:
		SetCapsLockState, %Par1%
	return
	pb_SetNumLockState:
		SetNumLockState, %Par1%
	return
	pb_SetScrollLockState:
		SetScrollLockState, %Par1%
	return
	pb_EnvAdd:
		EnvAdd, %Par1%, %Par2%, %Par3%
	return
	pb_EnvSub:
		EnvSub, %Par1%, %Par2%, %Par3%
	return
	pb_EnvDiv:
		EnvDiv, %Par1%, %Par2%
	return
	pb_EnvMult:
		EnvMult, %Par1%, %Par2%
	return
	pb_EnvGet:
		EnvGet, %Par1%, %Par2%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_EnvSet:
		EnvSet, %Par1%, %Par2%
	return
	pb_EnvUpdate:
		EnvUpdate
	return
	pb_FormatTime:
		FormatTime, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_Transform:
		Transform, %Par1%, %Par2%, %Par3%, %Par4%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_Random:
		Random, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_FileAppend:
		FileAppend, %Par1%, %Par2%, %Par3%
	return
	pb_FileCopy:
		FileCopy, %Par1%, %Par2%, %Par3%
	return
	pb_FileCopyDir:
		FileCopyDir, %Par1%, %Par2%, %Par3%
	return
	pb_FileCreateDir:
		FileCreateDir, %Step%
	return
	pb_FileCreateShortcut:
		FileCreateShortcut, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%, %Par6%, %Par7%, %Par8%, %Par9%
	return
	pb_FileDelete:
		FileDelete, %Step%
	return
	pb_FileGetAttrib:
		FileGetAttrib, %Par1%, %Par2%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_FileGetShortcut:
		Loop, 8
		{
			If (Par%A_Index% = "")
				Par%A_Index% := "_null"
		}
		FileGetShortcut, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%, %Par6%, %Par7%, %Par8%
		_null := ""
		Loop, 7
		{
			AI := A_Index + 1
			Try SavedVars(Par%AI%)
		}
	return
	pb_FileGetSize:
		FileGetSize, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_FileGetTime:
		FileGetTime, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_FileGetVersion:
		FileGetVersion, %Par1%, %Par2%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_FileMove:
		FileMove, %Par1%, %Par2%, %Par3%
	return
	pb_FileMoveDir:
		FileMoveDir, %Par1%, %Par2%, %Par3%
	return
	pb_FileRead:
		FileRead, %Par1%, %Par2%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_FileReadLine:
		FileReadLine, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_FileRecycle:
		FileRecycle, %Step%
	return
	pb_FileRecycleEmpty:
		FileRecycleEmpty, %Step%
	return
	pb_FileRemoveDir:
		FileRemoveDir, %Par1%, %Par2%
	return
	pb_FileSelectFile:
		FileSelectFile, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%
		FreeMemory()
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_FileSelectFolder:
		FileSelectFolder, %Par1%, %Par2%, %Par3%, %Par4%
		FreeMemory()
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_FileSetAttrib:
		FileSetAttrib, %Par1%, %Par2%, %Par3%, %Par4%
	return
	pb_FileSetTime:
		FileSetTime, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%
	return
	pb_Drive:
		Drive, %Par1%, %Par2%, %Par3%
	return
	pb_DriveGet:
		DriveGet, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_DriveSpaceFree:
		DriveSpaceFree, %Par1%, %Par2%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_Sort:
		Sort, %Par1%, %Par2%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StringGetPos:
		StringGetPos, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StringLeft:
		StringLeft, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StringRight:
		StringRight, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StringLen:
		StringLen, %Par1%, %Par2%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StringLower:
		StringLower, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StringUpper:
		StringUpper, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StringMid:
		StringMid, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StringReplace:
		StringReplace, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StringSplit:
		StringSplit, %Par1%, %Par2%, %Par3%, %Par4%
		CGN := Par1 . "0"
		Loop, % %CGN%
		{
			CGP := Par1 . A_Index
			Try SavedVars(CGP,,, RunningFunction)
		}
	return
	pb_StringTrimLeft:
		StringTrimLeft, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StringTrimRight:
		StringTrimRight, %Par1%, %Par2%, %Par3%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_SplitPath:
		Loop, 6
		{
			If (Par%A_Index% = "")
				Par%A_Index% := "_null"
		}
		SplitPath, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%, %Par6%
		_null := ""
		Loop, 5
		{
			AI := A_Index + 1
			Try SavedVars(Par%AI%)
		}
	return
	pb_InputBox:
		InputBox, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%, %Par6%, %Par7%, %Par8%,, %Par10%, %Par11%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_ToolTip:
		ToolTip, %Par1%, %Par2%, %Par3%, %Par4%
	return
	pb_TrayTip:
		TrayTip, %Par1%, %Par2%, %Par3%, %Par4%
	return
	pb_Progress:
		Progress, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%
	return
	pb_SplashImage:
		SplashImage, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%, %Par6%
	return
	pb_SplashTextOn:
		SplashTextOn, %Par1%, %Par2%, %Par3%, %Par4%
	return
	pb_SplashTextOff:
		SplashTextOff
	return
	pb_RegRead:
		RegRead, %Par1%, %Par2%, %Par3%, %Par4%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_RegWrite:
		RegWrite, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%
	return
	pb_RegDelete:
		RegDelete, %Par1%, %Par2%, %Par3%
	return
	pb_SetRegView:
		SetRegView, %Par1%
	return
	pb_IniRead:
		IniRead, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_IniWrite:
		IniWrite, %Par1%, %Par2%, %Par3%, %Par4%
	return
	pb_IniDelete:
		IniDelete, %Par1%, %Par2%, %Par3%
	return
	pb_SoundBeep:
		SoundBeep, %Par1%, %Par2%
	return
	pb_SoundGet:
		SoundGet, %Par1%, %Par2%, %Par3%, %Par4%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_SoundGetWaveVolume:
		SoundGetWaveVolume, %Par1%, %Par2%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_SoundPlay:
		SoundPlay, %Par1%, %Par2%
	return
	pb_SoundSet:
		SoundSet, %Par1%, %Par2%, %Par3%, %Par4%
	return
	pb_SoundSetWaveVolume:
		SoundSetWaveVolume, %Par1%, %Par2%
	return
	pb_ClipWait:
		Try Menu, Tray, Icon, %ResDllPath%, 77
		ChangeProgBarColor("Blue", "OSCProg", 28)
		ClipWait, %Par1%, %Par2%
		Try Menu, Tray, Icon, %ResDllPath%, 46
		ChangeProgBarColor("20D000", "OSCProg", 28)
	return
	pb_BlockInput:
		BlockInput, %Step%
	return
	pb_UrlDownloadToFile:
		UrlDownloadToFile, %Par1%, %Par2%
	return
	pb_CoordMode:
		CoordMode, %Par1%, %Par2%
	return
	pb_OutputDebug:
		OutputDebug, %Step%
	return
	pb_WinMenuSelectItem:
		WinMenuSelectItem, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%, %Par6%, %Par7%, %Par8%, %Par9%, %Par10%, %Par11%
	return
	pb_SendLevel:
		SendLevel, %Step%
	return
	pb_SetKeyDelay:
		SetKeyDelay, %Par1%, %Par2%, %Par3%
	return
	pb_Pause:
		ToggleIcon()
		Pause
	return
	pb_ExitApp:
		ExitApp
	return
	pb_ListVars:
		GoSub, ListVars
	return
	pb_StatusBarGetText:
		StatusBarGetText, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%, %Par6%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_StatusBarWait:
		Try Menu, Tray, Icon, %ResDllPath%, 77
		ChangeProgBarColor("Blue", "OSCProg", 28)
		StatusBarWait, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%, %Par6%
		Try Menu, Tray, Icon, %ResDllPath%, 46
		ChangeProgBarColor("20D000", "OSCProg", 28)
	return
	pb_Clipboard:
		SavedClip := ClipboardAll
		If (Step != "")
		{
			Clipboard =
			Clipboard := Step
			Sleep, 333
		}
		If (Target != "")
		{
			Win := SplitWin(Window)
			ControlSend, %Target%, {Control Down}{v}{Control Up}, % Win[1], % Win[2], % Win[3], % Win[4]
		}
		Else
			Send, {Control Down}{v}{Control Up}
		Clipboard := SavedClip
		SavedClip := ""
	return
	pb_Control:
		Win := SplitWin(Window)
		Control, % RegExReplace(Step, "(^\w*).*", "$1")
		, % RegExReplace(Step, "^\w*, ?(.*)", "$1")
		, %Target%, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_ControlFocus:
		Win := SplitWin(Window)
		ControlFocus, %Target%, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_ControlMove:
		Win := SplitWin(Window)
		ControlMove, %Target%, %Par1%, %Par2%, %Par3%, %Par4%, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_PixelSearch:
		CoordMode, Pixel, %Window%
		PixelSearch, FoundX, FoundY, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%, %Par6%, %Par7%
		SearchResult := ErrorLevel
		Try %Act3% := FoundX, %Act4% := FoundY
		GoSub, TakeAction
	return TakeAction
	pb_ImageSearch:
		CoordMode, Pixel, %Window%
		ImageSearch, FoundX, FoundY, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%
		SearchResult := ErrorLevel
		If ((Act5) && (ErrorLevel = 0))
			CenterImgSrchCoords(Par5, FoundX, FoundY)
		Try %Act3% := FoundX, %Act4% := FoundY
		GoSub, TakeAction
	return TakeAction
	pb_SendMessage:
		Win := SplitWin(Window)
		SendMessage, %Par1%, %Par2%, %Par3%, %Target%, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_PostMessage:
		Win := SplitWin(Window)
		PostMessage, %Par1%, %Par2%, %Par3%, %Target%, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_KeyWait:
		Try Menu, Tray, Icon, %ResDllPath%, 77
		ChangeProgBarColor("Blue", "OSCProg", 28)
		If (Action = "KeyWait")
			KeyWait, %Par1%, %Par2%
		Else
			WaitFor.Key(Step, DelayX / 1000)
		Try Menu, Tray, Icon, %ResDllPath%, 46
		ChangeProgBarColor("20D000", "OSCProg", 28)
	return
	pb_Input:
		Input, %Par1%, %Par2%, %Par3%, %Par4%
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_ControlEditPaste:
		Win := SplitWin(Window)
		Control, EditPaste, %Step%, %Target%, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_ControlGetText:
		Win := SplitWin(Window)
		ControlGetText, %Step%, %Target%, % Win[1], % Win[2], % Win[3], % Win[4]
		Try SavedVars(Step,,, RunningFunction)
	return
	pb_ControlGetFocus:
		Win := SplitWin(Window)
		ControlGetFocus, %Step%, % Win[1], % Win[2], % Win[3], % Win[4]
		Try SavedVars(Step,,, RunningFunction)
	return
	pb_ControlGet:
		Win := SplitWin(Window)
		ControlGet, %Par1%, %Par2%, %Par3%, %Target%, % Win[1], % Win[2], % Win[3], % Win[4]
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_ControlGetPos:
		Win := SplitWin(Window)
		ControlGetPos, %Step%X, %Step%Y, %Step%W, %Step%H, %Target%, % Win[1], % Win[2], % Win[3], % Win[4]
		CGPPars := "X|Y|W|H"
		Loop, Parse, CGPPars, |
		{
			CGP := Step . A_LoopField
			Try SavedVars(CGP,,, RunningFunction)
		}
	return
	pb_WinActivate:
		Win := SplitWin(Window)
		WinActivate, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_WinActivateBottom:
		Win := SplitWin(Window)
		WinActivateBottom, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_WinClose:
		Win := SplitWin(Window)
		WinClose, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_WinHide:
		Win := SplitWin(Window)
		WinHide, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_WinKill:
		Win := SplitWin(Window)
		WinKill, % Win[1], % Win[2], % Win[3], % Win[4], % Win[5]
	return
	pb_WinMaximize:
		Win := SplitWin(Window)
		WinMaximize, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_WinMinimize:
		Win := SplitWin(Window)
		WinMinimize, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_WinMinimizeAll:
		WinMinimizeAll, %Window%
	return
	pb_WinMinimizeAllUndo:
		WinMinimizeAllUndo, %Window%
	return
	pb_WinMove:
		Win := SplitWin(Window)
		WinMove, % Win[1], % Win[2], %Par1%, %Par2%, %Par3%, %Par4%, % Win[3], % Win[4]
	return
	pb_WinRestore:
		Win := SplitWin(Window)
		WinRestore, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_WinSet:
		Win := SplitWin(Window)
		WinSet, %Par1%, %Par2%, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_WinShow:
		Win := SplitWin(Window)
		WinShow, % Win[1], % Win[2], % Win[3], % Win[4]
	return
	pb_WinSetTitle:
		Win := SplitWin(Window)
		WinSetTitle, % Win[1], % Win[2], % Win[3], % Win[4], % Win[5]
	return
	pb_WinWait:
		Try Menu, Tray, Icon, %ResDllPath%, 77
		ChangeProgBarColor("Blue", "OSCProg", 28)
	,	WaitFor.WinExist(SplitWin(Window), Step)
		Try Menu, Tray, Icon, %ResDllPath%, 46
		ChangeProgBarColor("20D000", "OSCProg", 28)
	return
	pb_WinWaitActive:
		Try Menu, Tray, Icon, %ResDllPath%, 77
		ChangeProgBarColor("Blue", "OSCProg", 28)
	,	WaitFor.WinActive(SplitWin(Window), Step)
		Try Menu, Tray, Icon, %ResDllPath%, 46
		ChangeProgBarColor("20D000", "OSCProg", 28)
	return
	pb_WinWaitNotActive:
		Try Menu, Tray, Icon, %ResDllPath%, 77
		ChangeProgBarColor("Blue", "OSCProg", 28)
	,	WaitFor.WinNotActive(SplitWin(Window), Step)
		Try Menu, Tray, Icon, %ResDllPath%, 46
		ChangeProgBarColor("20D000", "OSCProg", 28)
	return
	pb_WinWaitClose:
		Try Menu, Tray, Icon, %ResDllPath%, 77
		ChangeProgBarColor("Blue", "OSCProg", 28)
	,	WaitFor.WinClose(SplitWin(Window), Step)
		Try Menu, Tray, Icon, %ResDllPath%, 46
		ChangeProgBarColor("20D000", "OSCProg", 28)
	return
	pb_WinGet:
		Win := SplitWin(Window)
		WinGet, %Par1%, %Par2%, % Win[1], % Win[2], % Win[3], % Win[4]
		Try SavedVars(Par1,,, RunningFunction)
	return
	pb_WinGetTitle:
		Win := SplitWin(Window)
		WinGetTitle, %Step%, % Win[1], % Win[2], % Win[3], % Win[4]
		Try SavedVars(Step,,, RunningFunction)
	return
	pb_WinGetClass:
		Win := SplitWin(Window)
		WinGetClass, %Step%, % Win[1], % Win[2], % Win[3], % Win[4]
		Try SavedVars(Step,,, RunningFunction)
	return
	pb_WinGetText:
		Win := SplitWin(Window)
		WinGetText, %Step%, % Win[1], % Win[2], % Win[3], % Win[4]
		Try SavedVars(Step,,, RunningFunction)
	return
	pb_WinGetpos:
		Win := SplitWin(Window)
		WinGetPos, %Step%X, %Step%Y, %Step%W, %Step%H, % Win[1], % Win[2], % Win[3], % Win[4]
		CGPPars := "X|Y|W|H"
		Loop, Parse, CGPPars, |
		{
			CGP := Step . A_LoopField
			Try SavedVars(CGP,,, RunningFunction)
		}
	return
	pb_GroupAdd:
		GroupAdd, %Par1%, %Par2%, %Par3%, %Par4%, %Par5%, %Par6%
	return
	pb_GroupActivate:
		GroupActivate, %Par1%, %Par2%
	return
	pb_GroupDeactivate:
		GroupDeactivate, %Par1%, %Par2%
	return
	pb_GroupClose:
		GroupClose, %Par1%, %Par2%
	return

	TakeAction:
	TakeAction := DoAction(FoundX, FoundY, Act1, Act2, SearchResult)
	If (TakeAction = "Continue")
		TakeAction := 0
	Else If (TakeAction = "Stop")
		StopIt := 1
	Else If (TimesX = 1) && (TakeAction = "Break")
		BreakIt++
	Else If (TakeAction = "Prompt")
	{
		If (SearchResult = 0)
			MsgBox, 49, %d_Lang035%, %d_Lang036% %FoundX%x%FoundY%.`n%d_Lang038%
		Else
			MsgBox, 49, %d_Lang035%, %d_Lang037%`n%d_Lang038%
		IfMsgBox, Cancel
			StopIt := 1
	}
	Else If (TakeAction = "Play Sound")
	{
		If (SearchResult = 0)
			SoundBeep
		Else
			Loop, 2
				SoundBeep
	}
	CoordMode, Mouse, %CoordMouse%
	return

	;##### Playback COM Commands #####

	pb_SendEmail:
		StringSplit, Act, Action, :
		Action := SubStr(Action, StrLen(Act1) + 2)
		StringSplit, Tar, Target, /
		CDO_To := SubStr(Tar1, 4)
	,	CDO_Sub := Action
	,	CDO_Msg := SubStr(Step, 3)
	,	CDO_Html := SubStr(Step, 1, 1)
	,	CDO_Att := Window
	,	CDO_CC := SubStr(Tar2, 4)
	,	CDO_BCC := SubStr(Tar3, 5)
		
	,	User_Accounts := UserMailAccounts.Get(true)
		For _each, _Section in User_Accounts
		{
			If (Act1 = _Section.email)
			{
				SelAcc := _Section
				break
			}
		}
		If (!IsObject(SelAcc))
		{
			Throw Exception(d_Lang112,, Act1)
			return
		}
		
		CDO(SelAcc, CDO_To, CDO_Sub, CDO_Msg, CDO_Html, CDO_Att, CDO_CC, CDO_BCC)
	return
	
	pb_DownloadFiles:
		WinHttpDownloadToFile(Step, Action)
	return
	
	pb_Zip:
		Zip(Step, Action, Target)
	return
	
	pb_Unzip:
		Unzip(Step, Action, Target)
	return
	
	pb_IECOM_Set:
		StringSplit, Act, Action, :
		StringSplit, El, Target, :
		IeIntStr := IEComExp(Act2, Step, El1, El2, "", Act3, Act1)

		Try
			ie.readyState
		Catch
		{
			If (ComAc)
				ie := WBGet()
			Else
			{
				ie := ComObjCreate("InternetExplorer.Application")
			,	ie.Visible := true
			}
		}
		If (!IsObject(ie))
		{
			ie := ComObjCreate("InternetExplorer.Application")
		,	ie.Visible := true
		}
		
		Eval(IeIntStr, CustomVars)
		
		If (Window = "LoadWait")
		{
			Try Menu, Tray, Icon, %ResDllPath%, 77
			ChangeProgBarColor("Blue", "OSCProg", 28)
			Try
				IELoad(ie)
			Try Menu, Tray, Icon, %ResDllPath%, 46
			ChangeProgBarColor("20D000", "OSCProg", 28)
		}
	return

	pb_IECOM_Get:
		If (RegExMatch(Step, "^(\w+)(\[\S+\]|\.\w+)+", lMatch))
		{
			Try
				z_Check := VarSetCapacity(%lMatch1%)
			Catch
			{
				MsgBox, 16, %d_Lang007%, %d_Lang041%
				return
			}
		}
		Else
		{
			Try
				z_Check := VarSetCapacity(%Step%)
			Catch
			{
				MsgBox, 16, %d_Lang007%, %d_Lang041%
				return
			}
		}
		
		StringSplit, Act, Action, :
		StringSplit, El, Target, :
		IeIntStr := IEComExp(Act2, "", El1, El2, Step, Act3, Act1)
		
		Try
			ie.readyState
		Catch
		{
			If (ComAc)
				ie := WBGet()
			Else
			{
				ie := ComObjCreate("InternetExplorer.Application")
			,	ie.Visible := true
			}
		}
		If (!IsObject(ie))
		{
			ie := ComObjCreate("InternetExplorer.Application")
		,	ie.Visible := true
		}
		
		lResult := Eval(IeIntStr, CustomVars)[1]
	,	AssignVar(Step, ":=", lResult, CustomVars, RunningFunction)
		Try SavedVars(Step,,, RunningFunction)
		
		If (Window = "LoadWait")
		{
			Try Menu, Tray, Icon, %ResDllPath%, 77
			ChangeProgBarColor("Blue", "OSCProg", 28)
			Try
				IELoad(ie)
			Try Menu, Tray, Icon, %ResDllPath%, 46
			ChangeProgBarColor("20D000", "OSCProg", 28)
		}
	return

	pb_COMInterface:
		If (Target != "")
		{
			If (!IsObject(%Action%))
				%Action% := ComObjCreate(%Action%, Target)
		}
	pb_Expression:
		Step := StrReplace(Step, "`n", ",")
		
		Eval(Step, CustomVars)
		
		If (Window = "LoadWait")
		{
			Try Menu, Tray, Icon, %ResDllPath%, 77
			ChangeProgBarColor("Blue", "OSCProg", 28)
			Try
				IELoad(%Action%)
			Try Menu, Tray, Icon, %ResDllPath%, 46
			ChangeProgBarColor("20D000", "OSCProg", 28)
		}
	return
}

SplitStep(CustomVars, ByRef Step, ByRef TimesX, ByRef DelayX, ByRef Type, ByRef Target, ByRef Window)
{
	local Pars := [], LoopField, _Step, _key, _value
	If (Type = cType34)
		_Step := Step
	If (Type = cType39)
		Step := RegExReplace(Step, "\w+", "%$0%", "", 1)
	EscCom(true, Step, TimesX, DelayX, Target, Window)
,	Step := StrReplace(Step, "%A_Space%", "ⱥ")
	If (InStr(FileCmdList, Type "|"))
	{
		If (RegExMatch(Step, "sU)%\s([\w%]+)\((.*)\)"))
			EscCom(true, Step)
		_Step := ""
		Loop, Parse, Step, `,, %A_Space%
		{
			LoopField := A_LoopField
		,	CheckVars(CustomVars, LoopField)
		,	LoopField := StrReplace(LoopField, ",", _x)
		,	_Step .= LoopField ", "
		}
		Step := RTrim(_Step, ", ")
	}
	CheckVars(CustomVars, Step, TimesX, DelayX, Target, Window)
,	Step := StrReplace(Step, "``,", _x)
,	Step := StrReplace(Step, "``n", "`n")
,	Step := StrReplace(Step, "``r", "`r")
,	Step := StrReplace(Step, "``t", "`t")
	Loop, Parse, Step, `,, %A_Space%
	{
		LoopField := A_LoopField
	,	CheckVars(CustomVars, LoopField)
		If ((InStr(Type, "String") = 1) || (Type = "SplitPath"))
		{
			For _key, _value in CustomVars
				If (LoopField = _key)
					LoopField := _value
		}
		Pars[A_Index] := LoopField
,		Pars[A_Index] := StrReplace(Pars[A_Index], "``n", "`n")
,		Pars[A_Index] := StrReplace(Pars[A_Index], "``r", "`r")
,		Pars[A_Index] := StrReplace(Pars[A_Index], _x, ",")
,		Pars[A_Index] := StrReplace(Pars[A_Index], "ⱥ", A_Space)
,		Pars[A_Index] := StrReplace(Pars[A_Index], "``")
	}
	Step := StrReplace(Step, _x, ",")
,	Step := StrReplace(Step, "ⱥ", A_Space)
,	Step := StrReplace(Step, "``")
	If (Type = cType34)
		Step := _Step
	return Pars
}

IfEval(_Name, _Operator, _Value)
{
	If (_Operator = "=")
		result := (_Name = _Value) ? true : false
	Else If (_Operator = "==")
		result := (_Name == _Value) ? true : false
	Else If (_Operator = "!=")
		result := (_Name != _Value) ? true : false
	Else If (_Operator = ">")
		result := (_Name > _Value) ? true : false
	Else If (_Operator = "<")
		result := (_Name < _Value) ? true : false
	Else If (_Operator = ">=")
		result := (_Name >= _Value) ? true : false
	Else If (_Operator = "<=")
		result := (_Name <= _Value) ? true : false
	Else If (_Operator = "in")
	{
		If _Name in %_Value%
			result := true
		Else
			result := false
	}
	Else If (_Operator = "not in")
	{
		If _Name not in %_Value%
			result := true
		Else
			result := false
	}
	Else If (_Operator = "contains")
	{
		If _Name contains %_Value%
			result := true
		Else
			result := false
	}
	Else If (_Operator = "not contains")
	{
		If _Name not contains %_Value%
			result := true
		Else
			result := false
	}
	Else If (_Operator = "between")
	{
		_Val1 := "", _Val2 := ""
		StringSplit, _Val, _Value, `n, %A_Space%%A_Tab%
		If _Name between %_Val1% and %_Val2%
			result := true
		Else
			result := false
	}
	Else If (_Operator = "not between")
	{
		_Val1 := "", _Val2 := ""
		StringSplit, _Val, _Value, `n, %A_Space%%A_Tab%
		If _Name not between %_Val1% and %_Val2%
			result := true
		Else
			result := false
	}
	Else If (_Operator = "is")
	{
		If _Name is %_Value%
			result := true
		Else
			result := false
	}
	Else If (_Operator = "is not")
	{
		If _Name is not %_Value%
			result := true
		Else
			result := false
	}
	return result
}

DoAction(X, Y, Action1, Action2, Error)
{
	If (Error = 0)
	{
		If (Action1 = "Move")
		{
			Click, %X%, %Y%, 0
			return ""
		}
		If (InStr(Action1, "Click"))
		{
			Loop, Parse, Action1, %A_Space%
				Act%A_Index% := A_LoopField
			Click, %X%, %Y% %Act1%, 1
			return ""
		}
		Else
			return Action1
	}
	If (Error = 1 || Error = 2)
		return Action2
}

RunExtFunc(File, FuncName, Params*)
{
	TempFile := A_Temp "\TempFile.ahk"
	For _key, _value in Params
		Pars .= """" _value """, "
	Pars := RTrim(Pars, " ,")
	SplitPath, File,, WorkDir
	
	TempScript =
	(LTrim
		#NoEnv
		SetWorkingDir %WorkDir%
		OutVar := %FuncName%(%Pars%)
		FileAppend, `%OutVar`%, `%A_ScriptFullPath`%, UTF-8
		ExitApp
		#SingleInstance, Force
		#NoTrayIcon
		#Include %File%
		
	)
	
	FileDelete, %TempFile%
	FileAppend, %TempScript%, %TempFile%, UTF-8
	RunWait, %TempFile%
	Loop, Read, %TempFile%
	{
		If (A_Index < 9)
			continue
		Result .= A_LoopReadLine "`n"
	}
	FileDelete, %TempFile%
	return SubStr(Result, 1, -1)
}

IfStatement(ThisError, CustomVars, Action, Step, TimesX, DelayX, Type, Target, Window, BreakIt, SkipIt)
{
	local Pars, VarName, Oper, VarValue, lMatch
	
	If (Step = "EndIf")
		return ThisError < 1 ? 0 : --ThisError
	If ((BreakIt > 0) || (SkipIt > 0))
		return ThisError
	If (Action = "[Else]")
	{
		If (ThisError = 1)
			return 0
		If (ThisError = 0)
			return 1
	}
	If (InStr(Action, "[ElseIf]"))
	{
		If ((ThisError = 0) || (ThisError = -1))
			return -1
		If (ThisError = 1)
			ThisError := 0
		Action := SubStr(Action, 10)
	}
	If (ThisError > 0)
		return ++ThisError
	If (ThisError = -1)
		return -1
	Tooltip
	CheckVars(CustomVars, Step, Target, Window)
,	EscCom(true, Step, TimesX, DelayX, Target, Window)
,	Step := StrReplace(Step, _z, A_Space)
,	Target := StrReplace(Target, _z, A_Space)
,	Window := StrReplace(Window, _z, A_Space)
	If (Action = If1)
	{
		IfWinActive, %Step%
			return 0
	}
	Else If (Action = If2)
	{
		IfWinNotActive, %Step%
			return 0
	}
	Else If (Action = If3)
	{
		IfWinExist, %Step%
			return 0
	}
	Else If (Action = If4)
	{
		IfWinNotExist, %Step%
			return 0
	}
	Else If (Action = If5)
	{
		IfExist, %Step%
			return 0
	}
	Else If (Action = If6)
	{
		IfNotExist, %Step%
			return 0
	}
	Else If (Action = If7)
	{
		ClipContents := Clipboard
		If (ClipContents = Step)
			return 0
	}
	Else If (Action = If8)
	{
		If (CustomVars["A_Index"] = Step)
			return 0
	}
	Else If (Action = If9)
	{
		If (SearchResult = 0)
			return 0
	}
	Else If (Action = If10)
	{
		If (SearchResult != 0)
			return 0
	}
	Else If (Action = If11)
	{
		Pars := SplitStep(CustomVars, Step, TimesX, DelayX, Type, Target, Window)
	,	VarName := Pars[1], VarName := %VarName%
		For _key, _value in CustomVars
			If (Pars[1] = _key)
				VarName := _value
		If (InStr(VarName, Pars[2]))
			return 0
	}
	Else If (Action = If12)
	{
		Pars := SplitStep(CustomVars, Step, TimesX, DelayX, Type, Target, Window)
	,	VarName := Pars[1], VarName := %VarName%
		For _key, _value in CustomVars
			If (Pars[1] = _key)
				VarName := _value
		If (!InStr(VarName, Pars[2]))
			return 0
	}
	Else If (Action = If13)
	{
		IfMsgBox, %Step%
			return 0
	}
	Else If (Action = If14)
	{
		CompareParse(Step, VarName, Oper, VarValue)
	,	CheckVars(CustomVars, VarName, VarValue)
	,	EscCom(true, VarValue)
		If (CustomVars.HasKey(VarName))
			VarName := CustomVars[VarName]
		Else
			VarName := %VarName%
		VarValue := StrReplace(VarValue, "``n", "`n")
		If (IfEval(VarName, Oper, VarValue))
			return 0
	}
	Else If (Action = If15)
	{
		EvalResult := Eval(Step, CustomVars)
		If (EvalResult[1])
			return 0
	}
	return 1
}

class WaitFor
{
	Key(Key, Delay := 0)
	{
		global StopIt, d_Lang039
		
		Loop
		{
			KeyWait, %Key%
			KeyWait, %Key%, % (Delay > 0) ? "D T" Delay : "D T0.5"
			Sleep, 10
		}
		Until ((ErrorLevel = 0)
		|| ((ErrorLevel = 1) && Delay > 0)
		|| (StopIt))
		If (StopIt = 1)
			return
		If (ErrorLevel)
		{
			MsgBox %d_Lang039%
			StopIt := 1
			return
		}
	}
	
	WinExist(Window, Seconds)
	{
		global StopIt
		
		Seconds *= 1000
		ini_Time := A_TickCount
		Loop
		{
			pass_time := A_TickCount - ini_Time
			Sleep, 10
		}
		Until (((WinExist(Window*)) || (StopIt))
			|| ((Seconds > 0) && (pass_Time > Seconds)))
	}
	
	WinActive(Window, Seconds)
	{
		global StopIt
		
		Seconds *= 1000
		ini_Time := A_TickCount
		Loop
		{
			pass_Time := A_TickCount - ini_Time
			Sleep, 10
		}
		Until (((WinActive(Window*)) || (StopIt))
			|| ((Seconds > 0) && (pass_Time > Seconds)))
	}
	
	WinNotActive(Window, Seconds)
	{
		global StopIt
		
		Seconds *= 1000
		ini_Time := A_TickCount
		Loop
		{
			pass_Time := A_TickCount - ini_Time
			Sleep, 10
		}
		Until (((!WinActive(Window*)) || (StopIt))
			|| ((Seconds > 0) && (pass_Time > Seconds)))
	}
	
	WinClose(Window, Seconds)
	{
		global StopIt
		
		Seconds *= 1000
		ini_Time := A_TickCount
		Loop
		{
			pass_Time := A_TickCount - ini_Time
			Sleep, 10
		}
		Until (((!WinExist(Window*)) || (StopIt))
			|| ((Seconds > 0) && (pass_Time > Seconds)))
	}
	
}

SplitWin(Window)
{
	Static _x := Chr(2), _y := Chr(3), _z := Chr(4)
	
	WinPars := []
	Window := StrReplace(Window, "``,", _x)
	Loop, Parse, Window, `,, %A_Space%
	{
		LoopField := StrReplace(A_LoopField, _x, ",")
		WinPars.Push(LoopField)
	}
	return WinPars
}

AssignVar(_Name, _Operator, _Value, CustomVars, RunningFunction)
{
	local _content, _ObjItems
	
	If (_Name == "_null")
		return
	
	If (!IsObject(_Value))
	{
		_Value := StrReplace(_Value, _z, A_Space)
		If (_Name = "Clipboard")
			_Value := StrReplace(_Value, "````,", ",")
		If (InStr(_Value, "!") = 1)
			_Value := !SubStr(_Value, 2)
	}
	
	Try _content := %_Name%
	
	While (RegExMatch(_Name, "(\w+)(\[\S+\]|\.\w+)+", lFound))
	{
		If (RegExMatch(lFound1, "^-?\d+$"))
			break
		_content := ParseObjects(_Name, CustomVars, _ObjItems)
	,	_Name := lFound1
	}
	
	If (_Operator = ":=")
		_content := _Value
	Else If (_Operator = "+=")
		_content += _Value
	Else If (_Operator = "-=")
		_content -= _Value
	Else If (_Operator = "*=")
		_content *= _Value
	Else If (_Operator = "/=")
		_content /= _Value
	Else If (_Operator = "//=")
		_content //= _Value
	Else If (_Operator = ".=")
		_content .= _Value
	Else If (_Operator = "|=")
		_content |= _Value
	Else If (_Operator = "&=")
		_content &= _Value
	Else If (_Operator = "^=")
		_content ^= _Value
	Else If (_Operator = ">>=")
		_content >>= _Value
	Else If (_Operator = "<<=")
		_content <<= _Value

	Try
	{
		If (IsObject(_ObjItems))
		{
			%_Name%[_ObjItems*] := _content
		}
		Else
			%_Name% := _content
	}
	
	Try SavedVars(_Name,,, RunningFunction)
}

CheckVars(CustomVars, ByRef CheckVar1 := "", ByRef CheckVar2 := "", ByRef CheckVar3 := "", ByRef CheckVar4 := "", ByRef CheckVar5 := "")
{
	Loop, 5
	{
		If (!IsByRef(CheckVar%A_Index%))
			continue
		_i := A_Index
		For _key, _value in CustomVars
		{
			While (RegExMatch(CheckVar%_i%, "i)%" _key "%", lMatch))
				CheckVar%_i% := RegExReplace(CheckVar%_i%, "U)" lMatch, _value)
		}
		CheckVar%_i% := DerefVars(CheckVar%_i%)
		
		If (RegExMatch(CheckVar%_i%, "sU)^%\s+(.+)$", lMatch))  ; Expressions
			EvalResult := Eval(lMatch1, CustomVars), CheckVar%_i% := EvalResult[1]
	}
}

DerefVars(v_String)
{
	global
	
	v_String := StrReplace(v_String, "%A_Space%", "%_z%")
	v_String := StrReplace(v_String, "``%", _y)
	While (RegExMatch(v_String, "%(\w+)%", rMatch))
	{
		FoundVar := StrReplace(%rMatch1%, "%", _y)
	,	FoundVar := StrReplace(FoundVar, ",", "``,")
	,	v_String := StrReplace(v_String, rMatch, FoundVar)
	}
	return StrReplace(v_String, _y, "%")
}

ExprGetPars(Expr)
{
	Expr := RegExReplace(Expr, "\[.*?\]", "[A]")
,	Expr := RegExReplace(Expr, "\(([^()]++|(?R))*\)", "[P]")
,	Expr := RegExReplace(Expr, """.*?""", "[T]")
,	ExprPars := StrSplit(Expr, ",", A_Space)
	return ExprPars
}
