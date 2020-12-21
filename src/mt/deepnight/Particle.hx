package mt.deepnight;

import flash.Vector;
import dn.M;

class Particle #if !macro extends #if spriteParticles flash.display.Sprite #else flash.display.Shape #end #end{
	public static var ALL : Vector<Particle> = new Vector();
	public static var DEFAULT_BOUNDS : flash.geom.Rectangle = null;
	public static var DEFAULT_BLENDMODE : flash.display.BlendMode = ADD;
	public static var AUTO_RESET_SETTINGS = true;
	public static var GX = 0;
	public static var GY = 0.4;
	public static var WINDX = 0.0;
	public static var WINDY = 0.0;
	public static var DEFAULT_SNAP_PIXELS = true;
	public static var LIMIT : Int = 1000;

	var rx				: Float; // real x,y
	var ry				: Float;
	public var dx		: Float;
	public var dy		: Float;
	public var da		: Float; // alpha
	public var ds		: Float; // scale
	public var dsx		: Float; // scaleX
	public var dsy		: Float; // scaleY
	public var dr		: Float;
	public var frict(never,set)	: Float;
	public var frictX	: Float;
	public var frictY	: Float;
	public var gx		: Float;
	public var gy		: Float;
	public var bounce	: Float;
	public var life(default,set)	: Float;
	var rlife			: Float;
	var maxLife			: Float;
	public var bounds	: Null<flash.geom.Rectangle>;
	public var fl_wind	: Bool;
	public var groundY	: Null<Float>;
	public var groupId	: Null<String>;
	public var fadeOutSpeed	: Float;

	public var delay(default, set)	: Float;

	public var onStart	: Null<Void->Void>;
	public var onBounce	: Null<Void->Void>;
	public var onUpdate	: Null<Void->Void>;
	public var onKill	: Null<Void->Void>;

	public var pixel			: Bool;
	public var killOnLifeOut	: Bool;
	public var ignoreLimit		: Bool; // if TRUE, cannot be killed by the performance LIMIT

	public function new(?x:Float, ?y:Float, ?pt:{x:Float, y:Float}) {
		super();
		if( pt!=null ) {
			x = pt.x;
			y = pt.y;
		}
		setPos(x,y);
		dx = dy = da = ds = dsx = dsy = 0;
		gx = GX;
		gy = GY + Std.random(Std.int(GY*10))/10;
		fadeOutSpeed = 0.1;
		ignoreLimit = false;
		bounce = 0.85;
		dr = 0;
		frictX = 0.95+Std.random(40)/1000;
		frictY = 0.97;
		delay = 0;
		life = 32+Std.random(32);
		pixel = DEFAULT_SNAP_PIXELS;
		bounds = DEFAULT_BOUNDS;
		killOnLifeOut = false;
		fl_wind = true;
		ALL.push(this);
		blendMode = DEFAULT_BLENDMODE;

		if( AUTO_RESET_SETTINGS )
			reset();

		#if spriteParticles
		this.mouseChildren = this.mouseEnabled = false;
		#end
	}

	#if !spriteParticles
	public function addChild(e:Dynamic) {
		mt.deepnight.Lib.macroError("You must add \"-D spriteParticles\" to your HXML to use addChild on a particle.");
	}
	#end

	function set_frict(v) {
		frictX = frictY = v;
		return v;
	}

	function set_delay(d:Float):Float {
		visible = d <= 0;
		return delay = d;
	}


	#if spriteParticles
	public function flatten(?padding=0.0) { // EXPERIMENTAL
		if( parent!=null )
			parent.removeChild(this);

		var bmp = mt.deepnight.Lib.flatten(this, padding);
		bmp.smoothing = false;
		graphics.clear();
		while( numChildren>0 )
			removeChildAt(0);
		addChild(bmp);

		for( f in filters )
			bmp.bitmapData.applyFilter(bmp.bitmapData, bmp.bitmapData.rect, new flash.geom.Point(0,0), f);
		filters = [];
	}
	#end

	public function clone() : Particle {
		var s = new haxe.Serializer();
		s.useCache = true;
		s.serialize(this);
		return haxe.Unserializer.run( s.toString() );
	}

	function set_life(l:Float):Float {
		if( l<0 )
			l = 0;
		life = l;
		rlife = l;
		maxLife = l;
		return l;
	}

	public inline function time() {
		return 1 - (rlife+alpha)/(maxLife+1);
	}

	public inline function drawBox(w:Float,h:Float, col:Int, ?a=1.0, ?fill=true) {
		graphics.clear();
		if( fill )
			graphics.beginFill(col, a);
		else
			graphics.lineStyle(1, col, a);
		graphics.drawRect(-Std.int(w/2),-Std.int(h/2), w,h);
		graphics.endFill();
	}

	public inline function drawCircle(r:Float, col:Int, ?a=1.0, ?fill=true, ?lineThickness=1.0) {
		graphics.clear();
		if( fill )
			graphics.beginFill(col, a);
		else
			graphics.lineStyle(lineThickness, col, a, true, flash.display.LineScaleMode.NONE);
		graphics.drawCircle(0,0,r);
		graphics.endFill();
	}

	public inline function drawDot(w:Int, col:Int, ?a=1.0) {
		drawBox(w,w, col, a);
	}

	public inline function reset() {
		gx = gy = dx = dy = dr = 0;
		frictX = frictY = 1;
	}

	public function destroy() {
		alpha = 0;
		life = 0;
		if( parent!=null )
			parent.removeChild(this);
	}

	public inline function getSpeed() {
		return Math.sqrt( dx*dx + dy*dy );
	}


	public static inline function sign() {
		return Std.random(2)*2-1;
	}

	public static inline function randFloat(f:Float) {
		return Std.random( Std.int(f*10000) ) / 10000;
	}

	public inline function moveAng(a:Float, spd:Float) {
		dx = Math.cos(a)*spd;
		dy = Math.sin(a)*spd;
	}

	public inline function getMoveAng() {
		return Math.atan2(dy,dx);
	}

	public inline function setPos(x,y) {
		rx = this.x = x;
		ry = this.y = y;
	}

	public static function clearAll() {
		for(p in ALL)
			p.destroy();
		ALL = new flash.Vector();
	}

	public static function update() {
		var i : #if openfl Int #else UInt #end = 0;
		var all = ALL;
		var wx = WINDX;
		var wy = WINDY;
		var limit = LIMIT;

		var count : #if openfl Int #else UInt #end = all.length;
		while(i < count) {
			var p = ALL[i];
			var wind = (p.fl_wind?1:0);
			p.delay--;
			if( p.delay>0 )
				i++;
			else {
				if( p.onStart!=null ) {
					var cb = p.onStart;
					p.onStart = null;
					cb();
				}

				// gravité
				p.dx+= p.gx + wind*wx;
				p.dy+= p.gy + wind*wy;

				// friction
				p.dx *= p.frictX;
				p.dy *= p.frictY;

				// mouvement
				p.rx += p.dx;
				p.ry += p.dy;

				// Ground
				if( p.groundY!=null && p.dy>0 && p.ry>=p.groundY ) {
					p.dy = -p.dy*p.bounce;
					p.ry = p.groundY-1;
					if( p.onBounce!=null )
						p.onBounce();
				}

				// Display coords
				if( p.pixel ) {
					p.x = Std.int(p.rx);
					p.y = Std.int(p.ry);
				}
				else {
					p.x = p.rx;
					p.y = p.ry;
				}

				p.rotation += p.dr;
				p.scaleX += p.ds + p.dsx;
				p.scaleY += p.ds + p.dsy;

				// Fade in
				if( p.rlife>0 && p.da!=0 ) {
					p.alpha += p.da;
					if( p.alpha>1 ) {
						p.da = 0;
						p.alpha = 1;
					}
				}

				p.rlife--;

				// Fade out (life)
				if( p.rlife<=0 || !p.ignoreLimit && Std.int(i) < cast(all.length-limit) )
					p.alpha -= p.fadeOutSpeed;

				// Death
				if( p.rlife<=0 && (p.alpha<=0 || p.killOnLifeOut) || p.bounds!=null && !p.bounds.contains(p.rx, p.ry)  ) {
					if( p.onKill!=null )
						p.onKill();
					if( p.parent!=null )
						p.parent.removeChild(p);
					all.splice(i, 1);
					count--;
				}
				else {
					if( p.onUpdate!=null )
						p.onUpdate();
					i++;
				}
			}
		}
	}
}

