/**
 * 
 */

    dojo.require("dijit.Menu");

    var pMenu;
    dojo.addOnLoad(function() {
        pMenu = new dijit.Menu({
            targetNodeIds: ["prog_menu"]
        });
        pMenu.addChild(new dijit.MenuItem({
            label: "Simple menu item"
        }));
        pMenu.addChild(new dijit.MenuItem({
            label: "Disabled menu item",
            disabled: true
        }));
        pMenu.addChild(new dijit.MenuItem({
            label: "Menu Item With an icon",
            iconClass: "dijitEditorIcon dijitEditorIconCut",
            onClick: function() {
                alert('i was clicked')
            }
        }));
        pMenu.addChild(new dijit.CheckedMenuItem({
            label: "checkable menu item"
        }));
        pMenu.addChild(new dijit.MenuSeparator());

        var pSubMenu = new dijit.Menu();
        pSubMenu.addChild(new dijit.MenuItem({
            label: "Submenu item"
        }));
        pSubMenu.addChild(new dijit.MenuItem({
            label: "Submenu item"
        }));
        pMenu.addChild(new dijit.PopupMenuItem({
            label: "Submenu",
            popup: pSubMenu
        }));

        pMenu.startup();
    });
