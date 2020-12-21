package mt.deepnight;

import dn.M;

#if (flash||nme||openfl)
import flash.display.Bitmap;
import flash.display.BitmapData;
	#if haxe3
	import haxe.ds.StringMap.StringMap;
	#end
#end

enum Day {
	Sunday;
	Monday;
	Tuesday;
	Wednersday;
	Thursday;
	Friday;
	Saturday;
}

class Lib {
	public static inline function countDaysUntil(now:Date, day:Day) {
		var delta = Type.enumIndex(day) - now.getDay();
		return if(delta<0) 7+delta else delta;
	}

	public static inline function getDay(date:Date) : Day {
		return Type.createEnumIndex(Day, date.getDay());
	}

	public static inline function setTime(date:Date, h:Int, ?m=0,?s=0) {
		var str = "%Y-%m-%d "+StringTools.lpad(""+h,"0",2)+":"+StringTools.lpad(""+m,"0",2)+":"+StringTools.lpad(""+s,"0",2);
		return Date.fromString( DateTools.format(date, str) );
	}

	public static inline function countDeltaDays(now_:Date, next_:Date) {
		var now = setTime(now_, 5);
		var next = setTime(next_, 5);
		return MLib.floor( (next.getTime() - now.getTime()) / DateTools.days(1) );
	}

	public static inline function leadingZeros(s:Dynamic, ?zeros=2) {
		var str = Std.string(s);
		while (str.length<zeros)
			str="0"+str;
		return str;
	}

	#if neko
	public static function drawExcept<T>(a:List<T>, except:T, ?randFn:Int->Int):T {
		if (a.length==0)
			return null;
		if (randFn==null)
			randFn = Std.random;
		var a2 = new Array();
		for (elem in a)
			if (elem!=except)
				a2.push(elem);
		return
			if (a2.length==0)
				null;
			else
				a2[ randFn(a2.length) ];

	}
	#end

	#if openfl
	public static function redirectTraces(func:Dynamic->?haxe.PosInfos->Void) {
		//throw "ERROR";
		#if cpp return;#end
		haxe.Log.trace = func;
	}
	#end
	#if flash9
	public static function redirectTracesToConsole(?customPrefix="") {
		haxe.Log.trace = function(m, ?pos)
		{
			try
			{
				if ( pos != null && pos.customParams == null )
					pos.customParams = ["debug"];

				flash.external.ExternalInterface.call("console.log", pos.fileName + "(" + pos.lineNumber + ") : " + customPrefix + Std.string(m));
			}
			catch(e:Dynamic) { }
		}
	}
	#end

	#if flash9
	public static inline function isMac() {
		return flash.system.Capabilities.os.indexOf("mac")>=0;
	}

	public static inline function isAndroid() {
		return flash.system.Capabilities.version.indexOf("AND")>=0;
	}

	public static function getFlashVersion() { // renvoie Float sous la forme "11.2"
		var ver = flash.system.Capabilities.version.split(" ")[1].split(",");
		return Std.parseFloat(ver[0]+"."+ver[1]);
	}

	public static function atLeastVersion(version:String) { // format : xx.xx.xx.xx ou xx,xx,xx,xx
		var s = StringTools.replace(version, ",", ".");
		var req = s.split(".");
		var fv = flash.system.Capabilities.version;
		var mine = fv.substr(fv.indexOf(" ")+1).split(",");
		for (i in 0...req.length) {
			if (mine[i]==null || req[i]==null)
				break;
			var m = Std.parseInt(mine[i]);
			var r = Std.parseInt(req[i]);
			if ( m>r )	return true;
			if ( m<r )	return false;

		}
		return true;
	}
	#end

	#if (flash9 || openfl)
	public static function getCookie(cookieName:String, varName:String, ?defValue:Dynamic) : Dynamic {
		var cookie = flash.net.SharedObject.getLocal(cookieName);
		return
			if ( Reflect.hasField(cookie.data, varName) )
				Reflect.field(cookie.data, varName);
			else
				defValue;
	}

	public static function setCookie(cookieName:String, varName:String, value:Dynamic) {
		var cookie = flash.net.SharedObject.getLocal(cookieName);
		Reflect.setField(cookie.data, varName, value);
		cookie.flush();
	}

	public static function resetCookie(cookieName:String, ?obj:Dynamic) {
		var cookie = flash.net.SharedObject.getLocal(cookieName);
		cookie.clear();
		if (obj!=null)
			for (key in Reflect.fields(obj))
				Reflect.setField(cookie.data, key, Reflect.field(obj, key));
		cookie.flush();
	}

	public static inline function constraintBox(o:flash.display.DisplayObject, maxWid, maxHei) {
		var r = MLib.fmin( MLib.fmin(1, maxWid/o.width), MLib.fmin(1, maxHei/o.height) );
		o.scaleX = r;
		o.scaleY = r;
		return r;
	}

