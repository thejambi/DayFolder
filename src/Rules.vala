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

interface Rule : GLib.Object {

	//public abstract string criteriaString { get; protected set; }
	//public abstract string destinationDir { get; protected set; }

	public abstract RuleCriteria criteria { get; protected set; }
	public abstract RuleAction action { get; protected set; }
	public abstract string displayKey { get; protected set; }
//	public abstract string criteriaType { get; }
//	public abstract string actionType { get; }

//~ 	public abstract bool processFile(FileInfo file, string dirPath);
	public abstract bool processFile(FileData file);

	public abstract string getCriteriaDisplayKey();

	public abstract string[] getSettingsEntryList();
}

class FileContainsRule : Object, Rule {

	// Instance variables
	//public string criteriaString { get; private set; }
	//public string destinationDir { get; private set; }

	public RuleCriteria criteria { get; protected set; }
	public RuleAction action { get; protected set; }
	public string displayKey { get; protected set; }
	/*public string criteriaType {
		get {
			return criteria.blahblah;
		}
	}
	public string actionType {
		get {
			return action.actionType;
		}
	}*/

	/**
	 * Constructor.
	 */
	public FileContainsRule(RuleCriteria criteria, RuleAction action) {
		this.criteria = criteria;
		this.action = action;
		this.displayKey = criteria.displayKey;
	}
	
	public bool processFile(FileData file) {
		if (this.criteria.fileMeetsCriteria(file)) {
			return this.action.processFile(file);
		}
		return false;
	}

	public string[] getSettingsEntryList() {
		//string[] stringList = new string[this.criteria.getSettingsEntryListSize() + this.action.getSettingsEntryListSize()];
		string[] criteriaStringList = this.criteria.getStringList();
		string[] actionStringList = this.action.getStringList();

		string[] stringList = new string[criteriaStringList.length + actionStringList.length];

		int i = 0;

		foreach (string s in criteriaStringList) {
			stringList[i++] = s;
		}
		foreach (string s in actionStringList) {
			stringList[i++] = s;
		}

		return stringList;
	}

	public string getCriteriaDisplayKey() {
		return this.criteria.displayKey;
	}

//~ 	public bool isRuleForFile(string fileName){
//~ 		return Regex.match_simple(criteriaString, fileName);
//~ 	}

//~ 	public string getDestinationDir() {
//~ 		return this.destinationDir;
//~ 	}
}

}
