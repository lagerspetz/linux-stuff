/* -*- mode: js2; js2-basic-offset: 4; indent-tabs-mode: nil -*- */

const Clutter = imports.gi.Clutter;
const Pango = imports.gi.Pango;
const GLib = imports.gi.GLib;
const Gio = imports.gi.Gio;
const Gtk = imports.gi.Gtk;
const Shell = imports.gi.Shell;
const Lang = imports.lang;
const Signals = imports.signals;
const St = imports.gi.St;
const Mainloop = imports.mainloop;

const AppFavorites = imports.ui.appFavorites;
const DND = imports.ui.dnd;
const Main = imports.ui.main;
const Overview = imports.ui.overview;
const PopupMenu = imports.ui.popupMenu;
const Search = imports.ui.search;
const Tweener = imports.ui.tweener;
const Workspace = imports.ui.workspace;
const AppDisplay = imports.ui.appDisplay;
const AltTab = imports.ui.altTab;

const Gettext = imports.gettext.domain('gnome-shell-extensions');
const _ = Gettext.gettext;

//hide
//const autohide_animation_time = 0.3;

// Keep enums in sync with GSettings schemas
const PositionMode = {
    LEFT: 0,
    RIGHT: 1
};

const AutoHideEffect = {
    RESIZE: 0,
    RESCALE: 1,
    MOVE: 2
};

// Settings
const DOCK_POSITION = PositionMode.LEFT;
const DOCK_SIZE = 48;
const DOCK_AUTOHIDE = true;
const DOCK_EFFECTHIDE = AutoHideEffect.MOVE;
const DOCK_AUTOHIDE_ANIMATION_TIME = 0.3;
// Do not change anything below this line (it is intentionally duplicate to keep in
// sync with master branch)

let position = PositionMode.LEFT;
let dockicon_size = 48;
let hideable = true;
let hideDock = true;
let hideEffect = AutoHideEffect.RESIZE;
let autohide_animation_time = 0.3;
const DND_RAISE_APP_TIMEOUT = 500;

/*************************************************************************************/
/**** start resize's Dock functions                                  *****************/
/*************************************************************************************/
function hideDock_size () {
    if (hideable){
       let monitor = Main.layoutManager.primaryMonitor
       let position_x = monitor.x;
       let height = (this._nicons)*(this._item_size + this._spacing) + 2*this._spacing;
       let width = this._item_size + 4*this._spacing;

       Tweener.addTween(this,{
              _item_size: 1,
              time: autohide_animation_time,
              transition: 'easeOutQuad',
              onUpdate: function () {
                   height = (this._nicons)*(this._item_size + this._spacing) + 2*this._spacing;
                   width = this._item_size + 4*this._spacing;
                   switch (position) {
                       case PositionMode.LEFT:
                              position_x=monitor.x-2*this._spacing;
                              break;
                       case PositionMode.RIGHT:
                       default:
                              position_x = monitor.x + (monitor.width-1-this._item_size-2*this._spacing);
                   }
                   this.actor.set_position (position_x,monitor.y+(monitor.height-height)/2);
                   this.actor.set_size(width,height);
              },
       });
       hideDock=true;
    }
}

function showDock_size () {
     let monitor = Main.layoutManager.primaryMonitor;
     let height = (this._nicons)*(this._item_size + this._spacing) + 2*this._spacing;
     let width = this._item_size + 4*this._spacing;
     let position_x = monitor.x;

     Tweener.addTween(this,{
             _item_size: dockicon_size,
             time: autohide_animation_time,
             transition: 'easeOutQuad',
             onUpdate: function () {
                height = (this._nicons)*(this._item_size + this._spacing) + 2*this._spacing;
                width = this._item_size + 4*this._spacing;
                switch (position) {
                   case PositionMode.LEFT:
                      position_x=monitor.x-2*this._spacing;
                      break;
                   case PositionMode.RIGHT:
                   default:
                      position_x=monitor.x + (monitor.width-this._item_size-2*this._spacing);
                }
                this.actor.set_position (position_x, monitor.y+(monitor.height-height)/2);
                this.actor.set_size(width,height);
             }
     });
     hideDock=false;
}

