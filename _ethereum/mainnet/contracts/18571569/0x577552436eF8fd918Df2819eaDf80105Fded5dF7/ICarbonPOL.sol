// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Token.sol";

/**
 * @notice CarbonPOL interface
 */
interface ICarbonPOL {
    /**
     * @notice returns the expected trade output (tokens received) given an eth amount sent for a token
     */
    function expectedTradeReturn(Token token, uint128 ethAmount) external view returns (uint128 tokenAmount);

    /**
     * @notice trades ETH for *amount* of token based on the current token price (trade by target amount)
     */
    function trade(Token token, uint128 amount) external payable;
}
