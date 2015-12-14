OPTION EXPLICIT
'STATS GATHERING----------------------------------------------------------------------------------------------------
name_of_script = "NOTES - EDRS disqualification match found.vbs"
start_time = timer

'Variables to be DIMMED for FUNC LIB when testing with Option explicit
DIM name_of_script, start_time, FuncLib_URL, run_locally, default_directory, beta_agency, req, fso, row

'LOADING FUNCTIONS LIBRARY FROM GITHUB REPOSITORY===========================================================================
IF IsEmpty(FuncLib_URL) = TRUE THEN	'Shouldn't load FuncLib if it already loaded once
	IF run_locally = FALSE or run_locally = "" THEN		'If the scripts are set to run locally, it skips this and uses an FSO below.
		IF default_directory = "C:\DHS-MAXIS-Scripts\Script Files\" THEN			'If the default_directory is C:\DHS-MAXIS-Scripts\Script Files, you're probably a scriptwriter and should use the master branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/master/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		ELSEIF beta_agency = "" or beta_agency = True then							'If you're a beta agency, you should probably use the beta branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/BETA/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		Else																		'Everyone else should use the release branch.
			FuncLib_URL = "https://raw.githubusercontent.com/MN-Script-Team/BZS-FuncLib/RELEASE/MASTER%20FUNCTIONS%20LIBRARY.vbs"
		End if
		SET req = CreateObject("Msxml2.XMLHttp.6.0")				'Creates an object to get a FuncLib_URL
		req.open "GET", FuncLib_URL, FALSE							'Attempts to open the FuncLib_URL
		req.send													'Sends request
		IF req.Status = 200 THEN									'200 means great success
			Set fso = CreateObject("Scripting.FileSystemObject")	'Creates an FSO
			Execute req.responseText								'Executes the script code
		ELSE														'Error message, tells user to try to reach github.com, otherwise instructs to contact Veronica with details (and stops script).
			MsgBox 	"Something has gone wrong. The code stored on GitHub was not able to be reached." & vbCr &_
					vbCr & _
					"Before contacting Veronica Cary, please check to make sure you can load the main page at www.GitHub.com." & vbCr &_
					vbCr & _
					"If you can reach GitHub.com, but this script still does not work, ask an alpha user to contact Veronica Cary and provide the following information:" & vbCr &_
					vbTab & "- The name of the script you are running." & vbCr &_
					vbTab & "- Whether or not the script is ""erroring out"" for any other users." & vbCr &_
					vbTab & "- The name and email for an employee from your IT department," & vbCr & _
					vbTab & vbTab & "responsible for network issues." & vbCr &_
					vbTab & "- The URL indicated below (a screenshot should suffice)." & vbCr &_
					vbCr & _
					"Veronica will work with your IT department to try and solve this issue, if needed." & vbCr &_
					vbCr &_
					"URL: " & FuncLib_URL
					script_end_procedure("Script ended due to error connecting to GitHub.")
		END IF
	ELSE
		FuncLib_URL = "C:\BZS-FuncLib\MASTER FUNCTIONS LIBRARY.vbs"
		Set run_another_script_fso = CreateObject("Scripting.FileSystemObject")
		Set fso_command = run_another_script_fso.OpenTextFile(FuncLib_URL)
		text_from_the_other_script = fso_command.ReadAll
		fso_command.Close
		Execute text_from_the_other_script
	END IF
END IF
'END FUNCTIONS LIBRARY BLOCK================================================================================================

'DECLARING VARIABLES
DIM case_number_dialog, case_number, edrs_disq_dialog, member_name, edrs_status, worker_signature, edrs_disq_dialog, contact_info, DISQ_state
DIM contact_date, contact_time, DISQ_reason, DISQ_begin, DISQ_end, DISQ_confirmation, IPV_requested, STAT_DISQ, IPV_TIKL