function initShowDock_size () {
        this._item_size=1;
        this._showDock();
}

function showEffectAddItem_size () {
        let primary = Main.layoutManager.primaryMonitor;
        let height = (this._nicons)*(this._item_size + this._spacing) + 2*this._spacing;
        let width = this._item_size + 4*this._spacing;

        Tweener.addTween(this.actor, {
                y: primary.y + (primary.height-height)/2,
                height: height,
                width: width,
                time: autohide_animation_time,
                transition: 'easeOutQuad'
        });
}

/**************************************************************************************/
/**** start rescale's Dock functions                                  *****************/
/**************************************************************************************/
function hideDock_scale () {
       this._item_size = dockicon_size;
       let monitor = Main.layoutManager.primaryMonitor;
       let cornerX = 0;
       let height = this._nicons*(this._item_size + this._spacing) + 2*this._spacing;
       let width = this._item_size + 4*this._spacing;

       switch (position) {
            case PositionMode.LEFT:
                cornerX=monitor.x;
                break;
            case PositionMode.RIGHT:
            default:
                cornerX = monitor.x + monitor.width-1;
        }

        if (hideable) {
               Tweener.addTween(this.actor,{
                       y: monitor.y + (monitor.height-height)/2,
                       x: cornerX,
                       height:height,
                       width: width,
                       scale_x: 0.025,
                       time: autohide_animation_time,
                       transition: 'easeOutQuad'
                     });
               hideDock=true;
        }
}

function showDock_scale () {
        this._item_size = dockicon_size;
        let monitor = Main.layoutManager.primaryMonitor;
        let position_x = monitor.x;
        let height = this._nicons*(this._item_size + this._spacing) + 2*this._spacing;
        let width = this._item_size + 4*this._spacing;

        switch (position) {
            case PositionMode.LEFT:
                position_x=monitor.x-2*this._spacing;
                break;
            case PositionMode.RIGHT:
            default:
                 position_x=monitor.x + (monitor.width-this._item_size-2*this._spacing);
        }
        Tweener.addTween(this.actor, {
                y: monitor.y + (monitor.height-height)/2,
                x: monitor.x + position_x,
                height: height,
                width: width,
                scale_x: 1,
                time: autohide_animation_time,
                transition: 'easeOutQuad'
        });
        hideDock=false;
}

function initShowDock_scale () {
        let primary = Main.layoutManager.primaryMonitor;
        let height = this._nicons*(this._item_size + this._spacing) + 2*this._spacing;
        let width = this._item_size + 4*this._spacing;

        this.actor.set_scale (0,0);
        this.actor.set_size (width,height);

        // set the position of the dock
        switch (position) {
                case PositionMode.LEFT:
                   this.actor.x = 0;
                   // effect of creation of the dock
                   Tweener.addTween(this.actor, {
                       x: primary.x-2*this._spacing,
                       y: primary.y + (primary.height-height)/2,
                       time: autohide_animation_time * 3,
                       transition: 'easeOutQuad'
                   });
                   break;
                case PositionMode.RIGHT:
                   default:
                   this.actor.x = primary.width-1;
                   // effect of creation of the dock
                   Tweener.addTween(this.actor, {
                      x: primary.x + primary.width-this._item_size- 2*this._spacing,
                      y: primary.y + (primary.height-height)/2,
                      time: autohide_animation_time * 3,
                      transition: 'easeOutQuad'
                   });
        }
        Tweener.addTween(this.actor,{
           scale_x: 1,
           scale_y: 1,
           time: autohide_animation_time * 3,
           transition: 'easeOutQuad'
        });
        hideDock=false;
}

