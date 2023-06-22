const Applet = imports.ui.applet;
const Lang = imports.lang;
const St = imports.gi.St;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;
const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const AccountsService = imports.gi.AccountsService;
const GnomeSession = imports.misc.gnomeSession;
const ScreenSaver = imports.misc.screenSaver;
const Settings = imports.ui.settings;


const cmd1 = '/usr/bin/sh -c "ldapsearch -x -b "o=gouv,c=fr" -H ldap://172.18.0.3 "uid=$USER" -LLL displayName | sed -ne \'s/^displayName: //p\'"';

const cmd2 = '/usr/bin/sh -c "ldapsearch -x -b "o=gouv,c=fr" -H ldap://172.18.0.3 "uid=$USER" -LLL Divcode | sed -ne \'s/^Divcode: //p\'"';

class CinnamonUserApplet extends Applet.TextApplet {
    constructor(orientation, panel_height, instance_id) {
        super(orientation, panel_height, instance_id);

        this.setAllowedLayout(Applet.AllowedLayout.BOTH);

	let [res,stdout,stderr] = GLib.spawn_command_line_sync(cmd1);
	const displayName = stdout.toString().trim();
	
	this.set_applet_label(displayName);
        //this.set_applet_icon_symbolic_name("avatar-default");

    }
}

function main(metadata, orientation, panel_height, instance_id) {
    return new CinnamonUserApplet(orientation, panel_height, instance_id);
}
