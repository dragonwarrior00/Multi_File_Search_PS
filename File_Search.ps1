<#
.SYNOPSIS
    Perform a syntax search within the same directory as the PowerShell script
.DESCRIPTION
    This will perform a syntax search and highlight the syntax within files in the same directory as the PowerShell script and sub-folders of the same directory. Not only a single word but full sentencing and special characters
    are searchable. The script also includes the ability to have line numbers appear and to word wrap search results. The script will also display the full path of the selected file, which is selectable. Additionally,
    pressing the Enter key or clicking the Submit button will perform the search. The Clear button will only clear search syntax and search results.
.NOTES
    Original author: Brien Posey
    Original script URL: https://www.itprotoday.com/powershell/how-i-built-my-own-powershell-multi-file-search-tool

    Modify author: Josh Lamberth

    Update (11/15/2024) - The following changes have been added:
        - Format of text including wording, size, and font style
        - Features relocation, size, and color
        - Non-adjustable form border style
        - Added read-only textbox to display the directory path of the selected file to allow a selectable path
        - Hidden left panel when not searching
        - Hidden right panel when not searching
        - Dynamic left panel display. That will be scrollable when hitting the max height of the form. No search result will display one item size blank result
        - Dynamic right panel display when a file is selected from the search result. The panel size will adjust based on the selected file content
        - Added a check option to display line numbers. If a search file is already selected, will re-select the file to display line numbers
        - Added a check option to word wrap the right panel. If a search file is already selected, will re-select the file to display results word-wrapped
        - Added a Clear button to clear search and reset left and right panels
        - Added the ability to use the Enter key to perform a search
        - Removed notification audio when the Enter key is used to perform a search
        - Set the default search directory as the same as the script directory
        - Trim start and end whitespace of searching syntax
        - Added ability to exclude file types (ie. exe, msi, etc..)
        - Dynamic set X location of Clear button, Exit button, Word Wrap checkbox, and Line Numbers checkbox
        - Set the minimal height of the left panel to be one item
        - Set the max size of the left panel to be set listbox width and dynamic form height
        - Set the max size of the right panel to be dynamic of listbox width and form height
        - Removed -RAW syntax from Get-Content and added -Join syntax

.LINK

.EXAMPLE

#>



Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Function Clear-Results {
    #Clear any results from previous searches and reset to default height
    [Void] $FileListBox.Items.Clear()
    $FileListBox.Visible = $false
    $FileListBox.Height = $ListBoxHeight
    $FileContentsTextBox.Text = ""
    $FileContentsTextBox.Visible = $false
    $FilePathTextBox.Text = ""
}

Function Get-FileContent {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]$SelectItem
    )

    IF ($LineNumberCheckbox.Checked){
        (Get-Content -Path $SelectItem | ForEach-Object {"{0,3} | {1,3}" -f ($_.ReadCount),$_}) -join [System.Environment]::NewLine
    } ELSE {
        (Get-Content -Path $SelectItem) -join [System.Environment]::NewLine
    }
}

Function Get-SelectedItem {

    If ($null -ne $FileListBox.SelectedItem){
        $FileContentsTextBox.Visible = $false

        # Re-select the left panel selected file and re-display content on the right panel
        $SelectedIndex = $FileListBox.SelectedIndex
        $FileListbox.SelectedIndex = "-1"
        $FileListBox.SelectedIndex = $SelectedIndex
    }
}

# Create a form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Multi-File Search Tool"
$Form.Width = 1065
$Form.Height = 880
$Form.FormBorderStyle = 'FixedDialog'

# $InputLabel

# Create the label to display instructions
$InputLabel = New-Object Windows.Forms.Label
$InputLabel.Text = "Enter the syntax to search for within directory"
$InputLabel.Font = New-Object Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Bold)
$InputLabel.AutoSize = $true
$InputLabel.Location = New-Object Drawing.Point(5, 30)
$InputLabel.ForeColor = [System.Drawing.Color]::Black

# Create the label to display instructions
$ResultsLabel = New-Object Windows.Forms.Label
$ResultsLabel.Text = "Files Containing Search Syntax"
$ResultsLabel.Font = New-Object Drawing.Font("Arial", 16, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold -bor [System.Drawing.FontStyle]::Underline))
$ResultsLabel.AutoSize = $true
$ResultsLabel.Location = New-Object Drawing.Point(10, 240)
$ResultsLabel.ForeColor = [System.Drawing.Color]::Black

# Create the label to display instructions
$FileContentsLabel = New-Object Windows.Forms.Label
$FileContentsLabel.Text = "Selected File's Contents"
$FileContentsLabel.Font = New-Object Drawing.Font("Arial", 16, [System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold -bor [System.Drawing.FontStyle]::Underline))
$FileContentsLabel.AutoSize = $true
$FileContentsLabel.Location = New-Object Drawing.Point(345, 240)
$FileContentsLabel.ForeColor = [System.Drawing.Color]::Black

