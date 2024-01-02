// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Bonding Curve
 *
 * @notice A friend.tech-like bonding curve definition
 *
 * @notice Bonding curve defines the price of the smallest unit of the asset as a function
 *      of the asset supply
 */
interface BondingCurve {
	/**
	 * @notice Bonding curve function definition. The function calculating the price
	 *      of the `amount` of shares given the current total supply `supply`
	 *
	 * @param supply total shares supply
	 * @param amount number of shares to buy/sell
	 * @return the price of the shares (all `amount` amount)
	 */
	function getPrice(uint256 supply, uint256 amount) external pure returns(uint256);
}
