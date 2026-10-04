package en;

import mt.flash.Key;
import flash.ui.Keyboard;
import dn.M;
import mt.deepnight.Lib;

class Hero extends Entity {
	public static var ALL : Array<Hero> = [];

	public var color		: Int;
	var jumpPow				: Float;
	var over				: Null<Entity>;
	var dir					: Int;
	var fakeJump			: Float;
	var offsetY				: Float;

	public function new(x,y) {
		super();
		color = 0x80FF00;
		ALL.push(this);
		setPos(x,y);
		climbable = true;

		while( !Game.ME.level.hasCollision(cx,cy+1) )
			cy++;

		dir = cx<Game.ME.level.wid*0.5 ? 1 : -1;
		isActive = false;
		jumpPow = 0;
		fakeJump = 0;
		offsetY = 0;
		radius = Const.GRID*0.5;

		spr.setGroup("heroHappy");
		spr.setCenter(0.5,0.5);
		//spr.graphics.clear();
		//spr.graphics.beginFill(color, 1);
		//spr.graphics.drawRect(-radius, -radius, radius*2, radius*2);
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	public function die() {
		Fx.ME.heroExplode(this);
		destroy();
		if( isActive && !Game.ME.complete )
			if( ALL.length>1 )
				activateNext();
			else
				Game.ME.delayer.addMs( Game.ME.restartLevel, 500 );
	}

	public static function getNext() {
		var next = false;
		for(e in ALL) {
			if( next )
				return e;

			if( e.isActive )
				next = true;
		}
		return ALL[0];
	}

	public static function activateNext() {
		var cur = getActive();
		var e = getNext();
		e.activate();
		if( cur!=null && e!=cur )
			cur.deactivate();
	}

	public static function getActive() {
		for(e in ALL)
			if( e.isActive )
				return e;
		throw "no one is active!";
	}

	public function activate() {
		if( isActive )
			return;

		weight = 0.1;
		Game.ME.buffer.dm.over(spr);
		isActive = true;
	}

	public function deactivate() {
		if( !isActive )
			return;

		weight = 1;
		isActive = false;
	}

	function project(dx,dy) {
		this.dx = dx;
		this.dy = dy;
		projected = true;
	}



	override function update() {
		if( isActive )
			tmod = 1;
		else
			tmod = ALL.length>2 ? 0.05 : 0.1;

		// Collisions with other heroes
		over = null;
		for(e in Entity.ALL) {
			if( e==this || !e.climbable )
				continue;

			// Circular collision
			var d = radius + e.radius;
			if( Lib.distanceSqr(xx,yy, e.xx,e.yy)< M.pow(d, 2) ) {
				var a = Math.atan2(e.yy-yy, e.xx-xx);
				var overlap = d - Lib.distance(xx,yy, e.xx,e.yy);
				//var wr = isActive ? 1 : (e.isActive ? 0 : 0.5);
				var wr = 1 - weight / (weight+e.weight);

				var oldX = xx;
				var oldY = yy;
				xx -= Math.cos(a) * overlap*wr;
				yy -= Math.sin(a) * overlap*wr;
				updateFromCoords();

				if( Game.ME.level.hasCollision(cx,cy) ) {
					xx = oldX;
					yy = oldY;
					updateFromCoords();
				}

				var oldX = e.xx;
				var oldY = e.yy;
				e.xx += Math.cos(a) * overlap*(1-wr);
				e.yy += Math.sin(a) * overlap*(1-wr);
				e.updateFromCoords();

				if( Game.ME.level.hasCollision(e.cx,e.cy) ) {
					e.xx = oldX;
					e.yy = oldY;
					e.updateFromCoords();
				}
			}

			// Landing over
			if( dy>=0 && xx>e.xx-d*0.9 && xx<e.xx+d*0.9 && e.yy>yy && yy>=e.yy-d*1.1 && yy<e.yy-d*0.8 ) {
				dy = 0;
				over = e;
				physics = false;
				stable = true;
			}
		}

		// jumping
		dy-=jumpPow;
		jumpPow*=0.4;
		if( jumpPow<=0.05 )
			jumpPow = 0;

		// Controls
		var s = 0.08;
		if( isActive && !projected && !Game.ME.complete ) {
			// Walk
			if( Key.isDown(Keyboard.LEFT) ) {
				dx-=s;
				dir = -1;
			}

			if( Key.isDown(Keyboard.RIGHT) ) {
				dx+=s;
				dir = 1;
			}

			// Jump
			if( Key.isDown(Keyboard.UP) && stable ) {
				//jumpPow = 0.45;
				if( over!=null && over.bumper ) {
					Fx.ME.hit(over.xx, over.yy);
					jumpPow = 0.45;
				}
				else
					jumpPow = 0.3;
				stable = false;
				over = null;
			}
		}


		if( isActive ) {
			spr.playAnim("heroHappy");
			spr.filters = [
				mt.deepnight.Color.getColorizeFilter(color, 1, 0),
				new flash.filters.GlowFilter(0xFFFF9B, 0.2, 8,8,1, 1, true),
				new flash.filters.GlowFilter(color, 1, 8,8,1),
				new flash.filters.GlowFilter(color, Lib.rnd(0.8,1), 32,32,2, 2),
			];
		}
		else {
			spr.playAnim("heroSad");
			var c = this==getNext() ? mt.deepnight.Color.interpolateInt(color,0x314459,0.9) : 0x314459;
			spr.filters = [
				mt.deepnight.Color.getColorizeFilter(c, 1, 0),
				new flash.filters.GlowFilter(0x0, 1, 32,32,2, 2),
			];
		}

		if( over!=null )
			if( !stable )
				over = null;
			else {
				dy = 0;
				stable = true;
				yy = over.yy-radius-over.radius;
				cy = Std.int(yy/Const.GRID);
				yr = (yy - cy*Const.GRID) / Const.GRID;
			}

		if( over==null )
			physics = true;

		super.update();

		if( stable && dx!=0 ) {
			fakeJump+=0.1;
			if( fakeJump>=1 )
				fakeJump = 0;
		}
		if( !stable || dx==0 )
			fakeJump = 0;

		if( cx>=Game.ME.level.wid-1 && Game.ME.curLevel==0 ) {
			Game.ME.levelComplete(true);
		}

		spr.y-=Math.sin(fakeJump*3.14)*1;
		spr.scaleX = dir;

	}
}