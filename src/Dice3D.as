package  
{
	import away3dlite.cameras.Camera3D;
	import away3dlite.containers.Scene3D;
	import away3dlite.containers.View3D;
	import away3dlite.debug.AwayStats;
	import away3dlite.materials.BitmapMaterial;
	import away3dlite.materials.WireframeMaterial;
	import away3dlite.primitives.Cube6;
	import away3dlite.primitives.Plane;
	import away3dlite.primitives.Trident;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import jiglib.geometry.JPlane;
	import jiglib.math.JMath3D;
	import jiglib.physics.constraint.JConstraintWorldPoint;
	import jiglib.physics.RigidBody;
	import jiglib.plugin.away3dlite.Away3DLiteMesh;
	import jiglib.plugin.away3dlite.Away3DLitePhysics;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author flashisobar
	 */
	public class Dice3D extends Sprite 
	{
		[Embed(source = "../assets/mapping_cube.png")]
		private var CubeImageClass:Class;
		
		private var _debug:Boolean = true;
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cube:Cube6;
		private var physics:Away3DLitePhysics;
		private var ground:RigidBody;
		private var cubes:Vector.<jiglib.physics.RigidBody>;
		private var _isDrag:Boolean = false;
		private var _isDispatch:Boolean = false;;
		private var _currDragBody:RigidBody;
		private var _dragConstraint:JConstraintWorldPoint;
		private var _planeToDragOn:Vector3D;
		private var _startMousePos:Vector3D;
		private var layer:Sprite;
		private var arrWall:Array;
		private var _currDiceNumber:Number;
		private var _onlyOnce:Boolean = false;
		
		public var finished:Signal = new Signal(uint);
		public var oncefinished:Signal = new Signal(uint);
		
		static public const GROUND_SIZE:int = 500;
		static public const GROUND_Y:int = 600;
		static public const ACTIVE_RANDOM_CUBES:Boolean = true;
		static private const NUM_OF_CUBES:uint = 20;
		static private const GROUND_RESTITUTION:Number = 0.8;
		static private const GROUND_FRICTION:Number = 0.2;

		public function Dice3D() 
		{

			if (stage)
				init();
			else
				addEventListener(Event.ADDED_TO_STAGE, init);

		}
		
		public function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			this._currDiceNumber = -1;
			init3D();
		}
		
		private function init3D():void
		{
			scene = new Scene3D();
			camera = new Camera3D();
			camera.x = 0;
			camera.y = -500;
			camera.z = 0;
			camera.lookAt(new Vector3D(0, 0, 1));
			
			view = new View3D();
			view.x = stage.stageWidth / 2;
			view.y = stage.stageHeight / 2;
			view.scene = scene;
			view.camera = camera;
			addChild(view);
			
			// ============= add physics =============
			// add mouse drag layer
			layer = new Sprite();
			layer.buttonMode = true;
			layer.mouseChildren = false;
			view.addChild(layer);
			
			physics = new Away3DLitePhysics(scene, 10);
			
			// add ground
			ground = physics.createGround(new WireframeMaterial(0x0, (_debug ? 1 : 0)), GROUND_SIZE*10, 0);
			ground.y = GROUND_Y;
			ground.movable = false;
			ground.friction = GROUND_FRICTION;
			ground.restitution = GROUND_RESTITUTION;
			
			// random cubes
			if (ACTIVE_RANDOM_CUBES)
			{
				cubes = new Vector.<RigidBody>(NUM_OF_CUBES, true);
				var cube_r:RigidBody;
				var color_r:Number;
				for (var i:int = 0; i < NUM_OF_CUBES; i++)
				{
					color_r = 0xFFFFFF * Math.random();
					cube_r = physics.createSphere(new WireframeMaterial(color_r), 25);
					cube_r.material.restitution = .1;
					cube_r.x = Math.random() * 500 - Math.random() * 500;
					cube_r.y = -500 - Math.random() * 1000;
					cube_r.z = Math.random() * 500 - Math.random() * 500;
					cube_r.rotationX = 360 * Math.random();
					cube_r.rotationY = 360 * Math.random();
					cube_r.rotationZ = 360 * Math.random();
					cube_r.mass = 3;
					//cube_r.setActive();
					cubes[i] = cube_r;
				}
			}
			// add drag ball
			//var material:WireColorMaterial = new WireColorMaterial();
			var material:BitmapMaterial = new BitmapMaterial(new CubeImageClass().bitmapData);
			material.smooth = true;
			_currDragBody = physics.createCube(material, 100, 100, 100);
			Away3DLiteMesh(_currDragBody.skin).mesh.layer = layer;
			//_currDragBody.mass = 3;
			_currDragBody.y = -600;
			_currDragBody.rotationX = 360 * Math.random();
			_currDragBody.rotationY = 360 * Math.random();
			_currDragBody.rotationZ = 360 * Math.random();
			
			// add wall
			createWall();
			
			// =======================================
			
			if(_debug){
				var axis:Trident = new Trident(300, false);
				scene.addChild(axis);
				var awayStats:AwayStats = new AwayStats(view);
				addChild(awayStats);
			}
			
			// start engine
			start();
		}
		
		/**
		 * create wall
		 */
		private function createWall():void
		{
			arrWall = [];
			var material:WireframeMaterial = new WireframeMaterial(0x0, (_debug ? 1 : 0));
			
			var left:Plane = new Plane(material, GROUND_SIZE, GROUND_SIZE);
			scene.addChild(left);
			var jleft:JPlane = new JPlane(new Away3DLiteMesh(left), new Vector3D(0, -1, 0));
			jleft.moveTo(new Vector3D(GROUND_SIZE >> 1, 0, 0));
			jleft.roll( -90);
			jleft.friction = GROUND_FRICTION;
			jleft.restitution = GROUND_RESTITUTION;
			physics.addBody(jleft);
			arrWall.push(jleft);
			
			var right:Plane = new Plane(material, GROUND_SIZE, GROUND_SIZE);
			scene.addChild(right);
			var jright:JPlane = new JPlane(new Away3DLiteMesh(right), new Vector3D(0, -1, 0));
			jright.moveTo(new Vector3D( -(GROUND_SIZE >> 1), 0, 0));
			jright.roll(90);
			jright.friction = GROUND_FRICTION;
			jright.restitution = GROUND_RESTITUTION;
			physics.addBody(jright);
			arrWall.push(jright);
			
			var front:Plane = new Plane(material, GROUND_SIZE, GROUND_SIZE);
			scene.addChild(front);
			var jfront:JPlane = new JPlane(new Away3DLiteMesh(front), new Vector3D(0, -1, 0));
			jfront.moveTo(new Vector3D(0, 0, -(GROUND_SIZE >> 1)));
			jfront.pitch( -90);
			jfront.friction = GROUND_FRICTION;
			jfront.restitution = GROUND_RESTITUTION;
			physics.addBody(jfront);
			arrWall.push(jfront);
			
			var back:Plane = new Plane(material, GROUND_SIZE, GROUND_SIZE);
			scene.addChild(back);
			var jback:JPlane = new JPlane(new Away3DLiteMesh(back), new Vector3D(0, -1, 0));
			jback.moveTo(new Vector3D(0, 0, (GROUND_SIZE >> 1)));
			jback.pitch(90);
			jback.friction = GROUND_FRICTION;
			jback.restitution = GROUND_RESTITUTION;
			physics.addBody(jback);
			arrWall.push(jback);
		}
		
		private function diceDecode():int
		{
			var axis:Vector3D = new Vector3D(0, 1, 0);
			
			var diceOrientation:Vector.<Vector3D> = _currDragBody.currentState.getOrientationCols();
			var faceUp:int = 0;

			/*
				1 front		Z
				2 left		X
				3 top		Y
				4 bottom	Y
				5 right		X
				6 back		Z
			*/
			// Y
			if (!_currDragBody.isActive && diceOrientation[1].dotProduct(axis) > 0.01)
				return faceUp = 3;
			else if (!_currDragBody.isActive && diceOrientation[1].dotProduct(axis) < -0.01)
				return faceUp = 4;
			// X
			if (!_currDragBody.isActive && diceOrientation[0].dotProduct(axis) > 0.01)
				return faceUp = 2;
			else if (!_currDragBody.isActive && diceOrientation[0].dotProduct(axis) < -0.01)
				return faceUp = 5;
			// Z
			if (!_currDragBody.isActive && diceOrientation[2].dotProduct(axis) > 0.01)
				return faceUp = 1;
			else if (!_currDragBody.isActive && diceOrientation[2].dotProduct(axis) < -0.01)
				return faceUp = 6;
			
			return -1;
		}
		
		/**
		 * start enable jiglibflash engine
		 */
		public function start(__y:Number = NaN):void 
		{
			if (!isNaN(__y))
				_currDragBody.y = __y;
				
			_onAddedToStage();
			addEventListener(Event.ENTER_FRAME, _onEnterFrame);
		}

		public function resize(__w:uint, __h:uint):void {
			if (__w < 500)
				__w = 500;
			if (__h < 500)
				__h = 500;
			arrWall[0].moveTo(new Vector3D(__w >> 1, 0, 0));
			arrWall[1].moveTo(new Vector3D( -(__w >> 1), 0, 0));
			arrWall[2].moveTo(new Vector3D(0, 0, -(__h >> 1)));
			arrWall[3].moveTo(new Vector3D(0, 0, (__h >> 1)));
		}
		
		public function destroy():void {
			removeEventListener(Event.ENTER_FRAME, _onEnterFrame);
			layer.removeEventListener(MouseEvent.MOUSE_DOWN, handleMousePress);
			// TODO: memory leak bug
			//view.destroy();
			//camera.destroy();
			//scene.destroy();
			view.removeChild(layer);
			removeChild(view);
			
			finished.removeAll();
			oncefinished.removeAll();
		}

		private function _onAddedToStage(e:Event=null):void
		{
			view.x = stage.stageWidth / 2;
			view.y = stage.stageHeight / 2;
			
			layer.addEventListener(MouseEvent.MOUSE_DOWN, handleMousePress);
		}
		
		private function handleMousePress(event:MouseEvent):void
		{
			if (_isDispatch)
				return;
				
			_isDrag = true;
			
			_startMousePos = _currDragBody.getTransform().position;
			
			_planeToDragOn = JMath3D.fromNormalAndPoint(Vector3D.Y_AXIS, new Vector3D(0, 0, -_startMousePos.z));
			var bodyPoint:Vector3D = _startMousePos.subtract(_currDragBody.currentState.position);
			_dragConstraint = new JConstraintWorldPoint(_currDragBody, bodyPoint, _startMousePos);
			physics.engine.addConstraint(_dragConstraint);
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, handleMouseRelease);
		
		}
		
		private function handleMouseMove(event:MouseEvent):void
		{
			if (_isDrag)
			{
				_isDispatch = true;
				var _ray:Vector3D = camera.lens.unProject(view.mouseX, view.mouseY, camera.screenMatrix3D.position.z);
				_ray = camera.transform.matrix3D.transformVector(_ray);
				_dragConstraint.worldPosition = JMath3D.getIntersectionLine(_planeToDragOn, camera.position, _ray);
			}
		}
		
		private function handleMouseRelease(event:MouseEvent):void
		{
			if (_isDrag)
			{
				_currDiceNumber = -1;
				_isDrag = false;
				physics.engine.removeConstraint(_dragConstraint);
				_currDragBody.setActive();
			}
			
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, handleMouseRelease);
		}
		
		private function _onEnterFrame(e:Event):void
		{
			physics.step();
			if (!_currDragBody.isActive)
			{
				if (_currDiceNumber < 0) {
					_currDiceNumber = diceDecode();
					trace("Dice3D:", _currDiceNumber);
					if (_onlyOnce) {
						_onlyOnce = false;
						_isDispatch = false;
						oncefinished.dispatch(_currDiceNumber);
						return;
					}
					if (_isDispatch) {
						_isDispatch = false;
						finished.dispatch(_currDiceNumber);
					}
				}
			}
			view.render();
		}
		
		public function get onlyOnce():Boolean 
		{
			return _onlyOnce;
		}
		
		public function set onlyOnce(value:Boolean):void 
		{
			_onlyOnce = value;
		}
		
	}

}