	public static inline function isOverlap(a:flash.geom.Rectangle, b:flash.geom.Rectangle) : Bool {
		return
			b.x>=a.x-b.width && b.x<=a.right &&
			b.y>=a.y-b.height && b.y<=a.bottom;
	}
	#end


	public static function shuffle<T>(l:Iterable<T>, randFunc:Int->Int) : Array<T> {
		// Source: http://bost.ocks.org/mike/shuffle/
		var out = new Array();
		for(e in l)
			out.push(e);

		var m = out.length;
		var i = 0;
		var tmp = null;
		while( m>0 ) {
			i = randFunc(m);
			m--;
			tmp = out[m];
			out[m] = out[i];
			out[i] = tmp;
		}
		return out;
	}

	public static function randomSpread(total:Int, nbStacks:Int, ?maxStackValue:Null<Int>, randFunc:Int->Int) : Array<Int> {
		if (total<=0 || nbStacks<=0)
			return new Array();

		if( maxStackValue!=null && total/nbStacks>maxStackValue ) {
			var a = [];
			for(i in 0...nbStacks)
				a.push(maxStackValue);
			return a;
		}

		if( nbStacks>total ) {
			var a = [];
			for(i in 0...total)
				a.push(1);
			return a;
		}

		var plist = new Array();
		for (i in 0...nbStacks)
			plist[i] = 1;

		var remain = total-plist.length;
		while (remain>0) {
			var move = MLib.ceil(total*(randFunc(8)+1)/100);
			if (move>remain)
				move = remain;

			var p = randFunc(nbStacks);
			if( maxStackValue!=null && plist[p]+move>maxStackValue )
				move = maxStackValue - plist[p];
			plist[p]+=move;
			remain-=move;
		}
		return plist;
	}


	public static inline function constraint(n:Dynamic, min:Dynamic, max:Dynamic) {
		return
			if (n<min) min;
			else if (n>max) max;
			else n;
	}

	public static inline function replaceTag(str:String, char:String, open:String, close:String) {
		var char = "\\"+char.split("").join("\\");
		var re = char+"([^"+char+"]+)"+char;
		return try { new EReg(re, "g").replace(str, open+"$1"+close); } catch (e:String) { str; }
	}

	public static inline function sign() {
		return Std.random(2)*2-1;
	}

	public static inline function distanceSqr(ax:Float,ay:Float,bx:Float,by:Float) : Float {
		return (ax-bx)*(ax-bx) + (ay-by)*(ay-by);
	}

	public static inline function idistanceSqr(ax:Int,ay:Int,bx:Int,by:Int) : Int {
		return (ax-bx)*(ax-bx) + (ay-by)*(ay-by);
	}

	public static inline function distance(ax:Float,ay:Float, bx:Float,by:Float) : Float {
		return Math.sqrt( distanceSqr(ax,ay,bx,by) );
	}


	public static inline function getNextPower2(n:Int) { // n est sur 32 bits
		n--;
		n |= n >> 1;
		n |= n >> 2;
		n |= n >> 4;
		n |= n >> 8;
		n |= n >> 16;
		return n++;
	}
	public static inline function getNextPower2_8bits(n:Int) { // n est sur 8 bits
		n--;
		n |= n >> 1;
		n |= n >> 2;
		n |= n >> 4;
		return n++;
	}

	public static inline function rnd(min:Float, max:Float, ?sign=false) {
		if( sign )
			return (min + Math.random()*(max-min)) * (Std.random(2)*2-1);
		else
			return min + Math.random()*(max-min);
	}

	public static inline function irnd(min:Int, max:Int, ?sign:Bool) {
		if( sign )
			return (min + Std.random(max-min+1)) * (Std.random(2)*2-1);
		else
			return min + Std.random(max-min+1);
	}


	public static function splitUrl(url:String) {
		if( url==null || url.length==0 )
			return null;
		var noProt = if( url.indexOf("://")<0 ) url else url.substr( url.indexOf("://")+3 );
		return {
			prot	: if( url.indexOf("://")<0 ) null else url.substr(0, url.indexOf("://")),
			dom		: if( noProt.indexOf("/")<0 ) noProt else if( noProt.indexOf("/")==0 ) null else noProt.substr(0, noProt.indexOf("/")),
			path	: if( noProt.indexOf("/")<0 ) "/" else noProt.substr(noProt.indexOf("/")),
		}
	}

	public static function splitMail(mail:String) {
		if (mail==null || mail.length==0)
			return null;
		if (mail.indexOf("@")<0)
			return null;
		else {
			var a = mail.split("@");
			if ( a[1].indexOf(".")<0 )
				return null;
			else
				return {
					usr	: a[0],
					dom	: a[1].substr(0,a[1].indexOf(".")),
					ext	: a[1].substr(a[1].indexOf(".")+1),
				}
		}
	}

