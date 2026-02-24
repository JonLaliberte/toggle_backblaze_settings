# Backblaze Settings Toggle

A bash script for macOS that allows you to quickly toggle Backblaze backup settings between **manual** (only when clicking "Backup Now") and **continuous** backup modes via the command line. Unlike the Backblaze settings UI, this script can be automated using `crontab` or other scheduling tools, enabling you to automatically switch between backup modes on a schedule (e.g., disabling continuous backups during work hours to preserve bandwidth).

## Features

- 🔄 Toggle between manual and continuous backup modes with a single command
- 📊 Check current backup status
- 📝 Automatic logging of all backup mode changes
- 🚀 First-run setup wizard to help create required configuration files
- ⚙️ Configurable file paths via configuration file
- 🛡️ Safe operation with permission checks and error handling

## Requirements

- macOS (tested on macOS with Backblaze installed)
- Backblaze backup software installed and configured
- Bash shell (Bash v3.2 comes preinstalled in macOS)
- Administrator privileges (sudo) may be required to modify Backblaze settings

## Installation

1. Clone or download this repository:
   ```bash
   git clone <repository-url>
   cd toggle_backblaze_settings
   ```

2. Make the script executable:
   ```bash
   chmod +x toggle_backblaze_settings.sh
   ```

3. (Optional) Create a configuration file:
   ```bash
   cp toggle_backblaze_settings.conf.example toggle_backblaze_settings.conf
   ```
   Edit `toggle_backblaze_settings.conf` if you want to customize file paths.

## First-Time Setup

On first run, the script will automatically detect if the required settings files are missing and guide you through the setup process:

1. **Run the script** (it will detect missing files):
   ```bash
   ./toggle_backblaze_settings.sh
   ```

2. **Follow the on-screen instructions**:
   - Open Backblaze Settings
   - Navigate to the "Schedule" section
   - Change the Backup Schedule to "Only When I Click <Backup Now>"
   - Click "OK" and close the Backblaze settings window

3. **Press Enter** when you've completed the steps

4. **Confirm file creation** when prompted (default: Y)

The script will then:
- Copy your current Backblaze settings to `MyOnlyWhenClickBzinfo.xml`
- Create `MyContinuouslyBzinfo.xml` with continuous backup settings
- You're ready to use the script!

## Usage

### Basic Commands

**Toggle between modes** (switches to the opposite of current setting):
```bash
./toggle_backblaze_settings.sh
```

**Set to manual backup** (only when clicking "Backup Now"):
```bash
./toggle_backblaze_settings.sh manual
```

**Set to continuous backup**:
```bash
./toggle_backblaze_settings.sh continuous
```

**Check current backup status**:
```bash
./toggle_backblaze_settings.sh --status
# or
./toggle_backblaze_settings.sh -s
```

**Show help**:
```bash
./toggle_backblaze_settings.sh --help
# or
./toggle_backblaze_settings.sh -h
```

### Accepted Arguments

The script accepts various forms of the backup mode arguments:
- **Manual**: `manual`, `Manual`, `MANUAL`, `only_when_click`, `click`
- **Continuous**: `continuous`, `Continuous`, `CONTINUOUS`, `auto`, `automatic`, `Automatic`, `AUTOMATIC`

### Running with Sudo

If you encounter permission errors, you may need to run the script with `sudo`:
```bash
sudo ./toggle_backblaze_settings.sh manual
```

## Automation

One of the key advantages of this script is that it can be automated using `crontab` or other scheduling tools, allowing you to automatically switch between backup modes on a schedule. This is particularly useful for work-from-home scenarios where you want to preserve bandwidth during work hours.

### Example: Schedule Backups to manual during work hours to save bandwidth for work

Here's an example `crontab` configuration that switches Backblaze to manual mode at 8:00 AM and back to continuous mode at 10:00 PM, Monday through Friday:

```bash
# Edit your crontab
crontab -e

# Add these lines (adjust the path to match your script location):
0 8 * * 1-5 /usr/bin/sudo /path/to/toggle_backblaze_settings.sh manual
0 22 * * 1-5 /usr/bin/sudo /path/to/toggle_backblaze_settings.sh continuous
```

**Important notes for crontab automation:**
- Use the full path to the script (not a relative path)
- You'll need to use `sudo` since modifying Backblaze settings requires administrator privileges
- You may need to configure passwordless sudo for the script, or use a different authentication method
- Test the script manually first to ensure it works with `sudo` in your environment

