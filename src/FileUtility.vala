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

/**
 * File Utility class.
 */
class FileUtility : Object {

	/**
	 * Create a folder (or make sure it exists).
	 */
	public static void createFolder(string dirPath){
		// Create the directory. This method doesn't care if it exists already or not.
		GLib.DirUtils.create_with_parents(dirPath, 0775);
	}

	/**
	 * Return the file extension from the given fileInfo.
	 */
	public static string getFileExtension(FileInfo file){
		string fileName = file.get_name();
		return fileName.substring(fileName.last_index_of("."));
	}

	public static string pathCombine(string pathStart, string pathEnd) {
		return Path.build_path(Path.DIR_SEPARATOR_S, pathStart, pathEnd);
	}

	/**
	 * Get the file path with the unique timestamp inserted at end of 
	 * filename before file extension.
	 */
	public static string addTimestampToFilePath(string filePath) {
		DateTime dateTime = new GLib.DateTime.now_local();

		string pathPrefix = filePath.substring(0, filePath.last_index_of("."));
		string fileExt = filePath.substring(filePath.last_index_of("."));
		string timestamp = dateTime.format("_%Y%m%d_%H%M%S");

		return pathPrefix + timestamp + fileExt;
	}

	public static bool directoryExists(string dirPath) {
		Zystem.debug("Checking if " + dirPath + " is a directory");
		var file = File.new_for_path(dirPath);
		return dirPath.length > 1 && file.query_file_type(0) == FileType.DIRECTORY;
	}
	
}


class FileData : Object {
	public string dirPath { get; set; }
	public FileInfo fileInfo { get; private set; }
	public File fileObject { get; private set; }

	public FileData(FileInfo fileInfo, string dirPath) {
		this.fileInfo = fileInfo;
		this.dirPath = dirPath;
		this.fileObject = File.new_for_path(FileUtility.pathCombine(this.dirPath, fileInfo.get_name()));
	}
}