# Create the label to display the full path
$FilePathLabel = New-Object Windows.Forms.Label
$FilePathLabel.Text = "File Directory Path:"
$FilePathLabel.Font = New-Object System.Drawing.Font('Arial',14,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Italic -bor [System.Drawing.FontStyle]::Underline))
$FilePathLabel.Location = New-Object Drawing.Point(10, 140)
$FilePathLabel.AutoSize = $true
$FilePathLabel.ForeColor = [System.Drawing.Color]::Black

# $InputBox
$InputBox = New-Object System.Windows.Forms.textbox
#$InputBox.Text = "This is where the query goes"
#$InputBox.Multiline = $true
$InputBox.Size = New-Object System.Drawing.Size(500,30)
$InputBox.Location = New-object System.Drawing.Size(10,70)
$InputBox.Font = New-Object System.Drawing.Font("Arial", 14)
$InputBox.Add_KeyDown([System.Windows.Forms.KeyEventHandler]{
    IF ($InputBox.Text -ne ""){
        # Check if Enter key is pressed and suppress key press sound
        IF ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
            $SubmitButton.PerformClick()
            $_.SuppressKeyPress = $true
        }
    }
})

# $SubmitButton
$SubmitButton = New-Object System.Windows.Forms.Button
$SubmitButton.Location = New-Object System.Drawing.Size (525,70)
$SubmitButton.Size = New-Object System.Drawing.Size(100,30)
$SubmitButton.Font=New-Object System.Drawing.Font("Arial", 14)
$SubmitButton.BackColor = "LightBlue"
$SubmitButton.Text = "Submit"
$SubmitButton.Add_Click({

            Clear-Results
            $FileListBox.Visible = $true

            $UserInputText = $InputBox.Text
            $SearchPath = $PSScriptRoot

            # Trim any search text leading and trailing whitespace
            $Global:UserInput = $UserInputText.TrimStart("").TrimEnd("")

            # Escape any special characters in the user input to avoid issues
            $SafeInput = [Regex]::Escape($userInput)


            IF ($SafeInput -ne ""){

                # Exclude file types from search results (ie. app installing files)
                $ExcludeFileTypes = @("*.exe", "*.msi", "*.pdb", "*.dll")

                # Get a list of all files and their path
                $Files = Get-ChildItem -Path $SearchPath -Recurse -Exclude $ExcludeFileTypes | Where-Object { -not $_.PSIsContainer } | Select-Object -ExpandProperty FullName
                    ForEach ($File in $Files){
                        If (Select-String -Path $File -Pattern $SafeInput)
                        {
                            [void] $FileListBox.Items.Add($File)
                        }
                    }
            }
        })

# $ExitButton
$ExitButton = New-Object System.Windows.Forms.Button
$ExitButton.Location = New-Object System.Drawing.Size ($($Form.Width - $ExitButton.Size.Width - 50),70)
$ExitButton.Size = New-Object System.Drawing.Size(100,30)
$ExitButton.Font= New-Object System.Drawing.Font("Arial", 14)
$ExitButton.BackColor = "LightGray"
$ExitButton.Text = "Exit"
$ExitButton.Add_Click({
            $Form.Close()
        })

# $ClearButton
$ClearButton = New-Object System.Windows.Forms.Button
$ClearButton.Location = New-Object System.Drawing.Size ($($Form.Width - $ExitButton.Size.Width - $ClearButton.Size.Width - 50),70)
$ClearButton.Size = New-Object System.Drawing.Size(100,30)
$ClearButton.Font=New-Object System.Drawing.Font("Arial", 14)
$ClearButton.BackColor = "LightYellow"
$ClearButton.Text = "Clear"
$ClearButton.Add_Click({
            $InputBox.Text = ""
            Clear-Results
        })

# WordWrap checkbox
$WordWrapCheckbox = New-Object System.Windows.Forms.CheckBox
$WordWrapCheckbox.Size = New-Object System.Drawing.Size(120,30)
$WordWrapCheckbox.Location = New-Object System.Drawing.Point($($Form.Width - $WordWrapCheckbox.Size.Width - 10),240)
$WordWrapCheckbox.Font=New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$WordWrapCheckbox.Text = "Word Wrap"
$WordWrapCheckbox.Add_CheckStateChanged({
    $FileContentsTextBox.Text = ""
    $FileContentsTextBox.WordWrap = $WordWrapCheckbox.Checked
    Get-SelectedItem
})

