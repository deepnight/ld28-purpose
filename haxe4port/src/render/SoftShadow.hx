package render;

/** Separable Heaps Gaussian blur with independent Flash blurX / blurY dimensions. */
class SoftShadow extends h2d.filter.Filter {
	var horizontal : AxisBlur;
	var vertical : AxisBlur;
	var blend : h3d.pass.ScreenFx<ShadowBlend>;
	var radius : Float;

	public function new(color:Int, opacity:Float, blurX:Float, blurY:Float, strength=1.0) {
		super();
		horizontal = new AxisBlur(blurX*0.5);
		vertical = new AxisBlur(blurY*0.5);
		radius = M.fmax(blurX,blurY)*0.5;
		blend = new h3d.pass.ScreenFx(new ShadowBlend());
		blend.shader.color.setColor(color);
		blend.shader.opacity = opacity*strength;
		smooth = false;
	}

	override function sync(ctx:h2d.RenderContext, object:h2d.Object) {
		boundsExtend = Math.ceil(radius)*2;
	}

	override function draw(ctx:h2d.RenderContext, source:h2d.Tile) {
		var tmp = ctx.textures.allocTileTarget("shadowHorizontal",source);
		var blurred = ctx.textures.allocTileTarget("shadowVertical",source);
		var out = ctx.textures.allocTileTarget("shadowComposite",source);
		horizontal.applyAxis(ctx,source.getTexture(),tmp,true);
		vertical.applyAxis(ctx,tmp,blurred,false);
		blend.shader.texture = source.getTexture();
		blend.shader.shadow = blurred;
		ctx.engine.pushTarget(out);
		blend.render();
		ctx.engine.popTarget();
		return h2d.Tile.fromTexture(out);
	}
}

private class AxisBlur extends h3d.pass.Blur {
	public function applyAxis(ctx:h2d.RenderContext, input:h3d.mat.Texture, output:h3d.mat.Texture, xAxis:Bool) {
		if( radius<=0 ) {
			h3d.pass.Copy.run(input,output,None);
			return;
		}
		if( values==null ) calcValues();
		shader.Quality = values.length;
		shader.values = values;
		shader.offsets = offsets;
		shader.texture = input;
		shader.isCube = false;
		shader.isDepth = false;
		shader.hasFixedColor = false;
		shader.pixel.set(xAxis ? 1/input.width : 0, xAxis ? 0 : 1/input.height);
		var oldFilter = input.filter;
		input.filter = Linear;
		pass.setBlendMode(None);
		ctx.engine.pushTarget(output);
		render();
		ctx.engine.popTarget();
		input.filter = oldFilter;
	}
}

private class ShadowBlend extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;
		@param var shadow : Sampler2D;
		@param var color : Vec3;
		@param var opacity : Float;
		function fragment() {
			var src = texture.get(input.uv);
			var a = min(1.0,shadow.get(input.uv).a*opacity)*(1.0-src.a);
			pixelColor = vec4(src.rgb+color*a,src.a+a);
		}
	};
}
