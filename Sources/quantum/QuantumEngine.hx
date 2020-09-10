package quantum;

import kha.Color;
import quantum.ui.IUI;
import kha.Window;
import zui.Id;
import kha.Scaler;
import kha.Image;
import kha.input.KeyCode;
import kha.input.Keyboard;
import quantum.ui.DebugUI;
import quantum.entities.display.IRenderable;
import quantum.entities.display.Sprite;
import quantum.entities.display.AnimatedSprite;
import quantum.scene.Scene;
import kha.Assets;
import kha.Scheduler;
import kha.System;
import kha.Framebuffer;
import signals.Signal1;
import zui.Zui;

class QuantumEngine
{
	public static final engine : QuantumEngine = new QuantumEngine();

	public final onSceneChanged : Signal1<Scene> = new Signal1<Scene>();

	public var width(default, null) : Int = 800;
	public var height(default, null) : Int = 600;

	public var ui(default, null) : IUI;
	public var scene(default, set) : Scene;

	var _initialized : Bool = false;
	var _fps : Float = 1 / 60;
	var _accumulator : Float = 0;
	var _backBuffer : Image;
	var _timer : Timer;

	var sprite : Sprite;
	var anim : AnimatedSprite;

	// Hack until notifyOnResize works for all targets
	var _winWidth : Int;
	var _winHeight : Int;

	private function new() {}

	public function initialize(width : Int = 800, height : Int = 600)
	{
		this.width = width;
		this.height = height;

		Assets.loadEverything(loadingFinished);
	}

	function loadingFinished()
	{
		_initialized = true;

		_backBuffer = Image.createRenderTarget(width, height);

		_timer = new Timer();

		ui = new DebugUI();

		onResize(System.windowWidth(0), System.windowHeight(0));

		sprite = new Sprite("tex");
		sprite.x = 64;
		sprite.y = 32;
		sprite.scale.x = 4;
		sprite.scale.y = 2;
		sprite.alpha = 0.7;
		sprite.color = Color.Red;

		var sub = new Sprite("tex");
		sub.x = 64;
		sub.y = 96;
		sub.alpha = 0.5;
		sprite.addChild(sub);

		anim = new AnimatedSprite("player", 32, 32);
		anim.x = 128;
		anim.y = 256;

		anim.addAnimation("idle", [0], 0, false);
		anim.addAnimation("run", [1, 2, 3, 4], 0.15, true);
		anim.addAnimation("jump", [5, 6, 7, 8, 9], 0.15, false);
		anim.addAnimation("air", [10], 0, false);
		anim.play("run");

		scene = new Scene();
		scene.background = 0xff009999;
		scene.addChild(sprite);
		scene.addChild(anim);

		var input = Input.instance;
		input.initialize();
		input.register("debugMenu", KeyCode.BackQuote);
		input.register("exit", KeyCode.Escape);
		input.register("left", KeyCode.Left);
		input.register("left", KeyCode.A);

		// Doesn't currently work for all targets, so
		// for now we use a hack.
		// Window
		// 	.get(0)
		// 	.notifyOnResize(onResize);

		System.notifyOnFrames(function(framebuffers)
		{
			render(framebuffers[0]);
		});
	}

	function render(framebuffer : Framebuffer)
	{
		if (!_initialized)
		{
			return;
		}

		// Resize hack until notifyOnResize works on all targets
		var curWinWidth = System.windowWidth(0);
		var curWinHeight = System.windowHeight(0);

		if (curWinWidth != _winWidth || curWinHeight != _winHeight)
		{
			onResize(curWinWidth, curWinHeight);
		}

		var gBuffer = _backBuffer.g2;

		gBuffer.begin();

		if (scene != null)
		{
			scene.render(gBuffer);
		}

		gBuffer.end();

		var gMain = framebuffer.g2;

		gMain.begin();
		Scaler.scale(_backBuffer, framebuffer, System.screenRotation);
		gMain.end();

		ui.render(gMain);

		update();
	}

	function update()
	{
		var dt = _timer.update();
		var input = Input.instance;

		// https://gafferongames.com/post/fix_your_timestep/
		_accumulator += dt;
		while (_accumulator >= _fps)
		{
			if (input.justPressed("debugMenu"))
			{
				ui.visible = !ui.visible;
			}

			if (scene != null)
			{
				scene.update(dt);
			}

			input.update();

			_accumulator -= _fps;
		}
	}

	function onResize(windowWidth : Int, windowHeight : Int)
	{
		_winWidth = windowWidth;
		_winHeight = windowHeight;

		var scaleRect = Scaler.targetRect(width, height, _winWidth, _winHeight, System.screenRotation);

		ui.scale(scaleRect.scaleFactor);
	}

	function set_scene(value : Scene) : Scene
	{
		scene = value;

		onSceneChanged.dispatch(scene);

		return scene;
	}
}
