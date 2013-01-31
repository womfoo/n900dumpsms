# n900dumpsms: Exports N900 SMS to XML
Command line tool for exporting your N900 SMS to XML.
The output can then be later imported to Android with the [SMS Backup and Restore App](https://play.google.com/store/apps/details?id=com.riteshsahu.SMSBackupRestore).

## How to get the el-v1.db SMS database:
* copy /home/user/.rtcom-eventlogger/el-v1.db from the device itself OR

* use a copy from the native backup app
    * extract /path-to-backup-folder/comm_and_cal.zip
    * extract Root/home/user/.rtcom-eventlogger/backup.tgz from comm_and_cal.zip
    * the file el-v1.db should be extracted

## Usage:
`n900dumpsms /path-to-extracted-file/el-v1.db`

SMSs will be saved to an output.xml file in the current directory

## TODO:
* research/implement sms service center
* directly import from comm_and_cal.zip
* or scp the db from the phone
