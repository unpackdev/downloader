// SPDX-License-Identifier: MPL-2.0
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.9;

import "./ITokenURIDescriptor.sol";
import "./ISTokensManagerStruct.sol";
import "./EnumerableSet.sol";
import "./Ownable.sol";

contract SimpleTiers is ITokenURIDescriptor, Ownable {
	EnumerableSet.UintSet private tiers;
	mapping(uint256 => string) public images;

	using EnumerableSet for EnumerableSet.UintSet;

	function image(
		uint256,
		address,
		ISTokensManagerStruct.StakingPositions memory _positions,
		ISTokensManagerStruct.Rewards memory,
		bytes32
	) external view returns (string memory) {
		uint256 amount = _positions.amount;
		uint256 pt;
		for (uint256 i = 0; i < tiers.length(); i++) {
			uint256 tier = tiers.at(i);
			if (tier <= amount && pt < tier) {
				pt = tier;
			}
		}
		return images[pt];
	}

	function setTier(uint256 _tier, string memory _image) external onlyOwner {
		if (tiers.contains(_tier)) {
			tiers.remove(_tier);
		}
		tiers.add(_tier);
		images[_tier] = _image;
	}

	function removeTier(uint256 _tier) external onlyOwner {
		tiers.remove(_tier);
		delete images[_tier];
	}

	function onBeforeMint(
		uint256,
		address,
		ISTokensManagerStruct.StakingPositions memory,
		bytes32
	) external pure returns (bool) {
		return true;
	}
}
