class Const { //}
	public static var WID = Std.int(flash.Lib.current.stage.stageWidth);
	public static var HEI = Std.int(flash.Lib.current.stage.stageHeight);
	public static var UPSCALE = 3;
	public static var GRID = 10;
	
	public static var LEVELS = 8;
	
	private static var uniq = 0;
	public static var DP_BG = uniq++;
	public static var DP_ENTITY = uniq++;
	public static var DP_LAVA = uniq++;
	public static var DP_FRONT = uniq++;
	public static var DP_FX = uniq++;
	public static var DP_INTERF = uniq++;
	public static var DP_MASK = uniq++;
}
