/*
 * Copyright (C) 2025 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package mobile.backend;

import lime.system.System as LimeSystem;
import haxe.io.Path;
import haxe.Exception;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

#if (sys && !ios)
import Sys;
#end

#if android
import mobile.android.AndroidPermissions;
import mobile.android.AndroidEnvironment;
import mobile.android.AndroidVersion;
import mobile.android.AndroidVersionCode;
import mobile.android.AndroidSettings;
#end

import mobile.utils.CoolUtil;
import mobile.utils.Language;

/**
 * A storage class for mobile.
 * @author Karim Akra and Lily Ross (mcagabe19)
 */
class StorageUtil
{
	#if sys
	public static final rootDir:String = LimeSystem.applicationStorageDirectory;
	
	#if android
	public static var curStorageType:String = "EXTERNAL";
	#end

	public static function getStorageDirectory(?force:Bool = false):String
	{
		var daPath:String = '';
		#if android
		daPath = force ? StorageType.fromStrForce(curStorageType) : StorageType.fromStr(curStorageType);
		daPath = Path.addTrailingSlash(daPath);
		#elseif ios
		daPath = LimeSystem.documentsDirectory;
		#else
		daPath = Sys.getCwd();
		#end

		return daPath;
	}

	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Void
	{
		try
		{
			var savePath:String = getStorageDirectory();
			var fullPath:String = Path.join([savePath, 'saves']);
			
			if (!FileSystem.exists(fullPath))
				FileSystem.createDirectory(fullPath);

			var filePath:String = Path.join([fullPath, fileName]);
			File.saveContent(filePath, fileData);
			
			if (alert)
				CoolUtil.showPopUp(Language.getPhrase('file_save_success', '{1} has been saved.', [fileName]), Language.getPhrase('mobile_success', "Success!"));
		}
		catch (e:Exception)
		{
			if (alert)
				CoolUtil.showPopUp(Language.getPhrase('file_save_fail', '{1} couldn\'t be saved.\n({2})', [fileName, e.message]), Language.getPhrase('mobile_error', "Error!"));
			else
				trace('$fileName couldn\'t be saved. (${e.message})');
		}
	}

	#if android
	// always force path due to haxe
	public static function getExternalStorageDirectory():String
	{
		return '/storage/emulated/0/.PsychEngine/';
	}
	
	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions(['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO']);
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		if (!AndroidEnvironment.isExternalStorageManager())
		{
			if (AndroidVersion.SDK_INT >= AndroidVersionCode.S)
				AndroidSettings.requestSetting('REQUEST_MANAGE_MEDIA');
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		}

		if ((AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU
			&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_IMAGES'))
			|| (AndroidVersion.SDK_INT < AndroidVersionCode.TIRAMISU
				&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')))
		{
			CoolUtil.showPopUp(Language.getPhrase('permissions_message', 'If you accepted the permissions you are all good!\nIf you didn\'t then expect a crash\nPress OK to see what happens'),
				Language.getPhrase('mobile_notice', "Notice!"));
		}

		try
		{
			if (!FileSystem.exists(StorageUtil.getStorageDirectory()))
				FileSystem.createDirectory(StorageUtil.getStorageDirectory());
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp('Please create directory to\n' + StorageUtil.getStorageDirectory(true) + '\nPress OK to close the game', 'Error!');
			LimeSystem.exit(1);
		}
	}

	public static function checkExternalPaths(?splitStorage:Bool = false):Array<String>
	{
		var process:Process = new Process('grep', ['-o', '/storage/....-....', '/proc/mounts']);
		var output:String = process.stdout.readAll().toString();
		process.close();
		
		var paths:String = output.replace("\n", ",");

		if (paths.endsWith(","))
			paths = paths.substr(0, paths.length - 1);
			
		if (splitStorage)
			paths = paths.replace('/storage/', '');
			
		return paths.split(',');
	}

	public static function getExternalDirectory(externalDir:String):String
	{
		var daPath:String = '';
		for (path in checkExternalPaths())
		{
			if (path.contains(externalDir))
			{
				daPath = path;
				break;
			}
		}

		daPath = Path.addTrailingSlash(daPath.endsWith("\n") ? daPath.substr(0, daPath.length - 1) : daPath);
		return daPath;
	}
	#end
	#end
}

#if android
@:runtimeValue
enum abstract StorageType(String) from String to String
{
	var EXTERNAL = "EXTERNAL";
	
	public static function fromStr(str:String):StorageType
	{
		final EXTERNAL_PATH:String = AndroidEnvironment.getExternalStorageDirectory() + '/.' + lime.app.Application.current.meta.get('file');

		return switch (str)
		{
			case "EXTERNAL": cast EXTERNAL_PATH;
			default: StorageUtil.getExternalDirectory(str) + '.' + StorageUtil.getExternalStorageDirectory();
		}
	}

	public static function fromStrForce(str:String):StorageType
	{
		final FORCED_PATH:String = '/storage/emulated/0/';
		final EXTERNAL_PATH:String = FORCED_PATH + '.' + lime.app.Application.current.meta.get('file');

		return switch (str)
		{
			case "EXTERNAL": cast EXTERNAL_PATH;
			default: StorageUtil.getExternalDirectory(str) + '.' + lime.app.Application.current.meta.get('file');
		}
	}
}
#end