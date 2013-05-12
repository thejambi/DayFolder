/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
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
using GLib;
using Gtk;
using Gdk;
using AppIndicator;

using dayfolder;
using zystem;

public class Main : Object {

	/* Icons */
	const string DF_INDICATOR_ICON = "dayfolder-panel";   // Installed	

	// SET THIS TO TRUE BEFORE BUILDING TARBALL
	private const bool isInstalled = true;

	private Gtk.Window window;
	private GLib.List<string> fileExtList;
	private GLib.List<string> monitoredDirsList;
	private string currentMonitoredDir;
	private Gtk.TreeView tvFileRules;
	private Gtk.TreeView tvMonitoredDirs;
	private Gtk.RadioButton rdoDaily;
	private Gtk.RadioButton rdoWeekly;
	private Gtk.RadioButton rdoMonthly;
	private Gtk.Entry txtFileNameContains;
	private Gtk.Entry txtFileRuleDest;
	private Gtk.Label lblDfLocationDisplay;
	private Gtk.Switch swUseDayFolder;
	private Gtk.Switch swMoveSubfolders;
	private Gtk.Button btnChangeDfLocation;
	private Gtk.Button btnChangeFileRuleDest;
	private Gtk.Label lblSrcFolderLocationDisplay;
	private Gtk.Label lblSubfoldersOption;
	private Gtk.Label lblDfTypeHeading;

	/**
	 * Constructor for Main. 
	 */
	public Main() {

		Zystem.debugOn = !isInstalled;

		Zystem.debug("Package data dir: " + Config.PACKAGE_DATA_DIR);

		// Create the UserData
		UserData.initializeUserData();

		fileExtList = new GLib.List<string>();
		monitoredDirsList = new GLib.List<string>();
		currentMonitoredDir = "";

		// Create AppIndicator
		var indicator = new Indicator("DayFolder", DF_INDICATOR_ICON,
		                              IndicatorCategory.APPLICATION_STATUS);
		indicator.set_status(IndicatorStatus.ACTIVE);

		// Create the Menu object
		Gtk.Menu menu = new Gtk.Menu();

		// Create the Clean Desktop menu item and add it
		Gtk.MenuItem item = new Gtk.MenuItem.with_label("Clean Up Folders");
		item.activate.connect(() => { UserData.cleanupAllMonDirs(); });
		menu.append(item);

		// Create the settings menu item
		item = new Gtk.MenuItem.with_label("Settings...");
		item.activate.connect(() => { settingsClicked(); });
		menu.append(item);

		// Create the Go To DayFolder menu item
		item = new Gtk.MenuItem.with_label("View DayFolder");
		item.activate.connect(() => { openTodaysFolderClicked(); });
		menu.append(item);

		// Create the Quit menu item
		menu.append(new Gtk.SeparatorMenuItem());
		item = new Gtk.MenuItem.with_label("Quit");
		item.activate.connect(() => { exitDayFolder(); });
		menu.append(item);

		menu.show_all();

		indicator.set_menu(menu);

		Gtk.main();
	}

	/**
	 * Opens the DayFolder root directory for user.
	 */
	private void openTodaysFolderClicked() {
		try {
			Gtk.show_uri(null, "file://" + UserData.getDefaultDfRootPath(), Gdk.CURRENT_TIME);
		} catch(Error e) {
			stderr.printf ("Error opening folder: %s\n", e.message);
		}
	}

	/**
	 * Create and show the settings window.
	 */
	private void settingsClicked() {
		this.window = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
		window.set_size_request(600, 500);
		window.resizable = false;
		window.title = "DayFolder Settings";
		window.destroy.connect(() => { on_destroy(window); });

		// Let's create the left side
		Gtk.Box leftSideBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);

		this.tvMonitoredDirs = new Gtk.TreeView();
		// Setup treeview
		this.setupMonitoredDirsListView();
		this.tvMonitoredDirs.insert_column_with_attributes(-1, "Monitored Folders", new CellRendererText(), "text", 0);

