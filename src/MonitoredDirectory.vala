/*
 * DayFolder
 *
 * Copyright (C) 2013 Zach Burnham <thejambi@gmail.com>
 *
 * DayFolder is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * DayFolder is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using zystem;

using Gee;

namespace dayfolder {

/**
 * This class will manage all data in the settings file for a monitored directory. 
 */
class MonitoredDirectory : Object {

	// Settings key names
	public static const string useDayFolderKey = "useDayFolder";
	public static const string dfRootPathKey = "dfRootPath";
	public static const string sourcePathKey = "sourcePath";
	public static const string moveDirsKey = "moveDirs";
	public static const string dfTypeKey = "dfType";

	// Settings variables
	public string dirPath { get; private set; }
	public string fileExtRulesGroup { get; private set; }
	public bool useDayFolder { get; set; default = true; }
	public string dfRootPath { get; private set; }
	public bool moveDirs { get; set; default = true; }
	public string dfType { get; private set; }

	// Other variables
	public string dayFolderDirPath { get; private set; }
	private HashMap<string, DfRule> rulesMap;

	/**
	 * Constructor.
	 */
	public MonitoredDirectory(string dirPath, bool useDayFolder, string dfRootPath, bool moveDirs, string dfType) {
		this.dirPath = dirPath;
		this.fileExtRulesGroup = dirPath + "FileExtRules";
		this.useDayFolder = useDayFolder;
		this.dfRootPath = dfRootPath;
		this.moveDirs = moveDirs;
		this.dfType = dfType;
		this.rulesMap = new HashMap<string, DfRule>();
	}

	/**
	 * Set the dfRootPath.
	 */
	public void setDfRootPath(string rootPath) {
		this.dfRootPath = rootPath;
	}

	/**
	 * Set the dfType.
	 */
	public void setDfType(string type) {
		this.dfType = type;
	}

	/**
	 * Add a FileRule for this monitored directory.
	 */
	public void addFileRule(string criteria, string destDir) {
		var rule = new FileContainsRule(criteria, destDir);
		this.rulesMap.set(rule.criteriaString, rule);
	}

	/**
	 * Remove the FileRule.
	 */
	public void removeFileRule(string criteria) {
		this.rulesMap.unset(criteria);
	}
		
	/**
	 * Returns list of all file rules.
	 */
	public ArrayList<DfRule> getFileRules() {
		Zystem.debug("In MonitoredDirectory.getFileRules()");
		ArrayList<DfRule> list = new ArrayList<DfRule>();

		foreach (DfRule rule in rulesMap.values) {
			list.add(rule);
		}

		return list;
	}

	/**
	 * Return the FileRule's destination.
	 */
	public string getFileRuleDest(string criteria) {
		return rulesMap.get(criteria).destinationDir;
	}

	/**
	 * Return if a rule exists for a file extension exists.
	 */
	public bool ruleExistsForCriteria(string criteria) {
		return this.rulesMap.has_key(criteria);
	}

	/**
	 * Sets dayFolderDirPath variable to today's dayFolder directory. This is based on the dfType, 
	 * and determines the path to the daily, weekly, or monthly folder.
	 */
	private void setDayFolderDirPath() {
		Zystem.debug("Generating DayFolderDirPath for " + dirPath);

		DateTime dateTime = new GLib.DateTime.now_local();
		string directoryName = "";
		
		if (this.dfType == UserData.dfTypeDaily) {
			// Get the dayfolder directory name from today's date
			directoryName = dateTime.format("%Y-%m-%d");
		} else if (this.dfType == UserData.dfTypeWeekly) {
			dateTime = dateTime.add_days(0 - dateTime.get_day_of_week());
			directoryName = dateTime.format("%Y-%m-%d to ") + dateTime.add_days(6).format("%Y-%m-%d");
		} else if (this.dfType == UserData.dfTypeMonthly) {
			directoryName = dateTime.add_days(1 - dateTime.get_day_of_month()).format("%Y-%m");
		}

		dayFolderDirPath = GLib.Path.build_path(GLib.Path.DIR_SEPARATOR_S, this.dfRootPath, directoryName);
	}

	/**
	 * 
	 */
	public bool isDailyDfType() {
		return dfType == UserData.dfTypeDaily;
	}

	public bool isWeeklyDfType() {
		return dfType == UserData.dfTypeWeekly;
	}

	public bool isMonthlyDfType() {
		return dfType == UserData.dfTypeMonthly;
	}
	

