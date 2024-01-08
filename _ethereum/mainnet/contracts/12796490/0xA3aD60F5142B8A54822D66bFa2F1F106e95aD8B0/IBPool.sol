// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.2;

interface IBPool {

    function MAX_IN_RATIO() external view returns (uint);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint);

    function getTotalDenormalizedWeight() external view returns (uint);

    function getBalance(address token) external view returns (uint);

    function getSwapFee() external view returns (uint);

    function calcPoolOutGivenSingleIn(
        uint tokenBalanceIn,
        uint tokenWeightIn,
        uint poolSupply,
        uint totalWeight,
        uint tokenAmountIn,
        uint swapFee
    ) external pure returns (uint poolAmountOut);

}
