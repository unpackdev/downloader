// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 🤛 👁👄👁 🤜 < Let's enjoy Solidity!!

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

import "./BallcellLiquidBoyaParameters.sol";
import "./Random.sol";

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

library BallcellLiquidBoyaMainCreateParameters {
	struct Arguments {
		bool canceled;
		bool revealed;
		uint256 tokenId;
		uint256 passcode;
		address owner;
		string seedPhrase;
		bytes32 seedNumber;
		bool isSpecial;
	}

	function createParameters(Arguments memory arguments) internal pure returns (BallcellLiquidBoyaParameters.Parameters memory) {
		BallcellLiquidBoyaParameters.Parameters memory parameters;
		parameters.revealed = arguments.revealed;
		parameters.tokenId = arguments.tokenId;
		parameters.passcode = arguments.passcode;

		if (arguments.canceled) {
			// キャンセルパペット
			parameters.rotation = 60;
			parameters.angle = 60;
			parameters.distance = 9;
			parameters.swing = 0;
			parameters.radiusBody = 1;
			parameters.radiusFoot = 1;
			parameters.radiusHand = 1;
			parameters.radiusHead = 6;
			parameters.colorHueBody = 0;
			parameters.colorHueRFoot = 0;
			parameters.colorHueLFoot = 0;
			parameters.colorHueRHand = 0;
			parameters.colorHueLHand = 0;
			parameters.colorHueHead = 0;
			parameters.colorHueREye = 0;
			parameters.colorHueLEye = 0;
			parameters.colorLightnessBody = 100;
			parameters.colorLightnessEye = 0;
			parameters.colorFlagOne = true;
			parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Neutral;
			parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Monotone;
			parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.None;
			parameters.backgroundColor = 0;
			parameters.backgroundRandom = 0;
		} else if (!arguments.revealed) {
			// 開示前のダミーパペット
			Random.Status memory randomStatus;
			Random.init(randomStatus, uint256(keccak256(abi.encodePacked(arguments.tokenId))));
			parameters.rotation = Random.get(randomStatus) % (120 + 1);
			parameters.angle = Random.get(randomStatus) % (90 + 1);
			parameters.distance = 2;
			parameters.swing = 10;
			parameters.radiusBody = 5;
			parameters.radiusFoot = 3;
			parameters.radiusHand = 2;
			parameters.radiusHead = 6;
			parameters.colorHueBody = 0;
			parameters.colorHueRFoot = 0;
			parameters.colorHueLFoot = 0;
			parameters.colorHueRHand = 0;
			parameters.colorHueLHand = 0;
			parameters.colorHueHead = 0;
			parameters.colorHueREye = 0;
			parameters.colorHueLEye = 0;
			parameters.colorLightnessBody = 0;
			parameters.colorLightnessEye = 100;
			parameters.colorFlagOne = true;
			parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Neutral;
			parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Monotone;
			parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.None;
			parameters.backgroundColor = 0;
			parameters.backgroundRandom = 0;
		} else if (arguments.tokenId == 1) {
			// tokenId=1 オリジンパペット
			parameters.rotation = 90;
			parameters.angle = 60;
			parameters.distance = 2;
			parameters.swing = 10;
			parameters.radiusBody = 5;
			parameters.radiusFoot = 3;
			parameters.radiusHand = 2;
			parameters.radiusHead = 6;
			parameters.colorHueBody = 0;
			parameters.colorHueRFoot = 0;
			parameters.colorHueLFoot = 0;
			parameters.colorHueRHand = 0;
			parameters.colorHueLHand = 0;
			parameters.colorHueHead = 0;
			parameters.colorHueREye = 0;
			parameters.colorHueLEye = 0;
			parameters.colorLightnessBody = 50;
			parameters.colorLightnessEye = 0;
			parameters.colorFlagOne = true;
			parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Neutral;
			parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Monotone;
			parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.None;
			parameters.backgroundColor = 0;
			parameters.backgroundRandom = 0;
		} else {
			// 乱数の準備
			Random.Status memory randomStatusToken;
			Random.Status memory randomStatusOwner;
			bytes memory seedToken = abi.encodePacked(arguments.seedPhrase, arguments.seedNumber, arguments.tokenId);
			bytes memory seedOwner = abi.encodePacked(arguments.seedPhrase, arguments.seedNumber, arguments.owner);
			Random.init(randomStatusToken, uint256(keccak256(seedToken)));
			Random.init(randomStatusOwner, uint256(keccak256(seedOwner)));

			// パラメータテーブル
			uint8[20][5] memory table;
			table[0] = [0, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9];
			table[1] = [3, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 7, 7, 8, 9];
			table[2] = [1, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4];
			table[3] = [1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 4];
			table[4] = [3, 4, 4, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 8, 8, 9];

			// トークンに紐づくパペット形状
			parameters.rotation = Random.get(randomStatusToken) % (120 + 1);
			parameters.angle = Random.get(randomStatusToken) % (90 + 1);
			parameters.distance = table[0][Random.get(randomStatusToken) % 20];
			parameters.swing = Random.get(randomStatusToken) % (40 + 1);
			parameters.radiusBody = table[1][Random.get(randomStatusToken) % 20];
			parameters.radiusFoot = table[2][Random.get(randomStatusToken) % 20];
			parameters.radiusHand = table[3][Random.get(randomStatusToken) % 20];
			parameters.radiusHead = table[4][Random.get(randomStatusToken) % 20];

			// オーナーに紐づくパペット色
			parameters.colorHueBody = Random.get(randomStatusOwner) % 360;
			parameters.colorHueRFoot = Random.get(randomStatusOwner) % 360;
			parameters.colorHueLFoot = Random.get(randomStatusOwner) % 360;
			parameters.colorHueRHand = Random.get(randomStatusOwner) % 360;
			parameters.colorHueLHand = Random.get(randomStatusOwner) % 360;
			parameters.colorHueHead = Random.get(randomStatusOwner) % 360;
			parameters.colorHueREye = Random.get(randomStatusOwner) % 360;
			parameters.colorHueLEye = Random.get(randomStatusOwner) % 360;

			// トークンに紐づくパペット特殊色 単色
			// 単色パペットは激レアなので、レアリティの存在しないホームページのミントからは出現しない。
			if (arguments.isSpecial && Random.get(randomStatusToken) % 10 == 0) {
				parameters.colorFlagOne = true;
				parameters.colorHueRFoot = parameters.colorHueBody;
				parameters.colorHueLFoot = parameters.colorHueBody;
				parameters.colorHueRHand = parameters.colorHueBody;
				parameters.colorHueLHand = parameters.colorHueBody;
				parameters.colorHueHead = parameters.colorHueBody;
			} else {
				parameters.colorFlagOne = false;
			}

			// トークンに紐づくパペット特殊色 輝度
			if (Random.get(randomStatusToken) % 2 == 0) {
				parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Neutral;
				parameters.colorLightnessBody = 50;
				parameters.colorLightnessEye = 20;
			} else if (Random.get(randomStatusToken) % 2 == 0) {
				parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Bright;
				parameters.colorLightnessBody = 80;
				parameters.colorLightnessEye = 20;
			} else {
				parameters.colorTypeBody = BallcellLiquidBoyaParameters.ColorTypeBody.Dark;
				parameters.colorLightnessBody = 20;
				parameters.colorLightnessEye = 80;
			}

			// トークンに紐づくパペット特殊色 目
			if (Random.get(randomStatusToken) % 2 == 0) {
				parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Monotone;
				parameters.colorHueREye = 0;
				parameters.colorHueLEye = 0;
				parameters.colorLightnessEye = parameters.colorLightnessEye > 50 ? 100 : 0;
			} else if (Random.get(randomStatusToken) % 2 == 0) {
				parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Single;
				parameters.colorHueLEye = parameters.colorHueREye;
			} else {
				parameters.colorTypeEye = BallcellLiquidBoyaParameters.ColorTypeEye.Double;
			}

			// 背景パラメータ
			uint backgroundType = Random.get(randomStatusToken) % 4;
			if (backgroundType == 0) { parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.None; }
			if (backgroundType == 1) { parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.Single; }
			if (backgroundType == 2) { parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.Circle; }
			if (backgroundType == 3) { parameters.backgroundType = BallcellLiquidBoyaParameters.BackgroundType.PolkaDot; }
			parameters.backgroundColor = Random.get(randomStatusToken) % 360;
			parameters.backgroundRandom = Random.get(randomStatusToken);
		}

		return parameters;
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