		leftSideBox.pack_start(tvMonitoredDirs, false, true, 0);

		Gtk.Button btnAddMonitoredDir = new Gtk.Button.with_label("Add");
		btnAddMonitoredDir.clicked.connect(() => { btnAddMonitoredDirClicked(btnAddMonitoredDir); });

		Gtk.Button btnRemoveMonitoredDir = new Gtk.Button.with_label("Remove");
		btnRemoveMonitoredDir.clicked.connect(() => { btnRemoveMonitoredDirClicked(btnRemoveMonitoredDir); });

		Gtk.Box leftSideButtonBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

		leftSideButtonBox.pack_start(btnAddMonitoredDir, false, true, 0);
		leftSideButtonBox.pack_start(btnRemoveMonitoredDir, false, true, 0);

		leftSideBox.pack_start(leftSideButtonBox, false, true, 0);
		leftSideBox.width_request = 160;
		
		
		// Main box
		Gtk.Box mainBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		
		Gtk.Label lblSrcFolderLocationHeading = this.createLabelLeftAlign("<b>Source Folder Location</b>");
		lblSrcFolderLocationHeading.use_markup = true;
		mainBox.pack_start(lblSrcFolderLocationHeading, false, false, 4);

		this.lblSrcFolderLocationDisplay = this.createLabelLeftAlign(null);
		lblSrcFolderLocationDisplay.label = "";
		mainBox.pack_start(lblSrcFolderLocationDisplay, false, true, 4);

		Gtk.Box dfLocationHeadingBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

		Gtk.Label lblDfLocationHeading = this.createLabelLeftAlign("<b>DayFolder Location</b>");
		lblDfLocationHeading.use_markup = true;
		dfLocationHeadingBox.pack_start(lblDfLocationHeading, true, true, 4);

		this.swUseDayFolder = new Gtk.Switch();
		this.swUseDayFolder.notify["active"].connect(this.swUseDayFolderClicked);
		dfLocationHeadingBox.pack_start(swUseDayFolder, false, true, 4);

		mainBox.pack_start(dfLocationHeadingBox, false, true, 0);

		Gtk.Box dfLocationDisplayBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

		this.lblDfLocationDisplay = this.createLabelLeftAlign(null);
		lblDfLocationDisplay.label = "";
		dfLocationDisplayBox.pack_start(lblDfLocationDisplay, true, true, 4);

		this.btnChangeDfLocation = new Gtk.Button.from_stock(Gtk.Stock.OPEN);
		btnChangeDfLocation.clicked.connect(() => { this.btnDfRootPathClicked(this.btnChangeDfLocation); });
		dfLocationDisplayBox.pack_start(btnChangeDfLocation, false, true, 4);

		mainBox.pack_start(dfLocationDisplayBox, false, true, 4);

		Gtk.Box subfoldersOptionBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

		this.lblSubfoldersOption = this.createLabelLeftAlign("Also move subfolders to DayFolder");
		lblSubfoldersOption.xalign = 0;
		subfoldersOptionBox.pack_start(lblSubfoldersOption, true, true, 4);

		this.swMoveSubfolders = new Gtk.Switch();
		// connect switch
		this.swMoveSubfolders.notify["active"].connect(this.swMoveSubfoldersClicked);
		subfoldersOptionBox.pack_start(swMoveSubfolders, false, false, 4);

		mainBox.pack_start(subfoldersOptionBox, false, true, 4);

		this.lblDfTypeHeading = this.createLabelLeftAlign("<b>DayFolder Type</b>");
		lblDfTypeHeading.use_markup = true;
		mainBox.pack_start(lblDfTypeHeading, false, true, 4);

		// Box for DayFolder type options
		Gtk.Box dfTypeBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

		this.rdoDaily = new Gtk.RadioButton.with_label_from_widget(new RadioButton(null), "Daily");
		this.rdoWeekly = new Gtk.RadioButton.with_label_from_widget(rdoDaily, "Weekly");
		this.rdoMonthly = new Gtk.RadioButton.with_label_from_widget(rdoWeekly, "Monthly");

