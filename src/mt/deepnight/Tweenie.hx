package mt.deepnight;

import dn.M;

enum TType {
	TLinear;
	TLoop; // loop : valeur initiale -> valeur finale -> valeur initiale
	TLoopEaseIn; // loop avec d�part lent
	TLoopEaseOut; // loop avec fin lente
	TEase;
	TEaseIn; // d�part lent, fin lin�aire
	TEaseOut; // d�part lin�aire, fin lente
	TBurn; // d�part rapide, milieu lent, fin rapide,
	TBurnIn; // d�part rapide, fin lente,
	TBurnOut; // d�part lente, fin rapide
	TZigZag; // une oscillation et termine sur Fin
	TRand; // progression chaotique de d�but -> fin. ATTENTION : la dur�e ne sera pas respect�e (plus longue)
	TShake; // variation al�atoire de la valeur entre D�but et Fin, puis s'arr�te sur D�but (d�part rapide)
	TShakeBoth; // comme TShake, sauf que la valeur tremble aussi en n�gatif
	TJump; // saut de D�but -> Fin
	TElasticEnd; // l�ger d�passement � la fin, puis r�ajustment
}

// GoogleDoc pour tester les valeurs de B�zier
// ->	https://spreadsheets.google.com/ccc?key=0ArnbjvQe8cVJdGxDZk1vdE50aUxvM1FlcDAxNWRrZFE&hl=en&authkey=CLCwp8QO

typedef Tween = {
	parent		: Dynamic,
	vname		: String,
	n			: Float,
	ln			: Float,
	speed		: Float,
	from		: Float,
	to			: Float,
	type		: TType,
	plays		: Int, // -1 = infini, 1 et plus = nombre d'ex�cutions (1 par d�faut)
	fl_pixel	: Bool, // arrondi toutes les valeurs si TRUE (utile pour les anims pixelart)
	onUpdate	: Null<Void->Void>,
	onUpdateT	: Null<Float->Void>, // callback appel� avec la progression (0->1) en param�tre
	onEnd		: Null<Void->Void>,
	interpolate	: Float->Float,
}

class Tweenie {
	static var DEFAULT_DURATION = DateTools.seconds(1);

	var tlist			: List<Tween>;
	var errorHandler	: String->Void;
	var baseFPS			: Int;

	public function new(?baseFPS=30) {
		this.baseFPS = baseFPS;
		tlist = new List();
		errorHandler = onError;
	}

	function onError(e) {
		trace(e);
	}

	public function count() {
		return tlist.length;
	}

	public function setErrorHandler(cb:String->Void) {
		errorHandler = cb;
	}

	public inline function create(parent:Dynamic, varName:String, to:Float, ?tp:TType, ?duration_ms:Float) {
		#if cpp
			return create_(parent, varName, to, tp, duration_ms);
		#elseif (nme || openfl)
			return create_(parent, varName, to, tp, duration_ms);
		#else
			return
			if( Reflect.hasField(parent,varName) )
				create_(parent, varName, to, tp, duration_ms);
			else
				create_(parent, untyped __unprotect__(varName), to, tp, duration_ms); // champ obfuscqu�

		#end
	}

	public function exists(p:Dynamic, v:String) {
		for (t in tlist)
			if (t.parent == p && t.vname == v)
				return true;
		return false;
	}

	function create_(p:Dynamic, v:String, to:Float, ?tp:TType, ?duration_ms:Float) {
		if ( duration_ms==null )
			duration_ms = DEFAULT_DURATION;

		if ( p==null )
			errorHandler("tween creation failed : null parent, v="+v+" tp="+tp);
		if ( tp==null )
			tp = TEase;

		// on supprime les tweens pr�c�dents appliqu�s � la m�me variable
		var tfound : TType = null;
		for(t in tlist)
			if(t.parent==p && t.vname==v) {
				tfound = t.type;
				tlist.remove(t);
			}
		if ( tfound!=null ) {
			if (tp==TEase && (tfound==TEase || tfound==TEaseOut) )
				tp = TEaseOut;
		}
		// ajout
		var t : Tween = {
			parent		: p,
			vname		: v,
			n			: 0.0,
			ln			: 0.0,
			speed		: 1 / ( duration_ms*baseFPS/1000 ), // une seconde
			from		: Reflect.getProperty(p,v),
			to			: to,
			type		: tp,
			fl_pixel	: false,
			plays		: 1,
			onUpdate	: null,
			onUpdateT	: null,
			onEnd		: null,
			interpolate	: getInterpolateFunction(tp),
		}


		if( t.from==t.to )
			t.ln = 1; // tweening inutile : mais on s'assure ainsi qu'un update() et un end() seront bien appel�s

		tlist.add(t);

		return t;
	}