	/**
	 * Debug method.
	 */
	public void printDebug() {
		Zystem.debug("Monitored Directory: " + dirPath);

		Zystem.debug("FileRules: ");
		foreach (DfRule rule in rulesMap.values) {
			Zystem.debug(rule.criteriaString);
		}
	}







	/********************************************* 
	 * 
	 ******************************************/



	/**
	 * Make sure that today's folder is created, then clean the desktop.
	 */
	public void runCleanup() {
		Zystem.debug("In MonitoredDirectory.runCleanup() for " + this.dirPath);

		this.setDayFolderDirPath();

		createTodaysFolder();

		try {
			File desktop = File.new_for_path(this.dirPath);
			FileEnumerator enumerator = desktop.enumerate_children(FILE_ATTRIBUTE_STANDARD_NAME, 0);
			FileInfo fileInfo;

			// Go through the files
			while((fileInfo = enumerator.next_file()) != null) {
				processFile(fileInfo);
			}
		} catch(Error e) {
			stderr.printf ("Error in DayFolder.cleanDesktop(): %s\n", e.message);
		}

		Zystem.debug("Finished cleaning directory");
	}

	/**
	 * Create today's folder in the DayFolder directory.
	 */
	private void createTodaysFolder() {
		// Create the directory. This method doesn't care if it exists already or not.
		GLib.DirUtils.create_with_parents(dayFolderDirPath, 0775);
	}

	/**
	 * Process the passed file.
	 */
	private void processFile(FileInfo file) {
		Zystem.debugFileInfo(file);

		/* Here'e what we can do.
		 * Go through all rules, if it's a match, process the file, or else keep going. 
		 * After all rules have been gone through, if none matched, just do default move.
		 */

		bool fileProcessed = false;

		if (file.get_file_type() == FileType.REGULAR) {
			foreach (DfRule rule in rulesMap.values) {
				fileProcessed = rule.processFile(file, this.dirPath);
				if (fileProcessed) {
					Zystem.debug(file.get_name() + " was processed.");
					break;
				} else {
					Zystem.debug(file.get_name() + " was NOT processed.");
				}
			}
		}

		if (!fileProcessed && this.fileShouldMoveToDayFolder(file)) {
			Zystem.debug("Moving regular file to DayFolder directory");
			moveFile(file);
		}
	}

	/**
	 * 
	 */
	private bool fileShouldMoveToDayFolder(FileInfo file) {
		bool result = false;
		if (file.get_file_type() == FileType.REGULAR && this.useDayFolder) {
			result = true;
		} else if (file.get_file_type() == FileType.DIRECTORY && this.useDayFolder && this.moveDirs) {
			result = true;
		}
		return result;
	}

	/**
	 * Actually move the file to where it's supposed to go.
	 */
	public void moveFile(FileInfo file, string destDir = "") {
		Zystem.debug("dayFolderDirPath is: " + dayFolderDirPath);

		string fileDestPath = "";

		if (destDir == "") {
			fileDestPath = dayFolderDirPath + "/" + file.get_name();
		} else {
			fileDestPath = destDir + "/" + file.get_name();
		}
		var destFile = File.new_for_path(fileDestPath);

		// If file already exists, add timestamp to file name
		if (destFile.query_exists()) {
			fileDestPath = addTimestampToFilePath(fileDestPath, (destDir != ""));
			destFile = File.new_for_path(fileDestPath);
		}

		// Only move the file if destination file does not exist. We don't want to write over any files.
		if (!destFile.query_exists()) {
			GLib.FileUtils.rename(dirPath + "/" + file.get_name(), fileDestPath);
		}
	}

	/**
	 * Get the file path with the unique timestamp inserted at end of 
	 * filename before file extension.
	 */
	private string addTimestampToFilePath(string filePath, bool isFileExtRule) {
		DateTime dateTime = new GLib.DateTime.now_local();

		string pathPrefix = filePath.substring(0, filePath.last_index_of("."));
		string fileExt = filePath.substring(filePath.last_index_of("."));
		string timestamp = "_";

		if (isFileExtRule) {
			timestamp = dateTime.format("_%Y%m%d_%H%M%S");
		} else if (isDailyDfType()) {
			timestamp = dateTime.format("_%H%M%S");
		} else if (isWeeklyDfType() || isMonthlyDfType()) {
			timestamp = dateTime.format("_%d_%H%M%S");
		}

		return pathPrefix + timestamp + fileExt;
	}	
	
}

}
