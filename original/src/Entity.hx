import mt.deepnight.deprecated.SpriteLibBitmap;
import mt.deepnight.Lib;
import dn.M;

class Entity {
	public static var UID = 0;
	public static var ALL : Array<Entity> = [];
	public static var TO_KILL : Array<Entity> = [];

	public var spr			: BSprite;
	public var cd			: dn.Cooldown;

	public var uid			: Int;
	public var cx			: Int;
	public var cy			: Int;
	public var xr			: Float;
	public var yr			: Float;
	public var xx			: Float;
	public var yy			: Float;
	public var dx			: Float;
	public var dy			: Float;
	public var frictX		: Float;
	public var frictY		: Float;
	public var radius		: Float;
	public var weight		: Float;

	public var tmod			: Float;

	var physics				: Bool;
	var stable				: Bool;
	var destroyed			: Bool;
	var projected			: Bool;
	var climbable			: Bool;
	var bumper				: Bool;
	public var isActive		: Bool;

	public function new() {
		ALL.push(this);
		uid = UID++;
		cx = cy = 5;
		xr = 0.5;
		yr = 0.5;
		weight = 1;
		dx = dy = 0;
		bumper = false;
		isActive = false;
		climbable = false;
		projected = false;
		physics = true;
		frictX = 0.5;
		frictY = 0.7;
		tmod = 1;
		radius = Const.GRID*0.5;
		stable = false;
		destroyed = false;
		cd = new dn.Cooldown(30);

		spr = new BSprite(Game.ME.tiles);
		//spr.setCenter(0.5, 1);
		spr.setPivotCoord(10,15);

		Game.ME.buffer.dm.add(spr, Const.DP_ENTITY);
		updateCoords();
	}

	public function setPos(x,y) {
		cx = x;
		cy = y;
		xr = yr = 0.5;
		updateCoords();
	}

	public function destroyImmediately() {
		destroy();
		unregister();
	}

	public function destroy() {
		if( destroyed )
			return;

		spr.parent.removeChild(spr);
		TO_KILL.push(this);
	}

	public function unregister() {
		TO_KILL.remove(this);
		ALL.remove(this);
	}

	inline function distance2(e:Entity) {
		return Lib.distanceSqr(xx,yy, e.xx,e.yy);
	}
	inline function distance(e:Entity) {
		return Math.sqrt(distance2(e));
	}

	function updateFromCoords() {
		cx = Std.int(xx/Const.GRID);
		cy = Std.int(yy/Const.GRID);
		xr = (xx - cx*Const.GRID) / Const.GRID;
		yr = (yy - cy*Const.GRID) / Const.GRID;
	}

	function updateCoords() {
		xx = (cx+xr) * Const.GRID;
		yy = (cy+yr) * Const.GRID;
		spr.x = Std.int(xx);
		spr.y = Std.int(yy);
	}


	function onHitWall() {
		if( projected ) {
			Fx.ME.hit(xx,yy);
			projected = false;
		}
	}


	//function yStep() {
	//}

	public function update() {
		cd.update(1);

		var level = Game.ME.level;



		// X movement
		xr+=dx*tmod;

		if( !projected )
			dx *= Math.pow(frictX, 1/tmod);

		if( level.hasCollision(cx-1,cy) && xr<0.3 ) {
			onHitWall();
			xr = 0.3;
		}

		if( level.hasCollision(cx+1,cy) && xr>0.7 ) {
			onHitWall();
			xr = 0.7;
		}

		if( level.hasCollision(cx-1,cy) && xr<0.4 ) {
			dx+=0.02*tmod;
		}

		if( level.hasCollision(cx+1,cy) && xr>0.6 ) {
			dx-=0.02*tmod;
		}

		while( xr>1 ) {
			xr--;
			cx++;
		}
		while( xr<0 ) {
			xr++;
			cx--;
		}
		if( M.fabs(dx)<=0.02 )
			dx = 0;



		// Y movement
		if( physics && !stable && !projected )
			dy+=0.05*tmod; // gravity
		if( stable && (!level.hasCollision(cx,cy+1) || yr<0.5) )
			stable = false;

		yr+=dy*tmod;

		if( !projected )
			dy *= Math.pow(frictY, tmod);

		if( level.hasCollision(cx,cy+1) && yr>0.5 ) {
			yr = 0.5;
			dy = 0;
			stable = true;
		}

		if( level.hasCollision(cx,cy-1) ) {
			if( yr<0.4 && dy<0 ) {
				//yr = 0.8;
				dy += 0.1;
			}

			if( yr<0.3 ) {
				yr = 0.3;
				dy = 0;
			}
		}

		while( yr>1 ) {
			yr--;
			cy++;
		}
		while( yr<0 ) {
			yr++;
			cy--;
		}

		updateCoords();
	}
}
