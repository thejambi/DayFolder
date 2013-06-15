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

enum ActionType {
	moveFile,
	copyFile,
	deleteFile;

	public string toString() {
		switch (this) {
			case moveFile:
				return UserData.moveFileActionString; //"Move file to a folder";
			case copyFile:
				return "Copy file to a folder";
			case deleteFile:
				return "Move file to trash";
			default:
				return "I'm sorry, the action is in another castle";
		}
	}

	public static ActionType[] all() {
		return { moveFile, copyFile, deleteFile };
	}
}

interface RuleAction : GLib.Object {

	public abstract ActionType kind { get; protected set; }

	/**
	 * Return true if file was processed successfully, false if not.
	 */
	public abstract bool processFile(FileData file);

	public abstract string[] getStringList();

	public abstract string getDisplayKey();

	public abstract string getTextBox1();
}

/**
 * Action: Move File
 ******************************************/
class MoveFileAction : Object, RuleAction {

	public ActionType kind { get; protected set; }
	
	public string destinationDir { get; private set; }
	
	public MoveFileAction(string destinationDir) {
		this.kind = ActionType.moveFile;
		
		this.destinationDir = destinationDir;
	}

	public bool processFile(FileData file) {
		Zystem.debug("Processing file for : " + this.kind.toString());

		string fileDestPath = this.destinationDir + "/" + file.fileInfo.get_name();

		var destFile = File.new_for_path(fileDestPath);

		// If file already exists, add timestamp to file name
		if (destFile.query_exists()) {
			fileDestPath = FileUtility.addTimestampToFilePath(fileDestPath);
			destFile = File.new_for_path(fileDestPath);
		}

		// Only do action if destination file does not exist. We don't want to write over any files.
		if (!destFile.query_exists()) {
			FileUtility.createFolder(this.destinationDir);	// Make sure folder exists
			return file.fileObject.move(destFile, FileCopyFlags.NONE);
		}

		return false;
	}

	public string[] getStringList() {
		return {kind.toString(), this.destinationDir};
	}

	public string getDisplayKey() {
		return "Move to " + this.destinationDir;
	}

	public string getTextBox1() {
		return this.destinationDir;
	}
}


/**
 * Action: Copy File
 ******************************************/
class CopyFileAction : Object, RuleAction {

	public ActionType kind { get; protected set; }
	
	public string destinationDir { get; private set; }
	
	public CopyFileAction(string destinationDir) {
		this.kind = ActionType.copyFile;
		
		this.destinationDir = destinationDir;
	}

	public bool processFile(FileData file) {
		Zystem.debug("Processing file for : " + this.kind.toString());

		string fileDestPath = this.destinationDir + "/" + file.fileInfo.get_name();

		var destFile = File.new_for_path(fileDestPath);

		// If file already exists, add timestamp to file name
		if (destFile.query_exists()) {
			fileDestPath = FileUtility.addTimestampToFilePath(fileDestPath);
			destFile = File.new_for_path(fileDestPath);
		}

		// Only do action if destination file does not exist. We don't want to write over any files.
		if (!destFile.query_exists()) {
			FileUtility.createFolder(this.destinationDir);	// Make sure folder exists
			return file.fileObject.copy(destFile, FileCopyFlags.NONE);
		}

		return false;
	}

	public string[] getStringList() {
		return {kind.toString(), this.destinationDir};
	}

	public string getDisplayKey() {
		return "Copy to " + destinationDir;
	}

	public string getTextBox1() {
		return this.destinationDir;
	}
}


/**
 * Action: Delete File
 ******************************************/
class DeleteFileAction : Object, RuleAction {

	public ActionType kind { get; protected set; }
	
	public DeleteFileAction() {
		this.kind = ActionType.deleteFile;
	}

	public bool processFile(FileData file) {
		Zystem.debug("Processing file for : " + kind.toString());

		return file.fileObject.trash();
	}

	public string[] getStringList() {
		return {kind.toString()};
	}

	public string getDisplayKey() {
		return "Delete";
	}

	public string getTextBox1() {
		return "";
	}
}


}