function showEffectAddItem_scale () {
        let monitor = Main.layoutManager.primaryMonitor;
        let height = this._nicons*(this._item_size + this._spacing) + 2*this._spacing;
        let width = this._item_size + 4*this._spacing;

        Tweener.addTween(this.actor, {
                y: monitor.y + (monitor.height-height)/2,
                height: height,
                width: width,
                time: autohide_animation_time,
                transition: 'easeOutQuad'
        });
}

/**************************************************************************************/
/**** start move Dock functions                                       *****************/
/**************************************************************************************/
function hideDock_move () {
       this._item_size = dockicon_size;
       let monitor = Main.layoutManager.primaryMonitor;
       let cornerX = 0;
       let height = this._nicons*(this._item_size + this._spacing) + 2*this._spacing;
       let width = this._item_size + 4*this._spacing;

       switch (position) {
            case PositionMode.LEFT:
                cornerX= monitor.x - width + this._spacing;
                break;
            case PositionMode.RIGHT:
            default:
                cornerX = monitor.x + monitor.width - this._spacing;
        }

        if (hideable) {
               Tweener.addTween(this.actor,{
                       x: cornerX,
                       y: monitor.y + (monitor.height - height)/2,
                       width: width,
                       height: height,
                       time: autohide_animation_time,
                       transition: 'easeOutQuad'
                     });
               hideDock=true;
        }
}

function showDock_move () {
        this._item_size = dockicon_size;
        let monitor = Main.layoutManager.primaryMonitor;
        let position_x = monitor.x;
        let height = this._nicons*(this._item_size + this._spacing) + 2*this._spacing;
        let width = this._item_size + 4*this._spacing;

        switch (position) {
            case PositionMode.LEFT:
                position_x=monitor.x - 2*this._spacing;
                break;
            case PositionMode.RIGHT:
            default:
                 position_x=monitor.x + (monitor.width-this._item_size-2*this._spacing);
        }
        Tweener.addTween(this.actor, {
                x: position_x,
                y: monitor.y + (monitor.height - height)/2,
                width: width,
                height: height,
                time: autohide_animation_time,
                transition: 'easeOutQuad'
        });
        hideDock=false;
}

function initShowDock_move () {
    this._showDock();
}

function showEffectAddItem_move () {
        let monitor = Main.layoutManager.primaryMonitor;
        let height = this._nicons*(this._item_size + this._spacing) + 2*this._spacing;
        let width = this._item_size + 4*this._spacing;

        Tweener.addTween(this.actor, {
                y: monitor.y + (monitor.height-height)/2,
                height: height,
                width: width,
                time: autohide_animation_time,
                transition: 'easeOutQuad'
        });
}

function Dock() {
    this._init();
}

