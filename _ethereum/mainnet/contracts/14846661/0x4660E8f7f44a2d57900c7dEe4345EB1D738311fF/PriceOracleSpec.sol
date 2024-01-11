// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Pair Price Oracle, a.k.a. Pair Oracle
 *
 * @notice Generic interface used to consult on the Uniswap-like token pairs conversion prices;
 *      one pair oracle is used to consult on the exchange rate within a single token pair
 *
 * @notice See also: https://docs.uniswap.org/protocol/V2/guides/smart-contract-integration/building-an-oracle
 *
 * @author Basil Gorin
 */
interface PairOracle {
	/**
	 * @notice Updates the oracle with the price values if required, for example
	 *      the cumulative price at the start and end of a period, etc.
	 *
	 * @dev This function is part of the oracle maintenance flow
	 */
	function update() external;

	/**
	 * @notice For a pair of tokens A/B (sell/buy), consults on the amount of token B to be
	 *      bought if the specified amount of token A to be sold
	 *
	 * @dev This function is part of the oracle usage flow
	 *
	 * @param token token A (token to sell) address
	 * @param amountIn amount of token A to sell
	 * @return amountOut amount of token B to be bought
	 */
	function consult(address token, uint256 amountIn) external view returns (uint256 amountOut);
}

/**
 * @title Price Oracle Registry
 *
 * @notice To make pair oracles more convenient to use, a more generic Oracle Registry
 *        interface is introduced: it stores the addresses of pair price oracles and allows
 *        searching/querying for them
 *
 * @author Basil Gorin
 */
interface PriceOracleRegistry {
	/**
	 * @notice Searches for the Pair Price Oracle for A/B (sell/buy) token pair
	 *
	 * @param tokenA token A (token to sell) address
	 * @param tokenB token B (token to buy) address
	 * @return pairOracle pair price oracle address for A/B token pair
	 */
	function getPriceOracle(address tokenA, address tokenB) external view returns (address pairOracle);
}

/**
 * @title Land Sale Price Oracle
 *
 * @notice Supports the Land Sale with the ETH/ILV conversion required,
 *       marker interface is required to support ERC165 lookups
 *
 * @author Basil Gorin
 */
interface LandSalePriceOracle {
	/**
	 * @notice Powers the ETH/ILV Land token price conversion, used when
	 *      selling the land for sILV to determine how much sILV to accept
	 *      instead of the nominated ETH price
	 *
	 * @notice Note that sILV price is considered to be equal to ILV price
	 *
	 * @dev Implementation must guarantee not to return zero, absurdly small
	 *      or big values, it must guarantee the price is up to date with some
	 *      reasonable update interval threshold
	 *
	 * @param ethOut amount of ETH sale contract is expecting to get
	 * @return ilvIn amount of sILV sale contract should accept instead
	 */
	function ethToIlv(uint256 ethOut) external returns (uint256 ilvIn);
}
