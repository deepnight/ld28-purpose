import mt.flash.Key;
import flash.ui.Keyboard;
import flash.display.Sprite;
import mt.deepnight.Lib;
import mt.deepnight.Buffer;
import mt.deepnight.deprecated.SpriteLibBitmap;

@:bitmap("assets/tiles.png") class GfxTiles extends flash.display.BitmapData {}

class Game extends mt.deepnight.Mode { //}
	public static var ME : Game;

	public var buffer		: Buffer;
	public var fx			: Fx;

	public var level		: Level;
	public var curLevel		: Int;
	public var tiles		: SpriteLibBitmap;
	var mask				: Sprite;
	var cm					: mt.deepnight.Cinematic;
	var msgs				: Array<flash.text.TextField>;
	public var complete		: Bool;

	public function new() {
		super();
		ME = this;
		msgs = [];
		complete = false;

		fx = new Fx();
		cm = new mt.deepnight.Cinematic();

		buffer = new Buffer(200,200, Const.UPSCALE, false, 0x0);
		root.addChild(buffer.render);
		//buffer.setTexture( Buffer.makeMosaic2(Const.UPSCALE, 0xFFFFFF), 0.2, true );
		buffer.setTexture( Buffer.makeMosaic(Const.UPSCALE, 0xFFFFFF), 0.1, true );

		tiles = new SpriteLibBitmap( new GfxTiles(0,0) );
		tiles.setSliceGrid(20,20);
		tiles.sliceGrid("ground", 0,0, 8);
		tiles.sliceGrid("plant", 0,2, 2);
		tiles.slice("branch", 40,40, 10,20, 3);
		tiles.slice("leaf", 70,40, 20,20, 3);
		tiles.sliceGrid("heroHappy", 0,3, 2);
		tiles.defineAnim("0(55), 1(3)");
		tiles.sliceGrid("heroSad", 2,3, 2);
		tiles.defineAnim("0(61), 1(3)");

		tiles.setSliceGrid(10,10);
		tiles.sliceGrid("lava", 0,8);
		tiles.sliceGrid("water", 1,8);
		tiles.sliceGrid("crate", 2,8);

		mask = new Sprite();
		mask.graphics.beginFill(0x0, 1);
		mask.graphics.drawRect(0,0,buffer.width,buffer.height);
		buffer.dm.add(mask, Const.DP_MASK);
		fadeIn();

		level = new Level();
		curLevel = 0;
		#if debug
		curLevel = 8;
		#end
		startLevel(curLevel);
	}