Dock.prototype = {
    _init : function() {
        this._placeholderText = null;
        this._menus = [];
        this._menuDisplays = [];

        this._favorites = [];

        // Load Settings
        position = DOCK_POSITION;
        dockicon_size = DOCK_SIZE;
        hideDock = hideable = DOCK_AUTOHIDE;
        hideEffect = DOCK_EFFECTHIDE;
        autohide_animation_time = DOCK_AUTOHIDE_ANIMATION_TIME;

        this._spacing = 4;
        this._item_size = dockicon_size;
        this._nicons = 0;
        this._selectFunctionsHide ();

        this.actor = new St.BoxLayout({ name: 'dock', vertical: true, reactive: true });

        this._grid = new Shell.GenericContainer();
        this.actor.add(this._grid, { expand: true, y_align: St.Align.START });
        this.actor.connect('style-changed', Lang.bind(this, this._onStyleChanged));

        this._grid.connect('get-preferred-width', Lang.bind(this, this._getPreferredWidth));
        this._grid.connect('get-preferred-height', Lang.bind(this, this._getPreferredHeight));
        this._grid.connect('allocate', Lang.bind(this, this._allocate));

        this._workId = Main.initializeDeferredWork(this.actor, Lang.bind(this, this._redisplay));

        this._tracker = Shell.WindowTracker.get_default();
        this._appSystem = Shell.AppSystem.get_default();

        this._installedChangedId = this._appSystem.connect('installed-changed', Lang.bind(this, this._queueRedisplay));
        this._appFavoritesChangedId = AppFavorites.getAppFavorites().connect('changed', Lang.bind(this, this._queueRedisplay));
        this._appStateChangedId = this._appSystem.connect('app-state-changed', Lang.bind(this, this._queueRedisplay));

        this._overviewShowingId = Main.overview.connect('showing', Lang.bind(this, function() {
            this.actor.hide();
        }));
        this._overviewHiddenId = Main.overview.connect('hidden', Lang.bind(this, function() {
            this.actor.show();
        }));
        Main.layoutManager.addChrome(this.actor, { affectsStruts: !DOCK_AUTOHIDE });

        this._leave_event = this.actor.connect('leave-event', Lang.bind(this, this._hideDock));
        this._enter_event = this.actor.connect('enter-event', Lang.bind(this, this._showDock));

        this._hideDock();
    },

    destroy: function() {
        if (this._installedChangedId) {
            this._appSystem.disconnect(this._installedChangedId);
            this._installedChangedId = 0;
        }

        if (this._appFavoritesChangedId) {
            AppFavorites.getAppFavorites().disconnect(this._appFavoritesChangedId);
            this._appFavoritesChangedId = 0;
        }

        if (this._appStateChangedId) {
            this._appSystem.disconnect(this._appStateChangedId);
            this._appStateChangedId = 0;
        }

        if (this._overviewShowingId) {
            Main.overview.disconnect(this._overviewShowingId);
            this._overviewShowingId = 0;
        }

        if (this._overviewHiddenId) {
            Main.overview.disconnect(this._overviewHiddenId);
            this._overviewHiddenId = 0;
        }

        this.actor.destroy();

        // Break reference cycles
        this._appSystem = null;
        this._tracker = null;
    },

    // fuctions hide
    _restoreHideDock: function(){
        hideable = DOCK_AUTOHIDE;
    },

    _disableHideDock: function (){
        hideable = false;
    },

    _selectFunctionsHide: function () {
        switch (hideEffect) {
        case AutoHideEffect.RESCALE:
            this._hideDock = hideDock_scale;
            this._showDock = showDock_scale;
            this._initShowDock = initShowDock_scale;
            this._showEffectAddItem = showEffectAddItem_scale;
            break;
        case AutoHideEffect.MOVE:
            this._hideDock = hideDock_move;
            this._showDock = showDock_move;
            this._initShowDock = initShowDock_move;
            this._showEffectAddItem = showEffectAddItem_move;
            break;
        case AutoHideEffect.RESIZE:
        default:
            this._hideDock = hideDock_size;
            this._showDock = showDock_size;
            this._initShowDock = initShowDock_size;
            this._showEffectAddItem = showEffectAddItem_size;
        }
    },

    _appIdListToHash: function(apps) {
        let ids = {};
        for (let i = 0; i < apps.length; i++)
            ids[apps[i].get_id()] = apps[i];
        return ids;
    },

    _queueRedisplay: function () {
        Main.queueDeferredWork(this._workId);
    },

    _redisplay: function () {
        this.removeAll();

        let favorites = AppFavorites.getAppFavorites().getFavoriteMap();

        let running = this._appSystem.get_running();
        let runningIds = this._appIdListToHash(running);

        let icons = 0;

        let nFavorites = 0;
        for (let id in favorites) {
            let app = favorites[id];
            let display = new DockIcon(app,this);
            this.addItem(display.actor);
            nFavorites++;
            icons++;
        }

        for (let i = 0; i < running.length; i++) {
            let app = running[i];
            if (app.get_id() in favorites)
                continue;
            let display = new DockIcon(app,this);
            icons++;
            this.addItem(display.actor);
        }
        this._nicons=icons;

        if (this._placeholderText) {
            this._placeholderText.destroy();
            this._placeholderText = null;
        }

        if (running.length == 0 && nFavorites == 0) {
            this._placeholderText = new St.Label({ text: _("Drag here to add favorites") });
            this.actor.add_actor(this._placeholderText);
        }

        let primary = Main.layoutManager.primaryMonitor;
        let height = (icons)*(this._item_size + this._spacing) + 2*this._spacing;
        let width = this._item_size + 4*this._spacing;

        if (this.actor.y != primary.y) {
                if (hideable && hideDock) {
                        this._hideDock();
                } else {
                   if (dockicon_size == this._item_size) {
                        // only add/delete icon
                        this._showEffectAddItem ();
                    } else {
                        // change size icon
                        this._showDock ();
                    }
                }
        } else {
                // effect of creation
                this._initShowDock ();
        }
    },

    _getPreferredWidth: function (grid, forHeight, alloc) {
        alloc.min_size = this._item_size;
        alloc.natural_size = this._item_size + this._spacing;
    },

    _getPreferredHeight: function (grid, forWidth, alloc) {
        let children = this._grid.get_children();
        let nRows = children.length;
        let totalSpacing = Math.max(0, nRows - 1) * this._spacing;
        let height = nRows * this._item_size + totalSpacing;
        alloc.min_size = height;
        alloc.natural_size = height;
    },

    _allocate: function (grid, box, flags) {
        let children = this._grid.get_children();

        let x = box.x1 + this._spacing;
        if (position == PositionMode.LEFT)
            x = box.x1 + 2*this._spacing;
        let y = box.y1 + this._spacing;

        for (let i = 0; i < children.length; i++) {
            let childBox = new Clutter.ActorBox();
            childBox.x1 = x;
            childBox.y1 = y;
            childBox.x2 = childBox.x1 + this._item_size;
            childBox.y2 = childBox.y1 + this._item_size;
            children[i].allocate(childBox, flags);
            y += this._item_size + this._spacing;
        }
    },


    _onStyleChanged: function() {
        let themeNode = this.actor.get_theme_node();
        let [success, len] = themeNode.get_length('spacing', false);
        if (success)
            this._spacing = len;
        [success, len] = themeNode.get_length('-shell-grid-item-size', false);
        if (success)
            this._item_size = len;
        this._grid.queue_relayout();
    },

    removeAll: function () {
        this._grid.get_children().forEach(Lang.bind(this, function (child) {
            child.destroy();
        }));
    },

    addItem: function(actor) {
        this._grid.add_actor(actor);
    }
};
Signals.addSignalMethods(Dock.prototype);

