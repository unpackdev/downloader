// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Token.sol";

/**
 * @notice CarbonPOL interface
 */
interface ICarbonPOL {

    /**
     * @notice returns the expected trade output (tokens received) given an token amount sent
     */
    function expectedTradeReturn(Token token, uint128 ethAmount) external view returns (uint128 tokenAmount);

    /**
     * @notice returns the expected trade input (how many tokens to send) given a token amount received
     */
    function expectedTradeInput(Token token, uint128 tokenAmount) external view returns (uint128 ethAmount);

    /**
     * @notice trades ETH for *amount* of token based on the current token price (trade by target amount)
     * @notice if token == ETH, trades BNT for amount of ETH
     */
    function trade(Token token, uint128 amount) external payable;
}
