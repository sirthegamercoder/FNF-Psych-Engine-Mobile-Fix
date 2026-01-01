package debug;

import flixel.FlxG;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.utils.Assets;
import openfl.system.System as OpenFlSystem;
import lime.system.System as LimeSystem;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if cpp
#if windows
@:cppFileCode('#include <windows.h>')
#elseif (ios || mac)
@:cppFileCode('#include <mach-o/arch.h>')
#else
@:headerInclude('sys/utsname.h')
#end
#end
class FPSCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;

	@:noCompletion private var times:Array<Float>;

	private var os:String = "";
	private var timeIndex:Int = 0;
    private var timeBuffer:Array<Float> = [];

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000) {
		super();
		
		#if !officialBuild
		var platformInfo:String = LimeSystem.platformName;
		
		#if cpp
		platformInfo += ' ${getArch()}';
		#end
		
		#if debug
		platformInfo += ' (Debug)';
		#elseif release
		platformInfo += ' (Release)';
		#end
		
		os = '\nOS: $platformInfo';

		background = true;
        backgroundColor = 0x66000000;
		
		if (LimeSystem.platformVersion != null && LimeSystem.platformVersion != LimeSystem.platformName) {
			os += ' - ${LimeSystem.platformVersion}';
		}
		#end

		positionFPS(x, y);

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(Assets.getFont("assets/fonts/fps.ttf").fontName, 14, color);
		width = FlxG.width;
		multiline = true;
		text = "FPS: ";

		times = [];
        timeBuffer = [for (i in 0...FlxG.updateFramerate) 0.0];
	}

	var deltaTimeout:Float = 0.0;
	public var peakMemoryMegas(default, null):Float = 0;
    private var memoryUpdateTimer:Float = 0;

	private override function __enterFrame(deltaTime:Float):Void {
		if (deltaTimeout > 1000) {
			deltaTimeout = 0.0;
			return;
		}

		final now:Float = haxe.Timer.stamp() * 1000;

		timeBuffer[timeIndex] = now;
		timeIndex = (timeIndex + 1) % FlxG.updateFramerate;

		var count:Int = 0;
		for (i in 0...FlxG.updateFramerate) {
			if (now - timeBuffer[i] < 1000 && timeBuffer[i] > 0) {
				count++;
			}
		}

		memoryUpdateTimer += deltaTime;
		if (memoryUpdateTimer > 500) {
			memoryUpdateTimer = 0;
			if (memoryMegas > peakMemoryMegas) {
				peakMemoryMegas = memoryMegas;
			}
		}
		
		updateText();
		deltaTimeout += deltaTime;
	}

	public dynamic function updateText():Void {
		var frameTime:Float = 1000 / (currentFPS > 0 ? currentFPS : 1);
		var fpsWarning:String = "";
        var memoryWarning:String = "";

		if (currentFPS < FlxG.drawFramerate * 0.5) {
			fpsWarning = " [LOW]";
			textColor = 0xFFFF0000;
		} else if (currentFPS < FlxG.drawFramerate * 0.8) {
			fpsWarning = " [WARNING]";
			textColor = 0xFFFFFF00;
		} else {
			textColor = 0xFF00FF00;
		}

		if (memoryMegas > 1.5 * 1024 * 1024 * 1024) {
			memoryWarning = " [HIGH]";
			textColor = 0xFFFF0000;
		}
		
		text = 
		'FPS: $currentFPS$fpsWarning' + 
		'\nMemory: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}$memoryWarning' +
		os;

		textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.drawFramerate * 0.5)
			textColor = 0xFFFF0000;
		else if (currentFPS < FlxG.drawFramerate * 0.8)
			textColor = 0xFFFFFF00;
	}

	inline function get_memoryMegas():Float
		return cast(OpenFlSystem.totalMemory, UInt);

	public inline function positionFPS(X:Float, Y:Float, ?scale:Float = 1){
		scaleX = scaleY = #if android (scale > 1 ? scale : 1) #else (scale < 1 ? scale : 1) #end;
		x = FlxG.game.x + X;
		y = FlxG.game.y + Y;
	}

	public function toggle(visible:Bool):Void {
        this.visible = visible;
	}

	public function isVisible():Bool {
		return this.visible;
	}

	#if cpp
	#if windows
	@:functionCode('
		SYSTEM_INFO osInfo;

		GetSystemInfo(&osInfo);

		switch(osInfo.wProcessorArchitecture)
		{
			case 9:
				return ::String("x86_64");
			case 5:
				return ::String("ARM");
			case 12:
				return ::String("ARM64");
			case 6:
				return ::String("IA-64");
			case 0:
				return ::String("x86");
			default:
				return ::String("Unknown");
		}
	')
	#elseif (ios || mac)
	@:functionCode('
		const NXArchInfo *archInfo = NXGetLocalArchInfo();
    	return ::String(archInfo == NULL ? "Unknown" : archInfo->name);
	')
	#else
	@:functionCode('
		struct utsname osInfo{};
		uname(&osInfo);
		return ::String(osInfo.machine);
	')
	#end
	@:noCompletion
	private function getArch():String
	{
		return "Unknown";
	}
	#end
}