**Crontab format explanation:**
- `0 8 * * 1-5` = At 8:00 AM, Monday through Friday
- `0 22 * * 1-5` = At 10:00 PM (22:00), Monday through Friday

This configuration ensures Backblaze stays out of the way during work hours (8 AM - 10 PM) on weekdays, then automatically resumes continuous backups in the evening.

## Configuration

### Configuration File

You can customize file paths by creating a `toggle_backblaze_settings.conf` file:

```bash
cp toggle_backblaze_settings.conf.example toggle_backblaze_settings.conf
```

Edit the configuration file to specify custom paths:

```bash
# Path to the manual backup settings file
MANUAL_BACKUP="/path/to/MyOnlyWhenClickBzinfo.xml"

# Path to the continuous backup settings file
CONTINUOUS_BACKUP="/path/to/MyContinuouslyBzinfo.xml"

# Path to the log file
LOG_FILE="/path/to/backblaze_settings_toggle.log"
```

If you don't create a configuration file, the script will use default paths in the script's directory:
- `MyOnlyWhenClickBzinfo.xml` - Manual backup settings
- `MyContinuouslyBzinfo.xml` - Continuous backup settings
- `backblaze_settings_toggle.log` - Activity log

### Default Backblaze Settings Location

The script modifies Backblaze's configuration file at:
```
/Library/Backblaze.bzpkg/bzdata/bzinfo.xml
```

This path is hardcoded and cannot be changed via configuration.

## How It Works

1. The script maintains two XML configuration files:
   - `MyOnlyWhenClickBzinfo.xml` - Contains settings with `backup_schedule_type="only_when_click_backup_now"`
   - `MyContinuouslyBzinfo.xml` - Contains settings with `backup_schedule_type="continuously"`

2. When you run the script, it:
   - Checks the current backup mode by reading the Backblaze configuration file
   - Copies the appropriate settings file to Backblaze's configuration location
   - Logs the action with a timestamp

3. The only difference between the two XML files is the `backup_schedule_type` attribute in the `<do_backup>` tag.

## Logging

All backup mode changes are logged to `backblaze_settings_toggle.log` (or your configured log file) with timestamps:

```
[2024-01-15 14:30:22] SET: Copied MyOnlyWhenClickBzinfo.xml to bzinfo.xml
[2024-01-15 15:45:10] SET: Copied MyContinuouslyBzinfo.xml to bzinfo.xml
```

## Troubleshooting

### Permission Denied Error

If you see "No write permission" errors, run the script with `sudo`:
```bash
sudo ./toggle_backblaze_settings.sh
```

### Settings Files Not Found

If the script can't find the settings files:
1. Make sure you've completed the first-time setup process
2. Check that `MyOnlyWhenClickBzinfo.xml` and `MyContinuouslyBzinfo.xml` exist in the script directory (or your configured location)
3. Re-run the setup by deleting the files and running the script again

### Cannot Determine Current Backup Status

If you see "Could not determine current backup status":
- Make sure Backblaze is installed
- Verify that `/Library/Backblaze.bzpkg/bzdata/bzinfo.xml` exists
- Check that you have read permissions for the file

### Script Not Executable

If you get "Permission denied" when running the script:
```bash
chmod +x toggle_backblaze_settings.sh
```

## Files

- `toggle_backblaze_settings.sh` - Main script
- `setup_settings_files.sh` - First-run setup logic
- `toggle_backblaze_settings.conf.example` - Example configuration file
- `MyOnlyWhenClickBzinfo.xml` - Manual backup settings (created during setup)
- `MyContinuouslyBzinfo.xml` - Continuous backup settings (created during setup)
- `backblaze_settings_toggle.log` - Activity log (created automatically)

## Notes

- The script modifies Backblaze's system configuration file, which requires appropriate permissions
- Always verify your backup settings in Backblaze after using this script
- The script preserves all other Backblaze settings; only the backup schedule type is changed

## Credits

This solution was inspired by information shared by Reddit user [brianwski](https://www.reddit.com/user/brianwski) in their [comment](https://www.reddit.com/r/backblaze/comments/1b909hh/comment/ktt0q6e/) on the Backblaze subreddit, which explained how to modify Backblaze backup settings by editing the `bzinfo.xml` configuration file.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

This script was written by **Zach Fine** with much help from **Cursor**.