	#if (flash9 || nme || openfl)
	public static function flatten(o:flash.display.DisplayObject, ?padding=0.0, ?copyTransforms=false, ?quality) {
		// Change quality
		var qold = try { flash.Lib.current.stage.quality; } catch(e:Dynamic) { flash.display.StageQuality.MEDIUM; };
		if( quality!=null )
			try {
				flash.Lib.current.stage.quality = quality;
			} catch( e:Dynamic ) {
				throw("Flatten quality error");
			}

		// Cancel transforms to draw into BitmapData
		var b = o.getBounds(o);
		var bmp = new flash.display.Bitmap( new flash.display.BitmapData(MLib.ceil(b.width+padding*2), MLib.ceil(b.height+padding*2), true, 0x0) );
		var m = new flash.geom.Matrix();
		m.translate(-b.x, -b.y);
		m.translate(padding, padding);
		bmp.bitmapData.draw(o, m, o.transform.colorTransform);

		// Apply transforms to Bitmap parent
		var m = new flash.geom.Matrix();
		m.translate(b.x, b.y);
		m.translate(-padding, -padding);
		if( copyTransforms ) {
			m.scale(o.scaleX, o.scaleY);
			m.rotate( MLib.toRad(o.rotation) );
			m.translate(o.x, o.y);
		}
		bmp.transform.matrix = m;

		// Restore quality
		if( quality!=null )
			try {
				flash.Lib.current.stage.quality = qold;
			} catch( e:Dynamic ) {
				throw("Flatten quality error");
			}
		return bmp;
	}


	public static function createTexture(source:flash.display.BitmapData, width:Float, height:Float, autoDisposeSource:Bool) {
		var bd = new BitmapData(MLib.ceil(width), MLib.ceil(height), source.transparent, 0x0);

		bd.lock();

		var pt = new flash.geom.Point();
		for(x in 0...MLib.ceil(width/source.width))
			for(y in 0...MLib.ceil(height/source.height)) {
				pt.x = x * source.width;
				pt.y = y * source.height;
				bd.copyPixels(source, source.rect, pt, source, true);
			}

		bd.unlock();

		if( autoDisposeSource ) {
			source.dispose();
			source = null;
		}
		return bd;
	}


	public static function flipBitmap(bd:BitmapData, flipX:Bool, flipY:Bool) {
		var tmp = bd.clone();
		var m = new flash.geom.Matrix();
		if( flipX ) {
			m.scale(-1, 1);
			m.translate(bd.width, 0);
		}
		if( flipY ) {
			m.scale(1, -1);
			m.translate(0, bd.height);
		}
		bd.draw(tmp, m);
		tmp.dispose();
	}
	#end


	public static inline function normalizeDeg(a:Float) { // [-180,180]
		while( a<-180 ) a+=360;
		while( a>180 ) a-=360;
		return a;
	}

	public static inline function angularDistanceDeg(a:Float,b:Float) {
		return MLib.fabs( angularSubstractionDeg(a,b) );
	}

	public static inline function angularSubstractionDeg(a:Float,b:Float) { // returns a-b (normalized)
		return normalizeDeg( normalizeDeg(a) - normalizeDeg(b) );
	}

	public static inline function normalizeRad(a:Float) { // [-PI,PI]
		while( a<-MLib.PI ) a+=MLib.PI2;
		while( a>MLib.PI ) a-=MLib.PI2;
		return a;
	}

	public static inline function angularDistanceRad(a:Float,b:Float) {
		return MLib.fabs( angularSubstractionRad(a,b) );
	}

	public static inline function angularSubstractionRad(a:Float,b:Float) { // returns a-b (normalized)
		a = normalizeRad(a);
		b = normalizeRad(b);
		return normalizeRad(a-b);
	}



	public static function makeXmlNode(name:String, ?attributes:Map<String, String>, ?inner:String) {
		if( attributes==null && inner==null )
			return '<$name/>';

		var a = [];
		for(k in attributes.keys())
			a.push( k+"='"+attributes.get(k)+"'" );

		var begin = '<$name ${a.join(" ")}';
		var end = inner!=null ? '>$inner</$name>' : "/>";
		return begin+end;
	}


	public static macro function macroError(err:ExprOf<String>) {
		var pos = haxe.macro.Context.currentPos();
		switch( err.expr ) {
			case EConst(CString(s)) : haxe.macro.Context.error(s, pos);
			default :
		}

		return {pos:pos, expr:EBlock([])}
	}


	#if flash
	public static function loadFile(onComplete:flash.utils.ByteArray->Void) {
		var file = new flash.net.FileReference();
		file.addEventListener(flash.events.Event.SELECT, function(_) {
			file.load();
		});
		file.addEventListener(flash.events.Event.COMPLETE, function(_) {
			onComplete(file.data);
		});
		file.browse();
	}


	public static function saveFile(defaultName:String, data:String, ?onComplete:Void->Void) {
		var file = new flash.net.FileReference();
		file.addEventListener(flash.events.Event.COMPLETE, function(_) if( onComplete!=null ) onComplete() );
		file.save(data, defaultName);
	}
	#end

}