		this.rdoDaily.toggled.connect(() => { this.rdoDayClicked(this.rdoDaily); });
		this.rdoWeekly.toggled.connect(() => { this.rdoWeekClicked(this.rdoWeekly); });
		this.rdoMonthly.toggled.connect(() => { this.rdoMonthClicked(this.rdoMonthly); });
		
		dfTypeBox.pack_start(rdoDaily, false, true, 2);
		dfTypeBox.pack_start(rdoWeekly, false, true, 2);
		dfTypeBox.pack_start(rdoMonthly, false, true, 2);

		mainBox.pack_start(dfTypeBox, false, true, 2);

		// Spacer
		Gtk.Label lblSpacer = new Gtk.Label("");
		lblSpacer.width_request = 20;
		lblSpacer.height_request = 30;

		mainBox.pack_start(lblSpacer, false, true, 2);

		// Box for File Rules
		Gtk.Box fileRulesBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);

		this.tvFileRules = new Gtk.TreeView();
		// Setup treeview
		this.setupFileRulesListView();
		tvFileRules.insert_column_with_attributes(-1, "File Rules", new CellRendererText(), "text", 0);

		fileRulesBox.pack_start(tvFileRules, true, true, 2);
		
		// Box for file rule editing stuff
		Gtk.Box fileRuleEditBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 2);

		Gtk.Label lblFileNameContains = this.createLabelLeftAlign("File name contains (such as a key word or file extention)");
		fileRuleEditBox.pack_start(lblFileNameContains, false, true, 2);

		this.txtFileNameContains = new Gtk.Entry();
		fileRuleEditBox.pack_start(txtFileNameContains, false, true, 2);

		Gtk.Label lblMoveFileTo = this.createLabelLeftAlign("Move file to...");
		fileRuleEditBox.pack_start(lblMoveFileTo, false, true, 2);

		// File Rule Destination box
		Gtk.Box fileRuleDestBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		
		this.txtFileRuleDest = new Gtk.Entry();
		fileRuleDestBox.pack_start(txtFileRuleDest, true, true, 0);

		this.btnChangeFileRuleDest = new Gtk.Button.from_stock(Gtk.Stock.OPEN);
		btnChangeFileRuleDest.clicked.connect(this.btnChangeFileRuleDestClicked);
		fileRuleDestBox.pack_start(btnChangeFileRuleDest, false, true, 2);

		fileRuleEditBox.pack_start(fileRuleDestBox, false, true, 0);

		// Add and Remove File Rule buttons
		Gtk.Box fileRuleButtonsBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
		Gtk.Button btnRemoveFileRule = new Button.with_label("Remove");
		btnRemoveFileRule.clicked.connect(this.btnRemoveFileRuleClicked);
		Gtk.Button btnSaveFileRule = new Button.with_label("Save");
		btnSaveFileRule.clicked.connect(this.btnSaveFileRuleClicked);

		fileRuleButtonsBox.pack_start(btnRemoveFileRule, false, true, 0);
		fileRuleButtonsBox.pack_start(btnSaveFileRule, false, true, 0);

		fileRuleEditBox.pack_start(fileRuleButtonsBox, true, true, 0);


		fileRulesBox.pack_start(fileRuleEditBox, false, true, 2);

		mainBox.pack_start(fileRulesBox, false, true, 2);

		// Pack containerBox and put that in the window
		Gtk.Box containerBox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

		containerBox.pack_start(leftSideBox, false, true, 4);
		containerBox.pack_start(mainBox, true, true, 4);
		
		window.add(containerBox);

		this.disableControls();
		
		window.show_all();
	}

	/**
	 * Setup the monitored directories listview with ListStore and signals.
	 */
	private void setupMonitoredDirsListView() {
		var listmodel = new ListStore(1, typeof (string));
		this.tvMonitoredDirs.model = listmodel;

		var treeSelection = this.tvMonitoredDirs.get_selection();
		treeSelection.set_mode(SelectionMode.SINGLE);
		treeSelection.changed.connect(() => {
			this.monitoredDirSelected();
		});

		this.loadMonitoredDirsView();
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
			this.fileExtRuleSelected();
		});
	}

	private Label createLabelLeftAlign(string? text) {
		var label = new Gtk.Label(text);
		label.xalign = 0;
		return label;
	}

	/**
	 * Load the user's File Extension Rules.
	 */
	private void loadFileExtRulesTreeView() {
		Zystem.debug("Loading FileExtRule TreeView...");
		
		var listmodel = this.tvFileRules.model as ListStore;

		listmodel.clear();
		fileExtList = new GLib.List<string>();

		TreeIter iter;

		// Get file extension rules settings and add them
		ArrayList<DfRule> rules = UserData.getFileRules(currentMonitoredDir);
		
		foreach (DfRule rule in rules) {
			listmodel.append(out iter);
			listmodel.set(iter, 0, rule.criteriaString);
			fileExtList.append(rule.criteriaString);
		}
	}

	/**
	 * Load the Monitored Directories TreeView.
	 */
	private void loadMonitoredDirsView() {
		var listmodel = this.tvMonitoredDirs.model as ListStore;

		listmodel.clear();
		monitoredDirsList = new GLib.List<string>();

		TreeIter iter;

		// Get directories and add them
		ArrayList<MonitoredDirectory> monitoredDirs = UserData.getMonitoredDirs();

		foreach (MonitoredDirectory dir in monitoredDirs) {
			listmodel.append(out iter);
			listmodel.set(iter, 0, dir.dirPath);
			monitoredDirsList.append(dir.dirPath);
		}

		this.disableControls();
	}

	/**
	 * 
	 */
	private void loadDfTypeOption() {
		// Get dfType option
		string dfType = UserData.getDfType(currentMonitoredDir);

		if (dfType == UserData.dfTypeDaily) {
			this.rdoDaily.activate();
		} else if (dfType == UserData.dfTypeWeekly) {
			this.rdoWeekly.activate();
		} else if (dfType == UserData.dfTypeMonthly) {
			this.rdoMonthly.activate();
		}
	}

	/**
	 * End program.
	 */
	private void exitDayFolder() {
		Gtk.main_quit();
	}

	/**
	 * 
	 */
	public void btnSaveFileRuleClicked() {
		UserData.addFileRule(currentMonitoredDir, this.txtFileNameContains.text, this.txtFileRuleDest.text);
		this.txtFileNameContains.text = "";
		this.txtFileRuleDest.text = "";
		loadFileExtRulesTreeView();
	}

	/**
	 * 
	 */
	public void btnChangeFileRuleDestClicked() {
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

	/**
	 * Closing a dialog.
	 */
	public void on_destroy (Widget window){
		// Nothing to do
	}

	/**
	 * 
	 */
	public void btnDfRootPathClicked(Button chooser) {
		
		var window = this.window;
		
		var fileChooser = new FileChooserDialog("Open File", window,
		                                        FileChooserAction.SELECT_FOLDER,
		                                        Stock.CANCEL, ResponseType.CANCEL,
		                                        Stock.OPEN, ResponseType.ACCEPT);
		if (fileChooser.run() == ResponseType.ACCEPT) {
			string path = fileChooser.get_filename();
			UserData.setDfRootPath(currentMonitoredDir, path);
			this.lblDfLocationDisplay.label = path;
		}
		fileChooser.destroy();
	}

	/**
	 * 
	 */
	public void btnRemoveFileRuleClicked() {
		string fileCriteriaString = getSelectedFileExt();

		UserData.removeFileRule(currentMonitoredDir, fileCriteriaString);

		this.txtFileNameContains.text = "";
		this.txtFileRuleDest.text = "";

		// Reload the treeview
		loadFileExtRulesTreeView();
	}

	/**
	 * Remove the selected monitored directory.
	 */
	public void btnRemoveMonitoredDirClicked(Button button) {
		Zystem.debug("Removing Monitored Dir...");
		string dirPath = getSelectedMonitoredDir();

		UserData.removeMonitoredDir(dirPath);

		// Reload the treeview
		loadMonitoredDirsView();
	}

	/**
	 * When choosing Daily DayFolder.
	 */
	public void rdoDayClicked(RadioButton button) {
		Zystem.debug("Day toggled");
		if (button.get_active() && UserData.getDfType(currentMonitoredDir) != UserData.dfTypeDaily) {
			UserData.setDfType(currentMonitoredDir, UserData.dfTypeDaily);
		}
	}

	/**
	 * When choosing Weekly DayFolder.
	 */
	public void rdoWeekClicked(RadioButton button) {
		Zystem.debug("Week toggled");
		if (button.get_active() && UserData.getDfType(this.currentMonitoredDir) != UserData.dfTypeWeekly) {
			UserData.setDfType(currentMonitoredDir, UserData.dfTypeWeekly);
		}
	}

	/**
	 * When choosing Monthly DayFolder.
	 */
	public void rdoMonthClicked(RadioButton button) {
		Zystem.debug("Month toggled");
		if (button.get_active() && UserData.getDfType(this.currentMonitoredDir) != UserData.dfTypeMonthly) {
			UserData.setDfType(currentMonitoredDir, UserData.dfTypeMonthly);
		}
	}

	/**
	 * Start a new monitored dir to add to settings. This adds a blank entry 
	 * to the tree view.
	 */
	public void btnAddMonitoredDirClicked(Button button) {
		var fileChooser = new FileChooserDialog("Add Monitored Folder", this.window,
		                                        FileChooserAction.SELECT_FOLDER,
		                                        Stock.CANCEL, ResponseType.CANCEL,
		                                        Stock.OPEN, ResponseType.ACCEPT);
		if (fileChooser.run() == ResponseType.ACCEPT) {
			string path = fileChooser.get_filename();
			this.addMonitoredDir(path);
		}
		fileChooser.destroy();
	}

	/**
	 * This is the process of adding a new monitored directory.
	 */
	private void addMonitoredDir(string path) {
		// Add to TreeView
		var listmodel = this.tvMonitoredDirs.model as ListStore;

		TreeIter iter;

		listmodel.append(out iter);
		listmodel.set(iter, 0, path);

		// Add to UserData
		UserData.addMonitoredDirectory(path);

		// Reload the monitored directories TreeView
		loadMonitoredDirsView();
	}

	/**
	 * This method is connected to the signal in the code when the settings window 
	 * was created. 
	 */
	private void fileExtRuleSelected() {
		string fileExt = getSelectedFileExt();

		this.txtFileNameContains.text = fileExt;
		this.txtFileRuleDest.text = UserData.getFileRuleDest(currentMonitoredDir, fileExt);
	}

	/**
	 * Get the file extension of the currently selected FileExtRule.
	 */
	private string getSelectedFileExt() {
		string fileExt = "";

		var view = this.tvFileRules;

		int index = getSelectedFromView(view);

		if (index >= 0) {
			fileExt = fileExtList.nth_data(index);
		}

		return fileExt;
	}

	/**
	 * Called when a monitored directory is selected.
	 */
	private void monitoredDirSelected() {
		// Enable controls
		enableControls();
		
		string monDirPath = getSelectedMonitoredDir();

		if (monDirPath != "") {
			currentMonitoredDir = monDirPath;
			loadCurrentMonitoredDir();
		}
	}

	/**
	 * Return currently selected monitored directory path as string.
	 */
	private string getSelectedMonitoredDir() {
		string dirPath = "";

		var view = this.tvMonitoredDirs;

		int index = getSelectedFromView(view);

		if (index >= 0) {
			dirPath = monitoredDirsList.nth_data(index);
		}

		return dirPath;
	}

	/**
	 * 
	 */
	private void loadCurrentMonitoredDir() {
		Zystem.debug("Loading Monitored Directory: " + currentMonitoredDir);

		// Set dfType radio button
		loadDfTypeOption();

		// Set switches
		this.setSwMoveSubfolders();
		this.setSwUseDayFolder();

		// Set Source Location label text
		this.lblSrcFolderLocationDisplay.label = UserData.getSourcePath(currentMonitoredDir);

		// Set DayFolder root path label text
		this.lblDfLocationDisplay.label = UserData.getDfRootPath(currentMonitoredDir);

		// Load the FileExtRules
		loadFileExtRulesTreeView();
	}

	private void setSwUseDayFolder() {
		bool useDayFolder = UserData.getUseDayFolder(currentMonitoredDir);

		this.swUseDayFolder.active = useDayFolder;

		this.enableUseDayFolderControls(useDayFolder);
	}

	private void setSwMoveSubfolders() {
		this.swMoveSubfolders.active = UserData.getMoveDirs(currentMonitoredDir);
	}

	/**
	 * Set the Use DayFolder option for the currentMonitoredDir and set appropriate widgets disabled.
	 */
	private void swUseDayFolderClicked() {
		Zystem.debug("swUseDayFolder: " + this.swUseDayFolder.active.to_string());

		UserData.setUseDayFolder(currentMonitoredDir, this.swUseDayFolder.active);

		this.enableUseDayFolderControls(this.swUseDayFolder.active);
	}
	
	/**
	 * Set the MoveDirs option to the 
	 */
	private void swMoveSubfoldersClicked() {
		Zystem.debug("swMoveSubfolders: " + this.swMoveSubfolders.active.to_string());

		UserData.setMoveDirs(currentMonitoredDir, this.swMoveSubfolders.active);
	}

	/**
	 * Return index value of currently selected item in passed in TreeView.
	 */
	private int getSelectedFromView(TreeView view) {
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
	 * Disable GUI controls.
	 */
	private void disableControls() {
		this.setControlsEnabled(false);
	}

	/**
	 * Enable GUI controls.
	 */
	private void enableControls() {
		this.setControlsEnabled(true);
	}

	/**
	 * Sets GUI widgets enabled value.
	 */
	private void setControlsEnabled(bool enabled) {
		var widgetList = getSettingsWidgets();

		foreach (Widget w in widgetList) {
			w.set_sensitive(enabled);
		}
	}

	private void enableUseDayFolderControls(bool enabled) {
		var widgetList = getUseDayFolderWidgets();

		foreach (Widget w in widgetList) {
			w.set_sensitive(enabled);
		}
	}

	private ArrayList<Widget> getUseDayFolderWidgets() {
		var widgetList = new ArrayList<Widget>();

		widgetList.add(this.btnChangeDfLocation);
		widgetList.add(this.swMoveSubfolders);
		widgetList.add(this.rdoDaily);
		widgetList.add(this.rdoWeekly);
		widgetList.add(this.rdoMonthly);
		widgetList.add(this.lblDfLocationDisplay);
		widgetList.add(this.lblSubfoldersOption);
		widgetList.add(this.lblDfTypeHeading);

		return widgetList;
	}

	/**
	 * Return list of widgets to disable or enable.
	 */
	private ArrayList<Widget> getSettingsWidgets() {
		var widgetList = new ArrayList<Widget>();

		widgetList.add(this.swUseDayFolder);
		widgetList.add(this.btnChangeDfLocation);
		widgetList.add(this.swMoveSubfolders);
		widgetList.add(this.rdoDaily);
		widgetList.add(this.rdoWeekly);
		widgetList.add(this.rdoMonthly);
		widgetList.add(this.btnChangeFileRuleDest);
		widgetList.add(this.txtFileNameContains);
		widgetList.add(this.txtFileRuleDest);

		return widgetList;
	}

	/** ************************************************* */

	/**
	 * Main method.
	 */
	static int main(string[] args) {
		Gtk.init(ref args);
		
		var app = new Main();
		
		return 0;
	}
}
