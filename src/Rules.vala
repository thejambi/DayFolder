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

using zystem;

namespace dayfolder {

interface DfRule : GLib.Object {

	public abstract string criteriaString { get; protected set; }
	public abstract string destinationDir { get; protected set; }

	public abstract bool processFile(FileInfo file, string dirPath);
}

class FileContainsRule : Object, DfRule {

	// Instance variables
	public string criteriaString { get; private set; }
	public string destinationDir { get; private set; }

	/**
	 * Constructor.
	 */
	public FileContainsRule(string criteria, string destinationDir) {
		this.criteriaString = criteria;
		this.destinationDir = destinationDir;

		// Make sure that the destination exists? No.
		
	}

	public bool processFile(FileInfo file, string dirPath) {
		bool match = false;

		if (this.criteriaString in file.get_name()) {
			match = true;
			// Process file - Move file to destinationDir
			this.moveFile(file, dirPath);
		}

		return match;
	}

	/**
	 * Actually move the file to where it's supposed to go.
	 */
	private void moveFile(FileInfo file, string dirPath) {
		Zystem.debug("Moving file based on Rule");

		string fileDestPath = "";

		fileDestPath = this.destinationDir + "/" + file.get_name();
		
		var destFile = File.new_for_path(fileDestPath);

		// If file already exists, add timestamp to file name
		if (destFile.query_exists()) {
			fileDestPath = this.addTimestampToFilePath(fileDestPath);
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
	private string addTimestampToFilePath(string filePath) {
		DateTime dateTime = new GLib.DateTime.now_local();

		string pathPrefix = filePath.substring(0, filePath.last_index_of("."));
		string fileExt = filePath.substring(filePath.last_index_of("."));
		string timestamp = dateTime.format("_%Y%m%d_%H%M%S");

		return pathPrefix + timestamp + fileExt;
	}

	public bool isRuleForFile(string fileName){
		//return (criteriaString == ext);
		return Regex.match_simple(criteriaString, fileName);
	}

	public string getDestinationDir() {
		return this.destinationDir;
	}
}

}