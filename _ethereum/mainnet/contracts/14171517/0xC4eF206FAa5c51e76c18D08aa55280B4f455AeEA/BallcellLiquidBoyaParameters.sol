// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 🤛 👁👄👁 🤜 < Let's enjoy Solidity!!

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

library BallcellLiquidBoyaParameters {
	struct Parameters {
		bool revealed;
		uint256 tokenId;
		uint256 passcode;

		uint256 rotation;
		uint256 angle;
		uint256 distance;
		uint256 swing;
		uint256 radiusBody;
		uint256 radiusFoot;
		uint256 radiusHand;
		uint256 radiusHead;

		uint256 colorHueBody;
		uint256 colorHueRFoot;
		uint256 colorHueLFoot;
		uint256 colorHueRHand;
		uint256 colorHueLHand;
		uint256 colorHueHead;
		uint256 colorHueREye;
		uint256 colorHueLEye;
		uint256 colorLightnessBody;
		uint256 colorLightnessEye;

		bool colorFlagOne;
		ColorTypeBody colorTypeBody;
		ColorTypeEye colorTypeEye;

		BackgroundType backgroundType;
		uint256 backgroundColor;
		uint256 backgroundRandom;
	}

	enum ColorTypeBody { Neutral, Bright, Dark }
	enum ColorTypeEye { Monotone, Single, Double }
	enum BackgroundType { None, Single, Circle, PolkaDot, GradationLinear, Lgbt }

	uint constant _keyRotation = 0;
	uint constant _keyAngle = 1;
	uint constant _keyDistance = 2;
	uint constant _keySwing = 3;
	uint constant _keyRadiusBody = 4;
	uint constant _keyRadiusFoot = 5;
	uint constant _keyRadiusHand = 6;
	uint constant _keyRadiusHead = 7;
	uint constant _keyColorHueBody = 8;
	uint constant _keyColorHueRFoot = 9;
	uint constant _keyColorHueLFoot = 10;
	uint constant _keyColorHueRHand = 11;
	uint constant _keyColorHueLHand = 12;
	uint constant _keyColorHueHead = 13;
	uint constant _keyColorHueREye = 14;
	uint constant _keyColorHueLEye = 15;
	uint constant _keyColorLightnessBody = 16;
	uint constant _keyColorLightnessEye = 17;
	function createArray(Parameters memory parameters) internal pure returns (uint16[18] memory) {
		uint16[18] memory array;
		array[_keyRotation] = uint16(parameters.rotation);
		array[_keyAngle] = uint16(parameters.angle);
		array[_keyDistance] = uint16(parameters.distance);
		array[_keySwing] = uint16(parameters.swing);
		array[_keyRadiusBody] = uint16(parameters.radiusBody);
		array[_keyRadiusFoot] = uint16(parameters.radiusFoot);
		array[_keyRadiusHand] = uint16(parameters.radiusHand);
		array[_keyRadiusHead] = uint16(parameters.radiusHead);
		array[_keyColorHueBody] = uint16(parameters.colorHueBody);
		array[_keyColorHueRFoot] = uint16(parameters.colorHueRFoot);
		array[_keyColorHueLFoot] = uint16(parameters.colorHueLFoot);
		array[_keyColorHueRHand] = uint16(parameters.colorHueRHand);
		array[_keyColorHueLHand] = uint16(parameters.colorHueLHand);
		array[_keyColorHueHead] = uint16(parameters.colorHueHead);
		array[_keyColorHueREye] = uint16(parameters.colorHueREye);
		array[_keyColorHueLEye] = uint16(parameters.colorHueLEye);
		array[_keyColorLightnessBody] = uint16(parameters.colorLightnessBody);
		array[_keyColorLightnessEye] = uint16(parameters.colorLightnessEye);
		return array;
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

