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

using Gee;



namespace dayfolder {

/**
 * Manages User's Settings. This class deals with interactions with  
 * data in the DayFolder settings file.
 */
class UserSettingsManager : Object {

	// Instance variables
	KeyFile keyFile;
	
	string dfConfPath;

	//const string fileExtRulesGroup = "FileExtRules";
	public const string rulesGroupSuffix = "?Rules";

	const string monitoredDirsGroup = "MonitoredDirectories";

	const string defaultDfType = UserData.dfTypeDaily;

	/**
	 * Constructor. 
	 */
	public UserSettingsManager() {
		
		// Make sure the settings folder exists
		string settingsDirPath = UserData.homeDirPath + "/.config/dayfolder";
		FileUtility.createFolder(settingsDirPath);

		// Get path to df.conf file
		this.dfConfPath = settingsDirPath + "/dayfolder.conf";
		
		// Make sure that settings files exist
		File settingsFile = File.new_for_path(this.dfConfPath);

		if (!settingsFile.query_exists()) {
			try {
				settingsFile.create(FileCreateFlags.NONE);
			} catch(Error e) {
				stderr.printf ("Error creating settings file: %s\n", e.message);
			}
		}
		
		// Initialize variables
		keyFile = new KeyFile();

		try {
			keyFile.load_from_file(this.dfConfPath, 0);
		} catch(Error e) {
			stderr.printf ("Error in UserSettingsManager(): %s\n", e.message);
		}
		
		// Process keyFile and save keyFile to disk if needed
		if (processKeyFile()) {
			this.writeKeyFile();
		}
	}

	/**
	 * Process the key file. Return true if keyFile needs to be written.
	 */
	private bool processKeyFile() {
		string originalKeyFileData = keyFile.to_data();
		
		// Return true if the keyFile data has been updated (if it's no longer the same as it was)
		return originalKeyFileData != keyFile.to_data();
	}
	
	/**
	 * Write settings file.
	 */
	private void writeKeyFile() {
		try {
			FileUtils.set_contents(this.dfConfPath, this.keyFile.to_data());
		} catch(Error e) {
			stderr.printf("Error writing keyFile: %s\n", e.message);
		}
	}
	
	/**
	 * Set dfRootPath for the given monitored directory.
	 */
	public void setDfRootPath(string monDirPath, string dfRootPath) {
		keyFile.set_string(monDirPath, MonitoredDirectory.dfRootPathKey, dfRootPath);
		writeKeyFile();
	}

	/**
	 * Set source location path for the given monitored directory.
	 */
	public void setSourcePath(string monDirPath, string sourcePath) {
		keyFile.set_string(monDirPath, MonitoredDirectory.sourcePathKey, sourcePath);
		writeKeyFile();
	}

	/**
	 * Set dfType for the given monitored directory.
	 */
	public void setDfType(string monDirPath, string dfType) {
		keyFile.set_string(monDirPath, MonitoredDirectory.dfTypeKey, dfType);
		writeKeyFile();
	}

	/**
	 * Set moveDirs for the given monitored directory.
	 */
	public void setMoveDirs(string monDirPath, bool moveDirs) {
		keyFile.set_boolean(monDirPath, MonitoredDirectory.moveDirsKey, moveDirs);
		writeKeyFile();
	}

	/**
	 * Set useDayFolder for the given monitored directory.
	 */
	public void setUseDayFolder(string monDirPath, bool useDayFolder) {
		keyFile.set_boolean(monDirPath, MonitoredDirectory.useDayFolderKey, useDayFolder);
	}

