package laya.d3.core.light {
	import laya.d3.core.render.RenderState;
	import laya.d3.core.scene.Scene;
	import laya.d3.math.Matrix4x4;
	import laya.d3.math.Vector3;
	import laya.d3.shader.ShaderCompile3D;
	import laya.d3.shader.ValusArray;
	import laya.d3.shadowMap.ParallelSplitShadowMap;
	import laya.events.Event;
	
	/**
	 * <code>DirectionLight</code> 类用于创建平行光。
	 */
	public class DirectionLight extends LightSprite {
		/** @private */
		private var _updateDirection:Boolean;
		/** @private */
		private var _direction:Vector3;
		
		/**
		 * 获取平行光的方向。
		 * @return 平行光的方向。
		 */
		public function get direction():Vector3 {
			if (_updateDirection) {
				transform.worldMatrix.getForward(_direction);
				Vector3.normalize(_direction, _direction);
				_updateDirection = false;
			}
			return _direction;
		}
		
		/**
		 * 设置平行光的方向。
		 * @param value 平行光的方向。
		 */
		public function set direction(value:Vector3):void {
			var worldMatrix:Matrix4x4 = transform.worldMatrix;
			worldMatrix.setForward(value);
			transform.worldMatrix = worldMatrix;
			Vector3.normalize(value, value);
			_direction = value;
			(shadow && _parallelSplitShadowMap) && (_parallelSplitShadowMap._setGlobalParallelLightDir(_direction));
		}
		
		/**
		 * @inheritDoc
		 */
		public override function get lightType():int {
			return TYPE_DIRECTIONLIGHT;
		}
		
		/**
		 * @inheritDoc
		 */
		override public function set shadow(value:Boolean):void {
			if (_shadow !== value) {
				_shadow = value;
				(scene) && (_initShadow());
			}
		}
		
		/**
		 * 创建一个 <code>DirectionLight</code> 实例。
		 */
		public function DirectionLight() {
			super();
			_updateDirection = false;
			direction = new Vector3(0.0, -0.5, -1.0);
			
			transform.on(Event.WORLDMATRIX_NEEDCHANGE, this, _onWorldMatrixChange);
		}
		
		/**
		 * @private
		 */
		private function _initShadow():void {
			if (_shadow) {
				_parallelSplitShadowMap = new ParallelSplitShadowMap();
				scene.parallelSplitShadowMaps.push(_parallelSplitShadowMap);
				_parallelSplitShadowMap.setInfo(scene, _shadowFarPlane, direction, _shadowMapSize, _shadowMapCount, _shadowMapPCFType);
			} else {
				var parallelSplitShadowMaps:Vector.<ParallelSplitShadowMap> = scene.parallelSplitShadowMaps;
				parallelSplitShadowMaps.splice(parallelSplitShadowMaps.indexOf(_parallelSplitShadowMap), 1);
				_parallelSplitShadowMap.disposeAllRenderTarget();
				_parallelSplitShadowMap = null;
				scene.removeShaderDefine(ParallelSplitShadowMap.SHADERDEFINE_SHADOW_PSSM1);
				scene.removeShaderDefine(ParallelSplitShadowMap.SHADERDEFINE_SHADOW_PSSM2);
				scene.removeShaderDefine(ParallelSplitShadowMap.SHADERDEFINE_SHADOW_PSSM3);
			}
		}
		
		/**
		 * @private
		 */
		private function _onWorldMatrixChange():void {
			_updateDirection = true;
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _addSelfRenderObjects():void {
			super._addSelfRenderObjects();
			_shadow && (_initShadow());
		}
		
		/**
		 * @inheritDoc
		 */
		override protected function _clearSelfRenderObjects():void {
			var scene:Scene = this.scene;
			var shaderValue:ValusArray = scene._shaderValues;
			shaderValue.setValue(Scene.LIGHTDIRCOLOR, null);
			shaderValue.setValue(Scene.LIGHTDIRECTION, null);
			scene.removeShaderDefine(ShaderCompile3D.SHADERDEFINE_DIRECTIONLIGHT);
		}
		
		/**
		 * 更新平行光相关渲染状态参数。
		 * @param state 渲染状态参数。
		 */
		public override function updateToWorldState(state:RenderState):Boolean {
			var scene:Scene = state.scene;
			if (scene.enableLight && _activeInHierarchy) {
				var shaderValue:ValusArray = scene._shaderValues;
				scene.addShaderDefine(ShaderCompile3D.SHADERDEFINE_DIRECTIONLIGHT);
				shaderValue.setValue(Scene.LIGHTDIRCOLOR, color.elements);
				shaderValue.setValue(Scene.LIGHTDIRECTION, direction.elements);
				return true;
			} else {
				scene.removeShaderDefine(ShaderCompile3D.SHADERDEFINE_DIRECTIONLIGHT);
				return false;
			}
		}
	}
}