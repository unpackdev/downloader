// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./MentalHealthCoalition.sol";

/// @title Initiative1Redeemer
/// Redeemer for The Mental Health Coalition Initiative 1 Mint
contract Initiative1Redeemer {

	/// Indicates that an invalid amount of tokens to redeem was provided
	error UnownedAmount();

	/// @dev Reference to the MentalHealthCoalition ERC-1155 contract
	MentalHealthCoalition private immutable _mentalHealthCoalition;

	/// Constructs the `Initiative1Redeemer` minting contract
	/// @param mentalHealthCoalition The address of the `MentalHealthCoalition` ERC-1155 contract
	constructor(address mentalHealthCoalition) {
		require(mentalHealthCoalition != address(0), "constructor: invalid inputs");
		_mentalHealthCoalition = MentalHealthCoalition(mentalHealthCoalition);
	}

	/// Redeems the provided type and quantity of Kennethisms
	/// @dev There are some optimizations to reduce minting gas costs, which have been thoroughly unit tested
	/// @param redeemTokenAmounts The amounts of tokens to be redeemed for token ids 0 through 3 (index equals id)
	function redeemKennethisms(uint256[4] calldata redeemTokenAmounts) external {
		// Check array contents, while producing the mintBurnBatch() input arrays
		uint count = 0; // Determines the size of the input arrays for minting
		unchecked {
			for (uint index = 0; index < 4; index++) {
				uint current = redeemTokenAmounts[index];
				// Are we redeeming this token id?
				if (current == 0) continue;
				// Validate sufficient ownership of the tokens to redeem
				if (_mentalHealthCoalition.balanceOf(msg.sender, index) < current) revert UnownedAmount();
				count++;
			}
		}
		// Now prepare the arrays to be passed into the minting function
		uint256[] memory newTokenIds = new uint256[](count);
		uint256[] memory oldTokenIds = new uint256[](count);
		uint256[] memory tokenAmounts = new uint256[](count);
		count = 0; // Reset count as an index into the arrays above
		unchecked {
			for (uint index = 0; index < 4; index++) {
				uint current = redeemTokenAmounts[index];
				// Are we redeeming this token id?
				if (current == 0) continue;
				newTokenIds[count] = index + 4;
				oldTokenIds[count] = index;
				tokenAmounts[count] = current;
				count++;
			}
		}
		_mentalHealthCoalition.mintBurnBatch(msg.sender, newTokenIds, tokenAmounts, oldTokenIds, tokenAmounts);
	}
}
