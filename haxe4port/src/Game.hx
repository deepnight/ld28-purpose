class Game extends dn.Process {
	public static var ME : Game;

	public var input : dn.heaps.input.ControllerAccess<GameAction>;
	var controller : dn.heaps.input.Controller<GameAction>;
	public var tick = 0;
	public var fx			: Fx;

	public var level		: Level;
	public var curLevel		: Int;
	public var tiles		: dn.heaps.slib.SpriteLib;
	var mask				: h2d.Bitmap;
	var cm					: dn.Cinematic;
	var msgs				: Array<h2d.Text>;
	public var complete		: Bool;

	public function new(scene:h2d.Scene) {
		super();
		ME = this;
		msgs = [];
		complete = false;

		createRoot(scene);
		controller = dn.heaps.input.Controller.createFromAbstractEnum(GameAction);
		controller.bindKeyboard(Left, hxd.Key.LEFT);
		controller.bindKeyboard(Right, hxd.Key.RIGHT);
		controller.bindKeyboard(Jump, hxd.Key.UP);
		controller.bindKeyboard(Switch, hxd.Key.SPACE);
		controller.bindKeyboard(Restart, [hxd.Key.ESCAPE, hxd.Key.R]);
		controller.bindKeyboard(Next, hxd.Key.N);
		input = controller.createAccess();
		fx = new Fx();
		cm = new dn.Cinematic(Const.FPS);
		tiles = new dn.heaps.slib.SpriteLib([hxd.Res.tiles.toTile()]);
		tiles.setSliceGrid(20,20);
		tiles.sliceGrid("ground", 0, 0,0, 8);
		tiles.sliceGrid("plant", 0, 0,2, 2);
		tiles.slice("branch", 0, 40,40, 10,20, 3);
		tiles.slice("leaf", 0, 70,40, 20,20, 3);
		tiles.sliceGrid("heroHappy", 0, 0,3, 2);
		tiles.defineAnim("heroHappy", "0(55), 1(3)");
		tiles.sliceGrid("heroSad", 0, 2,3, 2);
		tiles.defineAnim("heroSad", "0(61), 1(3)");

		tiles.setSliceGrid(10,10);
		tiles.sliceGrid("lava", 0, 0,8);
		tiles.sliceGrid("water", 0, 1,8);
		tiles.sliceGrid("crate", 0, 2,8);

		mask = new h2d.Bitmap(h2d.Tile.fromColor(0, Const.WID, Const.HEI));
		root.add(mask, Const.DP_MASK);
		fadeIn();

		level = new Level();
		curLevel = 0;
		startLevel(curLevel);
	}

	public function fadeOut(?cb:Void->Void) {
		tw.terminateWithoutCallbacks(mask.alpha);
		mask.alpha = 0;
		mask.visible = true;
		tw.createMs(mask.alpha, 1, #if debug 200 #else 2000 #end).onEnd = function() { if( cb!=null ) cb(); };
	}

	public function fadeIn() {
		tw.terminateWithoutCallbacks(mask.alpha);
		mask.visible = true;
		mask.alpha = 1;
		tw.createMs(mask.alpha, 0, #if debug 150 #else 1500 #end).onEnd = function() {
			mask.visible = false;
		}
	}

	public function clearMsgs() {
		for(tf in msgs)
			tw.createMs(tf.alpha, 0, 500).onEnd = function() {
				tf.remove();
			}
		msgs = [];
	}

	public function startLevel(n:Int) {
		if( n<0 || n>=Const.LEVELS ) throw "Invalid level: "+n;
		complete = false;
		cm.cancelEverything();
		delayer.cancelEverything();
		for(tf in msgs) tf.remove();
		msgs = [];
		tw.destroy();
		tw = new dn.Tweenie(Const.FPS);
		fadeIn();
		fx.clear();

		curLevel = n;
		switch(curLevel) {
			case 0 :
				cm.create({
					1500; addMsg("\"Purpose\"");
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

		if( en.Hero.ALL.length>0 ) en.Hero.ALL[0].activate();

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
			dn.Process.callAtTheBeginningOfNextFrame(function() startLevel(curLevel));
		});
	}

	public function restartLevel() {
		startLevel(curLevel);
	}

	public function levelComplete(?fast=false) {
		if( complete )
			return;

		cm.cancelEverything();
		complete = true;
		clearMsgs();
		if( fast )
			nextLevel();
		else
			delayer.addMs( nextLevel, 3500 );
	}

	public function createField(str:String, col=0xFFFFFF) {
		var tf = new h2d.Text(hxd.Res.font.toFont());
		tf.text = str;
		tf.textColor = col;
		return tf;
	}

	public function addMsg(str:String) {
		var tf = createField(str, 0xA0FF42);
		root.add(tf, Const.DP_INTERF);
		tf.filter = new render.SoftGlow(0x4F9D00,0.5,2);
		tf.alpha = 0;
		tf.x = Const.WID - tf.textWidth - 20 - msgs.length*3;
		tf.y = 20 + msgs.length*12;
		tw.createMs(tf.alpha, 1, 2500);
		msgs.push(tf);
	}

	public function instruction(str:String) {
		var tf = createField(str, 0x1E303E);
		root.add(tf, Const.DP_INTERF);
		tf.alpha = 0;
		tf.x = 10;
		tf.y = Const.HEI-tf.textHeight-10;
		tw.createMs(tf.alpha, 1, 2500);
		msgs.push(tf);
	}

	override function onDispose() {
		while( Entity.ALL.length>0 )
			Entity.ALL[0].destroyImmediately();
		controller.dispose();
		fx.destroy();
		cm.destroy();
		level.destroy();
		mask.tile.dispose();
		tiles.destroy();
		super.onDispose();
	}

	override function update() {
		tiles.tmod = tmod;
		cm.update(tmod);
		if( en.Hero.ALL.length>0 && input.isPressed(Switch) )
			en.Hero.activateNext();
		if( !complete && input.isPressed(Restart) )
			restartLevel();
		#if debug
		if( input.isPressed(Next) && !complete ) levelComplete(true);
		#end
	}

	override function fixedUpdate() {
		tick++;
		for(e in Entity.ALL)
			if( !e.destroyed ) e.update();
		while( Entity.TO_KILL.length>0 )
			Entity.TO_KILL[0].unregister();
		fx.darkness();
		fx.update();
	}
}
