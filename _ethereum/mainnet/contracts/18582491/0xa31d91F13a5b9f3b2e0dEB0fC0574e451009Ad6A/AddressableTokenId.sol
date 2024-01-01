// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// solhint-disable no-inline-assembly
library AddressableTokenId {
	uint256 private constant _ADDRESSMASK =
		0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000;
	uint256 private constant _IDMASK =
		0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;

	/// @dev convert a tokenId to its artist's address
	function getAddress(
		uint256 tokenId
	) internal pure returns (address tokenAddress) {
		//return address(uint160(tokenId >> 96));
		assembly ("memory-safe") {
			tokenAddress := shr(96, tokenId)
		}
	}

	/// @dev artistEditions are always even
	function getArtistEdition(
		uint256 tokenId
	) internal pure returns (uint256 artistTokenId) {
		assembly ("memory-safe") {
			if iszero(mod(tokenId, 2)) {
				mstore(0, "TokenId: Already Artist Edition")
				revert(0, 31)
			}
			let idSuffix := and(tokenId, _IDMASK)
			// underflow is impossible due to the oddness check above
			let artistIndex := sub(idSuffix, 1)
			let artistPrefix := and(tokenId, _ADDRESSMASK)
			artistTokenId := or(artistPrefix, artistIndex)
			// revert if the tokenId is already even
		}
	}
}
