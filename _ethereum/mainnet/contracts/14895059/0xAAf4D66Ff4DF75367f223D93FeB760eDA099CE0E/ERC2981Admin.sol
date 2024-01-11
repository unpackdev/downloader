// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OwnableInternal.sol";

import "./ERC2981Storage.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981Admin is OwnableInternal {
	/// @dev Sets token royalties
	/// @param recipient recipient of the royalties
	/// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
	function setRoyalties(address recipient, uint256 value) external onlyOwner {
		require(value <= 10000, "ERC2981Royalties: Too high");
		ERC2981Storage.layout().royalties = RoyaltyInfo(recipient, uint24(value));
	}
}
