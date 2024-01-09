// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 🤛 👁👄👁 🤜 < Let's enjoy Solidity!!

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

import "./Strings.sol";
import "./BallcellLiquidBoyaParameters.sol";
import "./Base64.sol";

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

interface _BallcellLiquidBoyaImage {
	function svg(BallcellLiquidBoyaParameters.Parameters memory parameters) external pure returns (bytes memory);
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

library BallcellLiquidBoyaMainMetadata {
	function metadata(BallcellLiquidBoyaParameters.Parameters memory parameters, string memory tokenName, address addressContractImage) internal pure returns (string memory) {
		bytes memory temporary = "{";
		temporary = abi.encodePacked(temporary, '"name": "', _name(parameters, tokenName), '", ');
		temporary = abi.encodePacked(temporary, '"description": "', _description(), '", ');
		temporary = abi.encodePacked(temporary, '"attributes": ', _attributes(parameters), ", ");
		temporary = abi.encodePacked(temporary, '"image": "', _image(parameters, addressContractImage), '"');
		temporary = abi.encodePacked(temporary, "}");
		return string(abi.encodePacked("data:application/json;base64,", Base64.encode(temporary)));
	}

	function _name(BallcellLiquidBoyaParameters.Parameters memory parameters, string memory tokenName) private pure returns (bytes memory) {
		if (bytes(tokenName).length == 0) { tokenName = "liquid boya"; }
		return abi.encodePacked(tokenName, " #", Strings.toString(parameters.tokenId));
	}

	function _description() private pure returns (bytes memory) {
		return "ballcell liquid boya is a full on-chain NFT.";
	}

	function _attributes(BallcellLiquidBoyaParameters.Parameters memory parameters) private pure returns (bytes memory) {
		if (!parameters.revealed) { return "[]"; }
		bytes memory temporary = "[";
		if (parameters.radiusBody < 5) { temporary = abi.encodePacked(temporary, '{"trait_type":"body size","value":"small"}', ","); }
		if (parameters.radiusBody == 5) { temporary = abi.encodePacked(temporary, '{"trait_type":"body size","value":"normal"}', ","); }
		if (parameters.radiusBody > 5) { temporary = abi.encodePacked(temporary, '{"trait_type":"body size","value":"big"}', ","); }
		if (parameters.radiusFoot < 3) { temporary = abi.encodePacked(temporary, '{"trait_type":"foot size","value":"small"}', ","); }
		if (parameters.radiusFoot == 3) { temporary = abi.encodePacked(temporary, '{"trait_type":"foot size","value":"normal"}', ","); }
		if (parameters.radiusFoot > 3) { temporary = abi.encodePacked(temporary, '{"trait_type":"foot size","value":"big"}', ","); }
		if (parameters.radiusHand < 2) { temporary = abi.encodePacked(temporary, '{"trait_type":"hand size","value":"small"}', ","); }
		if (parameters.radiusHand == 2) { temporary = abi.encodePacked(temporary, '{"trait_type":"hand size","value":"normal"}', ","); }
		if (parameters.radiusHand > 2) { temporary = abi.encodePacked(temporary, '{"trait_type":"hand size","value":"big"}', ","); }
		if (parameters.radiusHead < 6) { temporary = abi.encodePacked(temporary, '{"trait_type":"head size","value":"small"}', ","); }
		if (parameters.radiusHead == 6) { temporary = abi.encodePacked(temporary, '{"trait_type":"head size","value":"normal"}', ","); }
		if (parameters.radiusHead > 6) { temporary = abi.encodePacked(temporary, '{"trait_type":"head size","value":"big"}', ","); }
		if (parameters.colorTypeBody == BallcellLiquidBoyaParameters.ColorTypeBody.Neutral) { temporary = abi.encodePacked(temporary, '{"trait_type":"body color","value":"neutral"}', ","); }
		if (parameters.colorTypeBody == BallcellLiquidBoyaParameters.ColorTypeBody.Bright) { temporary = abi.encodePacked(temporary, '{"trait_type":"body color","value":"bright"}', ","); }
		if (parameters.colorTypeBody == BallcellLiquidBoyaParameters.ColorTypeBody.Dark) { temporary = abi.encodePacked(temporary, '{"trait_type":"body color","value":"dark"}', ","); }
		if (parameters.colorTypeEye == BallcellLiquidBoyaParameters.ColorTypeEye.Monotone) { temporary = abi.encodePacked(temporary, '{"trait_type":"eye color","value":"monotone"}', ","); }
		if (parameters.colorTypeEye == BallcellLiquidBoyaParameters.ColorTypeEye.Single) { temporary = abi.encodePacked(temporary, '{"trait_type":"eye color","value":"single"}', ","); }
		if (parameters.colorTypeEye == BallcellLiquidBoyaParameters.ColorTypeEye.Double) { temporary = abi.encodePacked(temporary, '{"trait_type":"eye color","value":"double"}', ","); }
		if (parameters.colorFlagOne) { temporary = abi.encodePacked(temporary, '{"trait_type":"special","value":"one color"}', ","); }
		if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.None) { temporary = abi.encodePacked(temporary, '{"trait_type":"background","value":"none"}', ","); }
		if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.Single) { temporary = abi.encodePacked(temporary, '{"trait_type":"background","value":"single"}', ","); }
		if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.Circle) { temporary = abi.encodePacked(temporary, '{"trait_type":"background","value":"circle"}', ","); }
		if (parameters.backgroundType == BallcellLiquidBoyaParameters.BackgroundType.PolkaDot) { temporary = abi.encodePacked(temporary, '{"trait_type":"background","value":"polka dot"}', ","); }
		temporary = abi.encodePacked(temporary, '{"display_type":"number","trait_type":"rotation","value":"', Strings.toString(parameters.rotation), '"}', ",");
		temporary = abi.encodePacked(temporary, '{"display_type":"number","trait_type":"angle","value":"', Strings.toString(parameters.angle), '"}', ",");
		temporary = abi.encodePacked(temporary, '{"display_type":"number","trait_type":"distance","value":"', Strings.toString(parameters.distance), '"}', ",");
		temporary = abi.encodePacked(temporary, '{"display_type":"number","trait_type":"swing","value":"', Strings.toString(parameters.swing), '"}');
		return abi.encodePacked(temporary, "]");
	}

	function _image(BallcellLiquidBoyaParameters.Parameters memory parameters, address addressContractImage) private pure returns (bytes memory) {
		bytes memory temporary = _BallcellLiquidBoyaImage(addressContractImage).svg(parameters);
		return abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(temporary));
	}
}

// ----------------------------------------------------------------
// ----------------------------------------------------------------
// ----------------------------------------------------------------

