// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
* @title Interface defining a contract that should manage multiple exchange-oracles
*/
interface IOracleManager {
    /**
    * @notice Function used to exchange currencies
    * @param srcToken The currency to be exchanged
    * @param dstToken The currency to be exchanged for
    * @param amountIn The amount of currency to be exchanged
    * @return The resulting amount of dstToken
    */
    function getAmountOut(
        address srcToken,
        address dstToken,
        uint256 amountIn
    ) external returns (uint256);

    /**
    * @notice Function used to see the current exchange amount
    * @param srcToken The currency to be exchanged
    * @param dstToken The currency to be exchanged for
    * @param amountIn The amount of currency to be exchanged
    * @return The resulting amount of dstToken
    */
    function getAmountOutView(
        address srcToken,
        address dstToken,
        uint256 amountIn
    ) external view returns (uint256);
}
