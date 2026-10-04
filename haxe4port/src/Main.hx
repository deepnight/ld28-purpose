class Main extends hxd.App {
	public static var ME : Main;
	public var game : Game;
	var gameScene : h2d.Scene;
	var frame : h3d.mat.Texture;
	var display : h2d.Bitmap;
	var mosaic : render.Mosaic;
	var elapsed = 0.;

	static function main() {
		hxd.Res.initEmbed();
		hxd.Timer.wantedFPS = Const.FPS;
		new Main();
	}

	override function init() {
		ME = this;
		engine.backgroundColor = 0xFF000000;
		// Apply filters at the original 200x200 resolution before nearest-neighbor scaling.
		gameScene = new h2d.Scene();
		gameScene.scaleMode = Fixed(Const.WID,Const.HEI,1,Left,Top);
		gameScene.defaultSmooth = false;
		frame = new h3d.mat.Texture(Const.WID,Const.HEI,[Target]);
		frame.filter = Nearest;
		display = new h2d.Bitmap(h2d.Tile.fromTexture(frame),s2d);
		display.smooth = false;
		mosaic = new render.Mosaic();
		display.filter = mosaic;
		game = new Game(gameScene);
		resizeDisplay();
	}

	function resizeDisplay() {
		if( display==null ) return;
		var scale = M.imin(Const.UPSCALE,dn.heaps.Scaler.bestFit_i(Const.WID,Const.HEI,engine.width,engine.height));
		display.setScale(scale);
		display.x = Math.floor((engine.width-Const.WID*scale)*0.5);
		display.y = Math.floor((engine.height-Const.HEI*scale)*0.5);
		mosaic.resize(scale,Const.WID*scale,Const.HEI*scale);
	}

	override function update(dt:Float) {
		elapsed = Math.min(dt,0.1);
		dn.Process.updateAll(elapsed*Const.FPS);
	}

	override function render(e:h3d.Engine) {
		gameScene.syncOnly(elapsed);
		frame.clear(0,1);
		// drawTo() during App.render does not begin a new scene context every frame.
		// Reset the texture cache each frame so filter targets can be reused.
		@:privateAccess gameScene.ctx.begin();
		game.root.drawTo(frame);
		@:privateAccess gameScene.ctx.end();
		s2d.render(e);
	}

	override function onResize() {
		super.onResize();
		resizeDisplay();
		dn.Process.resizeAll();
	}
}