# LineNumber checkbox
$LineNumberCheckbox = New-Object System.Windows.Forms.CheckBox
$LineNumberCheckbox.Size = New-Object System.Drawing.Size(135,30)
$LineNumberCheckbox.Location = New-Object System.Drawing.Point($($Form.Width - $LineNumberCheckbox.Size.Width - $WordWrapCheckbox.Size.Width - 10),240)
$LineNumberCheckbox.Font=New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$LineNumberCheckbox.Text = "Line Numbers"
$LineNumberCheckbox.Add_CheckStateChanged({
    $FileContentsTextBox.Text = ""
    Get-SelectedItem
})

# Create the left panel
$VisibleItems = 1
$ListBoxHeight = $VisibleItems * 28

$FileListBox = New-Object System.Windows.Forms.ListBox
$FileListBox.Location = New-Object System.Drawing.Point(10,270)
$FileListBox.Size = New-Object System.Drawing.Size (325, $ListBoxHeight)
$FileListBox.Font = New-Object System.Drawing.Font("Arial", 16)
$FileListBox.MaximumSize = New-Object System.Drawing.Size ($($FileListBox.Size.Width) , $($Form.Height - $FileListBox.Location.Y - 40))
$FileListBox.Visible = $false

# Auto adjust left panel list box size based on searched file result
$FileListBox.Add_ClientSizeChanged({
    $newHeight = $FileListBox.GetPreferredSize($FileListBox.Size).Height
    $FileListBox.Height = $newHeight
})

# Add an event handler to respond to item selection
$FileListbox.Add_SelectedIndexChanged({
    If ($FileListbox.SelectedIndex -ne "-1"){
        $SelectedItem = $FileListbox.SelectedItem
        $FileContents = Get-FileContent -SelectItem $SelectedItem
        $FileContentsTextBox.Text = $FileContents
        $FilePathTextBox.Text = $SelectedItem

        $WordToHighlight = $UserInput
        $Index = 0

        # Loop to find and highlight all instances of the word
        while (($Index = $FileContentsTextBox.Find($WordToHighlight, $Index, [System.Windows.Forms.RichTextBoxFinds]::None)) -ge 0) {
            # Select the word
            $FileContentsTextBox.Select($Index, $WordToHighlight.Length)

            # Apply the Highlight (yellow background)
            $FileContentsTextBox.SelectionBackColor = [System.Drawing.Color]::Yellow

            # Move the StartIndex forward for the next search
            $Index += $WordToHighlight.Length
        }
    }
})


# Create the right panel
$FileContentsTextBox = New-Object System.Windows.Forms.RichTextBox
$FileContentsTextBox.Multiline = $True
$FileContentsTextBox.Location = new-object System.Drawing.Size(345,270)
$FileContentsTextBox.Font= New-Object System.Drawing.Font("Arial", 16)
$FileContentsTextBox.Scrollbars = [System.Windows.Forms.ScrollBars]::Both
$FileContentsTextBox.Visible = $false
$FileContentsTextBox.WordWrap = $false
$FileContentsTextBox.MaximumSize = New-Object System.Drawing.Size ($($Form.Width - $FileListBox.Width - 45), $($Form.Height - $FileListBox.Location.Y - 43))

# Auto adjust right panel text box size based on selected file info
$FileContentsTextBox.Add_ContentsResized({
    $FileContentsTextBox.Visible = $true
    $newHeight = $FileContentsTextBox.GetPreferredSize($FileContentsTextBox.Size).Height
    $FileContentsTextBox.Height = $newHeight
    $newWidth = $FileContentsTextBox.GetPreferredSize($FileContentsTextBox.Size).Width
    $FileContentsTextBox.Width = $newWidth
})

# Display the selected file's full directory path
$FilePathTextBox = New-Object System.Windows.Forms.TextBox
$FilePathTextBox.Font = New-Object Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Italic)
$FilePathTextBox.ReadOnly = $true
$FilePathTextBox.BorderStyle = "None"
$FilePathTextBox.BackColor = $form.BackColor
$FilePathTextBox.Location = New-Object Drawing.Point(10, 170)
$FilePathTextBox.ForeColor = [System.Drawing.Color]::Black
$FilePathTextBox.Multiline = $true
$FilePathTextBox.Size = "$($Form.Width - 30),70"


# Add panels to the form
$Form.Controls.Add($InputLabel)
$Form.Controls.Add($ResultsLabel)
$Form.Controls.Add($FileContentsLabel)
$Form.Controls.Add($InputBox)
$Form.Controls.Add($SubmitButton)
$Form.Controls.Add($ClearButton)
$Form.Controls.Add($ExitButton)
$Form.Controls.Add($FileListBox)
$Form.Controls.Add($FileContentsTextBox)
$Form.Controls.Add($FilePathLabel)
$Form.Controls.Add($FilePathTextBox)
$Form.Controls.Add($LineNumberCheckbox)
$Form.Controls.Add($WordWrapCheckbox)


# Show the form
$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()
