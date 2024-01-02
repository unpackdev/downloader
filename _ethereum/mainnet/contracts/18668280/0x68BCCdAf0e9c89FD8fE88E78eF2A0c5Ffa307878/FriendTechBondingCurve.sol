// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BondingCurve.sol";

/**
 * @title FriendTech Bonding Curve
 *
 * @notice friend.tech definition of the bonding curve function
 */
contract FriendTechBondingCurve is BondingCurve {
	/**
	 * @inheritdoc BondingCurve
	 *
	 * @param s supply, total shares supply
	 * @param a amount, number of shares to buy/sell
	 */
	function getPrice(uint256 s, uint256 a) public pure returns(uint256) {
		// this is the original friend tech formula with the underflow fix
		// the fix allows both supply and amount be zero, as well as
		// it allows supply be zero when the amount is bigger than one
		uint256 sum1 = s == 0 ? 0 : (s - 1) * s * (2 * (s - 1) + 1) / 6;
		uint256 sum2 = s == 0 && a <= 1 ? 0 : (s + a - 1) * (s + a) * (2 * (s + a - 1) + 1) / 6;
		uint256 summation = sum2 - sum1;
		return summation * 1 ether / 16000;
	}
}
