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

using Gtk;

using dayfolder;

/**
 * This class is for random helpful methods.
 */
class Zystem : Object {

	public static bool debugOn { get; set; default = false; }
	
	/**
	 * My own println method. Hey, I'm a Java programmer!
	 */
	//public static void println(string s){
	//	stdout.printf(s + "\n");
	//}

	/**
	 * Debug method. Only prints if debug is set on.
	 */
	public static void debug(string s) {
		if (debugOn) {
			stdout.printf(s + "\n");
		}
	}

	/**
	 * 
	 */
	public static void debugFileInfo(FileInfo file) {
		debug("File type: " + file.get_file_type().to_string());
	}


	/**
	 * Gtk stuff.
	 ************/

	public static Label createLabelLeftAlign(string? text) {
		var label = new Gtk.Label(text);
		label.xalign = 0;
		return label;
	}

	/**
	 * Return index value of currently selected item in passed in TreeView.
	 */
	public static int getSelectedFromView(TreeView view) {
		int index = -1;
		var selection = view.get_selection() as TreeSelection;
		selection.set_mode(SelectionMode.SINGLE);
		TreeModel model;
		TreeIter iter;
		if (!selection.get_selected(out model, out iter)) {
			index = -1;
		} else {
			TreePath path = model.get_path(iter);
			index = int.parse(path.to_string());
		}

		return index;
	}







	/**
	 * This tests rules, criteria, actions.
	 */
	public static void testDayFolder() {
		debug("----------------DOING A CRAZY TEST---------------");
		// Add monitored dirs
		var m = new MonitoredDirectory("/home/zach/TestDayFolderSource", true, "/home/zach/TestDayFolder", true, "D");

		// Add rules
		var c = new FilenameContainsCriteria("test");
		var a = new DeleteFileAction();
		var r = new FileContainsRule(c, a);
		
		m.addRule(r);

		// Run
		m.runCleanup();
	}
	
}