'DIALOG-------------------------------------------------------------------
BeginDialog edrs_disq_dialog, 0, 0, 286, 210, "eDRS DISQ dialog"
  EditBox 110, 15, 165, 15, contact_info
  EditBox 45, 35, 25, 15, DISQ_state
  EditBox 120, 35, 50, 15, contact_date
  EditBox 225, 35, 50, 15, contact_time
  EditBox 65, 55, 210, 15, DISQ_reason
  EditBox 65, 75, 50, 15, DISQ_begin
  EditBox 225, 75, 50, 15, DISQ_end
  CheckBox 5, 100, 255, 10, "Verbal confirmation of DISQ rec'd from DISQ state. SNAP will not be issued.", DISQ_confirmation
  CheckBox 5, 115, 265, 10, "IPV (Intentional Program Violation) documentation requested from DISQ state.", IPV_requested
  CheckBox 5, 135, 155, 10, "STAT/DISQ panel has been added/updated.", STAT_DISQ
  CheckBox 5, 150, 120, 10, "Set 20 day TIKL for return of IPV.", IPV_TIKL
  ButtonGroup ButtonPressed
    OkButton 170, 140, 50, 15
    CancelButton 225, 140, 50, 15
  Text 5, 20, 105, 10, "Name/phone of contact person:"
  Text 5, 40, 40, 10, "DISQ state:"
  Text 75, 40, 45, 10, "Contact date:"
  Text 5, 80, 60, 10, "DISQ begin date: "
  Text 175, 40, 45, 10, "Contact time:"
  Text 5, 60, 60, 10, "Reason for DISQ:"
  Text 125, 80, 100, 10, "DISQ end date (if applicable):"
  GroupBox 0, 5, 280, 125, "Details of contact with DISQ state:"
  Text 10, 185, 255, 10, "See POLI/TEMP TE02.08.127 for procedural instructions."
  GroupBox 0, 170, 280, 35, "Questions about processing eDRS matches?"
EndDialog

'THE SCRIPT------------------------------------------------------------------------------------------
'Connecting to BlueZone & finding case number
EMConnect ""
call MAXIS_case_number_finder(case_number)

'custom functions grabbing HH member information/makes HH member information available in droplist
Call HH_member_custom_dialog(HH_member_array)

'updates the contact_date & contact_time variables to show the current date & time
contact_date = date
contact_time = time

'edrs status dialog
Do
	err_msg = ""
	dialog edrs_status_dialog
  If case_number = "" or IsNumeric(case_number) = FALSE THEN Msgbox "You must enter a case number."
Loop until err_msg = ""


'checking for active MAXIS session
Call check_for_MAXIS(False)

'TIKL for return of IPV if option is selected by user
If IPV_TIKL = 1 then
	call navigate_to_MAXIS_screen("dail", "writ")
	call create_MAXIS_friendly_date(contact_date, 20, 5, 18)
	EMSetCursor 9, 3
	Call write_variable_in_TIKL("Has IPV from (DISQ_state) been rec'd?  If not, contact (DISQ_state) contact again and case note. Refer to TE02.08.127 for procedural information.")
	transmit
	PF3
End if


'Case noting & navigating to a new case note
Call start_a_blank_CASE_NOTE
EMSendKey "***eDRS completed--match found***" & "<newline>"
EMSendKey "    HH MEMB         eDRS status" & "<newline>"
If DISQ_confirmation = 1 then call write_variable_in_CASE_NOTE("Verbal confirmation of DISQ rec'd from DISQ state. SNAP will not be issued.")
IF IPV_requested = 1 then call write_variable_in_CASE_NOTE("IPV (Intentional Program Violation) documentation requested from DISQ state.")
IF STAT_DISQ = 1 then Call write_variable_in_CASE_NOTE("STAT/DISQ panel has been added/updated.")
IF IPV_TIKL = 1 then Call write_variable_in_CASE_NOTE("A TIKL has been set for 20 days for the return of IPV.")


call write_variable_in_CASE_NOTE("---")
Call write_variable_in_CASE_NOTE(worker_signature)
	script_end_procedure("Since a match was found several steps need to be taken." & vbNewLine & vbNewLine _
	"1. Approve SNAP benefits for other eligible SNAP unit members." & vbNewLine & _
	"2. Determine if overpayments for the time period that benefits were paid & disqualified from the SNAP programs." & vbNewLine & _
	"3. Check Question 1 in the ""Penalty warnings and qualifications questions"" section of all CAFs the client has completed since the disqualification began." & vbNewLine & _
	"4. Consider making a fraud referral if the client received food support SNAP or MFIP benefits in Minnesota while disqualified in another state." & vbNewLine & vbNewLine & _
	"NOTE: If the case has been closed, these steps still need to be completed so the client will not receive any benefits they are not eligible for in the future. If you are" _
	"unable to update the STAT/DISQ panel because the case has been closed, submit a PF11 with the disqualification screen information and the HelpDesk will enter the information.")