function DockIcon(app, dock) {
    this._init(app, dock);
}

DockIcon.prototype = {
    _init : function(app, dock) {
        this.app = app;
        this.actor = new St.Button({ style_class: 'dock-app',
                                     button_mask: St.ButtonMask.ONE | St.ButtonMask.TWO,
                                     reactive: true,
                                     x_fill: true,
                                     y_fill: true });
        this.actor._delegate = this;
        this.actor.set_size(dockicon_size, dockicon_size);

        this._icon = this.app.create_icon_texture(dockicon_size);
        this.actor.set_child(this._icon);

        this.actor.connect('clicked', Lang.bind(this, this._onClicked));

        this._menu = null;
        this._menuManager = new PopupMenu.PopupMenuManager(this);

        this._has_focus = false;

        let tracker = Shell.WindowTracker.get_default();
        tracker.connect('notify::focus-app', Lang.bind(this, this._onStateChanged));

        this.actor.connect('button-press-event', Lang.bind(this, this._onButtonPress));
        this.actor.connect('destroy', Lang.bind(this, this._onDestroy));
        this.actor.connect('notify::hover', Lang.bind(this, this._hoverChanged));

        this._menuTimeoutId = 0;
        this._stateChangedId = this.app.connect('notify::state',
                                                Lang.bind(this, this._onStateChanged));
        this._onStateChanged();
        this._dock=dock;
    },

    _onDestroy: function() {
        if (this._stateChangedId > 0)
            this.app.disconnect(this._stateChangedId);
        this._stateChangedId = 0;
        this._removeMenuTimeout();
    },

    _removeMenuTimeout: function() {
        if (this._menuTimeoutId > 0) {
            Mainloop.source_remove(this._menuTimeoutId);
            this._menuTimeoutId = 0;
        }
    },

    _hoverChanged: function(actor) {
        if (actor != this.actor)
            this._has_focus = false;
        else
            this._has_focus = true;
        return false;
    },

    _onStateChanged: function() {
        let tracker = Shell.WindowTracker.get_default();
        let focusedApp = tracker.focus_app;
        if (this.app.state != Shell.AppState.STOPPED) {
            this.actor.add_style_class_name('running');
            if (this.app == focusedApp) {
                this.actor.add_style_class_name('focused');
            } else {
                this.actor.remove_style_class_name('focused');
            }
        } else {
            this.actor.remove_style_class_name('focused');
            this.actor.remove_style_class_name('running');
        }
    },

    _onButtonPress: function(actor, event) {
        let button = event.get_button();
        if (button == 1) {
            this._removeMenuTimeout();
            this._menuTimeoutId = Mainloop.timeout_add(AppDisplay.MENU_POPUP_TIMEOUT, Lang.bind(this, function() {
                this.popupMenu();
            }));
        } else if (button == 3) {
            this.popupMenu();
        }
    },

    _onClicked: function(actor, button) {
        this._removeMenuTimeout();

        if (button == 1) {
            this._onActivate(Clutter.get_current_event());
        } else if (button == 2) {
            // Last workspace is always empty
            let launchWorkspace = global.screen.get_workspace_by_index(global.screen.n_workspaces - 1);
            launchWorkspace.activate(global.get_current_time());
            this.emit('launching');
            this.app.open_new_window(-1);
        }
        return false;
    },

    getId: function() {
        return this.app.get_id();
    },

    popupMenu: function() {
        this._removeMenuTimeout();
        this.actor.fake_release();

        this._dock._disableHideDock();

        if (!this._menu) {
            this._menu = new DockIconMenu(this);
            this._menu.connect('activate-window', Lang.bind(this, function (menu, window) {
                this.activateWindow(window);
            }));
            this._menu.connect('open-state-changed', Lang.bind(this, function (menu, isPoppedUp) {
                if (!isPoppedUp){
                    //Restore value of autohidedock
                    this._dock._restoreHideDock();
                    this._dock._hideDock();

                    this._onMenuPoppedDown();
                }
            }));

            this._menuManager.addMenu(this._menu, true);
        }

        this._menu.popup();

        return false;
    },

    activateWindow: function(metaWindow) {
        if (metaWindow) {
            this._didActivateWindow = true;
            Main.activateWindow(metaWindow);
        }
    },

    setSelected: function (isSelected) {
        this._selected = isSelected;
        if (this._selected)
            this.actor.add_style_class_name('selected');
        else
            this.actor.remove_style_class_name('selected');
    },

    _onMenuPoppedDown: function() {
        this.actor.sync_hover();
    },

    _getRunning: function() {
        return this.app.state != Shell.AppState.STOPPED;
    },

    _onActivate: function (event) {
        this.emit('launching');
        let modifiers = Shell.get_event_state(event);

        if (modifiers & Clutter.ModifierType.CONTROL_MASK
            && this.app.state == Shell.AppState.RUNNING) {
            let current_workspace = global.screen.get_active_workspace().index();
            this.app.open_new_window(current_workspace);
        } else {
            let tracker = Shell.WindowTracker.get_default();
            let focusedApp = tracker.focus_app;

            if (this.app == focusedApp) {
                let windows = this.app.get_windows();
                let nextWindow = 0;
                for (let i = 0; i < windows.length; i++) {
                    let w = windows[i];
                    if (w.has_focus())
                        nextWindow = i+1;
                }
                if (nextWindow < windows.length)
                    Main.activateWindow(windows[nextWindow]);
                else
                    Main.activateWindow(windows[0]);
            } else {
                this.app.activate(-1);
            }
        }
        Main.overview.hide();
    },

    shellWorkspaceLaunch : function() {
        this.app.open_new_window();
    }
};
Signals.addSignalMethods(DockIcon.prototype);

