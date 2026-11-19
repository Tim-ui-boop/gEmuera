using Godot;

/// <summary>
/// 屏幕方向锁定开关（user://settings.cfg [Display] 段，APK 可写）。
/// LockLandscape 为 true 时把应用锁定为横屏（SensorLandscape：随重力在左右横屏间切换，
/// 但永不进入竖屏）；false 时保持 Godot 的 Sensor 行为，随系统自由旋转。
/// 仅在 Android 生效；桌面端保持原样。
/// </summary>
public static class ScreenOrientationSettings
{
	public const string SettingsPath = "user://settings.cfg";
	public const string SettingsSection = "Display";
	public const string LockLandscapeKey = "LockLandscape";

	static bool? lockLandscape;

	public static bool LockLandscape
	{
		get
		{
			if (lockLandscape == null)
				lockLandscape = Load();
			return lockLandscape.Value;
		}
		set
		{
			lockLandscape = value;
			Save(value);
			Apply();
		}
	}

	/// <summary>把当前设置应用到系统方向请求。失败只告警，绝不抛出。</summary>
	public static void Apply()
	{
		if (OS.GetName() != "Android")
			return;
		try
		{
			DisplayServer.ScreenSetOrientation(LockLandscape
				? DisplayServer.ScreenOrientation.SensorLandscape
				: DisplayServer.ScreenOrientation.Sensor);
		}
		catch (System.Exception ex)
		{
			GD.PushWarning("[ORIENTATION] apply failed -> " + ex.GetType().Name + ": " + ex.Message);
		}
	}

	static bool Load()
	{
		var cfg = new ConfigFile();
		cfg.Load(SettingsPath);
		return (bool)cfg.GetValue(SettingsSection, LockLandscapeKey, false);
	}

	static void Save(bool value)
	{
		var cfg = new ConfigFile();
		cfg.Load(SettingsPath);
		cfg.SetValue(SettingsSection, LockLandscapeKey, value);
		cfg.Save(SettingsPath);
	}
}
