package en;

import dn.M;

class Hero extends Entity {
	public static var ALL : Array<Hero> = [];

	public var color		: Int;
	var colorMatrix : h2d.filter.ColorMatrix;
	var glow : render.SoftGlow;
	var nearGlow : render.SoftGlow;
	var innerGlow : h2d.filter.InnerGlow;
	var jumpPow				: Float;
	var over				: Null<Entity>;
	var dir					: Int;
	var fakeJump			: Float;
	var offsetY				: Float;

	public function new(x,y) {
		super();
		color = 0x80FF00;
		colorMatrix = new h2d.filter.ColorMatrix();
		glow = new render.SoftGlow(color, 1, 16, 2);
		nearGlow = new render.SoftGlow(color, 1, 4);
		innerGlow = new h2d.filter.InnerGlow(0xFFFF9B, 0.2, 4);
		spr.filter = new h2d.filter.Group([colorMatrix, innerGlow, nearGlow, glow]);
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

		spr.set("heroHappy");
		spr.setCenterRatio(0.5,0.5);
	}

	override function unregister() {
		super.unregister();
		ALL.remove(this);
	}

	public function die() {
		if( destroyed ) return;
		Fx.ME.heroExplode(this);
		destroy();
		if( isActive && !Game.ME.complete ) {
			activateNext();
			if( getActive()==null )
				Game.ME.delayer.addMs(Game.ME.restartLevel,500);
		}
	}

	public static function getNext() {
		var next = false;
		for(e in ALL) {
			if( next && !e.destroyed )
				return e;

			if( e.isActive )
				next = true;
		}
		for(e in ALL) if( !e.destroyed ) return e;
		return null;
	}

	public static function activateNext() {
		var cur = getActive();
		var e = getNext();
		if( e!=null ) e.activate();
		if( cur!=null && e!=cur )
			cur.deactivate();
	}

	public static function getActive() {
		for(e in ALL)
			if( e.isActive && !e.destroyed )
				return e;
		return null;
	}

	public function activate() {
		if( isActive )
			return;

		weight = 0.1;
		Game.ME.root.over(spr);
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
			if( e==this || e.destroyed || !e.climbable )
				continue;

			// Circular collision
			var d = radius + e.radius;
			if( M.distSqr(xx,yy, e.xx,e.yy)< M.pow(d, 2) ) {
				var a = Math.atan2(e.yy-yy, e.xx-xx);
				var overlap = d - M.dist(xx,yy, e.xx,e.yy);
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
			if( Game.ME.input.isDown(Left) ) {
				dx-=s;
				dir = -1;
			}

			if( Game.ME.input.isDown(Right) ) {
				dx+=s;
				dir = 1;
			}

			// Jump
			if( Game.ME.input.isDown(Jump) && stable ) {
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


		var animId = isActive ? "heroHappy" : "heroSad";
		if( spr.anim.getAnimId()!=animId )
			spr.anim.playAndLoop(animId);
		var c:dn.Col = color;
		if( !isActive )
			c = this==getNext() ? c.to(0x314459,0.9) : 0x314459;
		colorMatrix.matrix = c.getColorizeMatrixH2d(1,0);
		innerGlow.enable = nearGlow.enable = isActive;
		glow.color = isActive ? color : 0;
		glow.setOpacity(isActive ? Lib.rnd(0.8,1) : 1);

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