function DockIconMenu(source) {
    this._init(source);
}

DockIconMenu.prototype = {
    __proto__: AppDisplay.AppIconMenu.prototype,

    _init: function(source) {
        switch (position) {
            case PositionMode.LEFT:
                PopupMenu.PopupMenu.prototype._init.call(this, source.actor, St.Align.MIDDLE, St.Side.LEFT, 0);
                break;
            case PositionMode.RIGHT:
            default:
                PopupMenu.PopupMenu.prototype._init.call(this, source.actor, St.Align.MIDDLE, St.Side.RIGHT, 0);
        }

        this._source = source;

        this.connect('activate', Lang.bind(this, this._onActivate));

        this.actor.add_style_class_name('dock-menu');

        // Chain our visibility and lifecycle to that of the source
        source.actor.connect('notify::mapped', Lang.bind(this, function () {
            if (!source.actor.mapped)
                this.close();
        }));
        source.actor.connect('destroy', Lang.bind(this, function () { this.actor.destroy(); }));

        Main.layoutManager.addChrome(this.actor);
    },

    _redisplay: function() {
        this.removeAll();

        let windows = this._source.app.get_windows();

        // Display the app windows menu items and the separator between windows
        // of the current desktop and other windows.
        let activeWorkspace = global.screen.get_active_workspace();
        let separatorShown = windows.length > 0 && windows[0].get_workspace() != activeWorkspace;

        for (let i = 0; i < windows.length; i++) {
            if (!separatorShown && windows[i].get_workspace() != activeWorkspace) {
                this._appendSeparator();
                separatorShown = true;
            }
            let item = this._appendMenuItem(windows[i].title);
            item._window = windows[i];
        }

        if (windows.length > 0)
            this._appendSeparator();

        let isFavorite = AppFavorites.getAppFavorites().isFavorite(this._source.app.get_id());

        this._newWindowMenuItem = windows.length > 0 ? this._appendMenuItem(_("New Window")) : null;

        this._quitAppMenuItem = windows.length >0 ? this._appendMenuItem(_("Quit Application")) : null;

        if (windows.length > 0)
            this._appendSeparator();
        this._toggleFavoriteMenuItem = this._appendMenuItem(isFavorite ?
                                                            _("Remove from Favorites")
                                                            : _("Add to Favorites"));

        this._highlightedItem = null;
    },

    _onActivate: function (actor, child) {
        if (child._window) {
            let metaWindow = child._window;
            this.emit('activate-window', metaWindow);
        } else if (child == this._newWindowMenuItem) {
            let current_workspace = global.screen.get_active_workspace().index();
            this._source.app.open_new_window(current_workspace);
            this.emit('activate-window', null);
        } else if (child == this._quitAppMenuItem) {
            this._source.app.request_quit();
        } else if (child == this._toggleFavoriteMenuItem) {
            let favs = AppFavorites.getAppFavorites();
            let isFavorite = favs.isFavorite(this._source.app.get_id());
            if (isFavorite)
                favs.removeFavorite(this._source.app.get_id());
            else
                favs.addFavorite(this._source.app.get_id());
        }
        this.close();
    }
}

function init(extensionMeta) {
    imports.gettext.bindtextdomain('gnome-shell-extensions', GLib.build_filenamev([extensionMeta.path, 'locale']));
}

let dock;

function enable() {
    dock = new Dock();
}

function disable() {
    dock.destroy();
    dock = null;
}
