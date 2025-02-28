class_name PankuConsole extends CanvasLayer
# `console.gd` is a global singleton that provides all modules with a common interface
# you can also use some of its members to interact with the console
 
signal interactive_shell_visibility_changed(visible:bool)
signal new_expression_entered(expression:String, result)
signal new_notification_created(bbcode:String)
signal toggle_console_action_just_pressed()

const SingletonName = "Panku"
const SingletonPath = "/root/" + SingletonName

# create_data_controller(objs:Array[Object]) -> PankuLynxWindow
var create_data_controller_window:Callable = func(objs:Array): return null

var windows_manager:PankuLynxWindowsManager
var module_manager:PankuModuleManager = PankuModuleManager.new()
var gd_exprenv:PankuGDExprEnv = PankuGDExprEnv.new()

# generate a notification, the notification may be displayed in the console or in the game depending on the module's implementation
func notify(any) -> void:
	var text = str(any)
	new_notification_created.emit(text)

func _init():
	if not InputMap.has_action("toggle_console"):
		InputMap.add_action("toggle_console")
		var default_open_console_event = InputEventKey.new()
		default_open_console_event.physical_keycode = KEY_QUOTELEFT
		InputMap.action_add_event("toggle_console", default_open_console_event)

func _input(_e):
	# change this to your own action, by default it is `toggle_console`(KEY_QUOTELEFT)
	if Input.is_action_just_pressed("toggle_console"):
		toggle_console_action_just_pressed.emit()

func _ready():
	assert(get_tree().current_scene != self, "Do not run console.tscn as a scene!")

	windows_manager = $LynxWindowsManager
	var base_instance = preload("./common/repl_base_instance.gd").new()
	base_instance._core = self
	gd_exprenv.set_base_instance(base_instance)

	# since panku console servers numerous purposes
	# we use a module system to manage all different features
	# modules are invisible to each other by design to avoid coupling
	# you can add or remove any modules here as you wish
	var modules:Array[PankuModule] = [
		PankuModuleNativeLogger.new(),
		PankuModuleScreenNotifier.new(),
		PankuModuleSystemReport.new(),
		PankuModuleHistoryManager.new(),
		PankuModuleEngineTools.new(),
		PankuModuleKeyboardShortcuts.new(),
		PankuModuleCheckLatestRelease.new(),
		PankuModuleInteractiveShell.new(),
		PankuModuleGeneralSettings.new(),
		PankuModuleDataController.new(),
		PankuModuleScreenCrtEffect.new(),
		PankuModuleExpressionMonitor.new(),
		PankuModuleTextureViewer.new(),
		PankuModuleVariableTracker.new(),
	]
	module_manager.init_manager(self, modules)

func _notification(what):
	# quit event
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		module_manager.quit_modules()