	public function fadeOut(?cb:Void->Void) {
		tw.terminate(mask);
		mask.alpha = 0;
		mask.visible = true;
		tw.create(mask, "alpha", 1, #if debug 200 #else 2000 #end).onEnd = cb;
	}

	public function fadeIn() {
		tw.terminate(mask);
		mask.visible = true;
		mask.alpha = 1;
		tw.create(mask, "alpha", 0, #if debug 150 #else 1500 #end).onEnd = function() {
			mask.visible = false;
		}
	}

	public function clearMsgs() {
		for(tf in msgs)
			tw.create(tf, "alpha", 0, 500).onEnd = function() {
				tf.parent.removeChild(tf);
			}
		msgs = [];
	}

	public function startLevel(n:Int) {
		cm.skip();
		delayer.skip();
		clearMsgs();
		tw.terminateAll();
		fadeIn();
		mt.deepnight.Particle.clearAll();

		switch(curLevel) {
			case 0 :
				cm.create({
					1500; addMsg("\"Purpose 2\"");
					2000; instruction("Use ARROW keys to move...");
				});
			case 1 :
				cm.create({
					500; addMsg("The gift of Birth is a matter of Sacrifice");
					1000; addMsg("For One to Live,");
					1200; addMsg("One must Die.");
				});
			case 2 :
				cm.create({
					1000; addMsg("Friendship can help you climb mountains.");
					2000; addMsg("But in the end,");
					700; addMsg("Only One will succeed.");
					1000; instruction("Use SPACE to switch the active character...");
				});
			case 3 :
				cm.create({
					1000; addMsg("Time seems to pass slowly,");
					2000; addMsg("When no one cares about you.");
				});
			case 4 :
				cm.create({
					1000; addMsg("Many companions,");
					1000; addMsg("Many betrayals.");
				});
			case 7 :
				cm.create({
					2000; addMsg("Sorry, this game is unfinished");
					2000; addMsg("and was created in about 7h.");
					2000; addMsg("Special thanks to my beloved Marine");
					2000; addMsg("For her kind support :)");
					1000; instruction("Thank you for playing!");
				});

			default :
		}

		while( Entity.ALL.length>0 )
			Entity.ALL[0].destroyImmediately();


		level.setLevel(n);

		for(pt in level.getSpots("hero"))
			new en.Hero(pt.cx, pt.cy);

		en.Hero.ALL[0].activate();

		for(pt in level.getSpots("plant"))
			new en.Plant(pt.cx, pt.cy);

		for(pt in level.getSpots("crate")) {
			new en.Crate(pt.cx, pt.cy);
		}

		for(pt in level.getSpots("lava"))
			new en.Lava(pt.cx, pt.cy);

		for(pt in level.getSpots("water"))
			new en.Water(pt.cx, pt.cy);
	}

	public function nextLevel() {
		fadeOut( function() {
			curLevel++;
			if( curLevel==Const.LEVELS )
				curLevel = 0;
			complete = false;
			startLevel(curLevel);
			fadeIn();
		});
	}

	public function restartLevel() {
		startLevel(curLevel);
	}

	public function levelComplete(?fast=false) {
		if( complete )
			return;

		cm.skip();
		complete = true;
		clearMsgs();
		if( fast )
			nextLevel();
		else
			delayer.addMs( nextLevel, 3500 );
	}

	public function createField(str:Dynamic, ?fit=true, ?col=0xFFFFFF) {
		var f = new flash.text.TextFormat();
		f.font = "def";
		f.size = 8;
		f.color = col;

		var tf = new flash.text.TextField();
		tf.width = fit ? 500 : 300;
		tf.height = 50;
		tf.mouseEnabled = tf.selectable = false;
		tf.defaultTextFormat = f;
		//tf.antiAliasType = flash.text.AntiAliasType.ADVANCED;
		//tf.sharpness = 800;
		tf.embedFonts = true;
		tf.htmlText = Std.string(str);
		tf.multiline = tf.wordWrap = true;
		if( fit ) {
			tf.width = tf.textWidth+5;
			tf.height = tf.textHeight+5;
		}
		return tf;
	}

	public function addMsg(str:String) {
		var tf = createField(str, 0xA0FF42);
		buffer.dm.add(tf, Const.DP_INTERF);
		tf.filters = [ new flash.filters.GlowFilter(0x4F9D00,0.5, 4,4,1) ];
		tf.alpha = 0;
		tf.x = buffer.width - tf.textWidth - 20 - msgs.length*3;
		tf.y = 20 + msgs.length*12;
		tw.create(tf, "alpha", 1, 2500);
		msgs.push(tf);
	}

	public function instruction(str:String) {
		var tf = createField(str, 0x1E303E);
		buffer.dm.add(tf, Const.DP_INTERF);
		tf.alpha = 0;
		//tf.x = 10;
		tf.y = buffer.height-tf.height-10;
		tw.create(tf, "alpha", 1, 2500);
		msgs.push(tf);
	}

	override function destroy() {
		super.destroy();

		while( Entity.ALL.length>0 ) {
			var e = Entity.ALL[0];
			e.destroy();
			e.unregister();
		}

		tiles.destroy();
	}

	override function preUpdate() {
		super.preUpdate();
		Key.update();
	}


	override function update() {
		super.update();
		cm.update();

		// Switch
		if( en.Hero.ALL.length>0 ) {
			if( Key.isToggled(Keyboard.SPACE) )
				en.Hero.activateNext();
		}

		if( !complete && (Key.isToggled(Keyboard.ESCAPE) || Key.isToggled(Keyboard.R)) )
			restartLevel();

		#if debug
		if( Key.isToggled(Keyboard.N) )
			nextLevel();
		#end

		for(e in Entity.ALL)
			e.update();

		while( Entity.TO_KILL.length>0 )
			Entity.TO_KILL[0].unregister();

		fx.darkness();
	}

	override function postUpdate() {
		super.postUpdate();
		fx.update();
	}

	override function render() {
		super.render();
		BSprite.updateAll();
		buffer.update();
	}
}
