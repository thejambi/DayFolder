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

enum CriteriaType {
	fileNameContains;

	public string toString() {
		switch (this) {
			case fileNameContains:
				return UserData.filenameContainsCriteriaString;
			default:
				return "I'm sorry, the criteria is in another castle";
		}
	}

	public static CriteriaType[] all() {
		return { fileNameContains };
	}
}

interface RuleCriteria : GLib.Object {

	//public abstract string criteriaString { get; protected set; }
	//public abstract string displayKey { get; protected set; }

	public abstract CriteriaType kind { get; protected set; }

	public abstract bool fileMeetsCriteria(FileData file);

	public abstract string[] getStringList();

	public abstract string getDisplayKey();
}

class FilenameContainsCriteria : Object, RuleCriteria {

	private string displayKey;

	public CriteriaType kind { get; protected set; }
	
	public string criteriaString { get; private set; }

	public FilenameContainsCriteria(string criteriaString) {
		this.kind = CriteriaType.fileNameContains;
		
		this.criteriaString = criteriaString;
		this.displayKey = this.criteriaString;
	}

	public bool fileMeetsCriteria(FileData file) {
		return this.criteriaString in file.fileInfo.get_name();
	}

	public string[] getStringList() {
		return { kind.toString(), this.criteriaString };
	}

	public string getDisplayKey() {
		return this.displayKey;
	}
}

}
