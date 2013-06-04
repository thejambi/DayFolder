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
 * This class is accessed statically throughout the application. 
 * It contains some of the user's data such as today's DayFolder directory path. 
 * It also acts as an interface for interacting with the UserSettingsManager object.
 */
class UserData : GLib.Object {

	// static const variables
	public static const string dfTypeDaily = "D";
	public static const string dfTypeWeekly = "W";
	public static const string dfTypeMonthly = "M";
	
	// Properties
	public static string currentMonitoredDir { get; set; }
	public static string desktopDirPath { get; private set; }
	public static string homeDirPath { get; private set; }

	private static UserSettingsManager settings;

	private static HashMap<string, MonitoredDirectory> monitoredDirsMap;

	/**
	 * Pretty much a static constructor. Initializes the variables so UserData is ready to use.
	 */
	public static void initializeUserData() {
		homeDirPath = Environment.get_home_dir();
		desktopDirPath = Environment.get_user_special_dir(UserDirectory.DESKTOP);

		settings = new UserSettingsManager();

		monitoredDirsMap = new HashMap<string, MonitoredDirectory>();

		loadMonitoredDirs();
	}

	/**
	 * Run cleanup on all monitored directories.
	 */
	public static void cleanupAllMonDirs() {
		foreach (MonitoredDirectory monDir in monitoredDirsMap.values) {
			monDir.runCleanup();
		}
	}

	/**
	 * Set the DayFolder root path from the passed in string in the settings and in the 
	 * monitored directory object.
	 */
	public static void setDfRootPath(string monDirPath, string path) {
		settings.setDfRootPath(monDirPath, path);
		MonitoredDirectory monDir = monitoredDirsMap.get(monDirPath);
		monDir.setDfRootPath(path);
	}

	public static void addFileRule(string dirPath, string criteriaString, string destDir) {
		Zystem.debug("In UserData.addFileRule");
		MonitoredDirectory dir = monitoredDirsMap.get(dirPath);
		
		RuleCriteria criteria = new FilenameContainsCriteria(criteriaString);
		RuleAction action = new MoveFileAction(destDir);
		Rule rule = new FileContainsRule(criteria, action);

		dir.addRule(rule);
		settings.addRule(dirPath, rule);
	}

	/**
	 * Load Monitored Directory Data from the settings.
	 */
	private static void loadMonitoredDirs() {
		ArrayList<MonitoredDirectory> monitoredDirs = settings.getMonitoredDirs();

		foreach (MonitoredDirectory dir in monitoredDirs) {
			monitoredDirsMap.set(dir.dirPath, dir);
//			Zystem.debug("Loaded Monitored Dir: " + dir.dirPath);
		}
	}

	/**
	 * Add a monitored directory.
	 */
	public static void addMonitoredDirectory(string dirPath) {
		var dir = new MonitoredDirectory(dirPath,				// dirPath
		                                 true,					// useDayFolder
		                                 getDefaultDfRootPath(),// dfRootPath
		                                 true,					// moveDirs
		                                 dfTypeDaily);			// dfType
		monitoredDirsMap.set(dir.dirPath, dir);
		settings.addMonitoredDirectory(dir);
	}

	/**
	 * Remove a monitored directory.
	 */
	public static void removeMonitoredDir(string dirPath) {
		monitoredDirsMap.unset(dirPath);
		settings.removeMonitoredDirectory(dirPath);
	}

	/**
	 * Return the default path to the DayFolder root directory.
	 */
	public static string getDefaultDfRootPath(){
		return UserData.homeDirPath + "/DayFolder";
	}

	/**
	 * Return the default path to the DayFolder root directory.
	 */
	public static string getDefaultSourcePath(){
		return UserData.homeDirPath + "/Desktop";
	}

	/**
	 * Returns list of all file rules for the given monitored directory.
	 */
	public static ArrayList<Rule> getFileRules(string monDirPath) {
		Zystem.debug("Calling MonitoredDirectory for fileRules...");
		var monDir = monitoredDirsMap.get(monDirPath);
		return monDir.getFileRules();
	}

	/**
	 * Returns list of all file ext rules in the rule manager.
	 */
	public static ArrayList<MonitoredDirectory> getMonitoredDirs() {
		ArrayList<MonitoredDirectory> list = new ArrayList<MonitoredDirectory>();

		foreach (MonitoredDirectory data in monitoredDirsMap.values) {
			list.add(data);
		}

		return list;
	}

	/**
	 * Remove the FileExtRule for the given monitored directory and remove from settings.
	 */
	public static void removeFileRule(string monDirPath, string criteria) {
		var monDir = monitoredDirsMap.get(monDirPath);
		monDir.removeFileRule(criteria);

		settings.removeFileRule(monDirPath, criteria);
	}

	/**
	 * Return the FileRule's destination for the given monitored directory.
	 */
	public static string getFileRuleDest(string monDirPath, string criteria) {
		var monDir = monitoredDirsMap.get(monDirPath);
		return monDir.getFileRuleDest(criteria);
	}

	/**
	 * Set whether or not to move subfolders in given monitored directory.
	 */
	public static void setMoveDirs(string monDirPath, bool moveDirs) {
		settings.setMoveDirs(monDirPath, moveDirs);
		
		MonitoredDirectory monDir = monitoredDirsMap.get(monDirPath);
		monDir.moveDirs = moveDirs;
	}

	public static bool getMoveDirs(string monDirPath) {
		MonitoredDirectory monDir = monitoredDirsMap.get(monDirPath);
		return monDir.moveDirs;
	}

	/**
	 * 
	 */
	public static void setUseDayFolder(string monDirPath, bool useDayFolder) {
		settings.setUseDayFolder(monDirPath, useDayFolder);

		MonitoredDirectory monDir = monitoredDirsMap.get(monDirPath);
		monDir.useDayFolder = useDayFolder;
	}

	public static bool getUseDayFolder(string monDirPath) {
		MonitoredDirectory monDir = monitoredDirsMap.get(monDirPath);
		return monDir.useDayFolder;
	}

	/**
	 * Sets the dfType in the settings and the monitored directory.
	 */
	public static void setDfType(string monDirPath, string dfType) {
		settings.setDfType(monDirPath, dfType);
		
		MonitoredDirectory monDir = monitoredDirsMap.get(monDirPath);
		monDir.setDfType(dfType);
	}

	/**
	 * Returns the DayFolder root directory path string.
	 */
	public static string getDfRootPath(string dirPath) {
		MonitoredDirectory dir = monitoredDirsMap.get(dirPath);
		return dir.dfRootPath;
	}

	/**
	 * Returns the source location path. 
	 */
	public static string getSourcePath(string dirPath) {
		MonitoredDirectory dir = monitoredDirsMap.get(dirPath);
		return dir.dirPath;
	}

	/**
	 * Return the dfType for the passed in monitored directory's path.
	 */
	public static string getDfType(string dirPath) {
		MonitoredDirectory dir = monitoredDirsMap.get(dirPath);
		return dir.dfType;
	}

	/**
	 * Debug method.
	 */
	public static void printDebug() {
		foreach (MonitoredDirectory monDir in monitoredDirsMap.values) {
			monDir.printDebug();
		}
	}
	
}

}