	static inline function fastPow2(n:Float):Float {
		return n*n;
	}
	static inline function fastPow3(n:Float):Float {
		return n*n*n;
	}

	static inline function bezier(t:Float, p0:Float, p1:Float,p2:Float, p3:Float) {
		return
			fastPow3(1-t)*p0 +
			3*t*fastPow2(1-t)*p1 +
			3*fastPow2(t)*(1-t)*p2 +
			fastPow3(t)*p3;
	}

	public function delete(parent:Dynamic) { // attention : les callbacks end() / update() ne seront pas appel�s !
		for(t in tlist)
			if(t.parent==parent)
				tlist.remove(t);
	}

	// suppression du tween sans aucun appel aux callbacks onUpdate, onUpdateT et onEnd (!)
	public function killWithoutCallbacks(parent:Dynamic, ?varName:String) {
		for (t in tlist)
			if (t.parent==parent && (varName==null || varName==t.vname))
				tlist.remove(t);
	}

	public function terminate(parent:Dynamic, ?varName:String) {
		for (t in tlist)
			if (t.parent==parent && (varName==null || varName==t.vname))
				terminateTween(t);
	}

	public function terminateTween(t:Tween, ?fl_allowLoop=false) {
		var v = t.from+(t.to-t.from)*t.interpolate(1);
		if (t.fl_pixel)
			v = Math.round(v);
		Reflect.setProperty(t.parent, t.vname, v);
		onUpdate(t,1);
		onEnd(t);
		if( fl_allowLoop && (t.plays==-1 || t.plays>1) ) {
			if( t.plays!=-1 )
				t.plays--;
			t.n = t.ln = 0;
		}
		else
			tlist.remove(t);
	}
	public function terminateAll() {
		for(t in tlist)
			t.ln = 1;
		update();
	}


	inline function onUpdate(t:Tween, n:Float) {
		if ( t.onUpdate!=null )
			t.onUpdate();
		if ( t.onUpdateT!=null )
			t.onUpdateT(n);
	}
	inline function onEnd(t:Tween) {
		if ( t.onEnd!=null ) {
			var cb = t.onEnd;
			t.onEnd = null;
			cb();
		}
	}

	function getInterpolateFunction(type:TType) {
		return switch(type) {
			case TLinear		: function(step) return step;
			case TRand			: function(step) return step;
			case TEase			: function(step) return bezier(step, 0,	0,		1,		1);
			case TEaseIn		: function(step) return bezier(step, 0,	0,		0.5,	1);
			case TEaseOut		: function(step) return bezier(step, 0,	0.5,	1,		1);
			case TBurn			: function(step) return bezier(step, 0,	1,	 	0,		1);
			case TBurnIn		: function(step) return bezier(step, 0,	1,	 	1,		1);
			case TBurnOut		: function(step) return bezier(step, 0,	0,		0,		1);
			case TZigZag		: function(step) return bezier(step, 0,	2.5,	-1.5,	1);
			case TLoop			: function(step) return bezier(step, 0,	1.33,	1.33,	0);
			case TLoopEaseIn	: function(step) return bezier(step, 0,	0,		2.25,	0);
			case TLoopEaseOut	: function(step) return bezier(step, 0,	2.25,	0,		0);
			case TShake			: function(step) return bezier(step, 0.5,	1.22,	1.25,	0);
			case TShakeBoth		: function(step) return bezier(step, 0.5,	1.22,	1.25,	0);
			case TJump			: function(step) return bezier(step, 0,	2,		2.79,	1);
			case TElasticEnd	: function(step) return bezier(step, 0,	0.7,	1.5,	1);
		}
	}

	public inline function update(?tmod=1.0) {
		for (t in tlist) {
			var dist = t.to-t.from;
			if (t.type==TRand)
				t.ln+=if(Std.random(100)<33) t.speed * tmod else 0;
			else
				t.ln+=t.speed * tmod;
			t.n = t.interpolate(t.ln);
			if ( t.ln<1 ) {
				// en cours...
				var val =
					if (t.type!=TShake && t.type!=TShakeBoth)
						t.from + t.n*dist ;
					else if ( t.type==TShake )
						t.from + Math.random() * MLib.fabs(t.n*dist) * (dist>0?1:-1);
					else
						t.from + Math.random() * t.n*dist * (Std.random(2)*2-1);
				if (t.fl_pixel)
					val = Math.round(val);
				Reflect.setProperty(t.parent, t.vname, val);
				onUpdate(t, t.ln);
			}
			else // fini !
				terminateTween(t, true);


		}
	}
}
