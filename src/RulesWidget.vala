/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/* DayFolder
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
using Gtk;

using dayfolder;

public class RulesWidget : Gtk.Box {

	private Gtk.Window window;
	private GLib.List<string> fileExtList;
	private Gtk.TreeView tvFileRules;
	private Gtk.Entry txtFileNameContains;
	private Gtk.Entry txtFileRuleDest;
	private Gtk.Button btnChangeFileRuleDest;
	private Gtk.Button btnSaveFileRule;
	private Gtk.Button btnRemoveFileRule;
	private Gtk.ComboBox criteriaComboBox;
	private Gtk.ComboBox actionComboBox;
	private Gtk.Label ruleMsgLabel;

	private CriteriaType selectedCriteriaType;
	private ActionType selectedActionType;

	// Constructor
	public RulesWidget () {
		this.selectedCriteriaType = CriteriaType.fileNameContains;
		this.selectedActionType = ActionType.moveFile;
		
		this.orientation = Gtk.Orientation.VERTICAL;
		
		fileExtList = new GLib.List<string>();



		// Box for File Rules
		Gtk.Box rulesBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);

		this.tvFileRules = new Gtk.TreeView();
		// Setup treeview
		this.setupFileRulesListView();
		tvFileRules.insert_column_with_attributes(-1, "File Rules", new CellRendererText(), "text", 0);

		//rulesBox.pack_start(tvFileRules, true, true, 2);
		this.pack_start(tvFileRules, false, true, 2);
		
		// Box for file rule editing stuff
		Gtk.Box fileRuleEditBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 2);

		//this.lblFileNameContains = Zystem.createLabelLeftAlign("File name contains (such as a key word or file extention)");

		/* combo box work */
		
		Gtk.Box criteriaBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		Gtk.Label lblCriteria = Zystem.createLabelLeftAlign("Criteria: ");
		criteriaBox.pack_start(lblCriteria, false, true, 0);
		
		// Create & fill a ListStore:
		Gtk.ListStore list_store = new Gtk.ListStore (1, typeof (string));
		Gtk.TreeIter iter = Gtk.TreeIter();

		foreach (CriteriaType criteriaType in CriteriaType.all()) {
			list_store.append(out iter);
			list_store.set(iter, 0, criteriaType.toString());
		}

		// The Box:
		this.criteriaComboBox = new Gtk.ComboBox.with_model (list_store);

		Gtk.CellRendererText renderer = new Gtk.CellRendererText ();
		criteriaComboBox.pack_start (renderer, true);
		criteriaComboBox.add_attribute (renderer, "text", 0);
		criteriaComboBox.active = 0;

		criteriaComboBox.changed.connect (() => {
			Value val1;

			criteriaComboBox.get_active_iter (out iter);
			list_store.get_value (iter, 0, out val1);

			stdout.printf ("Selection: %s\n", (string) val1);

			foreach (CriteriaType cType in CriteriaType.all()) {
				if (cType.toString() == (string) val1) {
					this.selectedCriteriaType = cType;
				}
			}
		});

		criteriaBox.pack_start(criteriaComboBox, false, true, 0);
		
		fileRuleEditBox.pack_start(criteriaBox, false, true, 2);
		
		//fileRuleEditBox.pack_start(lblFileNameContains, false, true, 2);


		
		// TODO make box for this stuff and make it magical
		this.txtFileNameContains = new Gtk.Entry();
		fileRuleEditBox.pack_start(txtFileNameContains, true, true, 2);
		
		//this.lblMoveFileTo = Zystem.createLabelLeftAlign("Move file to...");
		//fileRuleEditBox.pack_start(lblMoveFileTo, false, true, 2);

		/* combo box work */
		
		Gtk.Box actionBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		Gtk.Label lblaction = Zystem.createLabelLeftAlign("Action: ");
		actionBox.pack_start(lblaction, false, true, 0);
		
		// Create & fill a ListStore:
		list_store = new Gtk.ListStore (1, typeof (string));
		Gtk.TreeIter iter2 = Gtk.TreeIter();

		foreach (ActionType actionType in ActionType.all()) {
			list_store.append(out iter2);
			list_store.set(iter2, 0, actionType.toString());
		}

		// The Box:
		this.actionComboBox = new Gtk.ComboBox.with_model (list_store);

		renderer = new Gtk.CellRendererText ();
		actionComboBox.pack_start (renderer, true);
		actionComboBox.add_attribute (renderer, "text", 0);
		actionComboBox.active = 0;

		actionComboBox.changed.connect (() => {
			Value val1;

			actionComboBox.get_active_iter (out iter2);
			list_store.get_value (iter2, 0, out val1);

			stdout.printf ("Selection: %s\n", (string) val1);

			foreach (ActionType aType in ActionType.all()) {
				if (aType.toString() == (string) val1) {
					this.selectedActionType = aType;
				}
			}

			if (this.selectedActionType == ActionType.deleteFile) {
				Zystem.debug("I'll just ummmmmmmm disable some stuff now.");
				this.enableActionWidgets(false);
			} else {
				Zystem.debug("I'll just ummmmmmmm TOTALLY ENABLE some stuff now.");
				this.enableActionWidgets(true);
			}
		});

		actionBox.pack_start(actionComboBox, false, true, 0);

		fileRuleEditBox.pack_start(actionBox, false, true, 2);




		

		// TODO make box for this stuff and make it magical
		// File Rule Destination box
		Gtk.Box fileRuleDestBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		
		this.txtFileRuleDest = new Gtk.Entry();
		fileRuleDestBox.pack_start(txtFileRuleDest, true, true, 0);

		this.btnChangeFileRuleDest = new Gtk.Button.from_stock(Gtk.Stock.OPEN);
		btnChangeFileRuleDest.clicked.connect(this.btnChangeFileRuleDestClicked);
		fileRuleDestBox.pack_start(btnChangeFileRuleDest, false, true, 2);

		fileRuleEditBox.pack_start(fileRuleDestBox, true, true, 0);




		

		// Add and Remove File Rule buttons
		Gtk.Box fileRuleButtonsBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		this.btnRemoveFileRule = new Button.with_label("Remove");
		btnRemoveFileRule.clicked.connect(this.btnRemoveFileRuleClicked);
		this.btnSaveFileRule = new Button.with_label("Save");
		btnSaveFileRule.clicked.connect(this.btnSaveFileRuleClicked);

		this.ruleMsgLabel = new Gtk.Label("");

		fileRuleButtonsBox.pack_start(btnRemoveFileRule, false, true, 0);
		fileRuleButtonsBox.pack_start(btnSaveFileRule, false, true, 0);
		fileRuleButtonsBox.pack_start(ruleMsgLabel, false, true, 6);

		fileRuleEditBox.pack_start(fileRuleButtonsBox, false, true, 0);

		rulesBox.pack_start(fileRuleEditBox, true, true, 2);


		this.pack_start(rulesBox, false, true, 0);

	}

	private void enableActionWidgets(bool enabled) {
		this.txtFileRuleDest.set_sensitive(enabled);
		this.btnChangeFileRuleDest.set_sensitive(enabled);
	}





	/**
	 * 
	 */
	private void setupFileRulesListView() {
		var listmodel = new ListStore(1, typeof(string));
		this.tvFileRules.model = listmodel;

		var treeSelection = this.tvFileRules.get_selection();
		treeSelection.set_mode(SelectionMode.SINGLE);
		treeSelection.changed.connect(() => {
			this.fileRuleSelected();
		});
	}

	/**
	 * 
	 */
	public void btnRemoveFileRuleClicked() {
		this.ruleMsgLabel.label = "";
		
		string fileCriteriaString = getSelectedFileExt();

		UserData.removeFileRule(UserData.currentMonitoredDir, fileCriteriaString);

		this.txtFileNameContains.text = "";
		this.txtFileRuleDest.text = "";

		// Reload the treeview
		loadFileExtRulesTreeView();
	}

	/**
	 * 
	 */
	public void btnSaveFileRuleClicked() {
		//UserData.addFileRule(UserData.currentMonitoredDir, this.txtFileNameContains.text, this.txtFileRuleDest.text);
		this.ruleMsgLabel.label = "";

		Zystem.debug("HEEYYYYY WAIT!");

		bool looksGood = true;  // Benefit of the doubt.

		RuleCriteria criteria = null;
		RuleAction action = null;
		if (this.selectedCriteriaType.toString() == UserData.filenameContainsCriteriaString) {
			criteria = new FilenameContainsCriteria(this.txtFileNameContains.text);
			Zystem.debug("Criteria created.");
		} else {
			looksGood = false;
		}

		if (this.selectedActionType.toString() == UserData.moveFileActionString) {
			action = new MoveFileAction(this.txtFileRuleDest.text);
			looksGood = FileUtility.directoryExists(this.txtFileRuleDest.text);
			Zystem.debug("Action created: MoveFileAction " + looksGood.to_string());
		} else if (this.selectedActionType.toString() == UserData.copyFileActionString) {
			action = new CopyFileAction(this.txtFileRuleDest.text);
			looksGood = FileUtility.directoryExists(this.txtFileRuleDest.text);
			Zystem.debug("Action created: CopyFileAction " + looksGood.to_string());
		} else if (this.selectedActionType.toString() == UserData.deleteFileActionString) {
			action = new DeleteFileAction();
			Zystem.debug("Action created: DeleteFileAction");
		} else {
			looksGood = false;
		}

		//if (looksGood && action != null && criteria != null) {
		if (looksGood) {
			UserData.addRule(new FileContainsRule(criteria, action));
		} else {
			Zystem.debug("HEEYYYYY WAIT! There is something null and the rule can't be added!");
			this.ruleMsgLabel.label = "Error saving rule";
		}
		
		this.txtFileNameContains.text = "";
		this.txtFileRuleDest.text = "";
		loadFileExtRulesTreeView();
	}

	/**
	 * Load the user's File Extension Rules.
	 */
	public void loadFileExtRulesTreeView() {
		Zystem.debug("Loading FileExtRule TreeView...");
		
		var listmodel = this.tvFileRules.model as ListStore;

		listmodel.clear();
		fileExtList = new GLib.List<string>();

		TreeIter iter;

		// Get file extension rules settings and add them
		ArrayList<Rule> rules = UserData.getFileRules(UserData.currentMonitoredDir);
		
		foreach (Rule rule in rules) {
			listmodel.append(out iter);
			listmodel.set(iter, 0, rule.getCriteriaDisplayKey());
			fileExtList.append(rule.getCriteriaDisplayKey());
		}

		this.txtFileNameContains.text = ""; // Thest just need to be here for some reason.
		this.txtFileRuleDest.text = "";
	}



	/**
	 * This method is connected to the signal in the code when the settings window 
	 * was created. 
	 *
	private void fileExtRuleSelected() {
		string fileExt = getSelectedFileExt();

		this.txtFileNameContains.text = fileExt;
		this.txtFileRuleDest.text = UserData.getFileRuleDest(UserData.currentMonitoredDir, fileExt);				
	}*/

	private void fileRuleSelected() {
		// This will be what really happens...
		var rule = UserData.getRule(this.getSelectedFileExt());

		this.txtFileNameContains.text = rule.criteria.getDisplayKey();
		this.txtFileRuleDest.text = rule.action.getTextBox1();

		int i = 0;
		foreach (ActionType aType in ActionType.all()) {
			if (aType == rule.action.kind) {
				this.actionComboBox.set_active(i);
				break;
			}
			i++;
		}
	}

	/**
	 * Get the file extension of the currently selected FileExtRule.
	 */
	private string getSelectedFileExt() {
		string fileExt = "";

		var view = this.tvFileRules;

		int index = Zystem.getSelectedFromView(view);

		if (index >= 0) {
			fileExt = fileExtList.nth_data(index);
		}

		return fileExt;
	}



	/**
	 * 
	 */
	private void btnChangeFileRuleDestClicked() {
		var window = this.window;
		var txtDestDir = this.txtFileRuleDest;
		
		var fileChooser = new FileChooserDialog("Choose File Rule Destination", window,
		                                        FileChooserAction.SELECT_FOLDER,
		                                        Stock.CANCEL, ResponseType.CANCEL,
		                                        Stock.OPEN, ResponseType.ACCEPT);
		if (fileChooser.run() == ResponseType.ACCEPT) {
			string dirPath = fileChooser.get_filename();
			txtDestDir.text = dirPath;
		}
		fileChooser.destroy();
	}

}