	/**
	 * Get the monitored directories.
	 */
	public ArrayList<MonitoredDirectory> getMonitoredDirs() {
		ArrayList<MonitoredDirectory> monitoredDirs = new ArrayList<MonitoredDirectory>();

		try{
			string[] monitoredDirPaths = keyFile.get_keys(monitoredDirsGroup);

			foreach (string dirPath in monitoredDirPaths) {
//				Zystem.debug(dirPath);

				bool useDayFolder = getUseDayFolder(dirPath);
				string dfRootPath = getDfRootPath(dirPath);
				bool moveDirs = getMoveDirs(dirPath);
				string dfType = getDfType(dirPath);

				var monDir = new MonitoredDirectory(dirPath, useDayFolder, dfRootPath, moveDirs, dfType);

				// FileExtRules	// THIS IS OLD NOW
				if (keyFile.has_group(monDir.fileExtRulesGroup)) {
					string[] fileExts = keyFile.get_keys(monDir.fileExtRulesGroup);

					foreach (string ext in fileExts) {
						Zystem.debug("Adding file rule");
//						monDir.addFileRule(ext, keyFile.get_string(monDir.fileExtRulesGroup, ext));
						/*RuleCriteria criteria = new FilenameContainsCriteria(ext);
						RuleAction action = new MoveFileAction(keyFile.get_string(monDir.fileExtRulesGroup, ext));
						Rule rule = new FileContainsRule(criteria, action);
						monDir.addRule(rule);*/
					}
				}

				if (keyFile.has_group(monDir.rulesGroup)) {
					Zystem.debug("Has rules group!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
					string[] ruleKeys = keyFile.get_keys(monDir.rulesGroup);

					foreach (string key in ruleKeys) {
						Zystem.debug("Adding rule... well that would be the plan.. but.. yeah!");
						/*RuleCriteria criteria = new FilenameContainsCriteria(str);
						RuleAction action = new MoveFileAction(keyFile.get_string(monDir.fileExtRulesGroup, ext));*/

						SettingsRuleEntry ruleEntry = new SettingsRuleEntry(key, keyFile.get_string_list(monDir.rulesGroup, key));
						
//						Rule rule = new FileContainsRule(criteria, action);
						monDir.addRule(ruleEntry.getRule());
					}
				}

				monitoredDirs.add(monDir);
			}
		} catch (Error e) {
			stderr.printf ("Error in UserSettingsManager.getMonitoredDirs(): %s\n", e.message);
//			Zystem.debug("Settings file didn't have MonitoredDir info in it. That's totally fine.");
		}

		return monitoredDirs;
	}

	/**
	 * 
	 */
	//public void addFileRule(string monDirPath, Rule rule) {
//		keyFile.set_string(monDirPath + fileExtRulesGroup, rule.criteriaString, rule.destinationDir);
		//writeKeyFile();
		//Zystem.debug("settings cannot save yet.");
	//}

	public void addRule(string monDirPath, Rule rule) {
//		string[] ruleStrs = {rule.criteria.kind, rule.action.kind, rule.criteria.displayKey, rule.action.displayKey};
		
		keyFile.set_string_list(monDirPath + rulesGroupSuffix, rule.displayKey, rule.getSettingsEntryList());
		writeKeyFile();
	}

	/**
	 * Add monitored directory.
	 */
	public void addMonitoredDirectory(MonitoredDirectory dir) {
		// Create the new monitored directory entry and related settings group
		keyFile.set_boolean(monitoredDirsGroup, dir.dirPath, true);
		keyFile.set_boolean(dir.dirPath, MonitoredDirectory.useDayFolderKey, true);
		writeKeyFile();
	}

	/**
	 * Remove monitored directory.
	 */
	public void removeMonitoredDirectory(string dirPath) {
		keyFile.remove_key(monitoredDirsGroup, dirPath);
		writeKeyFile();
	}

	/**
	 * Remove the FileExtRule for the given monitored directory.
	 */
	public void removeFileRule(string monDirPath, string criteria) {
		keyFile.remove_key(monDirPath + rulesGroupSuffix, criteria);

		try {
			if (keyFile.get_keys(monDirPath + rulesGroupSuffix).length == 0) {
				keyFile.remove_group(monDirPath + rulesGroupSuffix);
			}
		} catch (KeyFileError e) {
			Zystem.debug("That's probably not good.");
		}
		
		writeKeyFile();
	}


	
	
	/**
	 * Get the UseDayFolder setting for the monitored dirpath.
	 */
	private bool getUseDayFolder(string dirPath) {
		bool useDf = true; // Default value
		
		try {
			useDf = keyFile.get_boolean(dirPath, MonitoredDirectory.useDayFolderKey);
		} catch (Error e) {
//			Zystem.debug("Could not retrieve UseDayFolder setting. Using default value.");
		}

		return useDf;
	}

	/**
	 * Get the dfRootPath setting for the monitored dirpath.
	 */
	private string getDfRootPath(string dirPath) {
		string rootPath = UserData.getDefaultDfRootPath(); // Default value
		
		try {
			rootPath = keyFile.get_string(dirPath, MonitoredDirectory.dfRootPathKey);
		} catch (Error e) {
//			Zystem.debug("Could not retrieve DayFolder root path setting. Using default value.");
		}

//		Zystem.debug("DayFolder Root Path is: " + rootPath);

		return rootPath;
	}

	/**
	 * Get the moveDirs setting for the monitored dirpath.
	 */
	private bool getMoveDirs(string dirPath) {
		bool moveDirs = true; // Default value
		
		try {
			moveDirs = keyFile.get_boolean(dirPath, MonitoredDirectory.moveDirsKey);
		} catch (Error e) {
//			Zystem.debug("Could not retrieve Move Subfolders setting. Using default value.");
		}

		return moveDirs;
	}

	/**
	 * Get the dfType setting for the monitored dirpath.
	 */
	private string getDfType(string dirPath) {
		string dfType = UserData.dfTypeDaily; // Default value
		
		try {
			dfType = keyFile.get_string(dirPath, MonitoredDirectory.dfTypeKey);
		} catch (Error e) {
//			Zystem.debug("Could not retrieve DayFolder type setting. Using default value.");
		}

		return dfType;
	}
}

/**
 * 
 *********************************/
class SettingsRuleEntry : Object {

