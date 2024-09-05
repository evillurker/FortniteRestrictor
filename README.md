Forrnite Restrictor is a simple application which restricts your child from excessively playing that game non stop.

Usage:
- Initial password is "admin"
- After running the program, you can set the hours in this format: HH:MM-HH:MM, HH:MM-HH:MM
- Starting hour must be lower than ending hour with the exception of 00:00 (For example, 19:00-00:00 is allowed, but keep in mind that 00:00 is already the next day)
- The Create Shortcut button will create a startup shortcut which will run the program silently when your pc starts.
- You can delete this shortcut by pressing that button again. The startup folder will appear and you will then be able to delete it.
- Pressing CTRL+ALT+O will run the control panel again, asking for your password, if you want to make changes.

If your child already knows how to close tasks in Windows Task Manager, you can restrict that by doing the following on his user:

Open Group Policy Editor:

    Press Win + R to open the Run dialog.
    Type gpedit.msc and press Enter.

Navigate to Task Manager Settings:

    Go to User Configuration -> Administrative Templates -> System -> Ctrl+Alt+Del Options.

Disable Task Manager:

    Find the setting Remove Task Manager and double-click on it.
    Set it to Enabled to disable access to the Task Manager.

Apply the Changes:

    Click Apply, then OK.
    The changes should take effect immediately, or you may need to restart the computer.