	public string key { get; private set; }
	private string[] stringList;
	/*public string criteriaType { get; private set; }
	public string actionType { get; private set; }
	public string criteriaDisplayKey { get; private set; }
	public string actionDisplayKey { get; private set; }*/

	/*string[] ruleStrs = {rule.criteriaType, rule.actionType, rule.criteria.displayKey, rule.action.displayKey};	
	keyFile.set_string_list(monDirPath + rulesGroupSuffix, rule.displayKey, ruleStrs);*/
//	public SettingsRuleEntry(string key, string cType, string aType, string cKey, string aKey) {
	public SettingsRuleEntry(string key, string[] stringGroup) {
		this.key = key;
		this.stringList = stringGroup;
		/*this.criteriaType = stringGroup[0];
		this.actionType = stringGroup[1];
		this.criteriaDisplayKey = stringGroup[2];
		this.actionDisplayKey = stringGroup[3];*/
	}

	public Rule? getRule() {
		RuleCriteria criteria = null;
		RuleAction action = null;
		Rule rule;

		int i = 0;

		Zystem.debug(this.stringList[i]);

		// The Criteria type comes first. Check that and get all needed values.
		if (this.stringList[i++] == RuleCriteria.filenameContainsType) {
			Zystem.debug(this.stringList[i]);
			criteria = new FilenameContainsCriteria(this.stringList[i++]);
		} else {
			Zystem.debug("Hey! Error! Bad criteria type.");
		}

		Zystem.debug(this.stringList[i]);

		if (this.stringList[i++] == RuleAction.moveFileActionType) {
			Zystem.debug(this.stringList[i]);
			action = new MoveFileAction(this.stringList[i++]);
		} else {
			Zystem.debug("Hey! Error! Bad action type.");
		}

		if (null != criteria && null != action) {
			rule = new FileContainsRule(criteria, action);
			return rule;
		}

		return null;
	}
}

}
